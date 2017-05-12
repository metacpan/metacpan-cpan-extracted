#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'debug' } );
ok( $log->is_debug,  'debug enabled' );
ok( !$log->is_trace, 'trace squelched' );

done_testing;
