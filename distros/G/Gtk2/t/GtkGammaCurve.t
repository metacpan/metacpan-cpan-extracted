#
# $Id$
#

#########################
# GtkGammaCurve Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 3;

ok( my $win = Gtk2::Window->new("toplevel") );

ok( my $gamma = Gtk2::GammaCurve->new() );

$win->add($gamma);

$gamma->curve->set_range(0, 255, 0, 255);

$win->show_all;

$gamma->curve->set_vector(0, 255);
$gamma->curve->set_curve_type('spline');
ok( eq_array( [ $gamma->curve->get_vector(2) ], [ 0, 255 ] ) );

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
