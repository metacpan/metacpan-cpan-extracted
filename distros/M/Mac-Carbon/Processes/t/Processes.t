#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 6 }

use Mac::Processes;

SKIP: {
#	skip "Mac::Processes", 6;

# other process tests are in Notification.t
# we should check struct fields, too

	my $exists = 1;
	while (my($psn, $pi) = each %Mac::Processes::Process) {
		$exists = 0, last unless -e $pi->processAppSpec;
	}
	ok($exists, 'check process paths');

	my $psn = GetCurrentProcess();
	is(GetProcessPID($psn),  $$,   'psn == pid');
	is(GetProcessForPID($$), $psn, 'pid == psn');
	ok(SameProcess($psn, GetProcessForPID($$)), 'SameProcess(psn, pid)');

	SKIP: {
		skip "No parent available", 2 unless $ENV{MAC_CARBON_GUI};
		my $info = $Process{$psn};
		skip "No parent available", 2 unless $Process{$info->processLauncher};
		ok(SetFrontProcess($info->processLauncher), 'set front process');
		ok(SameProcess($info->processLauncher, GetFrontProcess()), 'check front process');
	}
}

__END__
