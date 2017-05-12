#!/usr/bin/env perl
use Gtk2::TestHelper
  tests => 10,
  at_least_version => [2, 20, 0, "Gtk2::ToolItemGroup is new in 2.20"];

my $group = Gtk2::ToolItemGroup->new ('Test');
isa_ok ($group, 'Gtk2::ToolItemGroup');

my $item = Gtk2::ToolItem->new;
$group->insert ($item, 0);
$group->set_item_position ($item, 0);

my $window = Gtk2::Window->new;
$window->add ($group);
$window->show_all;

my $drop_item = $group->get_drop_item (10, 10);
ok ((defined $drop_item && $drop_item->isa ('Gtk2::ToolItem')) || !defined $drop_item);

$group->set_collapsed (TRUE);
ok ($group->get_collapsed);

$group->set_ellipsize ('none');
is ($group->get_ellipsize, 'none');

$group->set_label ('Test');
is ($group->get_label, 'Test');

my $label = Gtk2::Label->new ('Test');
$group->set_label_widget ($label);
is ($group->get_label_widget, $label);

is ($group->get_item_position ($item), 0);
is ($group->get_n_items, 1);
is ($group->get_nth_item (0), $item);

$group->set_header_relief ('normal');
is ($group->get_header_relief, 'normal');

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
