#!/usr/bin/perl

BEGIN {
	use Config;
	if (!$Config{d_flock}) {
		print "1..0 # Skipped: flock() not supported on this platform, use File::Flock::Forking to workaround\n";
		exit 0;
	}
}

use FindBin;
require "$FindBin::Bin/wrap.tm";

dirwrap(sub {
	require File::Flock;
	import File::Flock;
	require "$FindBin::Bin/flock2.tt";
});
