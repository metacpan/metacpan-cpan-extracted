use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;
use Test::MockModule;

use Log::Any qw{$log};
use Log::Any::Adapter;
use Unix::Syslog qw{:macros};

use vars qw{@syslog};

# Mock the Unix::Syslog classes to behave as we desire.
my $mock = Test::MockModule->new('Unix::Syslog');
$mock->mock('openlog', sub { 1; });
$mock->mock('syslog',  sub ($$@) {
    my ($priority, $format, @args) = @_;
    @syslog  = ($priority, sprintf($format, @args)); });

# Do nothing on closelog, since some libc implementations might abort if we
# didn't really call openlog, and I don't want that pain.
$mock->mock('closelog', sub {});

Log::Any::Adapter->set('Syslog');

my %tests = (
    trace     => LOG_DEBUG,
    debug     => LOG_DEBUG,
    info      => LOG_INFO,
    notice    => LOG_NOTICE,
    warning   => LOG_WARNING,
    error     => LOG_ERR,
    critical  => LOG_CRIT,
    alert     => LOG_ALERT,
    emergency => LOG_EMERG,
);

for my $level (sort keys %tests) {
    my $msg = "${level} level log";

    $log->$level($msg);

    is $syslog[0], $tests{$level}, "Log::Any ${level} maps to the right syslog priority";
    is $syslog[1], $msg, "Log::Any passed through the right message";
}


