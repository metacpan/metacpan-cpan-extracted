use strict;
use vars qw($dat);

BEGIN {
	my $file = 'samples/IP-COUNTRY.SAMPLE.BIN';
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
19.5.10.1	US
25.5.10.2	GB
43.5.10.3	JP
47.5.10.4	CA
51.5.10.5	DE
53.5.10.6	DE
80.5.10.7	GB
81.5.10.8	IL
83.5.10.9	PL
85.5.10.0	CH
