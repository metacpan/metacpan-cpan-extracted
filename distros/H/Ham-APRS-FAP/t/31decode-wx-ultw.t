
# an ultw wx packet decoding test
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 23 + 11 };
use Ham::APRS::FAP qw(parseaprs);

# first, the $ULTW format

my $aprspacket = 'WC4PEM-14>APN391,WIDE2-1,qAo,K2KZ-3:$ULTW0053002D028D02FA2813000D87BD000103E8015703430010000C';
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an ULTW wx packet");

ok($h{'wx'}->{'wind_direction'}, 64, "incorrect wind direction parsing");
ok($h{'wx'}->{'wind_speed'}, "0.3", "incorrect wind speed parsing");
ok($h{'wx'}->{'wind_gust'}, "2.3", "incorrect wind gust parsing");

ok($h{'wx'}->{'temp'}, "18.5", "incorrect temperature parsing");
ok($h{'wx'}->{'humidity'}, 100, "incorrect humidity parsing");
ok($h{'wx'}->{'pressure'}, "1025.9", "incorrect pressure parsing");

ok($h{'wx'}->{'rain_24h'}, undef, "incorrect rain_24h parsing");
ok($h{'wx'}->{'rain_1h'}, undef, "incorrect rain_1h parsing");
ok($h{'wx'}->{'rain_midnight'}, "4.1", "incorrect rain_midnight parsing");

ok($h{'wx'}->{'soft'}, undef, "incorrect wx software id");

# another, with a temperature below 0F

$aprspacket = 'SR3DGT>APN391,SQ2LYH-14,SR4DOS,WIDE2*,qAo,SR4NWO-1:$ULTW00000000FFEA0000296F000A9663000103E80016025D';
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an ULTW wx packet");

ok($h{'wx'}->{'wind_direction'}, 0, "incorrect wind direction parsing");
ok($h{'wx'}->{'wind_speed'}, undef, "incorrect wind speed parsing");
ok($h{'wx'}->{'wind_gust'}, "0.0", "incorrect wind gust parsing");

ok($h{'wx'}->{'temp'}, "-19.0", "incorrect temperature parsing");
ok($h{'wx'}->{'humidity'}, 100, "incorrect humidity parsing");
ok($h{'wx'}->{'pressure'}, "1060.7", "incorrect pressure parsing");

ok($h{'wx'}->{'rain_24h'}, undef, "incorrect rain_24h parsing");
ok($h{'wx'}->{'rain_1h'}, undef, "incorrect rain_1h parsing");
ok($h{'wx'}->{'rain_midnight'}, "0.0", "incorrect rain_midnight parsing");

ok($h{'wx'}->{'soft'}, undef, "incorrect wx software id");

# then, the !!... logging format

$aprspacket = 'MB7DS>APRS,TCPIP*,qAC,APRSUK2:!!00000066013D000028710166--------0158053201200210';
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 1, "failed to parse an ULTW wx packet");

ok($h{'wx'}->{'wind_direction'}, 144, "incorrect wind direction parsing");
ok($h{'wx'}->{'wind_speed'}, "14.7", "incorrect wind speed parsing");
ok($h{'wx'}->{'wind_gust'}, undef, "incorrect wind gust parsing");

ok($h{'wx'}->{'temp'}, "-0.2", "incorrect temperature parsing");
ok($h{'wx'}->{'temp_in'}, "2.1", "incorrect indoor temperature parsing");
ok($h{'wx'}->{'humidity'}, undef, "incorrect humidity parsing");
ok($h{'wx'}->{'pressure'}, "1035.3", "incorrect pressure parsing");

ok($h{'wx'}->{'rain_24h'}, undef, "incorrect rain_24h parsing");
ok($h{'wx'}->{'rain_1h'}, undef, "incorrect rain_1h parsing");
ok($h{'wx'}->{'rain_midnight'}, "73.2", "incorrect rain_midnight parsing");

ok($h{'wx'}->{'soft'}, undef, "incorrect wx software id");

