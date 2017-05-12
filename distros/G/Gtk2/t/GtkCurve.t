#
# $Id$
#

#########################
# GtkCurve Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 8;

my $win = Gtk2::Window->new ("toplevel");

$win->set_default_size (100, 100);

ok (my $curve = Gtk2::Curve->new (), 'Gtk2::Curve->new');

$win->add ($curve);

$win->show_all;

$curve->set_gamma (1.5);

$curve->reset;

my @vec = $curve->get_vector (4);
is (scalar (@vec), 4, 'get_vector size');

@vec = $curve->get_vector (2);
ok (eq_array (\@vec, [0, 1]), 'get_vector values');

$curve->set_range (0, 128, 0, 255);
ok (eq_array ([$curve->get (qw/min-x max-x min-y max-y/)], [0, 128, 0, 255]),
    'set_range');

$curve->set_vector (0, 255);
@vec = $curve->get_vector (2);
ok (eq_array (\@vec, [0, 255]), 'set_vector');

foreach (qw/linear spline free/)
{
	$curve->set_curve_type ($_);
	is ($curve->get ('curve-type'), $_, "set_curve_type $_");
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

