use strict;
use warnings;
use HTTP::ProxyAutoConfig;
use Test::More tests => 4;

# adapted from HTTP::ProxyPAC testing

# test via path
my $pac = HTTP::ProxyAutoConfig->new('t/proxy.pac');

my $got_proxy = $pac->FindProxy("http://www.google.com/");
is $got_proxy, 'DIRECT', "direct for Google";

$got_proxy = $pac->FindProxy("http://intra.example.com/");
is $got_proxy, 'PROXY google.com:80', "should be google 'proxy'";

$got_proxy = $pac->FindProxy("http://localhost/");
is $got_proxy, 'DIRECT', "localhost should be direct";

$got_proxy = $pac->FindProxy("http://192.168.108.3/");
is $got_proxy, 'PROXY yahoo.com:80', "192 IP ad should yield yahoo 'proxy'";
