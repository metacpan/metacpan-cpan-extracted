#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $tool = Gnome2::Dia::SelectionTool -> new();
isa_ok($tool, "Gnome2::Dia::SelectionTool");
