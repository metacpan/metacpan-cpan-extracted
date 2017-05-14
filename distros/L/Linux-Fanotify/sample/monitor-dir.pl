#!/usr/bin/perl -w

use strict;

use Linux::Fanotify qw(:consts);
use Fcntl;
use Cwd qw(abs_path);

################################################################################

die("Need root\n") unless ($< == 0);

my $path = $ARGV[0];

if (!$path || ! -d $path) {
	die("Usage: $0 <dir>\n");
}
$path = abs_path($path);

print <<EOF;
WARNING!

This script might NOT do what you expect!

fanotify_mark()ing a directory will NOT result in events for files or
subdirectories of the marked path (the FAN_EVENT_ON_CHILD flag can help only
a little here).

Consider marking mount paths instead of directories.

You will see output from this script when (e.g.) calling "ls" on the given
directory (or using functions such as opendir and closedir).

Monitoring path $path. Abort with ^C.
EOF

################################################################################

my $fanogrp = new Linux::Fanotify::FanotifyGroup(
	FAN_CLOEXEC | FAN_CLASS_CONTENT,
	O_RDONLY | O_LARGEFILE
) || die("Could not initialize fanotify: $!");

$fanogrp->mark(
	FAN_MARK_ADD | FAN_MARK_ONLYDIR, FAN_ACCESS | FAN_OPEN | FAN_CLOSE | FAN_ONDIR, -1, $path
) || die("Could not mark $path: $!\n");

while (1) {
	my @events = $fanogrp->read();
	foreach my $e (@events) {
		print("Received $e\n");
		if ($e->needsResponse()) {
			print("Allowing a request:\n$e\n");
			$e->allow();
		}
	}
}

