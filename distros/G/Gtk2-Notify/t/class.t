#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More tests => 7;
use Glib qw( TRUE FALSE );
use Gtk2::Notify;

my $app_name = 'test-suite';

is( Gtk2::Notify->is_initted, FALSE, 'not initted after loading' );
ok( Gtk2::Notify->init($app_name), 'init' );
is( Gtk2::Notify->is_initted, TRUE, 'now initted' );

is( Gtk2::Notify->get_app_name, $app_name, 'set/get app_name' );

lives_ok(sub { Gtk2::Notify->uninit; }, 'uninit');

SKIP: {
    skip 'various reasons', 2;

    lives_ok(sub { Gtk2::Notify->get_server_caps; }, 'get_server_caps');

    my @server_info = Gtk2::Notify->get_server_info;
    is( scalar @server_info, 4, 'get_server_info' );
}
