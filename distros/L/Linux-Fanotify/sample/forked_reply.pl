#!/usr/bin/perl -w

use strict;
use warnings;

use Linux::Fanotify qw(:consts :funcs);
use Fcntl;	# Provides O_* constants required for fanotify_init

################################################################################

die("Need root\n") unless ($< == 0);

my $path = $ARGV[0];

if (!$path) {
	die("Usage: $0 <mount point>\n");
}

print <<EOF;
WARNING!

This script demonstrates a problematic behavior of the fanotify subsystem
wrt ignoring events that require a response. It may mess up with your
queries.

In the main process, the incoming file handles are instantly closed, and
a forked process is expected to reply to the events. To allow the close()
call in the main process to not send a reply uppon closing the file
descriptor, we need to set the default_response variable to 0 ("ignore").

If you modify the child process to close the events as well without
replying, and later responses will not release the events they were targeted
at.

Monitoring mount point for path $path. Abort with ^C.
EOF

################################################################################

STDOUT->autoflush(1);

my $fd = fanotify_init(FAN_CLOEXEC | FAN_CLASS_CONTENT, O_RDONLY | O_LARGEFILE) || die("Could not initialize fanotify: $!");

fanotify_mark($fd, FAN_MARK_ADD | FAN_MARK_MOUNT, FAN_OPEN_PERM | FAN_CLOSE_WRITE, -1, $path) || die("Could not mark $path: $!\n");

$Linux::Fanotify::default_response = 0;

while (1) {
	my @events = fanotify_read($fd);
	printf("received %d events\n", scalar(@events));

	foreach my $e (@events) {

		printf("Pushing event to child.\n");

		my $pid = fork();
		die("Fork failed: $!") unless defined($pid);

		if ($pid) {
			$e->close();
		} else {
			printf("Got this request: " . $e . "\n");

			exit unless ($e->needsResponse());

			#
			# Modify 2 -> 3 to allow ignoring unanswered events
			#
			my $answer = int(rand(2));
			my $wait = int(rand(5)) + 1;

			if ($answer == 0) {
				print("Accepting after $wait seconds\n");
				sleep($wait);
				$e->allow();
			} elsif ($answer == 1) {
				print("Denying after $wait seconds\n");
				sleep($wait);
				$e->deny();
			} elsif ($answer == 2) {
				print("Ignoring after $wait seconds\n");
				sleep($wait);
			} else {
				die("Invalid randomness\n");
			}

			exit;
		}
	}
}

1;
