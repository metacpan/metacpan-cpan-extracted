#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();

# The C ABI: the table has a stable address, the selftest walks a block
# through every entry in C and produces the same bytes the Perl surface does
# for the same structure, and the provider config points a consumer at the
# installed header.

my $p = Frozen::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, Frozen::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer: where the loader maps the object decides the sign bit');

# ---- the selftest ---------------------------------------------------------
#
# A table is a list of addresses, and nothing about compiling one proves an
# entry points where its declaration says. The selftest builds a structure in
# C, freezes it, and reads it back through every entry with every answer
# checked: the container doors, the three-way probe, descent by key and by
# path, the array and the hash by position, the four leaf readers, forged
# handles of two shapes, the walk, and the SV bridge.
my ($step, $bytes, $data) = Frozen::_abi_selftest();

is($step, 0, 'every entry in the table answered as its declaration says')
    or diag("check number $step in fz_abi_selftest failed; the numbers are "
          . "the FZ_STEP comments in include/fz/fz_abi_impl.h");

ok(defined $bytes && length $bytes, 'and it froze a block on the way through');
ok(!utf8::is_utf8($bytes), 'which is bytes');

# The second opinion. The table can be self-consistently wrong - two entries
# of the same shape answering each other's questions perfectly - and the Perl
# surface is what cannot be wrong in the same direction, because it does not
# go through the table at all.
is($bytes, Frozen->freeze($data, flat => '.'),
   'the block the C side built equals the Perl surface\'s for the same structure');

# And the structure really is the one the selftest's checks describe, rather
# than whatever the C happened to build: a test that took the C side's word
# for both halves would compare it with itself.
is_deeply($data, {
    greeting => 'hello',
    plural   => { one => '1 item', other => 'n items' },
    nums     => [ -5, ~0, 1.5 ],
    flags    => { on => \1, off => \0, none => undef },
    'a.b'    => 'dotted',
}, 'and the structure it built is the one the checks are written against');

# ---- the two ends of the version -----------------------------------------
#
# The table compiled into the .so, and the header that was INSTALLED for
# consumers to compile against. They are different files, and nothing else
# notices when an append moves one and not the other: the table would answer 1
# while the header promised 2, and every consumer built against 2 would refuse
# a provider that in fact has what it wants.
is(Frozen::_abi_version(), 1, 'the table reports the version it shipped at');

{
    require Frozen::Install::Files;
    no warnings 'once';
    my $core = $Frozen::Install::Files::CORE;
    ok(defined $core && -d $core, 'Install::Files records where the header went')
        or diag 'CORE: ' . ($core // 'undef');

    my $h = defined $core ? "$core/fz_abi.h" : undef;
    ok(defined $h && -f $h, 'and fz_abi.h is there for a consumer to include');

    my $header;
    if (defined $h && open my $fh, '<', $h) {
        while (<$fh>) { $header = $1, last if /^\#define\s+FZ_ABI_VERSION\s+(\d+)/ }
        close $fh;
    }
    is($header, Frozen::_abi_version(),
       'the installed header and the compiled table name the same ABI version');
}

# ---- what a consumer is promised ------------------------------------------
#
# Not the table's contents - a consumer resolves those in C - but the two
# things it cannot check for itself from Perl: that the header it compiled
# against is the one being installed, and that the entries it was written for
# are still in the order they were published in. An append moves nothing
# above it; a REORDER moves everything, silently, because a function pointer
# has no name at runtime.
{
    my $core = do { no warnings 'once'; $Frozen::Install::Files::CORE };
    my @members;
    SKIP: {
        skip 'no installed header to read', 1 unless defined $core && -f "$core/fz_abi.h";
        open my $fh, '<', "$core/fz_abi.h" or skip "cannot read the header: $!", 1;
        my $in;
        while (<$fh>) {
            $in = 1 if /^typedef struct fz_abi \{/;
            next unless $in;
            last if /^\} fz_abi;/;
            push @members, $1 if /\(\s*\*(\w+)\s*\)\s*\(/;
        }
        close $fh;
        is_deeply(\@members, [qw(
            open attach close error
            root probe child path at key_at count kind
            str iv uv nv
            walk sv_from_node
        )], 'the entries are in the order version 1 published them');
    }
}

done_testing;
