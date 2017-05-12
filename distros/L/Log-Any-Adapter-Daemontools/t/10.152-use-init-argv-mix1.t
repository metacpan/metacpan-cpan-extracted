#! /usr/bin/perl

BEGIN { @ARGV= qw( -qvv --quiet --quiet ) }
use Test::More;
use Log::Any '$log';

use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { argv => 1 } );

ok( $log->is_notice, 'notice enabled' );
ok( !$log->is_info,  'info squelched' );

done_testing;
