use strict;
use vars qw($dat);

BEGIN {
  foreach my $file ("GeoIP.dat",'/usr/local/share/GeoIP/GeoIP.dat') {
    if (-f $file) {
      $dat = $file;
      last;
    }
  }
  unless ($dat) {
    print "1..0 # skip No GeoIP.dat found\n";
    exit 0;
  }
  # CPAN testers lack DNS services sometimes
  if ( $ENV{AUTOMATED_TESTING} ){
    print "1..0 # skip cpantesters b/c DNS Service is often not avail";
    exit 0;
  }
}

use Test;

$^W = 1;

BEGIN { plan tests => 12 }

use Geo::IP::PurePerl;

my $gi = Geo::IP::PurePerl->new($dat);

while (<DATA>) {
  chomp;
  my ($host, $exp_country) = split("\t");
  my $country = $gi->country_code_by_name($host);
  ok($country, $exp_country);
}

__DATA__
203.174.65.12	JP
212.208.74.140	FR
200.219.192.106	BR
134.102.101.18	DE
193.75.148.28	BE
134.102.101.18	DE
147.251.48.1	CZ
194.244.83.2	IT
203.15.106.23	AU
196.31.1.1	ZA
yahoo.com	US
www.gov.ru	RU
