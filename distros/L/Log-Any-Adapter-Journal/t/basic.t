use 5.010;
use strict;
use warnings;
use Test::More;

use Log::Any qw($log);
use Log::Any::Adapter;
Log::Any::Adapter->set( 'Journal', min_level => 'trace' );

#   $log-> [method]     [message]      [expected]
_test_log( 'trace',     'TEST trace',   '<7>TEST trace' );
_test_log( 'debug',     'TEST debug',   '<7>TEST debug' );
_test_log( 'info',      'TEST info',    '<6>TEST info' );
_test_log( 'notice',    'TEST notice',  '<5>TEST notice' );
_test_log( 'warning',   'TEST warn',    '<4>TEST warn' );
_test_log( 'error',     'TEST error',   '<3>TEST error' );
_test_log( 'critical',  'TEST critial', '<2>TEST critial' );
_test_log( 'alert',     'TEST alert',   '<1>TEST alert' );
_test_log( 'emergency', 'TEST emerg',   '<0>TEST emerg' );

is( $log->is_trace,     1, 'is_trace' );
is( $log->is_debug,     1, 'is_debug' );
is( $log->is_info,      1, 'is_info' );
is( $log->is_notice,    1, 'is_notice' );
is( $log->is_warning,   1, 'is_warning' );
is( $log->is_error,     1, 'is_error' );
is( $log->is_critical,  1, 'is_critical' );
is( $log->is_alert,     1, 'is_alert' );
is( $log->is_emergency, 1, 'is_emergency' );

# We shouldn't print traces if min_level is debug or higher
Log::Any::Adapter->set( 'Journal', min_level => 'debug' );
_test_log( 'trace', 'TEST trace', undef, 'no trace when min_level=debug' );
_test_log( 'debug', 'TEST debug', '<7>TEST debug' );

sub _test_log {
    my ( $level, $msg, $expected_msg, $debug_msg ) = @_;
    $debug_msg ||= $expected_msg;
    $expected_msg &&= $expected_msg . "\n";

    # Bump Builder level so it reports caller for _test_log
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # Set the Adapter _fh to a string so we can test it
    my $messages;
    open my $fh, '>', \$messages or die 'Unable to open $message as fh';
    Log::Any->get_logger()->adapter->{_fh} = $fh;

    # Log the message
    $log->$level($msg);

    # Close the filehandle and check the result
    close $fh;
    is $messages, $expected_msg, $debug_msg;
}

done_testing;
