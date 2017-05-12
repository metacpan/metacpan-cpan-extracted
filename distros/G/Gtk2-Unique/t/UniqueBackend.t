#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 8;

use Gtk2::Unique;

exit tests();

sub tests {
	my $backend = Gtk2::UniqueBackend->create();
	isa_ok($backend, 'Gtk2::UniqueBackend');
	
	is($backend->get_name, undef, "get_name()");
	$backend->set_name("perl-testing");
	is($backend->get_name, "perl-testing", "set_name()");
	
	is($backend->get_startup_id, undef, "get_startup_id()");
	$backend->set_startup_id("staring");
	is($backend->get_startup_id, "staring", "set_startup_id()");
	
	isa_ok($backend->get_screen, 'Gtk2::Gdk::Screen', "get_screen()");
	$backend->set_screen(Gtk2::Gdk::Screen->get_default);
	is($backend->get_screen, Gtk2::Gdk::Screen->get_default, "set_screen()");
	
	ok($backend->get_workspace >= 0, "get_workspace()");
#	ok($backend->request_name(), "request_name()");
	
#	my $response = $backend->send_message(1, undef, 0);
#	is ($response, '', "send_message()");
	
	return 0;
}
