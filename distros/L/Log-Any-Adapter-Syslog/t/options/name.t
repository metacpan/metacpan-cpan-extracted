use strict;
use warnings;

use Test::More tests => 4;
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

# Now, can we set a custom name?
lives_ok {
    Log::Any::Adapter->set('Syslog', name => 'example-name');
} "No exception setting the adapter to syslog with a name override";

is $openlog[0], 'example-name', "the custom name was preserved";
is $openlog[1], LOG_PID, "the default options were used";
is $openlog[2], LOG_LOCAL7, "the default facility was used";
