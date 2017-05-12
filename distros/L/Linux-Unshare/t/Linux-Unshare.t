use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;
BEGIN { use_ok('Linux::Unshare', qw(unshare CLONE_NEWNS CLONE_FS CLONE_FILES CLONE_NEWUTS CLONE_SYSVSEM CLONE_NEWIPC CLONE_NEWNET CLONE_NEWUSER CLONE_CONTAINER unshare_ns)) };

SKIP: {
	skip "Should be root to test mount --bind", 1 if $<;
	my $pid = fork();
	if ($pid) {
		waitpid($pid, 0);
	} else {
		# Legacy unshare_ns should return 0 on success
		unshare_ns() and die $!;
		system("mount --bind /dev/null $0") and die;
		exit;
	}
	my $res = `umount $0 2>&1`;
	isnt($res, '');
};

is(unshare(CLONE_NEWNS), $< ? undef : 1);
is(unshare(CLONE_FS), 1);
is(unshare(CLONE_FILES), 1);
is(unshare(CLONE_SYSVSEM), 1);
SKIP: {
	skip "Should be root to test CLONE_NEWUTS", 1 if $<;
	is(unshare(CLONE_NEWUTS), 1);
};
SKIP: {
	skip "Should be root to test CLONE_NEWIPC", 1 if $<;
	is(unshare(CLONE_NEWIPC), 1);
};
SKIP: {
	skip "Should be root to test CLONE_NEWNET", 1 if $<;
	is(unshare(CLONE_NEWNET), 1);
};
SKIP: {
	skip "Should be root to test CLONE_NEWUSER", 1 if $<;
	is(unshare(CLONE_NEWUSER), 1);
};
SKIP: {
	skip "Should be root to test CLONE_CONTAINER", 1 if $<;
	is(unshare(CLONE_CONTAINER), 1);
};
