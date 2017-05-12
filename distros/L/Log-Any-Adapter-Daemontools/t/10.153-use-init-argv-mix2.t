#! /usr/bin/perl

BEGIN { @ARGV= qw( -vv --quiet --verbose ) }
use Test::More;
use Log::Any '$log';

use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'error', argv => 1 } );

ok( $log->is_notice, 'notice enabled' );
ok( !$log->is_info,  'info squelched' );

done_testing;
