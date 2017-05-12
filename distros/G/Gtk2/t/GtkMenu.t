#!/usr/bin/perl
#
# $Id$
#

#########################
# GtkMenu Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 66;

ok( my $menubar = Gtk2::MenuBar->new );

my ($num, $menu, $accelgroup, $button, $menuitem, $rootmenu, $optmenu);
foreach $num (qw/1 2 3/)
{
	ok( $menu = Gtk2::Menu->new );

	$accelgroup = Gtk2::AccelGroup->new;

	$menu->set_accel_group ($accelgroup);
	is ($menu->get_accel_group, $accelgroup);

	$menu->set_accel_path ("<gtk2perl>/main/menu");

	$menu->set_title ("gtk2perl bla");
	is ($menu->get_title, "gtk2perl bla");

	$menu->set_tearoff_state (FALSE);
	ok (!$menu->get_tearoff_state);

	$menu->reposition;

	$button = Gtk2::Button->new ("Bla");

	$menu->attach_to_widget ($button, sub {
		my ($callback_button, $callback_menu) = @_;

		is ($callback_button, $button);
		is ($callback_menu, $menu);
	});

	is ($menu->get_attach_widget, $button);

	SKIP: {
		skip "new 2.6 stuff", 1
			unless Gtk2->CHECK_VERSION (2, 6, 0);

		my @list = Gtk2::Menu->get_for_attach_widget ($button);
		is ($list[0], $menu);
	}

	$menu->detach;

	SKIP: {
		skip "set_screen is new in 2.2", 0
			unless Gtk2->CHECK_VERSION (2, 2, 0);

		$menu->set_screen (Gtk2::Gdk::Screen->get_default);
		$menu->set_screen (undef);
	}

	$menuitem = undef;
	foreach (qw/One Two Three Four/)
	{
		ok( $menuitem = Gtk2::MenuItem->new($_.' '.$num) );
		$menu->append( $menuitem );
	}
	ok( $rootmenu = Gtk2::MenuItem->new('_Root Menu '.$num) );
	$menu->reorder_child($menuitem, 1);

	$menu->set_active (TRUE);
	is ($menu->get_active, $menuitem);

	if( $num == 1 )
	{
		$rootmenu->set_submenu($menu);
#		$menu->set_tearoff_state(TRUE);
		$menubar->append($rootmenu);
		ok(TRUE);
	}
	elsif( $num == 2 )
	{
		$rootmenu->set_submenu($menu);
		$rootmenu->set_right_justified(TRUE);
		$menubar->append($rootmenu);
		ok(TRUE);
	}
	elsif( $num == 3 )
	{
		ok(TRUE);
	}

	ok(TRUE);
}

ok( $optmenu = Gtk2::OptionMenu->new );
$optmenu->set_menu($menu);

my $i_know_you = 0;

my $position_callback = sub {
	return if $i_know_you++;

	my ($menu, $x, $y, $data) = @_;

	isa_ok ($menu, "Gtk2::Menu");
	like ($x, qr/^\d+$/);
	like ($y, qr/^\d+$/);
	is ($data, "bla");

	SKIP: {
		skip("attach and set_monitor are new in 2.4", 0)
			unless Gtk2->CHECK_VERSION (2, 4, 0);

		$menu->attach(Gtk2::MenuItem->new("Bla"), 0, 1, 0, 1);
		$menu->set_monitor(0);
	}

	return (50, 50);
};

$menu->popup(undef, undef, $position_callback, "bla", 1, 0);
$menu->popdown;
ok(TRUE);

# crib note: $position_callback sub must be a proper closure referring to a
# variable outside itself to weaken away like this
require Scalar::Util;
Scalar::Util::weaken($position_callback);
ok ($position_callback, 'popup() holds onto position_callback');

my $next_position_callback_variable = 0;
my $next_position_callback = sub { $next_position_callback_variable++;
                                   return (50,50) };
$menu->popup(undef, undef, $next_position_callback, undef, 1, 0);
$menu->popdown;
is ($position_callback, undef,
    'next popup() drops previously held position_callback');

# crib note: again $next_position_callback must refer to a variable outside
# itself to weaken away like this
require Scalar::Util;
Scalar::Util::weaken($next_position_callback);
ok ($next_position_callback, 'popup() holds onto next_position_callback');
$menu->popup(undef, undef, undef, undef, 1, 0);
$menu->popdown;
is ($next_position_callback, undef,
    'popup() with no position func drops held position_callback');

# If we never entered the pos. callback, fake four tests
unless ($i_know_you) {
	foreach (0 .. 3) {
		ok (TRUE, 'faking pos. callback');
	}
}

{
  my $item = Gtk2::MenuItem->new;
  my $menu = Gtk2::Menu->new;
  my $detach_args;
  my $detach_func = sub { $detach_args = \@_; };
  $menu->attach_to_widget ($item, $detach_func);
  $menu->detach;
  is_deeply ($detach_args, [ $item, $menu ], 'detach callback args');

  # crib note: $detach_func must be a closure referring to a variable
  # outside itself to weaken away like this
  Scalar::Util::weaken ($detach_func);
  is ($detach_func, undef, 'detach callback func freed after called');
}

{
  my $popup_runs = 0;
  my $saw_warning = '';
  { local $SIG{__WARN__} = sub { $saw_warning = $_[0] };
    $menu->popup(undef, undef, sub {
                   $popup_runs = 1;
                   die;
                 }, undef, 1, 0);
  }
  note "popup position runs=$popup_runs warn='$saw_warning'";
  $menu->popdown;
  ok ($popup_runs,
      'popup positioning die() - popup runs');
  ok ($saw_warning,
      'popup positioning die() - die not fatal, turned into warning');
}

SKIP: {
	skip 'new 2.14 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	my $menu = Gtk2::Menu->new;
	$menu->set_accel_path ('<gtk2perl>/main/menu');
	is ($menu->get_accel_path, '<gtk2perl>/main/menu');

	$menu->set_monitor (0);
	is ($menu->get_monitor, 0);
}

SKIP: {
	skip 'new 2.18 stuff', 1
		unless Gtk2->CHECK_VERSION(2, 18, 0);

	$menu->set_reserve_toggle_size(FALSE);
	is ($menu->get_reserve_toggle_size, FALSE, '[sg]et_reserve_toggle_size');
}

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
