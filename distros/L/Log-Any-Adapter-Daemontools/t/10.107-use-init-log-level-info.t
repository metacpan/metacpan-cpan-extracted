#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'info' } );
ok( $log->is_info,   'info enabled' );
ok( !$log->is_debug, 'debug squelched' );

done_testing;
