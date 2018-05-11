#!/usr/local/bin/perl
use strict;
use warnings;

use File::Fingerprint;
use YAML qw(Dump);

foreach my $file ( @ARGV )
	{
	my $print = File::Fingerprint->roll( $file );
	
	print Dump( $print ), "\n\n";
	
	}
