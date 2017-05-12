#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 6;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvas.t,v 1.2 2004/10/15 16:14:04 kaffeetisch Exp $

###############################################################################

my $canvas = Gnome2::Dia::Canvas -> new();
isa_ok($canvas, "Gnome2::Dia::Canvas");

$canvas -> request_update();
$canvas -> update_now();
$canvas -> resolve_now();

$canvas -> set_extents([0, 0, 100, 100]);
$canvas -> set_static_extents(1);

$canvas -> set_snap_to_grid(1);
is_deeply([$canvas -> snap_to_grid(12, 13)], [10, 10]);

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine");
# my $handle = Gnome2::Dia::Handle -> new_with_pos($item, 5, 5);

# my $item_two = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine");
# my $handle_two = Gnome2::Dia::Handle -> new_with_pos($item_two, 10, 10);

# FIXME: warn join ", ", $canvas -> glue_handle($handle_one, 0, 0);
# FIXME: warn $canvas -> find_objects_in_rectangle ([0, 0, 100, 100]);

my $constraint = Gnome2::Dia::Constraint -> new();
my $var = Gnome2::Dia::Variable -> new();

$constraint -> add($var, 23);

$canvas -> add_constraint($constraint);
$canvas -> remove_constraint($constraint);

isa_ok($canvas -> get_pango_layout(), "Gtk2::Pango::Layout");

$canvas -> redraw_views();

$canvas -> preserve($item, "cap", "butt", 1);
$canvas -> preserve_property($item, "cap");
$canvas -> preserve_property_last($item, "cap");

$canvas -> push_undo();
$canvas -> push_undo(undef);
$canvas -> push_undo("Comment");

is($canvas -> get_undo_depth(), 0);

$canvas -> pop_redo();

is($canvas -> get_redo_depth(), 0);

$canvas -> clear_redo();

$canvas -> pop_undo();
$canvas -> clear_undo();

$canvas -> set_undo_stack_depth(0);
is($canvas -> get_undo_stack_depth(), 0);
