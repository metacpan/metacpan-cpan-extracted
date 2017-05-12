#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'warning' } );
ok( $log->is_warning, 'warning enabled' );
ok( !$log->is_notice, 'notice squelched' );

done_testing;
