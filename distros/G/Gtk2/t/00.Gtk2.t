#!/usr/bin/perl
#
# $Id$
#

use strict;
use warnings;

#########################
# Gtk2 Tests
# 	- rm
#########################

#########################

# NOTE: this is the bootstrap test -- no Gtk2::TestHelper here!

use Test::More tests => 30;
BEGIN { use_ok('Gtk2') };

#########################

my @run_version = Gtk2->get_version_info;
my @compile_version = Gtk2->GET_VERSION_INFO;

diag 'Testing Gtk2 ', $Gtk2::VERSION;
diag '   Running against gtk+ ', join '.', @run_version;
diag '  Compiled against gtk+ ', join '.', @compile_version;

is( @run_version, 3, 'version info is three items long' );
is (Gtk2->check_version(0,0,0), 'Gtk+ version too new (major mismatch)',
    'check_version pass');
is (Gtk2->check_version(50,0,0), 'Gtk+ version too old (major mismatch)',
    'check_version fail');
ok (defined (Gtk2::major_version), 'major_version');
ok (defined (Gtk2::minor_version), 'minor_version');
ok (defined (Gtk2::micro_version), 'micro_version');

is (@compile_version, 3, 'version info is three items long');
ok (Gtk2->CHECK_VERSION(0,0,0), 'CHECK_VERSION pass');
ok (!Gtk2->CHECK_VERSION(50,0,0), 'CHECK_VERSION fail');
is (Gtk2::MAJOR_VERSION, $compile_version[0], 'MAJOR_VERSION');
is (Gtk2::MINOR_VERSION, $compile_version[1], 'MINOR_VERSION');
is (Gtk2::MICRO_VERSION, $compile_version[2], 'MICRO_VERSION');

#########################

SKIP:
{
	Gtk2->disable_setlocale;

	skip 'Gtk2->init_check failed, probably unable to open DISPLAY', 
		17, unless( Gtk2->init_check );

	ok( Gtk2->init );
	ok( Gtk2->set_locale );

	isa_ok( Gtk2->get_default_language, "Gtk2::Pango::Language" );

	is( Gtk2->main_level, 0, 'main level is zero when there are no loops' );

	my $window = Gtk2::Object->new ("Gtk2::Window");
	my $object = Gtk2::Object->new ("Gtk2::Label");

	my $event = Gtk2::Gdk::Event->new ("button-press");

	$event->button (1);
	$event->time (time);
	$event->state ([qw/shift-mask control-mask/]);

	Gtk2::Gdk::Event->put ($event);

	$window->add ($object);
	$object->realize;

	$object->propagate_event ($event);

	# warn Gtk2->get_current_event;
	# warn Gtk2->get_current_event_time;
	# warn Gtk2->get_current_event_state;
	# warn Gtk2->get_event_widget ($event);

	my $events = 0;
	my $retval;

	while (Gtk2->events_pending) {
		$retval = Gtk2->main_iteration;
		$events++;
	}

	ok( $events );
	ok( $retval );

	Gtk2::Gdk::Event->put ($event);

	$events = 0;

	while (Gtk2->events_pending) {
		$retval = Gtk2->main_iteration_do (0);
		$events++;
	}

	ok( $events );
	ok( $retval );

	my $snooper;
	ok( $snooper = Gtk2->key_snooper_install (sub { warn @_; 0; }, "bla") );
	Gtk2->key_snooper_remove ($snooper);

	Gtk2->init_add( sub { ok(1); } );
	Gtk2->init_add( sub { ok($_[0] eq 'foo'); }, 'foo' );
	ok(1);

	Gtk2->quit_add_destroy (1, $object);

	my $q1;
	ok( $q1 = Gtk2->quit_add( 0, sub { Gtk2->quit_remove($q1); ok(1); } ) );
	ok( Gtk2->quit_add( 0, sub { ok($_[0] eq 'bar'); }, 'bar' ) );

	Glib::Idle->add( sub { Gtk2->main_quit; 0 } );
	Gtk2->main;
	ok(1);
}

__END__

Copyright (C) 2003-2004, 2013 by the gtk2-perl team (see the file AUTHORS for
the full list).  See LICENSE for more information.
