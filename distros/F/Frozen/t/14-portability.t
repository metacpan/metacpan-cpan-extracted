#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();
use Config;

# The edges that only appear on machines this one is not.

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my %data = (greeting => 'hello', n => 42, list => [1, 2, 3]);
my $good = Frozen->freeze(\%data);

# ---- big-endian --------------------------------------------------------
#
# No big-endian machine is available and none is needed: byteswap the probe
# and assert the refusal fires. A block of the other endianness is REFUSED,
# never byteswapped - byteswapping on read would be a branch on every
# dereference on the hot path, serving a case that has no caller.

{
    my $swapped = $good;
    substr($swapped, 12, 4) = reverse substr($swapped, 12, 4);
    eval { Frozen->attach($swapped); 1 };
    like($@, qr/endianness/, 'a wrong-endian block is refused');
    unlike($@, qr/swap/i, 'and is not byteswapped');
}

# ---- a format version this build does not read -------------------------

{
    my $future = $good;
    substr($future, 4, 2) = pack('v', 99);
    eval { Frozen->attach($future); 1 };
    like($@, qr/format version/, 'a future format version is refused');
}

# ---- the reserved 64-bit-offset flag -----------------------------------
#
# Over 4 GiB is refused with a message naming the flag rather than a generic
# size error, and the header is crafted rather than a 4 GiB file written.

{
    my $off64 = $good;
    substr($off64, 8, 4) = pack('V', unpack('V', substr($off64, 8, 4)) | 0x1);
    eval { Frozen->attach($off64); 1 };
    like($@, qr/64-bit offsets/, 'the reserved 64-bit-offset flag is refused');
}

# ---- an offset width this build does not read --------------------------

{
    my $w = $good;
    substr($w, 16, 1) = chr(8);
    eval { Frozen->attach($w); 1 };
    like($@, qr/offset width/, 'an unexpected offset width is refused');
}

# ---- alignment ----------------------------------------------------------
#
# mmap gives page alignment; a scalar's PV gives whatever it gives. attach
# copies, which settles it - but the block must read correctly whatever the
# source pointer was, and that is what this asserts.

{
    for my $shift (0 .. 7) {
        my $padded = ("\0" x $shift) . $good;
        my $mis    = substr($padded, $shift);
        my $fz     = eval { Frozen->attach($mis) };
        ok($fz, "a block from a PV shifted by $shift attaches") or diag $@;
        my ($v) = $fz->fetch($fz->root, 'greeting');
        is($v, 'hello', "...and reads correctly at shift $shift");
    }
}

# ---- integer width ------------------------------------------------------
#
# The format stores an i64 regardless of the perl's IV width, so a value that
# does not fit the reading perl's IV must not come back silently wrong.

{
    my $fz = Frozen->attach($good);
    my ($n) = $fz->fetch($fz->root, 'n');
    is($n, 42, 'a small integer reads on any IV width');

    diag("this perl: ivsize=$Config{ivsize} nvsize=$Config{nvsize} "
       . "longsize=$Config{longsize}");

  SKIP: {
        skip 'needs 64-bit IVs to construct the value', 2
            unless $Config{ivsize} >= 8;
        my $big = Frozen->attach(Frozen->freeze({ big => ~0, neg => -(2**40) }));
        my ($u) = $big->fetch($big->root, 'big');
        is($u, ~0, 'a UV above IV_MAX round-trips');
        my ($s) = $big->fetch($big->root, 'neg');
        is($s, -(2**40), 'and a large negative IV');
    }
}

# ---- no-mmap fallback ---------------------------------------------------
#
# `copy => 1` is the path a caller takes when a file might be rewritten under
# the mapping, and it is also what a platform without mmap would get. It must
# read identically and must SAY that it is not mapped.

{
    my $path = "$dir/x.frz";
    Frozen->freeze_to($path, \%data);
    my $mapped = Frozen->open($path);
    my $copied = Frozen->open($path, copy => 1);

    is($copied->is_mapped, 0, 'copy => 1 reports that it is not mapped');
    is($mapped->size, $copied->size, 'both see the same size');
    my ($a) = $mapped->fetch($mapped->root, 'greeting');
    my ($b) = $copied->fetch($copied->root, 'greeting');
    is($a, $b, 'and both read the same value');
    is($copied->verify, 1, 'and the copy verifies');
}

# ---- the checksum is written on every build ----------------------------

{
    my $sum = unpack('V', substr($good, 48, 4));
    isnt($sum, 0, 'the checksum field is populated, not left at zero');
    is(Frozen->attach($good)->verify, 1, 'and it verifies');
}

done_testing;
