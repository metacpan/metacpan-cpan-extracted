#!perl
# Single-entry payloads that don't fit in a single read_data call.
# The Entry::slurp / Entry::read paths and the do_extract_all_seq
# write loop all use 64 KiB chunk buffers internally; we exercise
# 5 MiB to stress the loop.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# Build a deterministic 5 MiB payload (random Perl bytes; not
# compressible to a tiny size, exercises the chunk loop).
my $size = 5 * 1024 * 1024;
my $payload = '';
{
    my $seed = 42;
    while (length($payload) < $size) {
        $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
        $payload .= pack('N', $seed);
    }
    substr($payload, $size) = '' if length($payload) > $size;
}
is(length $payload, $size, "built ${size}-byte payload");

my $tar = "$dir/large.tar";
my $w = File::Raw::Archive->create($tar);
$w->add(name => 'huge.bin', content => $payload);
$w->add(name => 'small.txt', content => 'after the huge entry');
$w->close;

ok(-s $tar > $size, 'archive size exceeds payload');

# Round-trip via slurp.
{
    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    is($e->name, 'huge.bin', 'huge.bin entry name');
    is($e->size, $size, 'huge.bin entry size');
    my $back = $e->slurp;
    is(length $back, $size, 'slurp returned full payload length');
    ok($back eq $payload, 'slurp content bit-exact (5 MiB)');

    my $next = $r->next;
    is($next->name, 'small.txt', 'next entry after huge');
    is($next->slurp, 'after the huge entry', 'small entry intact');
    $r->close;
}

# Round-trip via read($n) in chunks.
{
    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    my $accum = '';
    while ((my $chunk = $e->read(128 * 1024)) ne '') {
        $accum .= $chunk;
    }
    is(length $accum, $size, 'read() loop accumulated full payload');
    ok($accum eq $payload, 'read() loop content bit-exact');
    $r->close;
}

# Round-trip via extract_all.
{
    my $dest = "$dir/extracted";
    File::Raw::Archive->extract_all($tar, $dest);
    ok(-f "$dest/huge.bin", 'extract_all wrote huge.bin');
    is(-s "$dest/huge.bin", $size, 'extracted file size matches');
    open my $fh, '<:raw', "$dest/huge.bin" or die $!;
    my $on_disk = do { local $/; <$fh> };
    close $fh;
    ok($on_disk eq $payload, 'extracted bytes bit-exact');
}

# .tar.gz round-trip with a multi-MB payload.
{
    my $gz = "$dir/large.tar.gz";
    my $gw = File::Raw::Archive->create($gz, compression => 'gzip', level => 1);
    $gw->add(name => 'huge.bin', content => $payload);
    $gw->close;
    # Note: linear-congruential pseudo-random bytes are essentially
    # incompressible, so we don't assert -s $gz < $size - just that a
    # gz file was produced and round-trips correctly.
    ok(-s $gz > 0, 'gzip output produced');
    my $r = File::Raw::Archive->open($gz);
    my $e = $r->next;
    is($e->size, $size, 'gz: size matches');
    ok($e->slurp eq $payload, 'gz: payload round-trips bit-exact');
    $r->close;
}

done_testing;
