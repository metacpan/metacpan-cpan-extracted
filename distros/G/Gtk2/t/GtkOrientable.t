#!/usr/bin/perl
use Gtk2::TestHelper
	tests => 6,
	at_least_version => [2, 16, 0, 'GtkOrientable: it appeared in 2.16'];


my $vbox = Gtk2::VBox -> new();
isa_ok($vbox, "Gtk2::Orientable");
is($vbox->get_orientation, 'vertical');

my $hbox = Gtk2::HBox -> new();
isa_ok($hbox, "Gtk2::Orientable");
is($hbox->get_orientation, 'horizontal');


# Swap the orientation
$vbox->set_orientation('horizontal');
is($vbox->get_orientation, 'horizontal');

$hbox->set_orientation('vertical');
is($hbox->get_orientation, 'vertical');


__END__

Copyright (C) 2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
