#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'emergency' } );
ok( $log->is_emergency, 'emergency enabled' );
ok( !$log->is_alert,    'alert squelched' ) or diag explain Log::Any::Adapter::Daemontools->global_config;

done_testing;
