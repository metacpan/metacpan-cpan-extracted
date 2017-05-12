#!/usr/bin/perl
# vim: set syntax=perl :
#
# $Id$
#

#########################
# GtkDialog Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 33;

ok( my $win = Gtk2::Window->new('toplevel') );

# a constructor made dialog, run
ok( my $d1 = Gtk2::Dialog->new("Test Dialog", $win,
		[qw/destroy-with-parent no-separator/],
		'gtk-cancel', 2, 'gtk-quit', 3 ) );
ok( my $btn1 = $d1->add_button('Another', 4) );
ok( $d1->get_has_separator == 0 );
Glib::Idle->add( sub {
		$btn1->clicked;
		0;
	});
ok( $d1->run == 4 );
$d1->hide;

# a hand made dialog, run
ok( my $d2 = Gtk2::Dialog->new );
ok( $d2->add_button('First Button', 0) );
ok( my $btn2 = $d2->add_button('gtk-ok', 1) );
$d2->set_has_separator(1);
ok( $d2->get_has_separator == 1 );
$d2->set_has_separator(0);
ok( $d2->get_has_separator == 0 );
$d2->add_buttons('gtk-cancel', 2, 'gtk-quit', 3, 'Last Button', 4);
$d2->add_action_widget(Gtk2::Button->new("Uhh"), 5);
$d2->set_default_response(4);
$d2->set_response_sensitive(4, 1);
$d2->signal_connect( response => sub {
		ok( $_[1] == 1 );
		1;
	});
Glib::Idle->add( sub {
		$btn2->clicked;
		0;
	});
ok( $d2->run == 1 );
$d2->hide;

# a constructor made dialog, show
ok( my $d3 = Gtk2::Dialog->new("Test Dialog", $win,
		[qw/destroy-with-parent no-separator/],
		'gtk-ok', 22, 'gtk-quit', 33 ) );
ok( my $btn3 = $d3->add_button('Another', 44) );
ok( $d3->get_has_separator == 0 );
$d3->vbox->pack_start( Gtk2::Label->new('This is just a test.'), 0, 0, 0);
$d3->action_area->pack_start( Gtk2::Label->new('<- Actions'), 0, 0, 0);
$d3->show_all;
$d3->signal_connect( response => sub {
		ok( $_[1] == 44 );
		1;
	});
ok(1);

$btn3->clicked;
ok(1);

# make sure that known response types are converted to strings for the reponse
# signal of Gtk2::Dialog and its ancestors
foreach my $package (qw/Gtk2::Dialog Gtk2::InputDialog/) {
	my $d = $package->new;
	my $b = $d->add_button('First Button', 'ok');
	$d->signal_connect( response => sub {
		is( $_[1], 'ok', "$package reponse" );
		TRUE;
	});
	Glib::Idle->add( sub {
		$b->clicked;
		FALSE;
	});
	is( $d->run, 'ok', "$package run" );
	$d->hide;
}

SKIP: {
	skip 'set_alternative_button_order is new in 2.6', 3
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$d3->set_alternative_button_order (2, 3);
	$d3->set_alternative_button_order (qw(ok cancel accept), 3);
	$d3->set_alternative_button_order;

	my $screen = Gtk2::Gdk::Screen->get_default;
	like (Gtk2->alternative_dialog_button_order ($screen), qr/^(?:1|)$/);
	like (Gtk2->alternative_dialog_button_order (undef), qr/^(?:1|)$/);
	like (Gtk2->alternative_dialog_button_order, qr/^(?:1|)$/);
}

SKIP: {
	skip 'get_response_for_widget is new in 2.8', 1
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	is( $d3->get_response_for_widget (($d3->action_area->get_children)[1]), 44 );
}

# 2.14 introduced accessors for the struct members vbox and action_area.  we
# provide them under the new name for all versions of gtk+ by using direct
# struct access on older versions.  for compatibility, we continue to provide
# the old names.
isa_ok ($d3->get_action_area, 'Gtk2::HButtonBox');
isa_ok ($d3->get_content_area, 'Gtk2::VBox');

ok ($d3->action_area == $d3->get_action_area);
ok ($d3->vbox == $d3->get_content_area);

SKIP: {
	skip 'get_widget_for_response is new in 2.20', 2
		unless Gtk2->CHECK_VERSION (2, 20, 0);

	# number response id
	is ($d3->get_widget_for_response(44), $btn3);

	# enum name response id
	my $button = Gtk2::Button->new('foo');
	$d3->add_action_widget($button, 'help');
	is ($d3->get_widget_for_response('help'), $button);
}

# Make sure that our custom "response" marshaller is used.
{
	my $d = Gtk2::Dialog->new("Test Dialog", undef, [],
				  'gtk-ok', 'ok');
	$d->signal_connect(response => sub {
		is ($_[1], 'ok');
		Gtk2->main_quit;
	});
	run_main (sub { $d->response ('ok'); });
}

__END__

Copyright (C) 2003-2005, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
