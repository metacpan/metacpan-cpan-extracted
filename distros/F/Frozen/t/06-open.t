#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $path = "$dir/cat.frz";
my %data = (greeting => 'hello', items => { one => '1 item', other => 'n items' },
            list => [1, 2, 3], nothing => undef);
Frozen->freeze_to($path, \%data);

# ---- open, map, close -----------------------------------------------------

{
    my $fz = Frozen->open($path);
    ok($fz, 'open returns a container');
    isa_ok($fz, 'Frozen');
    ok($fz->is_open, 'and it is open');
    is($fz->size, -s $path, 'size is the file size');
    ok($fz->is_mapped, 'and it is a real mapping, not a read')
        or diag 'mmap unavailable here; the sharing claim does not hold';

    ok(defined $fz->find('greeting'), 'a key is found through the container');
    ok(!defined $fz->find('absent'),  'and an absent key is absent');

    $fz->close;
    ok(!$fz->is_open, 'close closes it');
    $fz->close;
    ok(!$fz->is_open, 'and close is idempotent');

    # A use after close is a croak, never a crash. That contract is what the
    # poison build actually enforces.
    eval { $fz->find('greeting'); 1 };
    like($@, qr/closed/, 'a use after close croaks rather than crashing');
    eval { $fz->size; 1 };
    like($@, qr/closed/, 'and so does size');
}

# ---- DESTROY without an explicit close ------------------------------------

{
    my $fz = Frozen->open($path);
    ok($fz->is_open, 'a container that is never closed by hand');
    undef $fz;
    ok(1, '...is destroyed without a warning or a crash');
}

# ---- copy => 1, for a file that might be rewritten -----------------------

{
    my $fz = Frozen->open($path, copy => 1);
    ok($fz, 'copy => 1 opens');
    is($fz->is_mapped, 0, 'and reports that it is NOT mapped, truthfully');
    ok(defined $fz->find('greeting'), 'and reads the same');
    is($fz->size, -s $path, 'and is the same size');
}

# ---- attach, the no-file door --------------------------------------------

{
    my $bytes = Frozen->freeze(\%data);
    my $fz    = Frozen->attach($bytes);
    ok($fz, 'attach takes a scalar');
    is($fz->is_mapped, 0, 'an attached scalar is not a mapping');
    ok(defined $fz->find('greeting'), 'and reads');

    # attach COPIES. Holding a reference to the caller's SV is not enough:
    # `undef $bytes` leaves the SV alive but frees its string buffer, and a
    # pointer into that buffer is then dangling. A reference counts the SV,
    # not the PV inside it - so this line is the test that found it.
    undef $bytes;
    ok(defined $fz->find('greeting'),
       'and it still reads after the caller emptied the scalar it came from');
}

# ---- alignment, which the copy settles for free --------------------------
#
# mmap gives page alignment; a scalar's PV gives whatever it gives. An
# unaligned base means an unaligned 64-bit load for every INT and NUM, which
# faults on strict-alignment platforms and is undefined behaviour everywhere.

{
    my $bytes = Frozen->freeze(\%data);
    my $off   = "\0" . $bytes;                 # shift by one byte
    my $mis   = substr($off, 1);
    my $fz    = eval { Frozen->attach($mis) };
    ok($fz, 'a scalar whose PV may be misaligned still attaches') or diag $@;
    ok(defined $fz->find('greeting'), 'and reads correctly either way');
}

# ---- refusals -------------------------------------------------------------

{
    is(Frozen->open("$dir/does-not-exist.frz"), undef,
       'a missing file returns undef, the slurp convention');

    my $bad = "$dir/notfrozen.bin";
    open my $fh, '>:raw', $bad or die $!;
    print {$fh} 'X' x 128;
    close $fh;
    eval { Frozen->open($bad); 1 };
    like($@, qr/does not begin with FRZN/, 'a non-Frozen file is refused by magic');

    # Truncation. total_size against the file length is the cheapest check
    # there is, and it costs an fstat that has already happened.
    my $short = "$dir/short.frz";
    open my $in, '<:raw', $path or die $!;
    my $blk = do { local $/; <$in> };
    close $in;
    open my $out, '>:raw', $short or die $!;
    print {$out} substr($blk, 0, length($blk) - 16);
    close $out;
    eval { Frozen->open($short); 1 };
    like($@, qr/truncated/, 'a truncated file is refused, naming what is wrong');

    # Endianness. No big-endian machine is needed: byteswap the probe and
    # assert the refusal fires.
    my $swapped = $blk;
    substr($swapped, 12, 4) = reverse substr($swapped, 12, 4);
    eval { Frozen->attach($swapped); 1 };
    like($@, qr/endianness/, 'a wrong-endian block is refused, not byteswapped');
}

# ---- many containers ------------------------------------------------------

{
    my @open = map { Frozen->open($path) } 1 .. 50;
    is(scalar(grep { $_->is_open } @open), 50, '50 containers open at once');
    $_->close for @open;
    is(scalar(grep { $_->is_open } @open), 0, 'and all close');
}

# ---- the mapping outlives the file ---------------------------------------

SKIP: {
    skip 'POSIX unlink semantics', 2 if $^O eq 'MSWin32';
    my $tmp = "$dir/doomed.frz";
    Frozen->freeze_to($tmp, \%data);
    my $fz = Frozen->open($tmp);
    unlink $tmp;
    ok(!-e $tmp, 'the file is gone');
    ok(defined $fz->find('greeting'),
       'and the mapping still reads - it is what keeps the file alive');
}

done_testing;
