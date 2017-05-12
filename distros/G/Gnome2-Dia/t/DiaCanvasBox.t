#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 3;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvasBox.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

###############################################################################

my $box = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasBox");
isa_ok($box, "Gnome2::Dia::CanvasBox");
isa_ok($box -> border, "Gnome2::Dia::Shape");
isa_ok($box -> border, "Gnome2::Dia::Shape::Path");
