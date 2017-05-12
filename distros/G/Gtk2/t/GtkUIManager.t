#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "GtkUIManager is new in 2.4"],
	tests => 14;


my $ui_manager = Gtk2::UIManager->new;
isa_ok ($ui_manager, 'Gtk2::UIManager');

$ui_manager->set_add_tearoffs (TRUE);
ok ($ui_manager->get_add_tearoffs);

$ui_manager->set_add_tearoffs (FALSE);
ok (!$ui_manager->get_add_tearoffs);

my $group_one = Gtk2::ActionGroup->new ("Barney");
my $group_two = Gtk2::ActionGroup->new ("Fred");

my @entries = (
  [ "HelpMenu", undef, "_Help" ],
  [ "About", undef, "_About", "<control>A", "About" ],
  [ "Help", undef, "_Help", "<control>H", "Help" ],
  [ "License", undef, "_License", "<control>L", "License" ],
);

$group_one->add_actions (\@entries, undef);

$ui_manager->insert_action_group ($group_one, 0);
$ui_manager->insert_action_group ($group_two, 1);

is_deeply ([$ui_manager->get_action_groups], [$group_one, $group_two]);

$ui_manager->remove_action_group ($group_two);

isa_ok ($ui_manager->get_accel_group, "Gtk2::AccelGroup");

my $ui_info = <<__EOD__;
<ui>
  <menubar name='MenuBar'>
    <menu action='HelpMenu'>
      <menuitem action='About'/>
    </menu>
  </menubar>
  <menubar name='MenuBla'>
    <menu action='HelpMenu'>
      <menuitem action='License'/>
    </menu>
  </menubar>
</ui>
__EOD__

ok (my $id = $ui_manager->add_ui_from_string ($ui_info) != 0);

ok (my $new_id = $ui_manager->new_merge_id != 0);
$ui_manager->add_ui ($new_id, "/MenuBar/HelpMenu", "Help", "Help", qw(menuitem), 0);

ok (my $new_new_id = $ui_manager->new_merge_id != 0);
$ui_manager->add_ui ($new_new_id, "/MenuBar/HelpMenu/License", "License", "License", qw(menuitem), 1);
$ui_manager->remove_ui ($new_new_id);

$ui_manager->ensure_update;
ok (defined ($ui_manager->get_ui));

isa_ok ($ui_manager->get_widget ("/MenuBar/HelpMenu/About"), "Gtk2::ImageMenuItem");

my @menubars = $ui_manager->get_toplevels ("menubar");
is (@menubars, 2);
isa_ok ($menubars[0], "Gtk2::MenuBar");
isa_ok ($menubars[1], "Gtk2::MenuBar");

isa_ok ($ui_manager->get_action ("/MenuBar/HelpMenu/About"), "Gtk2::Action");

# FIXME: guint $ui_manager->add_ui_from_file (const gchar *filename);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
