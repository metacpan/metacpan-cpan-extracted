
# APRS-IS path special cases
# Fri Sep 10 2010, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 3 };
use Ham::APRS::FAP qw(parseaprs);
use Data::Dumper;

my $aprspacket = "IQ3VQ>APD225,TCPIP*,qAI,IQ3VQ,THIRD,92E5A2B6,T2HUB1,200106F8020204020000000000000002,T2FINLAND:!4526.66NI01104.68E#PHG21306/- Lnx APRS Srv - sez. ARI VR EST";
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse a packet with an IPv6 address in the path");
ok($h{'digipeaters'}->[6]->{'call'}, '200106F8020204020000000000000002', "wrong IPv6 address parsed from qAI trace path");

$aprspacket = "IQ3VQ>APD225,200106F8020204020000000000000002,TCPIP*,qAI,IQ3VQ,THIRD,92E5A2B6,T2HUB1,200106F8020204020000000000000002,T2FINLAND:!4526.66NI01104.68E#PHG21306/- Lnx APRS Srv - sez. ARI VR EST";
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "managed to parse a packet with an IPv6 address in the path before qAI");

