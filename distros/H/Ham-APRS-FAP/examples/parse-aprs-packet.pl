#!/usr/bin/perl

use strict;
use Data::Dumper;
use Ham::APRS::FAP;

my $aprspacket = 'OH2RDP>BEACON,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220/RELAY,WIDE, OH2AP Jarvenpaa';

my %packet;
my $retval = Ham::APRS::FAP::parseaprs($aprspacket, \%packet);

if ($retval == 1) {
	# decoding ok, do something with the data
	print "Parsing succesful:\n";
	printf(
		"Position: latitude %.4f longitude %.4f\n",
		$packet{'latitude'}, $packet{'longitude'}
	) if (defined $packet{'latitude'});
	print "Comment: $packet{comment}\n" if defined $packet{'comment'};
	print "\n";
	print Dumper(\%packet);
} else {
	warn "Parsing failed: $packet{resultmsg} ($packet{resultcode})\n";
}

