#!/usr/bin/perl

BEGIN {
	use Config;
	if ($Config{d_flock}) {
		print "1..0 # Skipped: flock() is supported on this platform\n";
		exit 0;
	}
}

use FindBin;
require "$FindBin::Bin/wrap.tm";

dirwrap(sub {
	require File::Flock::Forking;
	import File::Flock::Forking;
	require File::Flock;
	import File::Flock;
	require "$FindBin::Bin/flock.tt"
});

