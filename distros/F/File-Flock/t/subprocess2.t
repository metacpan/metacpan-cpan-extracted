#!/usr/bin/perl

use FindBin;
require "$FindBin::Bin/wrap.tm";

dirwrap(sub {
	require File::Flock::Subprocess;
	import File::Flock::Subprocess;
	require "$FindBin::Bin/flock2.tt"
});

