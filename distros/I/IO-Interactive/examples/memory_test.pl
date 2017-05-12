#!/usr/bin/perl

use IO::Interactive;

print "Testing memory consumption as process $$\n";

$SIG{INT} = sub { exit };

while( 1 )
	{
	print { interactive } 'a' x 4096;
	}