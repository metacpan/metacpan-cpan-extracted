use warnings;
use strict;

use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(sem_set_limit low_sem_resources relieve_ipc_pressure);

# Coverage for the platform resource-awareness helpers in IPCShareableTest.
# Tests that create many tied variables use these to detect a small SysV
# semaphore-set budget (eg. OpenBSD, kern.seminfo.semmni = 10) and release IPC
# as they go, rather than exhausting the host.

my $limit = sem_set_limit();

ok ! defined $limit || $limit =~ /^\d+$/,
    'sem_set_limit() returns undef or a non-negative integer';

my $low = low_sem_resources();
ok $low == 0 || $low == 1, 'low_sem_resources() returns a boolean';

is $low, (defined $limit && $limit < IPCShareableTest::LOW_SEM_SETS() ? 1 : 0),
    'low_sem_resources() reflects the measured limit against the threshold';

is low_sem_resources(), $low, 'low_sem_resources() is stable (cached)';

if (defined $limit) {
    diag "host reports $limit SysV semaphore set(s); threshold is "
        . IPCShareableTest::LOW_SEM_SETS();
}
else {
    is $low, 0, 'an undeterminable limit is treated as not-constrained';
}

# relieve_ipc_pressure() must run cleanly whether or not the host is constrained
# (it is a no-op unless low_sem_resources() is true).
ok eval { relieve_ipc_pressure(); 1 }, 'relieve_ipc_pressure() runs without error';

done_testing();
