use strict;
use vars qw($dat);

BEGIN {
	my $file = 'samples/IPV6-COUNTRY.SAMPLE.BIN';
  if (-f $file) {
		$dat = $file;
  } else {
    print "1..0 # Error no IP2Location binary data file found\n";
    exit;
  }
}

use Test;

$^W = 1;

BEGIN { plan tests => 10 }

use Geo::IP2Location;

my $obj = Geo::IP2Location->open($dat);

while (<DATA>) {
  chomp;
  my ($ipaddr, $exp_country) = split("\t");
  my $country = $obj->get_country_short($ipaddr);
  ok(uc($country), $exp_country);
}

__DATA__
2A04:0000:0000:0000:0000:0000:0000:0000	DE
2A04:0040:0000:0000:0000:0000:0000:0000	AT
2A04:0080:0000:0000:0000:0000:0000:0000	PL
2A04:00C0:0000:0000:0000:0000:0000:0000	TR
2A04:0100:0000:0000:0000:0000:0000:0000	UA
2A04:0180:0000:0000:0000:0000:0000:0000	FR
2A04:0200:0000:0000:0000:0000:0000:0000	GB
2A04:0240:0000:0000:0000:0000:0000:0000	FI
2A04:02C0:0000:0000:0000:0000:0000:0000	RU
2A04:0340:0000:0000:0000:0000:0000:0000	CZ
