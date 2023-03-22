
use strict;
use warnings;

use Test::More tests => 33;

use Log::Any qw{$log};
use Log::Any::Adapter;
use Log::Any::Adapter::Syslog;

# Mock the Sys::Syslog classes to behave as we desire.
my @logs;
my @openlogs;
no warnings qw( redefine once );
local *Log::Any::Adapter::Syslog::openlog = sub {
  push @openlogs, \@_;
  $Sys::Syslog::facility = $_[2];
};
local *Log::Any::Adapter::Syslog::syslog = sub { push @logs, \@_ };
local *Log::Any::Adapter::Syslog::closelog = sub { };

Log::Any::Adapter->set('Syslog');

my %tests = (
    trace     => "debug",
    debug     => "debug",
    info      => "info",
    notice    => "notice",
    warning   => "warning",
    error     => "err",
    critical  => "crit",
    alert     => "alert",
    emergency => "emerg",
);

for my $level (sort keys %tests) {
    my $msg = "${level} level log";

    $log->$level($msg);

    is $logs[-1][0], $tests{$level}, "Log::Any ${level} maps to the right syslog priority";
    is $logs[-1][1], $msg, "Log::Any passed through the right message";
}

# Check that the log was opened
is scalar @openlogs, 1, 'openlog() called once so far';
is $openlogs[-1][0], 'syslog.t', 'log opened with correct name';
is $openlogs[-1][1], 'pid', 'log opened with correct options';
is $openlogs[-1][2], 'local7', 'log opened with correct facility';

# Check that we can open another log
Log::Any::Adapter->set( 'Syslog',
    name => 'foo',
    options => "pid,perror",
    facility => 'user',
);
$log->error( "foo" );
is scalar @openlogs, 2, 'openlog() called twice so far';
is $openlogs[-1][0], 'foo', 'log opened with correct name';
is $openlogs[-1][1], 'pid,perror', 'log opened with correct options';
is $openlogs[-1][2], 'user', 'log opened with correct facility';

# Check that a closed log gets re-opened
Sys::Syslog::closelog();
$log->info( 'reopened' );
is scalar @openlogs, 3, 'openlog() called thrice so far';
is $openlogs[-1][0], 'foo', 'log opened with correct name';
is $openlogs[-1][1], 'pid,perror', 'log opened with correct options';
is $openlogs[-1][2], 'user', 'log opened with correct facility';

# Check that log level works
@logs = ();
Log::Any::Adapter->set( 'Syslog', log_level => 'emergency' );
$log->error( 'foo' );
is scalar @logs, 0, 'no log written because log_level too high';
$log->emergency( 'help' );
is $logs[-1][0], 'emerg', 'emergency log is logged';
is $logs[-1][1], 'help', 'emergency log is logged';

