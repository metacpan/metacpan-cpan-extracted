#!/usr/bin/env perl -w

# Check that the timezone for Amsterdam is correct.  Expecting to
# get 'Europe/Amsterdam'.

use strict;
use Test;
BEGIN { plan tests => 3 }

# Use the module.
use Geo::Location::TimeZone;

my %lookups = (	"1" =>	{	"z",	"Europe/Amsterdam",
				"lat",	"52.356",
				"lon",	"4.891",
			},
		"2" => {	"z",	"Europe/Riga",
				"lat",	"56.950100",
				"lon",  "24.114150",
			},
		"3" => {	"z",	"Australia/Perth",
				"lat",	"-31.9",
				"lon",  "115.8",
			},
		);


# Check that the object can be created.
my $gobj = Geo::Location::TimeZone->new();
if( defined( $gobj ) ){
	foreach my $rkey( keys %lookups ){
		my $tz = $gobj->lookup( lat => $lookups{"$rkey"}{"lat"}, lon => $lookups{"$rkey"}{"lon"} );
		if( $tz eq $lookups{"$rkey"}{"z"} ){
			ok(1);
		}else{
			ok(0);
			print "# Got back $tz for timezone.  Expected " . $lookups{"$rkey"}{"z"} . " X\n";
		}
	}
}else{
	ok( 0 );
}
exit;
__END__
