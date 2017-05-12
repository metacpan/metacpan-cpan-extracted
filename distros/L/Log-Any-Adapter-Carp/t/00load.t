#!/usr/bin/env perl

use Test::More;
use Log::Any qw($log);
use Log::Any::Adapter;

require_ok('Log::Any::Adapter::Carp');

my $rslt = Log::Any::Adapter->set( 'Carp', log_level => 'warning' );

ok( $rslt, 'Set adapter' );

isa_ok( $log, 'Log::Any::Proxy', 'Found logger' );

foreach my $level (qw/ is_trace is_debug is_info is_notice /) {
    ok( !$log->$level, 'Not logging at $level level' );
}

foreach my $level (
    qw/ is_warning is_error is_alert
    is_critical is_emergency /
  )
{
    ok( $log->$level, 'Logging at $level level' );
}

done_testing;
