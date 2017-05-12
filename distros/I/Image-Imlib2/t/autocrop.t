#!/usr/bin/perl -w
use strict;
use Test::More tests => 8;

use_ok('Image::Imlib2');

my $i = Image::Imlib2->load("t/blob.png");
isa_ok($i, 'Image::Imlib2');
my($x, $y, $w, $h) = $i->autocrop_dimensions;
is($x, 128);
is($y, 8);
is($w, 123);
is($h, 200);

my $cropped = $i->autocrop;
is($cropped->width, 123);
is($cropped->height, 200);
$cropped->save("t/cropped.png");

