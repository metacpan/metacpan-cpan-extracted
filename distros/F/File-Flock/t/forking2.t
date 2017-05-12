#!/usr/bin/perl

use FindBin;
require "$FindBin::Bin/wrap.tm";

dirwrap(sub {
	$ENV{FLOCK_FORKING_USE} = 'subprocess';
	require File::Flock::Forking;
	import File::Flock::Forking;
	require File::Flock;
	import File::Flock;
	require "$FindBin::Bin/flock2.tt"
});

