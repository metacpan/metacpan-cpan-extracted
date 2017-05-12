#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaItemTool.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

###############################################################################

my $tool = Gnome2::Dia::ItemTool -> new();
isa_ok($tool, "Gnome2::Dia::ItemTool");
