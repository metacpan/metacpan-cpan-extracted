use strict;
use warnings;

use Test::Simple tests => 26;

use Farly::IPv4::Address;
use Farly::IPv4::Network;

my $any = Farly::IPv4::Network->new("0.0.0.0 0.0.0.0");

my $net1 = Farly::IPv4::Network->new("10.20.31.254 255.255.255.0");
my $net2 = Farly::IPv4::Network->new("10.20.31.128 255.255.255.192");
my $net3 = Farly::IPv4::Network->new("10.20.30.0 255.255.255.0");
my $net4 = Farly::IPv4::Network->new("10.20.31.254 255.255.255.0");
my $net5 = Farly::IPv4::Network->new("10.20.31.0/28");

my $net11  = Farly::IPv4::Network->new("10.20.31.0 255.255.255.0");
my $net12 = Farly::IPv4::Network->new("10.20.31.0 255.255.255.128");
my $net13 = Farly::IPv4::Network->new("10.20.30.0 255.255.255.192");
my $net14  = Farly::IPv4::Network->new("10.20.31.0 255.255.255.0");
my $net15 = Farly::IPv4::Network->new("10.20.32.2 255.255.255.255");
my $net16 = Farly::IPv4::Network->new("10.20.32.2 255.255.255.255");
my $net17 = Farly::IPv4::Network->new("0.0.0.0 0.0.0.0");
my $net18  = Farly::IPv4::Network->new("10.20.31.0 0.0.0.127");

my $ip1 = Farly::IPv4::Address->new("10.20.30.254");
my $ip2   = Farly::IPv4::Address->new("10.20.31.254");
my $ip3   = Farly::IPv4::Address->new("10.20.30.2");
my $ip4   = Farly::IPv4::Address->new("10.20.32.2");
my $ip5   = Farly::IPv4::Address->new("10.20.32.3");


ok ( $any->network_address()->as_string() eq "0.0.0.0", "any network address");

ok ( $any->broadcast_address()->as_string() eq "255.255.255.255", "any broadcast address");

ok ( $net1->wc_mask()->as_string eq "0.0.0.255", "wc_mask 1");

ok ( $net2->wc_mask()->as_string eq "0.0.0.63", "wc_mask 2");

ok ( $net1->contains($net2) , "contains net 1");

ok ( $net11->contains($net12) , "contains net 2");

ok ( $net1->contains($ip2) , "contains ip");

ok ( ! $net1->contains($ip1) , "! contains ip");

ok ( ! $net1->contains($net3), "! contains net" );

ok ( $net1->equals($net4) , " equals net" );

ok ( ! $net11->equals($net12), " ! equals net" );

ok ( $net4->contains($net5), "contains net /bits");

ok ( !$net11->equals($ip2), "! net equals ip" );

ok ( $net15->equals($net16) , "/32 equals /32" );
ok ( $net15->equals($ip4) , "net/32 equals ip");

ok ( $net2->gt($net3), "net gt net");

ok ( $net13->lt($net14), "net lt net");

ok ( $net3->adjacent($net1), "adjacent net 1" );

ok ( $net1->adjacent($net3), "! adjacent net 2" );

ok ( ! $net5->adjacent($net15), "! adjacent net" );

ok ( $net15->adjacent($ip5), " adjacent ip");

ok ( $net18->as_string() eq "10.20.31.0 255.255.255.128", "wild card mask in");

ok( $net11->compare( $net12 ) == -1, "compare networks lt" );

ok( $net12->compare( $net11 ) == 1,"compare networks gt" );

ok( $net13->compare( $net3 ) == 1, "compare networks gt 2" );

ok( $net11->compare( $net14 ) == 0, "compare networks equal" );

