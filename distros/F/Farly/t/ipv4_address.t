use strict;
use warnings;

use Test::Simple tests => 24;

use Farly::IPv4::Address;
use Farly::IPv4::Network;

my $ip1 = Farly::IPv4::Address->new("10.1.2.3");
my $ip2 = Farly::IPv4::Address->new("10.1.2.3");
my $ip3 = Farly::IPv4::Address->new("10.1.1.3");
my $ip4 = Farly::IPv4::Address->new("10.1.3.3");
my $ip5 = Farly::IPv4::Address->new("10.1.3.4");

ok ( $ip1->compare( $ip2 ) == 0, "compare equal");

ok ( $ip4->compare( $ip5 ) == -1, "compare less than");

ok ( $ip4->compare( $ip3 ) == 1, "compare greater than");

eval { my $ip6 = Farly::IPv4::Address->new("ip10.1.3.4"); };

ok ( $@ =~ /invalid address/, "invalid address");

eval { my $ip6 = Farly::IPv4::Address->new("10.1.3"); };

ok ( $@ =~ /invalid address/, "invalid address");

eval { my $ip6 = Farly::IPv4::Address->new("256.10.1.3"); };

ok ( $@ =~ /format wrapped in pack/, "invalid address");

ok( ref($ip1) eq "Farly::IPv4::Address", "IPv4Address new" );

ok( $ip1->as_string() eq "10.1.2.3", "as_string" );

ok( $ip1->equals($ip2), "equals ip" );

ok( !$ip1->equals($ip3), "! equals ip" );

ok( $ip1->gt($ip3), "gt IPv4Address" );

ok( !$ip1->gt($ip4), "! gt IPv4Address" );

ok( $ip1->lt($ip4), "lt IPv4Address" );

ok( !$ip1->lt($ip3), "! lt IPv4Address" );

ok( $ip4->adjacent($ip5), "adjacent IPv4Address" );

ok( !$ip1->adjacent($ip5), "! adjacent IPv4Address" );

ok( $ip5->adjacent($ip4), "adjacent IPv4Address" );

my @arr = $ip1->iter();

ok ( scalar(@arr) eq 1, "iter size IPv4Address" );

ok ( $arr[0]->as_string() eq "10.1.2.3 10.1.2.3", "iter contents IPv4Address" );

#IPNet tests
my $net1 = Farly::IPv4::Network->new("10.1.1.0 255.255.255.0");
my $net2 = Farly::IPv4::Network->new("10.1.2.0 255.255.255.0");
my $net3 = Farly::IPv4::Network->new("10.1.3.0 255.255.255.0");
my $net4 = Farly::IPv4::Network->new("10.1.2.3 255.255.255.255");

ok( ref($net1) eq "Farly::IPv4::Network", "IPv4Network new" );

ok( $ip1->equals($net4), "equals IPv4Network" );

ok( $net2->contains($ip1), "contains" );

ok( $net3->gt($ip1), "gt IPv4Network" );

ok( $net1->lt($ip1), "lt IPv4Network" );
