#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "Action-based menus are new in 2.4"],
	tests => 4;

my $button = Gtk2::ToggleToolButton->new;
isa_ok ($button, 'Gtk2::ToggleToolButton');

$button = Gtk2::ToggleToolButton->new_from_stock ('gtk-ok');
isa_ok ($button, 'Gtk2::ToggleToolButton');

$button->set_active (TRUE);
ok ($button->get_active);

$button->set_active (FALSE);
ok (!$button->get_active);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
