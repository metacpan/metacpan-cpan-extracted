#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

foreach ( 0 .. 3 ) {
	my $line = $_;
	last unless defined $line;
	print "$_ : $line \n";
}

1;

__END__
