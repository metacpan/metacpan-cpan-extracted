use strict;
use vars qw($dat);

BEGIN {
	my $file = 'samples/IP2PROXY-IP-PROXYTYPE-COUNTRY-REGION-CITY-ISP.SAMPLE.BIN';
  if (-f $file) {
		$dat = $file;
  } else {
    print "1..0 # Error no IP2Proxy binary data file found\n";
    exit;
  }
}

use Test;

$^W = 1;

BEGIN { plan tests => 3 }

use Geo::IP2Proxy;

my $obj = Geo::IP2Proxy->open($dat);

while (<DATA>) {
  chomp;
  my ($ipaddr, $exp_country) = split("\t");
  my $country = $obj->getCountryShort($ipaddr);
  ok(uc($country), $exp_country);
}

__DATA__
0000:0000:0000:0000:0000:0000:0000:0000	-
2A04:0000:0000:0000:0000:0000:0000:0000	-
FFFF:0000:0000:0000:0000:0000:0000:0000	-
