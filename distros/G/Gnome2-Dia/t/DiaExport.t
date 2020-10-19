#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 2;

# $Id$

###############################################################################

my $canvas = Gnome2::Dia::Canvas -> new();

# Gnome2::Dia::Export -> print(..., ...);

my $svg = Gnome2::Dia::Export::SVG -> new();
isa_ok($svg, "Gnome2::Dia::Export::SVG");

$svg -> render($canvas);
$svg -> save("tmp.svg");

chmod(0000, "tmp.svg");

eval {
  $svg -> save("tmp.svg");
};

like($@, qr/^Could not open file tmp.svg for writing/);

unlink("tmp.svg");
