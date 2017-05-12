# *-*-perl-*-*
use Test;
use strict;
$^W = 1;
use IP::Authority;
BEGIN { plan tests => 29 }

my $auth = IP::Authority->new();

while (<DATA>) {
    chomp;
    my ($ipaddr, $exp_auth) = split("\t");
    if ($exp_auth){
	ok($auth->inet_atoauth($ipaddr), $exp_auth);
    }
}

__DATA__
203.174.65.12	AP
212.208.74.140	RI
200.219.192.106	LA
134.102.101.18	RI
193.75.148.28	RI
134.102.101.18	RI
147.251.48.1	RI
194.244.83.2	RI
203.15.106.23	AP
196.31.1.1	AF
210.54.22.1	AP
210.25.5.5	AP
210.54.122.1	AP
210.25.15.5	AP
192.37.51.100	RI
192.37.150.150	RI
192.106.51.100	RI
192.106.150.150	RI
203.174.65.12	AP
212.208.74.140	RI
200.219.192.106	LA
134.102.101.18	RI
193.75.148.28	RI
134.102.101.18	RI
147.251.48.1	RI
194.244.83.2	RI
203.15.106.23	AP
196.31.1.1	AF
209.243.9.154	AR
