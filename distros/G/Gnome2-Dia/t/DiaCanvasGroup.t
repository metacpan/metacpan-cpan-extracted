#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 4;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvasGroup.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

###############################################################################

my $group = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasGroup");
isa_ok($group, "Gnome2::Dia::CanvasGroup");

my $item = $group -> create_item("Gnome2::Dia::CanvasLine");
isa_ok($item, "Gnome2::Dia::CanvasItem");

$group -> raise_item($item, 1);
$group -> lower_item($item, 0);

is($group -> foreach(sub {
  is($_[0], $group);
  return 1;
}, "bla"), 1);
