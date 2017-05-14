#!/usr/bin/perl -w

use strict;
use warnings;

use Linux::Fanotify qw(:consts);
use Fcntl;	# Provides O_* constants required for fanotify_init

################################################################################

die("Need root\n") unless ($< == 0);

my $path = $ARGV[0];

if (!$path) {
	die("Usage: $0 <mount point>\n");
}

print <<EOF;


This script initializes fanotify and marks a mount point for monitoring
using the module's object oriented interface. For each event under that mount
point, you will be asked to allow, deny, or hold the operation. Please
note that the default response FAN_DENY is effective in this script, resulting
in a deny for cases where you answer "hold".

Monitoring mount point for path $path. Abort with ^C.
EOF

################################################################################

die("Need root\n") unless ($< == 0);

my $fagrp = new Linux::Fanotify::FanotifyGroup(FAN_CLOEXEC | FAN_CLASS_CONTENT, O_RDONLY | O_LARGEFILE) || die("Could not initialize fanotify: $!");
$fagrp->mark(FAN_MARK_ADD | FAN_MARK_MOUNT, FAN_OPEN_PERM | FAN_CLOSE_WRITE, -1, $path) || die("Could not mark $path: $!\n");

while (1) {
	my @events = $fagrp->read();
	printf("received %d events\n", scalar(@events));

	foreach my $e (@events) {
		printf("Got this request: " . $e . " -- proceed (y/n/h for yes/no/hold)? ");

		my $a = lc(<STDIN>);
		chomp($a);

		if (grep { $_ eq $a } qw(y j yes ja)) {
			$e->allow();
		} elsif (grep { $_ eq $a } qw(h hold)) {
			printf("Not answering this event request.\n");
		} else {
			$e->deny();
		}
	}
}

1;
