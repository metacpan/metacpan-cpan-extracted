use warnings;
use strict;

use IPC::Shareable qw(:lock);
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process live_seg_count unique_glue relieve_ipc_pressure require_free_sem_sets);

require_free_sem_sets();

use JSON qw(encode_json decode_json);
use POSIX ();

# A scalar holding a plain (non-ref) value is stored verbatim and automatically
# under the normal (default json) tie: no __sv__ wrapping, no escaping, one
# segment. The caller owns encode/decode. A reference still fans out as before.
#
# relieve_ipc_pressure() between blocks is a no-op on roomy hosts (so behaviour
# there is unchanged) but releases each block's IPC on small-semmni hosts like
# OpenBSD (semmni=10), so the accumulated ties never exhaust the system.

my $SIZE = 65536;

# ---------------------------------------------------------------------------
# Segment layout: a plain scalar is 'IPC::Shareable' + \x1e + the bytes,
# NOT wrapped as {"__sv__":...}.
# ---------------------------------------------------------------------------
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-fmt'), create => 1, destroy => 1, size => $SIZE };
    $s = q({"a":1});
    my $bytes = (tied $s)->seg->shmread;
    $bytes =~ s/\x00+$//;
    is $bytes, "IPC::Shareable\x1e" . q({"a":1}),
        'plain scalar stored verbatim (tag + \x1e + bytes)';
    unlike $bytes, qr/__sv__/, '...no __sv__ escaping in the segment';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# Pre-serialize a deep structure -> ONE segment; fetch verbatim; user decodes.
# ---------------------------------------------------------------------------
{
    my $struct = {
        name  => 'widget',
        count => 3,
        tags  => [qw(a b c)],
        meta  => { deep => [1, 2, { x => 'y' }] },
    };
    my $blob = encode_json($struct);

    my $before = live_seg_count();
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-struct'), create => 1, destroy => 1, size => $SIZE };
    $s = $blob;

    is live_seg_count() - $before, 1, 'pre-serialized deep structure occupies exactly ONE segment';
    is $s, $blob, 'scalar returns the pre-serialized bytes verbatim';
    is_deeply decode_json($s), $struct, 'caller decodes the bytes back to the original structure';
}
relieve_ipc_pressure();

# Contrast: a native nested tie of the same shape fans out to many segments.
{
    my $before = live_seg_count();
    tie my %h, 'IPC::Shareable', { key => unique_glue('sv-native'), create => 1, destroy => 1, size => $SIZE };
    %h = (name => 'widget', meta => { deep => [1, 2, { x => 'y' }] });
    cmp_ok live_seg_count() - $before, '>', 1, 'a native nested tie fans out (verbatim collapses to one)';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# Plain strings, integers, floats round-trip (numbers come back as strings).
# ---------------------------------------------------------------------------
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-scalars'), create => 1, destroy => 1, size => 1024 };

    $s = 'just a plain string';
    is $s, 'just a plain string', 'plain (non-JSON) string round-trips verbatim';

    $s = 42;
    is $s, 42,           'integer round-trips (string-equal)';
    cmp_ok $s, '==', 42, 'integer round-trips (numerically equal)';

    $s = -7;
    cmp_ok $s, '==', -7, 'negative integer ok';

    $s = 3.14;
    cmp_ok $s, '==', 3.14, 'float round-trips numerically';
}
relieve_ipc_pressure();

# undef is preserved (falls through to {"__sv__":null}, not verbatim).
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-undef'), create => 1, destroy => 1, size => 256 };
    $s = 'set';
    $s = undef;
    ok ! defined $s, 'undef round-trips as undef (preserved via normal path)';
    my $bytes = (tied $s)->seg->shmread;
    $bytes =~ s/\x00+$//;
    is $bytes, q(IPC::Shareable{"__sv__":null}), '...stored as {"__sv__":null}, not verbatim';
}
relieve_ipc_pressure();

# Empty string is a defined ''.
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-empty'), create => 1, destroy => 1, size => 256 };
    $s = '';
    ok defined $s, 'empty string is defined';
    is $s, '', '...and equals the empty string';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# A reference still fans out into child segment(s) (unchanged behavior).
