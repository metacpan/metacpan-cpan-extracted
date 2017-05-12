#! /usr/bin/perl

BEGIN { @ARGV= qw( -v ) }
use Test::More;
use Log::Any '$log';

use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { argv => 1 } );

ok( $log->is_debug,  'debug enabled' );
ok( !$log->is_trace, 'trace squelched' );

done_testing;
