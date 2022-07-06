#!/usr/bin/env perl

use strict;
use warnings;
use lib "lib";
# Simple phash benchmark:
# bench/benchmark.pl [image?]
# Without an argument, the 1024x680 images/M31.jpg is loaded

use Image::PHash;
use Time::HiRes;

my $file = $ARGV[0] || 'images/M31.jpg';
die "File $file not found" unless -f $file;
print "Benchmarking using $file\n";

my @libs = qw/Image::Imlib2 GD Image::Magick Imager/;

foreach my $lib (@libs) {
    next unless eval "require $lib;";
    print "$lib hash rate: ";
    my $start = Time::HiRes::time();
    my $cnt   = 0;
    while (Time::HiRes::time() - $start < 5) {
        my $p = Image::PHash->new($file, $lib)->pHash();
        $cnt++
    }
    my $rate = int($cnt/(Time::HiRes::time() - $start));

    print "$rate/s\n";
}

my @hashes;
foreach (1..100) {
    my $h = '';
    $h .= sprintf("%x", rand(16)) for 1..16;
    push @hashes, $h;
}
my $start = Time::HiRes::time();
my $cnt   = 0;
while (Time::HiRes::time() - $start < 2) {
    my $d = Image::PHash::diff($hashes[rand(@hashes)], $hashes[rand(@hashes)]);
    $cnt++;
}

printf "64bit hash diff rate: %d/s\n", $cnt/(Time::HiRes::time() - $start);
