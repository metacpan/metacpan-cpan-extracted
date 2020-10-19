#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $tool = Gnome2::Dia::ItemTool -> new();
isa_ok($tool, "Gnome2::Dia::ItemTool");
