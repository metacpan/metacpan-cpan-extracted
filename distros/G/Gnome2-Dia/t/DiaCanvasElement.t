#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 4;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvasElement.t,v 1.2 2005/02/24 17:32:06 kaffeetisch Exp $

###############################################################################

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasBox");
isa_ok($item, "Gnome2::Dia::CanvasElement");

my $handles = $item -> get("handles");
isa_ok($handles, "ARRAY");
is($#{$handles}, 7);

is($item -> get_opposite_handle($handles -> [0]), $handles -> [3]);
