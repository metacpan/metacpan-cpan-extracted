#! /usr/bin/perl

use Test::More;
use Log::Any '$log';
use_ok( 'Log::Any::Adapter', 'Daemontools', -init => { level => 'error' } );
ok( $log->is_error,    'error enabled' );
ok( !$log->is_warning, 'warning squelched' );

done_testing;
