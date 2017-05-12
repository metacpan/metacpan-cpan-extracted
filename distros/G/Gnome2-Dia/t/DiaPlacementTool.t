#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaPlacementTool.t,v 1.2 2004/09/25 19:13:30 kaffeetisch Exp $

###############################################################################

my $tool = Gnome2::Dia::PlacementTool -> new("Gnome2::Dia::CanvasLine",
                                             has_head => 1,
                                             has_tail => 1,
                                             head_a => 23);
isa_ok($tool, "Gnome2::Dia::PlacementTool");
