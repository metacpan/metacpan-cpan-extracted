#!/usr/bin/env perl

use Test::More;
use Log::Any qw($log);
use Log::Any::Adapter;

Log::Any::Adapter->set( 'Carp', no_trace => 1, log_level => 'warn' );

my $msg;
$SIG{__WARN__} = sub { $msg = shift; };

$log->info('Not logged');
ok( !defined $msg, 'Not logged below threshold' );

$log->error('Is logged');
is( $msg, "Is logged\n", 'Log message at appropriate, no trace' );

Log::Any::Adapter->set( 'Carp', log_level => 'info' );

$log->info('Now logged');
like( $msg, qr/^Now logged/,             'Log at new appropriate level' );
like( $msg, qr{Now logged at .*basic.t}, 'Log message, with trace' );

Log::Any::Adapter->set( 'Carp', log_level => 'info', full_trace => 1 );

$log->info('Now logged');
like(
    $msg,
    qr{Now logged at .*Log::Any::Adapter::Carp.*basic.t}s,
    'Log message, with full trace'
);

done_testing();
