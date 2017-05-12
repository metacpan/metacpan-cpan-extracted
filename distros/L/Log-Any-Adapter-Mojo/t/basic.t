#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), '..', 'lib';

use Data::Dumper;
use Mojolicious;
use Test::More tests => 29;
use Test::Mojo;

use File::Temp qw{ tempfile tmpnam };

use_ok 'Log::Any::Adapter::Mojo';

use Log::Any qw($log);

# From 1.53 on an experimental formatter is added to Mojo::Log and the
# default log format has been simplified.
# Since all testcases are based on the old format, we need a custom
# Logger to simulate old behaviour.
package MyLog;
use Mojo::Base 'Mojo::Log';

# overload formatter
sub format {
    my ( $self, $level, @msgs ) = @_;
    my $msgs = join "\n",
        map { utf8::decode $_ unless utf8::is_utf8 $_; $_ } @msgs;

    # Caller
    my ( $pkg, $line ) = ( caller(2) )[ 0, 2 ];

    ( $pkg, $line ) = ( caller(3) )[ 0, 2 ]
        if $pkg eq ref $self || $pkg eq 'Mojo::Log';

    return '' . localtime(time) . " $level $pkg:$line [$$]: $msgs\n";
}

package main;

# See comment about formatter above
my $mojo_log = $Mojolicious::VERSION * 1.0 >= 1.53 ? MyLog->new : Mojo::Log->new;

Log::Any->set_adapter( 'Mojo', logger => $mojo_log );

$ENV{MOJO_LOG_LEVEL} = 'debug';

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
$ENV{MOJO_LOG_LEVEL} = 'error';

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

    like(
        _capture_stderr(
            sub {
                $log->$level($msg);
            }
        ),
        qr/\A\w{3}\ \w{3}\ +\d{1,2}\ \d{2}:\d{2}:\d{2}\ \d{4}
           \ \Q$target_level\E .*?\ \[\d+\]:\ \Q$msg\E\n\z/xms,
        $label
    );
    return;
}

# Redirect STDERR to temporary file. Execute function and return
# captured output.
sub _capture_stderr {
    my ($func_to_exec) = @_;

    my ( $temp_file_handle_stderr, $temp_file_name_stderr )
        = tempfile( UNLINK => 1, EXLOCK => 0 );

    open my $old_file_handle_stderr, '>&STDERR'
        or Carp::croak qq{Can't dup STDERR: $!};

    open STDERR, '>', $temp_file_name_stderr
        or Carp::croak
        qq{Can't redirect STDERR to $temp_file_name_stderr: $!};

    my $store = $|;

    select STDERR;
    $| = 1;

    $func_to_exec->();

    open STDERR, '>&', $old_file_handle_stderr
        or Carp::croak qq{Can't dup old_stderr: $!};

    $| = $store;

    open my $fh, '<', $temp_file_name_stderr
        or Carp::confess qq{$temp_file_name_stderr: $!};

    # Slurp temp. file content.
    my $stderr_output = do {
        local $/;
        <$fh>;
    };
    close $fh;

    return $stderr_output;
}

## Test that correct package and line is displayed in log.

######### Test package

package MyTest;
use Log::Any qw($log);

sub do_log {
    my ( $class, $msg ) = @_;
    return $log->debug($msg);
}

######### Test package

package main;

$ENV{MOJO_LOG_LEVEL} = 'debug';    # back to debug level

my $msg = 'asdfjkjkladfjk889234jkljk3rmnvm,m,zxcv,asdfkljfk';
like(
    _capture_stderr(
        sub {
            MyTest->do_log($msg);
            return;
        }
    ),
    qr/\A\w{3}\ \w{3}\ +\d{1,2}\ \d{2}:\d{2}:\d{2}\ \d{4}\ debug
       \ MyTest:\d+\ \[\d+\]:\ \Q$msg\E\n\z/xms,
    'Test log package and line'
);

1;
