#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use_ok('Media::Convert::Asset');
use_ok('Media::Convert::KeyframeFinder');

my $asset = Media::Convert::Asset->new(url => 't/testvids/bbb.mp4');

my $finder = Media::Convert::KeyframeFinder->new(asset => $asset);
my $keyframes = $finder->keyframes;
my $expected_keyframes = [0.000000, 3.166667, 4.708333, 15.125000, 17.875000];
is_deeply($keyframes, $expected_keyframes, "key frames are what we expect");

done_testing
