#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Email::Blaster::StandAlone');

ok( my $blaster = Email::Blaster::StandAlone->new(), 'new' );

ok( $blaster->handle_event( type => 'server_startup' ), 'handled server_startup' );
is( $ENV{STARTUP_OK} => 1, "startup handler ran");

# Allow the blaster to run for 4 seconds:
local $SIG{ALRM} = sub { $blaster->continue_running(0) };
alarm(4);
$blaster->run( );
alarm(0);

# Quitting:
ok( $blaster->handle_event( type => 'server_shutdown' ), 'handled server_shutdown' );
is( $ENV{SHUTDOWN_OK} => 1, "shutdown handler ran");


