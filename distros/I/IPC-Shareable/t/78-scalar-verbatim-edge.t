use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue relieve_ipc_pressure);

use JSON qw(encode_json);
use Storable qw(freeze);

# Backward-compat, storable, and validation edges for the automatic verbatim
# scalar storage.
#
# relieve_ipc_pressure() between blocks is a no-op on roomy hosts (so behaviour
# there is unchanged) but releases each block's IPC on small-semmni hosts like
# OpenBSD (semmni=10), so the accumulated ties never exhaust the system.

# ---------------------------------------------------------------------------
# 1. A legacy {"__sv__":...} scalar segment (no sentinel) still reads: the
#    verbatim peek finds no \x1e and falls through to the json unwrap.
# ---------------------------------------------------------------------------
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('edge-legacy-sv'), create => 1, destroy => 1, size => 1024 };
    # Hand-write a legacy json-wrapped scalar body (what an older release wrote).
    tied($s)->seg->shmwrite('IPC::Shareable' . encode_json({ '__sv__' => 'hello' }));
    is $s, 'hello', 'legacy {"__sv__":...} scalar segment still reads correctly';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# 2. A string that LOOKS like the wrapper is stored verbatim, not unwrapped:
#    the sentinel keeps us from re-interpreting the caller's bytes.
# ---------------------------------------------------------------------------
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('edge-literal-sv'), create => 1, destroy => 1, size => 1024 };
    my $trap = '{"__sv__":"trap"}';
    $s = $trap;
    is $s, $trap, 'a literal __sv__-shaped string round-trips verbatim (not unwrapped)';
    my $bytes = tied($s)->seg->shmread;
    $bytes =~ s/\x00+$//;
    is $bytes, "IPC::Shareable\x1e" . $trap, '...stored verbatim with the sentinel';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# 3. A legacy Storable-frozen scalar segment (first body byte 0x04, not the
#    \x1e sentinel) still triggers the storable->json fallback: warn + switch.
# ---------------------------------------------------------------------------
{
    my $key = unique_glue('edge-legacy-frozen');

    tie my $seed, 'IPC::Shareable', { key => $key, create => 1, destroy => 1, serializer => 'storable', size => 1024 };
    # Hand-write a legacy Storable-frozen scalar body (freeze of \$val).
    tied($seed)->seg->shmwrite('IPC::Shareable' . freeze(\'frozen-hello'));

    my @warns;
    {
        local $SIG{__WARN__} = sub { push @warns, @_ };
        tie my $s2, 'IPC::Shareable', { key => $key, create => 0, size => 1024 };  # json default
        is $s2, 'frozen-hello',
            'legacy frozen scalar readable via storable->json fallback';
        is tied($s2)->attributes('serializer'), 'storable',
            'serializer switched to storable for the session';
    }
    ok scalar(grep { /Storable-encoded/ } @warns),
        'fallback warning emitted for the frozen scalar';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# 4. Serializer-agnostic: a storable scalar holding a plain value is verbatim;
#    holding a ref it takes the storable path, and both round-trip.
# ---------------------------------------------------------------------------
{
    tie my $sp, 'IPC::Shareable', { key => unique_glue('edge-stor-plain'), create => 1, destroy => 1, serializer => 'storable', size => 1024 };
    $sp = 'plain-stor';
    is $sp, 'plain-stor', 'storable scalar plain value round-trips';
    my $b = tied($sp)->seg->shmread;
    $b =~ s/\x00+$//;
    is $b, "IPC::Shareable\x1eplain-stor", '...stored verbatim (serializer-agnostic)';
}
relieve_ipc_pressure();
{
    tie my $sr, 'IPC::Shareable', { key => unique_glue('edge-stor-ref'), create => 1, destroy => 1, serializer => 'storable', size => 4096 };
    $sr = { deep => [1, 2, 3] };
    is $sr->{deep}[2], 3, 'storable scalar holding a ref round-trips';
    my $b = tied($sr)->seg->shmread;
    $b =~ s/\x00+$//;
    unlike $b, qr/^IPC::Shareable\x1e/, '...and is NOT verbatim (ref takes the serializer path)';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# 5. Aggregate ties are untouched by verbatim (always serialized).
# ---------------------------------------------------------------------------
{
    tie my %hj, 'IPC::Shareable', { key => unique_glue('edge-hash-json'), create => 1, destroy => 1, size => 4096 };
    %hj = (a => 1, b => 'two');
    is $hj{a}, 1,     'json hash round-trips (a)';
    is $hj{b}, 'two', 'json hash round-trips (b)';
    my $b = tied(%hj)->seg->shmread;
    $b =~ s/\x00+$//;
    unlike $b, qr/^IPC::Shareable\x1e/, '...json hash segment is not verbatim';

    tie my @aj, 'IPC::Shareable', { key => unique_glue('edge-arr-json'), create => 1, destroy => 1, size => 4096 };
    @aj = (10, 20, 30);
    is $aj[1], 20, 'json array round-trips';

    tie my %hs, 'IPC::Shareable', { key => unique_glue('edge-hash-stor'), create => 1, destroy => 1, serializer => 'storable', size => 4096 };
    %hs = (x => 'y');
    is $hs{x}, 'y', 'storable hash round-trips';
    my $bs = tied(%hs)->seg->shmread;
    $bs =~ s/\x00+$//;
    unlike $bs, qr/^IPC::Shareable\x1e/, '...storable hash segment is not verbatim';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# 6. Only json and storable are accepted serializers ('raw' is not public).
# ---------------------------------------------------------------------------
{
    for my $bad (qw(raw bogus none)) {
        my $ok = eval {
            tie my $s, 'IPC::Shareable', { key => unique_glue("edge-bad-$bad"), create => 1, destroy => 1, serializer => $bad };
            1;
        };
        ok ! $ok, "serializer => '$bad' is rejected";
    }

    eval { tie my $s, 'IPC::Shareable', { key => unique_glue('edge-bad-msg'), create => 1, destroy => 1, serializer => 'raw' } };
    like $@, qr/must be 'json' or 'storable'/,
        'rejection message names the valid serializers';
}
relieve_ipc_pressure();

IPC::Shareable::_end;

assert_clean_process();

done_testing();
