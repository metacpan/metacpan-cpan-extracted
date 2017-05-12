#
# $Id$
#

sub on_unthreaded_freebsd {
  if ($^O eq 'freebsd') {
    require Config;
    if ($Config::Config{ldflags} !~ m/-pthread\b/) {
      return 1;
    }
  }
  return 0;
}

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "GtkFileChooser is new in 2.4"],
	tests => 6,
	(on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ());


my $widget = Gtk2::FileChooserWidget->new ('save');

isa_ok ($widget, 'Gtk2::FileChooserWidget');
ginterfaces_ok($widget);

is ($widget->get_action, 'save');

$widget = Gtk2::FileChooserWidget->new_with_backend ('open',
                                                     'backend');

isa_ok ($widget, 'Gtk2::FileChooserWidget');
isa_ok ($widget, 'Gtk2::FileChooser');

is ($widget->get_action, 'open');

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
