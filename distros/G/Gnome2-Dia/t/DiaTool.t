#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 6;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaTool.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

Gtk2 -> init();

###############################################################################

my $canvas = Gnome2::Dia::Canvas -> new();
my $view = Gnome2::Dia::CanvasView -> new($canvas, 1);

my $tool = Gnome2::Dia::DefaultTool -> new();
isa_ok($tool, "Gnome2::Dia::Tool");

ok(!$tool -> button_press($view, Gtk2::Gdk::Event -> new("button-press")));
ok(!$tool -> button_release($view, Gtk2::Gdk::Event -> new("button-release")));
ok(!$tool -> motion_notify($view, Gtk2::Gdk::Event -> new("motion-notify")));
ok(!$tool -> key_press($view, Gtk2::Gdk::Event -> new("key-press")));
ok(!$tool -> key_release($view, Gtk2::Gdk::Event -> new("key-release")));
