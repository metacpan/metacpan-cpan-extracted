#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

# Compressible input: highly repetitive so level 9 beats level 1.
my $payload = ("the quick brown fox jumps over the lazy dog\n" x 1000);

my $p1 = "$dir/level1.gz";
my $p9 = "$dir/level9.gz";

file_spew($p1, $payload, plugin => 'gzip', level => 1);
file_spew($p9, $payload, plugin => 'gzip', level => 9);

my $size1 = -s $p1;
my $size9 = -s $p9;
ok($size1 > 0, "level=1 produced output ($size1 bytes)");
ok($size9 > 0, "level=9 produced output ($size9 bytes)");
cmp_ok($size9, '<=', $size1,
    "level=9 ($size9) <= level=1 ($size1) for compressible input");

is(file_slurp($p1, plugin => 'gzip'), $payload, 'level=1 round-trip');
is(file_slurp($p9, plugin => 'gzip'), $payload, 'level=9 round-trip');

# Level 0 = no compression -- must still produce a valid gzip stream.
my $p0 = "$dir/level0.gz";
file_spew($p0, $payload, plugin => 'gzip', level => 0);
ok(-s $p0 >= length($payload),
    'level=0 output >= input length (no compression)');
is(file_slurp($p0, plugin => 'gzip'), $payload, 'level=0 round-trip');

done_testing;
