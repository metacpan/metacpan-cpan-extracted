#!/usr/bin/perl -w

use strict;

use Linux::Fanotify qw(:funcs :consts);
use Fcntl;

################################################################################

die("Need root\n") unless ($< == 0);

my $path = $ARGV[0];

if (!$path) {
	die("Usage: $0 <mount point>\n");
}

print <<EOF;
This script initializes fanotify and marks a mount point for monitoring
1000 times for testing purposes. It does so in separate jobs.

Monitoring mount point for path $path.
EOF

################################################################################

for (my $i = 0; $i < 1000; $i++) {

	my $pid = fork();

	if (!defined($pid)) {
		die("fork failed: $!\n");
	} elsif ($pid == 0) {
		print("init $i\n");
		my $fd = fanotify_init(FAN_CLOEXEC | FAN_CLASS_CONTENT, O_RDONLY | O_LARGEFILE) || die("Could not initialize fanotify: $!");
		print("mark $i\n");

		fanotify_mark($fd, FAN_MARK_ADD | FAN_MARK_MOUNT, FAN_OPEN_PERM | FAN_CLOSE_WRITE, -1, $path) || die("Could not mark $path: $!\n");
		print("done $i (exiting).\n");
		exit;
	}
	# parent continues loop
}

1;
