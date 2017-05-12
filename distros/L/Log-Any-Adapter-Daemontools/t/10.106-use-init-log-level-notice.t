#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'notice' } );
ok( $log->is_notice, 'notice enabled' );
ok( !$log->is_info,  'info squelched' );

done_testing;