# ---------------------------------------------------------------------------
{
    my $before = live_seg_count();
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-ref'), create => 1, destroy => 1, size => $SIZE };
    $s = { a => 1, b => [2, 3] };
    cmp_ok live_seg_count() - $before, '>', 1, 'a scalar holding a ref fans out (not verbatim)';
    is $s->{a},    1, 'ref value readable';
    is $s->{b}[1], 3, 'nested ref value readable';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# Flip-flop: string -> ref -> string in the same scalar; child cleaned up.
# ---------------------------------------------------------------------------
{
    my $base = live_seg_count();
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-flip'), create => 1, destroy => 1, size => $SIZE };

    $s = 'plain';
    is $s, 'plain', 'flip: string value';
    is live_seg_count() - $base, 1, '...one segment (verbatim)';

    $s = { k => 9 };
    is $s->{k}, 9, 'flip: ref value';
    cmp_ok live_seg_count() - $base, '>', 1, '...fans out to a child';

    $s = 'again';
    is $s, 'again', 'flip: back to a string value';
    is live_seg_count() - $base, 1, '...child cleaned up, back to one segment';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# Round-trip under shared and exclusive locks.
# ---------------------------------------------------------------------------
{
    my $blob = encode_json({ a => 1 });
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-lock'), create => 1, destroy => 1, size => 1024 };
    $s = $blob;

    my $obj = tied $s;

    $obj->lock(LOCK_SH);
    is $s, $blob, 'LOCK_SH FETCH returns verbatim bytes';
    $obj->unlock;

    my $blob2 = encode_json({ a => 2 });
    $obj->lock(LOCK_EX);
    $s = $blob2;
    $obj->unlock;
    is $s, $blob2, 'LOCK_EX write then read back ok';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# Payload hazards: literal tag text, the \x1e sentinel byte, internal NULs.
# ---------------------------------------------------------------------------
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-haz'), create => 1, destroy => 1, size => 1024 };

    my $tagtext = 'IPC::Shareable' . '{"looks":"tagged"}';
    $s = $tagtext;
    is $s, $tagtext, 'payload beginning with the literal tag round-trips';

    $s = "a\x1eb\x1ec";
    is $s, "a\x1eb\x1ec", 'payload containing the \x1e sentinel byte round-trips';

    $s = "a\x00b\x00c";
    is $s, "a\x00b\x00c", 'internal NUL bytes preserved';
    is length($s), 5, '...with correct length';
}
relieve_ipc_pressure();

# UTF-8 octets (encode_json output) round-trip and decode back intact.
{
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-utf8'), create => 1, destroy => 1, size => 1024 };
    my $struct = { msg => "caf\x{e9}", snow => "\x{2603}" };
    my $blob = encode_json($struct);
    $s = $blob;
    is $s, $blob, 'UTF-8 JSON octets stored verbatim';
    is_deeply decode_json($s), $struct, 'UTF-8 payload decodes back intact';
}
relieve_ipc_pressure();

# Size guard still applies (tag + sentinel + payload must fit).
{
    my $size = 64;
    tie my $s, 'IPC::Shareable', { key => unique_glue('sv-size'), create => 1, destroy => 1, size => $size };

    my $fits = 'x' x ($size - length('IPC::Shareable') - 1);   # -1 for the \x1e sentinel
    $s = $fits;
    is $s, $fits, 'payload that fills the segment (minus tag+sentinel) fits';

    my $over = 'x' x ($size - length('IPC::Shareable'));
    my $ok = eval { $s = $over; 1 };
    ok ! $ok, 'oversize payload croaks';
    like $@, qr/exceeds shared segment size/, '...with the size-exceeded message';
}
relieve_ipc_pressure();

# ---------------------------------------------------------------------------
# Cross-process: a producer stores, a separate process reads verbatim.
# ---------------------------------------------------------------------------
{
    my $glue = unique_glue('sv-xproc');
    my $blob = encode_json({ shared => [4, 5, 6], who => 'parent' });

    tie my $p, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1, size => $SIZE };
    $p = $blob;

    pipe(my $rd, my $wr) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $rd;
        tie my $c, 'IPC::Shareable', { key => $glue, create => 0, size => $SIZE };
        my $msg = (defined $c && $c eq $blob) ? 'MATCH' : 'MISMATCH';
        print {$wr} $msg;
        close $wr;
        POSIX::_exit(0);
    }

    close $wr;
    my $got = do { local $/; <$rd> };
    close $rd;
    waitpid $pid, 0;

    is $got, 'MATCH', "consumer process reads the producer's bytes verbatim";
}
relieve_ipc_pressure();

IPC::Shareable::_end;

assert_clean_process();

done_testing();
