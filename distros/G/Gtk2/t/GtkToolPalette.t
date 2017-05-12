#!/usr/bin/env perl
use Gtk2::TestHelper
  tests => 10,
  at_least_version => [2, 20, 0, "Gtk2::ToolPalette is new in 2.20"];

my $palette = Gtk2::ToolPalette->new;
isa_ok ($palette, 'Gtk2::ToolPalette');

my $group = Gtk2::ToolItemGroup->new ('Test');
$palette->add ($group);

$palette->set_exclusive ($group, TRUE);
ok ($palette->get_exclusive ($group));

$palette->set_expand ($group, TRUE);
ok ($palette->get_expand ($group));

$palette->set_group_position ($group, 0);
is ($palette->get_group_position ($group), 0);

$palette->set_icon_size ('menu');
is ($palette->get_icon_size, 'menu');
$palette->unset_icon_size;

$palette->set_style ('icons');
is ($palette->get_style, 'icons');
$palette->unset_style;

my $scroller = Gtk2::ScrolledWindow->new;
$scroller->add ($palette);
isa_ok ($palette->get_hadjustment, 'Gtk2::Adjustment');
isa_ok ($palette->get_vadjustment, 'Gtk2::Adjustment');

my $button = Gtk2::Button->new ('Test');
$palette->add_drag_dest ($button, 'all', 'groups', 'copy');
isa_ok (Gtk2::ToolPalette->get_drag_target_group, 'HASH');
isa_ok (Gtk2::ToolPalette->get_drag_target_item, 'HASH');
$palette->set_drag_source ('groups');

=comment Interactive d'n'd test:

{
my $palette = Gtk2::ToolPalette->new;
my $group = Gtk2::ToolItemGroup->new ('Test');
my $item = Gtk2::ToolItem->new;
my $child = Gtk2::Label->new ('TestTest');
$item->add ($child);
$group->insert ($item, 0);
$palette->add ($group);

my $button = Gtk2::Button->new ('Test');
$palette->add_drag_dest ($button, 'all', 'groups', 'copy');

$button->signal_connect (drag_data_received => sub {
  my ($button, $context, $x, $y, $selection, $info, $time, $data) = @_;
  my $palette = $context->get_source_widget->get_ancestor ('Gtk2::ToolPalette');
  my $group = $palette->get_drag_item ($selection);
  isa_ok ($group, 'Gtk2::ToolItemGroup');
});

my $window = Gtk2::Window->new;
my $vbox = Gtk2::VBox->new;
$vbox->add ($palette);
$vbox->add ($button);
$window->add ($vbox);
$window->set_default_size (50, 100);
$window->show_all;

isa_ok ($palette->get_drop_group (10, 10), 'Gtk2::ToolItemGroup');
isa_ok ($palette->get_drop_item (10, 30), 'Gtk2::ToolItem');

Gtk2->main;
}

=cut

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
