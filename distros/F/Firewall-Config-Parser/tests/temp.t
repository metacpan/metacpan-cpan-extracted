#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Mojo::Util qw(dumper);

my $string = "ip route-static 0.0.0.0 0.0.0.0 10.1.1.1";

if (
  $string =~ /ip\s+route-static\s+(vpn-instance\s+(?<vpn>\S+)\s+)?(?<net>\S+)\s+(?<mask>\d+|\d+\.\d+\.\d+\.\d+)\s+
    ((?<dstint>[a-zA-Z]+\S+\d+)\s+)?(vpn-instance\s+(?<vpn1>\S+)\s*)?(?<nexthop>\d+\.\d+\.\d+\.\d+)?/oxi
  )
{

  say dumper $+{vpn}, $+{net}, $+{mask}, $+{dstint}, $+{vpn1}, $+{nexthop};

}
else {

  say "not match";
}

