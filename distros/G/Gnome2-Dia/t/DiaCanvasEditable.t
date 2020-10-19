#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasText");
isa_ok($item, "Gnome2::Dia::CanvasEditable");

my $shape = Gnome2::Dia::Shape::Text -> new();

$item -> start_editing($shape);
$item -> editing_done($shape, "Urgs");
$item -> text_changed($shape, "Urgs");
