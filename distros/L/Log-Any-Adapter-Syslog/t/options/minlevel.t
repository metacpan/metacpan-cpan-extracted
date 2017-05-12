use strict;
use warnings;

use Test::More tests => 38;
use Test::Exception;
use Test::MockModule;

use Log::Any qw{$log};
use Log::Any::Adapter;
use Unix::Syslog qw{:macros};

use vars qw{@syslog};

# Mock the Unix::Syslog classes to behave as we desire.
my $mock = Test::MockModule->new('Unix::Syslog');
$mock->mock('closelog', sub {});
$mock->mock('openlog', sub {});
$mock->mock('syslog',  sub ($$@) { @syslog  = @_; });

# Custom options
lives_ok { Log::Any::Adapter->set('Syslog', min_level => 'info') }
    "No exception setting the adapter to syslog with options";

test_level(
    trace     => '',
    debug     => '',
    info      => 1,
    notice    => 1,
    warning   => 1,
    error     => 1,
    critical  => 1,
    alert     => 1,
    emergency => 1,
);

# min level from ENV
$ENV{LOG_LEVEL} = 'warning';
lives_ok { Log::Any::Adapter->set('Syslog') }
    "No exception setting the adapter to syslog with options";

test_level(
    trace     => '',
    debug     => '',
    info      => '',
    notice    => '',
    warning   => 1,
    error     => 1,
    critical  => 1,
    alert     => 1,
    emergency => 1,
);

sub test_level {
    my %tests = @_;
    for my $level (sort keys %tests) {
        @syslog = ();
        my $msg = "${level} level log";
        $log->$level($msg);
        my $islevel = 'is_'.$level;

        if ($tests{$level}) {
            is $syslog[2], $msg, "Log::Any passed through the right message";
        } else {
            is scalar(@syslog), 0, "Log::Any blocked the right message";
        }
        is($log->$islevel(),$tests{$level},'Detection '.$level.' level ok');
    }
    return;
}
