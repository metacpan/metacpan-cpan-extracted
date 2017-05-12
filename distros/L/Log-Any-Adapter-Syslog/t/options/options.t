use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Test::MockModule;

use Log::Any qw{$log};
use Log::Any::Adapter;
use Unix::Syslog qw{:macros};

use vars qw{@openlog @syslog};

# Mock the Unix::Syslog classes to behave as we desire.
my $mock = Test::MockModule->new('Unix::Syslog');
$mock->mock('openlog', sub { @openlog = @_; });
$mock->mock('syslog',  sub ($$@) { @syslog  = @_; });

# Do nothing on closelog, since some libc implementations might abort if we
# didn't really call openlog, and I don't want that pain.
$mock->mock('closelog', sub {});

# Custom options
lives_ok { Log::Any::Adapter->set('Syslog', options => LOG_NDELAY) }
    "No exception setting the adapter to syslog with options";

is $openlog[0], 'options.t', "the right syslog name was inferred";
is $openlog[1], LOG_NDELAY, "the custom options were used";
is $openlog[1] & LOG_PID, 0, "the default LOG_PID option was not merged";
is $openlog[2], LOG_LOCAL7, "the default LOG_LOCAL7 facility was used";
