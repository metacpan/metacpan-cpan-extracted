# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Linux-Setns.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('Linux::Setns') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.




SKIP: {
	skip "Should be root to test CLONE_ALL", 1 if $>;
	is(&Linux::Setns::setns("/proc/$$/ns/mnt", CLONE_ALL), 1);
};
SKIP: {
	skip "Should be root to test CLONE_NEWIPC", 1 if $>;
	is(&Linux::Setns::setns("/proc/$$/ns/ipc", CLONE_NEWIPC), 1);
};
SKIP: {
	skip "Should be root to test CLONE_NEWNET", 1 if $>;
	is(&Linux::Setns::setns("/proc/$$/ns/net", CLONE_NEWNET), 1);
};
SKIP: {
	skip "Should be root to test CLONE_NEWUTS", 1 if $>;
	is(&Linux::Setns::setns("/proc/$$/ns/uts", CLONE_NEWUTS), 1);
};

is(&Linux::Setns::setns("/proc/100000/ns/mnt", CLONE_ALL), 0);
is(&Linux::Setns::setns("/proc/$$/ns/mnt", CLONE_NEWNET), 0);
