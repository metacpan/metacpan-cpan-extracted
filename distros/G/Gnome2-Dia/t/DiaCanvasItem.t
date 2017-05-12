#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More skip_all => "Currently completely broken", tests => 25;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvasItem.t,v 1.2 2004/09/25 19:13:29 kaffeetisch Exp $

###############################################################################

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine",
                                             join => "round");
isa_ok($item, "Gnome2::Dia::CanvasLine");
is($item -> get("join"), "round");

isa_ok($item -> flags, "Gnome2::Dia::CanvasItemFlags");
is($item -> canvas, undef);
isa_ok($item -> bounds, "ARRAY");
is($item -> connected_handles, undef);

$item -> set(affine => [1, 1, 1, 1, 1, 1]);
is_deeply($item -> get("affine"), [1, 1, 1, 1, 1, 1]);
$item -> set(affine => [1, 0, 0, 1, 0, 0]);
is_deeply($item -> get("affine"), [1, 0, 0, 1, 0, 0]);

my $parent = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasGroup");

$item -> set_parent(undef);
$item -> set_parent($parent);

$item -> set_child_of($parent);

$item -> request_update();
$item -> update_now();
$parent -> update_child($item, [1, 0, 0, 1, 0, 0]);

isa_ok($item -> affine_w2i(), "ARRAY");
isa_ok($item -> affine_i2w(), "ARRAY");
is_deeply([$item -> affine_point_w2i(0, 0)], [0, 0]);
is_deeply([$item -> affine_point_i2w(0, 0)], [0, 0]);

$item -> update_handles_w2i();
$item -> update_handles_i2w();

my $connectable = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine");
my $handle = Gnome2::Dia::Handle -> new($connectable);

$handle -> set(connectable => 1);
ok($item -> connect($handle));
ok($item -> disconnect($handle));
ok($item -> disconnect_handles());

$item -> select();
$item -> unselect();
ok(!$item -> is_selected());

$item -> focus();
$item -> unfocus();
ok(!$item -> is_focused());

$item -> grab();
$item -> ungrab();
ok(!$item -> is_grabbed());

$item -> visible();
$item -> invisible();
ok(!$item -> is_visible());

$item -> identity();
$item -> scale(1, 1);
$item -> rotate(0);
$item -> shear_x(23, 42);
$item -> shear_y(42, 23);
$item -> move(1, 1);
$item -> flip(1, 0);
$item -> move_interactive(4, 5);
$item -> expand_bounds(2);

is_deeply([$item -> bb_affine([1, 0, 0, 1, 0, 0])], [-2, -2, 2, 2]);

my $iter = $item -> get_shape_iter();
isa_ok($iter, "Gnome2::Dia::CanvasIter");

isa_ok($item -> shape_value($iter), "Gnome2::Dia::Shape");
isa_ok($item -> shape_value($iter), "Gnome2::Dia::Shape::Path");

ok(!$item -> shape_next($iter));

$item -> preserve_property("line");

###############################################################################

my $line = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine");

is($line -> get_closest_segment(0, 0), 0);

$line -> set(add_point => [1, 1]);

$line -> set(dash => [0, 1, 2, 3, 4, 5]);
# warn q($line -> get("dash"));
