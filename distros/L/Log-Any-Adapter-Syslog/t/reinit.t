use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;
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

# Verify that we get the right options passed to the instance.
lives_ok { Log::Any::Adapter->set('Syslog') }
    "No exception setting the adapter to syslog without arguments";

is_deeply \@openlog, [ 'reinit.t', LOG_PID, LOG_LOCAL7 ],
    'openlog called with expected parameters';

# Call again with the same parameters and check we didn't call openlog again
@openlog = ();
lives_ok { Log::Any::Adapter->set('Syslog') }
    "No exception setting the adapter to syslog again without arguments";
is scalar @openlog, 0, 'openlog was not called';

# Call again with the new parameters and check we do call openlog
lives_ok { Log::Any::Adapter->set('Syslog', name => 'foo') }
    "No exception setting the adapter to syslog again with new arguments";
is_deeply \@openlog, [ 'foo', LOG_PID, LOG_LOCAL7 ],
    'openlog called with expected parameters';

# Call again with the same parameters and check we didn't call openlog again
@openlog = ();
lives_ok { Log::Any::Adapter->set('Syslog', name => 'foo') }
    "No exception setting the adapter to syslog again with new arguments";
is scalar @openlog, 0, 'openlog was not called';

# Call again with the new parameters and check we do call openlog
lives_ok { Log::Any::Adapter->set('Syslog', options => LOG_NDELAY ) }
    "No exception setting the adapter to syslog again with new arguments";
is_deeply \@openlog, [ 'reinit.t', LOG_NDELAY, LOG_LOCAL7 ],
    'openlog called with expected parameters';


done_testing();
