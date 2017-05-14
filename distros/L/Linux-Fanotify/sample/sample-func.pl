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
This script initializes fanotify and marks a mount point for monitoring
using the module's functional interface. For each event under that mount
point, you will be asked to allow, deny, or hold the operation. Please
note that you will be able to break stuff with the hold operation, as
the default response is set to 0 here.

Monitoring mount point for path $path. Abort with ^C.
EOF

################################################################################

$Linux::Fanotify::default_response = 0;

my $fagrp = fanotify_init(FAN_CLOEXEC | FAN_CLASS_CONTENT, O_RDONLY | O_LARGEFILE) || die("Could not initialize fanotify: $!");
fanotify_mark($fagrp, FAN_MARK_ADD | FAN_MARK_MOUNT, FAN_OPEN_PERM | FAN_CLOSE_WRITE, -1, $path) || die("Could not mark $path: $!\n");

while (1) {
	my @events = fanotify_read($fagrp);
	printf("received %d events\n", scalar(@events));

	foreach my $e (@events) {
		printf("Got this request: " . $e);

		if ($e->needsResponse()) {
			print(" -- proceed (y/n/h for yes/no/hold)? ");

			my $a = lc(<STDIN>);
			chomp($a);

			if (grep { $_ eq $a } qw(y j yes ja)) {
				fanotify_write($e, FAN_ALLOW);
			} elsif (grep { $_ eq $a } qw(h hold)) {
				printf("Not answering this event request.\n");
			} else {
				fanotify_write($e, FAN_DENY);
			}
		} else {
			print(" (no response required)\n");
		}
	}
}

1;
