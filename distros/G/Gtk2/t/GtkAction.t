#!/usr/bin/perl
#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, "Action-based menus are new in 2.4"],
	tests => 31, noinit => 0;

my $action = Gtk2::Action->new (name => 'Open',
                                label => '_Open',
                                tooltip => 'Open Something',
                                stock_id => 'gtk-open');

is ($action->is_sensitive, 1);
is ($action->get_sensitive, 1);

is ($action->is_visible, 1);
is ($action->get_visible, 1);

isa_ok ($action, 'Gtk2::Action');
is ($action->get_name, 'Open');

$action->signal_connect (activate => sub { ok (TRUE) });
$action->activate;

# most of these are for action implementations
my $icon_widget = $action->create_icon ('large-toolbar');
isa_ok ($icon_widget, 'Gtk2::Image');

my $group = Gtk2::ActionGroup->new ('dummy');
$group->add_action ($action);

my $widget = $action->create_menu_item;
isa_ok ($widget, 'Gtk2::MenuItem');

$widget = $action->create_tool_item;
isa_ok ($widget, 'Gtk2::ToolItem');

my $proxy = Gtk2::Button->new;
$action->connect_proxy ($proxy);
my @proxies = $action->get_proxies;
ok (grep {$_ == $proxy} @proxies);
$action->disconnect_proxy ($proxy);

$action->connect_accelerator;
$action->disconnect_accelerator;
## /* protected ... for use by child actions */
$action->block_activate_from ($proxy);
$action->unblock_activate_from ($proxy);
## /* protected ... for use by action groups */
$action->set_accel_path ('<Action>/');
$action->set_accel_group (undef);
$action->set_accel_group (Gtk2::AccelGroup->new);

# call $action->get_proxies within an ActionGroup connect_proxy signal, to
# check the ref-counting/sinking/not-sinking on that get_proxies is ok there.
{
  my $actions = Gtk2::ActionGroup->new ("Actions");
  $actions->add_actions
    ([ [ 'FileMenu', undef, '_File' ] ]);
  $actions->signal_connect (connect_proxy => \&connect_get_proxies);
  my $proxies_called = 0;
  sub connect_get_proxies {
    my ($actions, $action, $widget) = @_;
    $action->get_proxies;
    $proxies_called++;
  }
  my $ui = Gtk2::UIManager->new;
  $ui->insert_action_group ($actions, 0);
  $ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
    </menu>
  </menubar>
</ui>
HERE
  # dodgy refs result in g_critical logs
  my $old_fatal = Glib::Log->set_always_fatal (['critical', 'fatal-mask']);
  $ui->get_widget('/MenuBar');
  Glib::Log->set_always_fatal ($old_fatal);
  is ($proxies_called, 1,
      '$action->get_proxies ok under a connect_proxy signal');
}

SKIP: {
	skip "new 2.6 stuff", 3
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$action->set_sensitive(FALSE);
	is ($action->is_sensitive, FALSE);

	$action->set_visible(FALSE);
	is ($action->is_visible, FALSE);

	ok (defined $action->get_accel_path);
}

SKIP: {
	skip "new 2.10 stuff", 1
		unless Gtk2->CHECK_VERSION (2, 10, 0);

	isa_ok ($widget->get_action, 'Gtk2::Action');
}

SKIP: {
	skip "new 2.12 stuff", 1
		unless Gtk2->CHECK_VERSION (2, 12, 0);

	is ($action->create_menu, undef);
}

SKIP: {
	skip "new 2.16 stuff", 13
		unless Gtk2->CHECK_VERSION (2, 16, 0);

	$action->set_label('new label');
	is ($action->get_label, 'new label', '[gs]et_label');

	$action->set_short_label('new short label');
	is ($action->get_short_label, 'new short label', '[gs]et_short_label');

	# it seems resetting label and short_label to undef is not possible,
	# so use a new gtkaction with no label/short_label to test the getters
	my $a_undef = Gtk2::Action->new (name => 'Open');
	is ($a_undef->get_label, undef, 'get_label with undef');
	is ($a_undef->get_short_label, undef, 'get_short_label with undef');

	$action->set_tooltip('new tooltip');
	is ($action->get_tooltip, 'new tooltip', '[gs]et_tooltip');
	$action->set_tooltip(undef);
	is ($action->get_tooltip, undef, '[gs]et_tooltip with undef');

	$action->set_stock_id('gtk-ok');
	is ($action->get_stock_id, 'gtk-ok', '[gs]et_stock_id');
	$action->set_stock_id(undef);
	is ($action->get_stock_id, undef, '[gs]et_stock_id with undef');

	$action->set_icon_name('my-icon-name');
	is ($action->get_icon_name, 'my-icon-name', '[gs]et_icon_name');
	$action->set_icon_name(undef);
	is ($action->get_icon_name, undef, '[gs]et_icon_name with undef');

	$action->set_visible_horizontal(FALSE);
	is ($action->get_visible_horizontal, FALSE, '[gs]et_visible_horizontal');

	$action->set_visible_vertical(FALSE);
	is ($action->get_visible_vertical, FALSE, '[gs]et_visible_vertical');

	$action->set_is_important(TRUE);
	is ($action->get_is_important, TRUE, '[gs]et_is_important');

	$action->block_activate;
	$action->unblock_activate;
}

SKIP: {
	skip 'new 2.20 stuff', 1
		unless Gtk2->CHECK_VERSION(2, 20, 0);

	$action->set_always_show_image (TRUE);
	ok ($action->get_always_show_image);
}

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
