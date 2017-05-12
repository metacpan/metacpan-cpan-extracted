#!/usr/bin/env perl
use Gtk2::TestHelper
  tests => 4,
  at_least_version => [2, 16, 0, "Gtk2::Activatable is new in 2.16"];

my $activatable = Gtk2::Button->new ('Test');
isa_ok ($activatable, 'Gtk2::Activatable');

my $action = Gtk2::Action->new ('name', 'label', 'tooltip', 'gtk-ok');

is ($activatable->get_related_action, undef);
$activatable->set_related_action ($action);
is ($activatable->get_related_action, $action);

$activatable->set_use_action_appearance (TRUE);
ok ($activatable->get_use_action_appearance);

$activatable->do_set_related_action ($action);
$activatable->sync_action_properties ($action);

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
