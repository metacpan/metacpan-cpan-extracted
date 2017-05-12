#!/usr/bin/perl
#
# $Id$
#

#########################
# GtkWindow Tests
# 	- rm
#########################

#########################

use Gtk2::TestHelper tests => 120;

ok( my $win = Gtk2::Window->new );
ok( $win = Gtk2::Window->new('popup') );
ok( $win = Gtk2::Window->new('toplevel') );

$win->set_title;
ok(1);
$win->set_title(undef);
ok(1);
$win->set_title('');
ok(1);
$win->set_title('Test Window');
ok(1);

is( $win->get_title, 'Test Window' );

$win->set_resizable(TRUE);
ok(1);

ok( $win->get_resizable );

$win->set_modal(TRUE);
ok(1);

ok( $win->get_modal );

$win->set_default_size(640, 480);
ok(1);

# the window manager needn't honor our request, but the
# widget should be holding the values and the bindings
# should return them correctly.
my @s = $win->get_default_size;
ok( $s[0] == 640 && $s[1] == 480 );

my $geometry = {
	min_width => 10,
	min_height => 10
};

my $label = Gtk2::Label->new("Bla");

$win->set_geometry_hints($label, $geometry);
ok(1);
$win->set_geometry_hints($label, $geometry, undef);
ok(1);
$win->set_geometry_hints($label, $geometry, qw(min-size));
ok(1);

foreach (qw/north-west north north-east west center east
	    south-west south south-east static/)
{
	$win->set_gravity($_);
	ok(1);

	is( $win->get_gravity , $_, "gravity $_" );
}

foreach (qw/none center mouse center-always center-on-parent/)
{
	$win->set_position($_);
	ok(1, "set_position $_");
}

$win->set_position('center');
ok(1);

my @position = $win->get_position;
is(scalar(@position), 2);

ok( my $win2 = Gtk2::Window->new );

$win2->set_transient_for($win);
ok(1);

is( $win2->get_transient_for, $win );

$win2->set_destroy_with_parent(TRUE);
ok(1);

ok( $win2->get_destroy_with_parent );

my @toplvls = Gtk2::Window->list_toplevels;
is(scalar(@toplvls), 4);

use Gtk2::Gdk::Keysyms;
my $mnemonic = $Gtk2::Gdk::Keysyms{ KP_Enter };

$win2->add_mnemonic($mnemonic, $label);
ok(1);

ok( defined $win2->mnemonic_activate($mnemonic, "shift-mask") );

SKIP: {
	skip "activate_key and propagate_key_event are new in 2.4", 2
		unless Gtk2->CHECK_VERSION (2, 4, 0);

	my $event = Gtk2::Gdk::Event::Key->new ("key-press");
	$event->keyval ($Gtk2::Gdk::Keysyms{ A });

	ok ( ! $win2->activate_key ($event) );
	ok ( ! $win2->propagate_key_event ($event) );
}

$win2->remove_mnemonic($mnemonic, $label);
ok(1);

$win2->set_mnemonic_modifier("control-mask");
ok(1);

is_deeply(\@{ $win2->get_mnemonic_modifier }, ["control-mask"]);

$win2->set_focus;
ok(1);

$win2->set_focus(Gtk2::Entry->new());
ok(1);

my $button = Gtk2::Button->new ('i can default!');
$button->can_default (TRUE);
$win2->set_default($button);

$win2->set_decorated(TRUE);
ok(1);
ok( $win2->get_decorated );

$win2->set_has_frame(FALSE);
ok(1);

ok( !$win2->get_has_frame );

$win2->set_role('tool');
ok(1);

is( $win2->get_role, 'tool' );

foreach (qw/normal dialog menu toolbar/)
{
	$win2->set_type_hint($_);
	ok(1);

	is( $win2->get_type_hint, $_ );
}

SKIP: {
	skip 'stuff missing in 2.0.x', 6
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	foreach (qw/splashscreen utility dock desktop/)
	{
		$win2->set_type_hint($_);

		is( $win2->get_type_hint, $_ );
	}

	SKIP: {
		skip 'taskbar stuff missing on windows', 1
			if $^O eq 'MSWin32';

		$win2->set_skip_taskbar_hint('true');

		ok( $win2->get_skip_taskbar_hint );
	}

	$win2->set_skip_pager_hint('true');

	ok( $win2->get_skip_pager_hint );
}

ok( ! $win->get_default_icon_list );

# need pixbufs
#$win->set_default_icon_list(...)

# need file
#$win->set_default_icon_from_file(...)

# need a pixbuf
#$win->set_icon($pixbuf);

# doesn't have an icon ^
ok( ! $win->get_icon );

# doesn't have an icon ^
ok( ! $win->get_icon_list );

my $accel_group = Gtk2::AccelGroup->new;
$win->add_accel_group ($accel_group);
$win->remove_accel_group ($accel_group);


# we can set this here, but we'll have to wait until events have
# been handled to check them.  see the run_main block, below.
$win->set_frame_dimensions(0, 0, 300, 500);

ok( $win2->parse_geometry("100x100+10+10") );

SKIP: {
	skip 'set_auto_startup_notification is new in 2.2', 0
		unless Gtk2->CHECK_VERSION(2, 2, 0);

	$win2->set_auto_startup_notification(FALSE);
}

$win->show;
ok(1);

