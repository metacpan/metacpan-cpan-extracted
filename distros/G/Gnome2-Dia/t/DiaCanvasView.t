#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 15;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvasView.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

Gtk2 -> init();

###############################################################################

my $canvas = Gnome2::Dia::Canvas -> new();

my $view = Gnome2::Dia::CanvasView -> aa_new();
isa_ok($view, "Gnome2::Dia::CanvasView");
isa_ok($view, "Gnome2::Canvas");

is($view -> canvas, undef);
is($view -> root_item, undef);
isa_ok($view -> handle_layer, "Gnome2::Dia::HandleLayer");

$view = Gnome2::Dia::CanvasView -> new($canvas, 1);
isa_ok($view, "Gnome2::Dia::CanvasView");
isa_ok($view, "Gnome2::Canvas");

$view -> unset_canvas();
is($view -> get_canvas(), undef);

$view -> set_canvas($canvas);
is($view -> get_canvas(), $canvas);

$view -> set_zoom(0.23);
is($view -> get_zoom(), 0.23);

my $tool = Gnome2::Dia::DefaultTool -> new();

$view -> set_tool($tool);

SKIP: {
  skip("get_tool and [sg]et_default_tool are new in 0.13.0", 2)
    unless (Gnome2::Dia -> CHECK_VERSION(0, 13, 0));

  is($view -> get_tool(), $tool);

  $view -> set_default_tool($tool);
  is($view -> get_default_tool(), $tool);
}

$view -> select_rectangle([0, 0, 0, 0]);
$view -> select_all();
$view -> unselect_all();

$view -> request_update();

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasText");
$canvas -> root -> add($item);

my $view_item = $view -> find_view_item($item);
isa_ok($view_item, "Gnome2::Dia::CanvasViewItem");

SKIP: {
  skip("some DiaCanvasViewItem stuff is broken", 2); # FIXME: Version check.

  $view -> select($view_item);
  $view -> unselect($view_item);
  $view -> focus($view_item);
  $view -> move(23, 42, $view_item);

  my $shape = Gnome2::Dia::Shape::Text -> new();

  if (Gnome2::Dia -> CHECK_VERSION(0, 13, 2)) {
    $view -> start_editing($view_item, 23, 42);
  }
  else {
    $view -> start_editing($view_item, $shape);
  }

  $view -> editing_done();

  is(Gnome2::Dia::CanvasView -> get_active_view(), undef);
  $view -> signal_emit(button_press_event => Gtk2::Gdk::Event -> new("button-press"));
  is(Gnome2::Dia::CanvasView -> get_active_view(), $view);
}
