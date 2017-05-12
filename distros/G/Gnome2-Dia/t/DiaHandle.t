#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 7;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaHandle.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

###############################################################################

my $item = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine");

my $handle = Gnome2::Dia::Handle -> new($item);
isa_ok($handle, "Gnome2::Dia::Handle");

$handle = Gnome2::Dia::Handle -> new_with_pos($item, 10, 10);
isa_ok($handle, "Gnome2::Dia::Handle");

$handle -> set_strength(qw(very-weak));

$handle -> set_pos_i(10, 10);
is_deeply([$handle -> get_pos_i()], [10, 10]);

$handle -> set_pos_w(10, 10);
is_deeply([$handle -> get_pos_w()], [10, 10]);

$handle -> set_pos_i_affine(10, 10, [1, 0, 0, 1, 5, 5]);
$handle -> update_i2w_affine([1, 0, 0, 1, 0, 0]);
$handle -> request_update_w2i();
$handle -> update_w2i();
$handle -> update_w2i_affine([1, 0, 0, 1, 0, 0]);

is($handle -> distance_i(10, 10), 0);
is($handle -> distance_w(10, 10), 0);

is(Gnome2::Dia::Handle -> size(), 9);

my $constraint = Gnome2::Dia::Constraint -> new();

$handle -> add_constraint($constraint);
$handle -> add_point_constraint($handle);
$handle -> add_line_constraint($handle, $handle);
$handle -> remove_all_constraints();
# assertion: $handle -> remove_constraint($constraint);
