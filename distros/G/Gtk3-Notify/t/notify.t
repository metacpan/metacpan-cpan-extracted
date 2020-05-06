#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;


BEGIN { require Gtk3::Notify; }
unless (eval { Gtk3::Notify->import; 1 }) {
  my $error = $@;
  if (eval { $error->isa ('Glib::Error') &&
             $error->domain eq 'g-irepository-error-quark'})
  {
    BAIL_OUT ("OS unsupported: $error");
  } else {
    BAIL_OUT ("Cannot load Gtk3::Notify: $error");
  }
}


use_ok('Gtk3::Notify');

is(Gtk3::Notify::is_initted(), '', "Is not initialized");

sub main {
    Gtk3::Notify::import('', '-init', 'test_app');
    is(Gtk3::Notify::is_initted(), 1, "Is initialized");
    my $view = Gtk3::Notify::Notification->new("Title", "test", undef);
    isa_ok($view, 'Gtk3::Notify::Notification');
    my $app_name = "Test";
    Gtk3::Notify::set_app_name($app_name);
    is(Gtk3::Notify::get_app_name(), $app_name,, "Retrieving just set name");
    can_ok($view, 'set_timeout');
    $view->set_timeout(100);
    return 0;
}


SKIP: {
    skip 'Gtk3::init_check failed, probably unable to open DISPLAY'
	unless Gtk3::init_check();

	exit main() unless caller;
}
