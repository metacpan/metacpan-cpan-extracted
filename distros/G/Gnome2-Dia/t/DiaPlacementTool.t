#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $tool = Gnome2::Dia::PlacementTool -> new("Gnome2::Dia::CanvasLine",
                                             has_head => 1,
                                             has_tail => 1,
                                             head_a => 23);
isa_ok($tool, "Gnome2::Dia::PlacementTool");
