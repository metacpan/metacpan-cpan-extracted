#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasText");
my $handle = Gnome2::Dia::Handle -> new($item);

my $tool = Gnome2::Dia::HandleTool -> new();
isa_ok($tool, "Gnome2::Dia::HandleTool");

$tool -> set_grabbed_handle($handle);
