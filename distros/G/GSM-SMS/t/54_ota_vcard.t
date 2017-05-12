use strict;
use Test::More tests => 2;

BEGIN {
	use_ok( 'GSM::SMS::OTA::VCard' );
}

my $correct = "424547494E3A56434152440A56455253494F4E3A322E310A4E3A56616E2064656E204272616E64652C4A6F68616E0A54454C3B505245463A2B33323437353136313631360A454E443A56434152440A";

my $stream = GSM::SMS::OTA::VCard::OTAVcard_makestream( "Van den Brande", "Johan", "+32475161616" );

is( $stream, $correct, "Compare makestream against correct value" );
