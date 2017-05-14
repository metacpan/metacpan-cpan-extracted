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
This script demonstrates a variety of options how events can be responded
to. It does so 1000 times for testing purposes.

Please open arbitrary files in the monitored path (sth like
echo foo > somefile ; while [ 1 ] ; do cat somefile ; done
)

Monitoring mount point for path $path.
EOF

################################################################################

my $fd = fanotify_init(FAN_CLOEXEC | FAN_CLASS_CONTENT, O_RDONLY | O_LARGEFILE) || die("Could not initialize fanotify: $!");
fanotify_mark($fd, FAN_MARK_ADD | FAN_MARK_MOUNT, FAN_OPEN_PERM, -1, $path) || die("Could not mark $path: $!\n");

for (my $i = 0; $i < 1000; $i++) {
	my @events = fanotify_read($fd);
	printf("loop count %d -- received %d events\n", $i, scalar(@events));

	foreach my $e (@events) {
		if (!$e->needsResponse()) {
			printf("Event does not require a response: $e\n");
		} elsif (($i % 7) == 0) {
			printf("Allowing this request (using allow()): $e\n");
			$e->allow();
		} elsif (($i % 7) == 1) {
			printf("Denying this request (using deny()): $e\n");
			$e->deny();
		} elsif (($i % 7) == 2) {
			printf("Allowing this request (using fanotify_write()): $e\n");
			fanotify_write($e, FAN_ALLOW);
		} elsif (($i % 7) == 3) {
			printf("Denying this request (using fanotify_write()): $e\n");
			fanotify_write($e, FAN_DENY);
		} elsif (($i % 7) == 4) {
			printf("Allowing this request (using _write): $e\n");
			# Please note that the _write object method is unsupported.
			$e->_write(FAN_ALLOW);
		} elsif (($i % 7) == 5) {
			printf("Denying this request (using _write): $e\n");
			# Please note that the _write object method is unsupported.
			$e->_write(FAN_DENY);
		} elsif (($i % 7) == 6) {
			printf("Ignoring this request, relying on default response: $e\n");
		}

		print("Next.\n");
	}
}

1;
