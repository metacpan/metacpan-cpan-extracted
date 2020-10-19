#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 4;

# $Id$

###############################################################################

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasBox");
isa_ok($item, "Gnome2::Dia::CanvasElement");

my $handles = $item -> get("handles");
isa_ok($handles, "ARRAY");
is($#{$handles}, 7);

is($item -> get_opposite_handle($handles -> [0]), $handles -> [3]);
