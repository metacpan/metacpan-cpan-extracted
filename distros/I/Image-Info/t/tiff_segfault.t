#!/usr/bin/perl -w

use strict;
use FindBin;
use Test::More 'no_plan';

use Image::Info qw(image_info);

sub slurp ($) { open my $fh, shift or die $!; local $/; <$fh> }

# test case for RT #100847
my $imgdata = slurp "$FindBin::RealBin/../img/segfault.tif";
my $info = image_info \$imgdata;
ok $info->{error}, 'should not segfault';
