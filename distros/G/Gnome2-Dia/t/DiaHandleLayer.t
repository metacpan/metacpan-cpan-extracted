#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 2;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaHandleLayer.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

Gtk2 -> init();

###############################################################################

my $canvas = Gnome2::Dia::Canvas -> new();
my $view = Gnome2::Dia::CanvasView -> new($canvas, 1);
my $layer = $view -> handle_layer;

isa_ok($layer, "Gnome2::Canvas::Item");

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasText");
$view -> canvas -> root -> add($item);

my $view_item = $view -> find_view_item($item);
my $handle = Gnome2::Dia::Handle -> new($item);

$layer -> update_handles($view_item);
is_deeply([$layer -> get_pos_c($handle)], [0, 0]);
$layer -> request_redraw(0, 0);
$layer -> request_redraw_handle($handle);
