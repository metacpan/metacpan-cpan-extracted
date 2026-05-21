#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use File::Raw::Gzip;

# Round-trip: encode then decode reproduces the input across each mode.

my $dir = tempdir(CLEANUP => 1);

my @inputs = (
    "",
    "hello",
    "x" x 1024,
    join('', map { chr(int(rand(256))) } 1 .. 4096),
    "\x00\x01\x02 mixed binary \xff\xfe \nnewlines\n",
);

for my $mode (qw(gzip zlib raw)) {
    for my $i (0 .. $#inputs) {
        my $payload = $inputs[$i];
        my $path = "$dir/$mode-$i.bin";

        file_spew($path, $payload, plugin => 'gzip', mode => $mode);
        my $back = file_slurp($path, plugin => 'gzip', mode => $mode);

        is($back, $payload, "$mode mode round-trip input #$i (" . length($payload) . " bytes)");
    }
}

done_testing;
