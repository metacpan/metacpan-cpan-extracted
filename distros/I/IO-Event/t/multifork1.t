#!/usr/bin/perl -I.

eval { require Event; };
if ($@) {
	print "1..0 # Skip Event not installed\n";
	exit 0;
}
use FindBin;
require "$FindBin::Bin/multifork.tt";
