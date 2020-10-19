#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 3;

# $Id$

###############################################################################

my $box = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasBox");
isa_ok($box, "Gnome2::Dia::CanvasBox");
isa_ok($box -> border, "Gnome2::Dia::Shape");
isa_ok($box -> border, "Gnome2::Dia::Shape::Path");
