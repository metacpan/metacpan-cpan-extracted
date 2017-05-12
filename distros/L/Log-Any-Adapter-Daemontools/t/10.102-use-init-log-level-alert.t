#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'alert' } );
ok( $log->is_alert,     'alert enabled' );
ok( !$log->is_critical, 'critical squelched' );

done_testing;
