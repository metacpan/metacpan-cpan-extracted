#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'critical' } );
ok( $log->is_critical, 'critical enabled' );
ok( !$log->is_error,   'error squelched' );

done_testing;
