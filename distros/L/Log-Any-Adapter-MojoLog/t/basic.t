#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious;
use Test::More;

use Log::Any::Adapter::MojoLog;
use Log::Any qw($log);

my $mojo_log = Mojo::Log->new->level('debug');
$mojo_log->unsubscribe('message');
my @messages;
$mojo_log->on(message => sub {
  shift;
  push @messages, [@_];
});
Log::Any->set_adapter( 'MojoLog', logger => $mojo_log );

_test_log( 'trace',     'debug', 'TEST trace',     'trace' );
_test_log( 'debug',     'debug', 'TEST debug',     'debug' );
_test_log( 'info',      'info',  'TEST info',      'info' );
_test_log( 'notice',    'info',  'TEST notice',    'notice' );
_test_log( 'warning',   'warn',  'TEST warning',   'warning' );
_test_log( 'error',     'error', 'TEST error',     'error' );
_test_log( 'critical',  'fatal', 'TEST critical',  'critical' );
_test_log( 'alert',     'fatal', 'TEST alert',     'alert' );
_test_log( 'emergency', 'fatal', 'TEST emergency', 'emergency' );

is( $log->is_trace,     1, 'is_trace' );
is( $log->is_debug,     1, 'is_debug' );
is( $log->is_info,      1, 'is_info' );
is( $log->is_notice,    1, 'is_notice' );
is( $log->is_warning,   1, 'is_warning' );
is( $log->is_error,     1, 'is_error' );
is( $log->is_critical,  1, 'is_critical' );
is( $log->is_alert,     1, 'is_alert' );
is( $log->is_emergency, 1, 'is_emergency' );

# Set level to error only
$mojo_log->level('error');

is( $log->is_trace,     '', 'is_trace' );
is( $log->is_debug,     '', 'is_debug' );
is( $log->is_info,      '', 'is_info' );
is( $log->is_notice,    '', 'is_notice' );
is( $log->is_warning,   '', 'is_warning' );
is( $log->is_error,     1,  'is_error' );
is( $log->is_critical,  1,  'is_critical' );
is( $log->is_alert,     1,  'is_alert' );
is( $log->is_emergency, 1,  'is_emergency' );

# Test log line. Not testing caller
sub _test_log {
  my ( $level, $target_level, $msg, $label ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  $log->$level($msg);
  is_deeply $messages[-1], [$target_level, $msg], $label;
}

done_testing;

