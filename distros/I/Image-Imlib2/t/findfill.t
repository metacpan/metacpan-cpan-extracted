#!/usr/bin/perl -w
use strict;
use Test::More tests => 12;

use_ok('Image::Imlib2');

my $i = Image::Imlib2->load("t/findfill.png");
my($w, $h) = ($i->width, $i->height);
isa_ok($i, 'Image::Imlib2');

# find red
$i->set_colour(255, 0, 0, 255);
my($rx, $ry) = $i->find_colour;
is($rx, 186);
is($ry, 51);
$i->set_colour(127, 0, 0, 255);
$i->fill($rx, $ry);
$i->fill($rx + 10, $ry);

# find green
$i->set_colour(0, 255, 0, 255);
($rx, $ry) = $i->find_colour;
is($rx, 163);
is($ry, 145);
$i->set_colour(0, 127, 0, 255);
$i->fill($rx, $ry);
$i->fill($rx + 10, $ry);

# find blue
$i->set_colour(0, 0, 255, 255);
($rx, $ry) = $i->find_colour;
is($rx, 158);
is($ry, 97);
$i->set_colour(0, 0, 127, 255);
$i->fill($rx, $ry);
$i->fill($rx + 5, $ry);

# find orange, which isn't there
$i->set_colour(255, 127, 0, 255);
($rx, $ry) = $i->find_colour;
is($rx, undef);
is($ry, undef);

my $new = Image::Imlib2->new($w, $h);
$new->set_colour(255, 255, 255, 255);
$new->fill_rectangle(0, 0, $w, $h);

# find black
$i->set_colour(0, 0, 0, 255);
($rx, $ry) = $i->find_colour;
is($rx, 143);
is($ry, 12);
$i->set_colour(127, 127, 127, 255);
$i->fill($rx, $ry, $new);
#$new->save("new.png");

#$i->save("done.png");
