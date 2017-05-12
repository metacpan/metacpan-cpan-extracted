#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'trace' } );
ok( $log->is_debug,  'trace enabled' );

done_testing;