run_main sub {
		$win2->show;

		# there are no widgets, so this should fail
		ok( ! $win->activate_focus );

		# there are no widgets, so this should fail
		ok( ! $win->activate_default );

		# there are no widgets, so this should fail
		ok( ! $win->get_focus );

		$win->present;
		ok(1);

		$win->iconify;
		ok(1);

		# doesnt work no error message
		$win->deiconify;
		ok(1);

		$win->stick;
		ok(1);

		$win->unstick;
		ok(1);

		# doesnt work no error message
		$win->maximize;
		ok(1);

		# doesnt work no error message
		$win->unmaximize;
		ok(1);

		# gtk2.2 req
		SKIP: {
			my $reason;
			if ($^O eq 'MSWin32') {
				$reason = 'GdkScreen not available on win32';
			} elsif (!Gtk2->CHECK_VERSION (2, 2, 0)) {
				$reason = 'stuff not available before 2.2.x';
			} else {
				$reason = undef;
			}

			skip $reason, 1 if defined $reason;

			$win->set_screen(Gtk2::Gdk::Screen->get_default());
			is($win->get_screen, Gtk2::Gdk::Screen->get_default());

			$win->fullscreen;
			$win->unfullscreen;
		}

		SKIP: {
			skip "new things in 2.4", 3
				unless Gtk2->CHECK_VERSION (2, 4, 0);

			like($win->is_active, qr/^(1|)$/);
			like($win->has_toplevel_focus, qr/^(1|)$/);

			$win->set_keep_above (1);
			$win->set_keep_below (1);

			$win->set_accept_focus (1);
			is ($win->get_accept_focus, 1);

			$win->set_default_icon (Gtk2::Gdk::Pixbuf->new ("rgb", 0, 8, 15, 15));
		}

		# Commented out because there seems to be no way to finish the
		# drags.  We'd be getting stale pointer grabs otherwise.
		# $win->begin_resize_drag("south-east", 1, 23, 42, 0);
		# ok(1);
		# $win->begin_move_drag(1, 23, 42, 0);
		# ok(1);

		$win->move(100, 100);

		# these are widget methods and not window, but they need 
		# testing and this seemed like a good place to do it
		my $tmp = $win->intersect(Gtk2::Gdk::Rectangle->new(0, 0, 10, 10));
		isa_ok( $tmp, 'Gtk2::Gdk::Rectangle' );
		$tmp = $win->intersect(Gtk2::Gdk::Rectangle->new(-10, -10, 1, 1));
		ok( !$tmp );

		$win->resize(480,600);

		# window managers don't honor our size request exactly,
		# or at least we aren't guaranteed they will
		ok( $win->get_size );
		ok( $win->get_frame_dimensions );

		$win2->reshow_with_initial_size;
		ok(1);
};


my $group = Gtk2::WindowGroup->new;
isa_ok( $group, "Gtk2::WindowGroup" );

$group->add_window ($win);
$group->remove_window ($win);

SKIP: {
	skip "new 2.6 stuff", 2
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$win->set_focus_on_map (TRUE);
	is ($win->get_focus_on_map, TRUE);

	$win->set_icon_name ("gtk-ok");
	is ($win->get_icon_name, "gtk-ok");

	Gtk2::Window->set_default_icon_name ("gtk-cancel");
}

SKIP: {
	skip("new 2.8 stuff", 1)
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	$win->set_urgency_hint (TRUE);
	is ($win->get_urgency_hint, TRUE);

	$win->present_with_time (time);
}

SKIP: {
	skip("new 2.10 stuff", 2)
		unless Gtk2->CHECK_VERSION (2, 10, 0);

	$win->set_deletable (TRUE);
	is ($win->get_deletable, TRUE);

	isa_ok ($win->get_group, "Gtk2::WindowGroup");
}

SKIP: {
	skip("new 2.12 stuff", 1)
		unless Gtk2->CHECK_VERSION (2, 12, 0);

	$win->set_startup_id('Start me!');

	$win->set_opacity (0.5);
	is ($win->get_opacity, 0.5);
}

SKIP: {
	skip 'new 2.14 stuff', 4
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	my $window = Gtk2::Window->new ();
	is ($window->get_default_widget (), undef);

	my $widget = Gtk2::Entry->new ();
	$widget->set (can_default => TRUE);
	$window->set_default ($widget);
	is ($window->get_default_widget (), $widget);

	my $group = Gtk2::WindowGroup->new ();
	$group->add_window (Gtk2::Window->new ());
	$group->add_window (Gtk2::Window->new ());
	$group->add_window (Gtk2::Window->new ());

	my @list = $group->list_windows ();
	is (scalar @list, 3);
	isa_ok ($list[0], 'Gtk2::Window');
}

SKIP: {
	skip 'new 2.16 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 16, 0);

	Gtk2::Window->set_default_icon_name (undef);
	is (Gtk2::Window->get_default_icon_name,undef, '[gs]et_default_icon_name with undef');
	Gtk2::Window->set_default_icon_name ('gtk-ok');
	is (Gtk2::Window->get_default_icon_name,'gtk-ok', 'get_default_icon_name');
}

SKIP: {
	skip 'new 2.20 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 20, 0);

	my $window = Gtk2::Window->new;
	is ($window->get_window_type, 'toplevel');

	$window->set_mnemonics_visible (TRUE);
	ok ($window->get_mnemonics_visible);
}

SKIP: {
	skip 'new 2.22 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 22, 0);

	my $window = Gtk2::Window->new;
	my $group = Gtk2::WindowGroup->new ();
	$group->add_window ($window);

	ok ($window->has_group);

	my $grab = $group->get_current_grab;
	ok ((defined $grab && $grab->isa ('Gtk2::Widget')) || !defined $grab);
}


__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
