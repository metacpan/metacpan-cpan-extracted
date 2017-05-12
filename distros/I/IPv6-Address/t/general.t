use warnings;
use strict;
use Test::More qw(no_plan);

BEGIN {
	use_ok("IPv6::Address");
}

my %addresses =	(
	"2001:648:2000::/48" => "2001:648:2000::/48",
	"0:0:1:0:0:1:1:1/48" => "0:0:1::1:1:1/48",
	"::1/48" => "::1/48",
	"1::/48" => "1::/48",
	"0:0:1:1:0:0:1:1/48" => "0:0:1:1::1:1/48",
	"1:1:0:0:1:1:0:0/48" => "1:1:0:0:1:1::/48",
	"::/8" => "::/8",
	"1:1:0:0:1:1:0:0/48" => "1:1:0:0:1:1::/48",
	"0:0:1:1:1:1:0:0/48" => "0:0:1:1:1:1::/48",
);

for my $address_str (keys %addresses) {
	my $ipv6 = IPv6::Address->new($address_str);
	isa_ok($ipv6,"IPv6::Address");
	ok($ipv6 eq $addresses{$address_str},"stringify check");
	#print $ipv6->string," ",$addresses{$address_str},"\n";
}

my $ipv6 = IPv6::Address->new("2001:648:2000:de::210/64");

is( unpack("B128", $ipv6->get_mask_bitstr), ('1'x64).('0'x64), 'check mask bitstring');

is($ipv6->string(ipv4=>1,nocompress=>1),'2001:648:2000:de:0:0:0.0.2.16/64',"stringify without compression test");
is($ipv6->string(ipv4=>1),'2001:648:2000:de::0.0.2.16/64',"stringify with IPv4");
is($ipv6->string(nocompress=>1),'2001:648:2000:de:0:0:0:210/64',"stringify without compression");
is($ipv6->string(full=>1),'2001:0648:2000:00de:0000:0000:0000:0210/64',"stringify with full expansion");
is($ipv6->string,'2001:648:2000:de::210/64',"stringify plain vanilla");

is(IPv6::Address->new('::/64')->string(ipv4=>1),'::0.0.0.0/64','IPv4 compatible all zeros');

is($ipv6->first_address->to_string,'2001:648:2000:de::/64','first address');
is($ipv6->last_address->to_string,'2001:648:2000:de:ffff:ffff:ffff:ffff/64','first address');

#multicast test
my $m_ipv6 = IPv6::Address->new("FF02:0:0:0:0:0:0:6/10");
isa_ok($m_ipv6,"IPv6::Address");
ok($m_ipv6->is_multicast,"multicast check");
ok(!$ipv6->is_multicast,"multicast check 2");

ok(IPv6::Address->new("::/128")->is_unspecified,"unspecified address");
ok(IPv6::Address->new("::/8")->is_unspecified,"unspecified address 2");
ok(IPv6::Address->new("::1/128")->is_loopback,"loopback address");
ok(IPv6::Address->new("::1/8")->is_loopback,"loopback address 2");

my $prefix = IPv6::Address->new("2001:648:2001::/49");
isa_ok($prefix,'IPv6::Address');
is($prefix->enumerate_with_IPv4('147.102.136.25',0x00007fff)->string,'2001:648:2001:819::/64','Enumerate IPv6 address using an IPv4 number plus an arbitrary mask');

#IPv4Subnet tests

my $b1 = IPv4Subnet->new('147.102.136.0/21');
isa_ok($b1,'IPv4Subnet');
ok($b1->contains('147.102.136.0'),'147.102.136.0/21 contains 147.102.136.0');
ok($b1->contains('147.102.136.255'),'147.102.136.0/21 contains 147.102.136.255');
ok($b1->contains('147.102.137.0'),'147.102.136.0/21 contains 147.102.137.0');
ok($b1->contains('147.102.143.255'),'147.102.136.0/21 contains 147.102.143.255');
ok(!$b1->contains('147.102.144.0'),'147.102.136.0/21 does not contain 147.102.144.0');

my $b2 = IPv4Subnet->new('0.0.0.0/0');
isa_ok($b2,'IPv4Subnet');
is($b2->get_length,4294967296,'0.0.0.0/0 length is 2^32');
is($b2->get_start,0,'0.0.0.0/0 starts at 0');
is($b2->get_stop,4294967295,'0.0.0.0/0 ends at 4294967295');
ok($b2->contains('1.2.3.4'),'0.0.0.0/0 contains anything');
ok($b2->contains('0.0.0.0'),'0.0.0.0/0 contains anything');

my $b3 = IPv4Subnet->new('10.10.10.10/32');
isa_ok($b3,'IPv4Subnet');
is($b3->get_length,1,'$b3 length is 1');
is($b3->get_start,168430090,'10.10.10.10/32 starts at 168430090');
is($b3->get_stop,168430090,'10.10.10.10/32 stops at 168430090');

my $block1 = [ '147.102.136.0/21' ];
my $block2 = [ '10.0.0.0/24', '10.10.0.0/24' ];

is(IPv4Subnet::calculate_compound_offset('147.102.136.0',$block1),0);
is(IPv4Subnet::calculate_compound_offset('147.102.136.1',$block1),1);
is(IPv4Subnet::calculate_compound_offset('147.102.137.0',$block1),256);
is(IPv4Subnet::calculate_compound_offset('147.102.137.1',$block1),257);
is(IPv4Subnet::calculate_compound_offset('147.102.143.255',$block1),2047);


is(IPv4Subnet::calculate_compound_offset('10.0.0.0',$block2),0);
is(IPv4Subnet::calculate_compound_offset('10.0.0.1',$block2),1);
is(IPv4Subnet::calculate_compound_offset('10.0.0.255',$block2),255);
is(IPv4Subnet::calculate_compound_offset('10.10.0.0',$block2),256);
is(IPv4Subnet::calculate_compound_offset('10.10.0.255',$block2),511);

is(IPv4Subnet->new('0.0.0.0/24')->get_mask,'255.255.255.0','/24 netmask');
is(IPv4Subnet->new('0.0.0.0/32')->get_mask,'255.255.255.255','/32 netmask');
is(IPv4Subnet->new('0.0.0.0/16')->get_mask,'255.255.0.0','/16 netmask');
is(IPv4Subnet->new('0.0.0.0/30')->get_mask,'255.255.255.252','/30 netmask');
is(IPv4Subnet->new('0.0.0.0/0')->get_mask,'0.0.0.0','/0 netmask');
is(IPv4Subnet->new('0.0.0.0/1')->get_mask,'128.0.0.0','/1 netmask');

is(IPv4Subnet->new('0.0.0.0/24')->get_wildcard,'0.0.0.255','/24 wildcard');
is(IPv4Subnet->new('0.0.0.0/32')->get_wildcard,'0.0.0.0','/32 wildcard');
is(IPv4Subnet->new('0.0.0.0/16')->get_wildcard,'0.0.255.255','/16 wildcard');
is(IPv4Subnet->new('0.0.0.0/30')->get_wildcard,'0.0.0.3','/30 wildcard');
is(IPv4Subnet->new('0.0.0.0/0')->get_wildcard,'255.255.255.255','/0 wildcard');
is(IPv4Subnet->new('0.0.0.0/1')->get_wildcard,'127.255.255.255','/1 wildcard');

is(IPv4Subnet->new('10.20.30.40/24')->get_start_ip,'10.20.30.0','start IP of 10.20.30.40/24');
is(IPv4Subnet->new('10.20.30.40/24')->get_stop_ip,'10.20.30.255','stop IP of 10.20.30.40/24');
is(IPv4Subnet->new('10.20.30.40/32')->get_start_ip,'10.20.30.40','start IP of 10.20.30.40/24');
is(IPv4Subnet->new('10.20.30.40/32')->get_stop_ip,'10.20.30.40','stop IP of 10.20.30.40/24');
is(IPv4Subnet->new('10.20.30.40/0')->get_start_ip,'0.0.0.0','start IP of 10.20.30.40/24');
is(IPv4Subnet->new('10.20.30.40/0')->get_stop_ip,'255.255.255.255','stop IP of 10.20.30.40/24');
################

my $p1 = IPv6::Address->new('2001:648:2001::/48');
my $p2 = IPv6::Address->new('2001:648:2001::/49');
my $p3 = IPv6::Address->new('2001:648:2001:beef::/64');
my $p4 = IPv6::Address->new('2001:648:2001:be00::/56');
my $p5 = IPv6::Address->new('2001:648:2001:beef::/128');
isa_ok($p1,'IPv6::Address');
is($p1->enumerate_with_offset(0,64),'2001:648:2001::/64');
is($p2->enumerate_with_offset(0,64),'2001:648:2001::/64');
is($p1->enumerate_with_offset(15,64),'2001:648:2001:f::/64');
is($p2->enumerate_with_offset(255,64),'2001:648:2001:ff::/64');
is($p1->enumerate_with_offset(65535,64),'2001:648:2001:ffff::/64');
is($p2->enumerate_with_offset(4095,64),'2001:648:2001:fff::/64');

eval {
is($p2->enumerate_with_offset(65535,64),'2001:648:2001:ffff::/64');
};
ok($@,'enumerate with offset larger than the set bit length should fail');



is($p1->radius_string,'0x0030200106482001',"radius representation");
is($p2->radius_string,'0x003120010648200100',"radius representation");
is($p3->radius_string,'0x0040200106482001beef',"radius representation");



is($p1->enumerate_with_offset(0,63),'2001:648:2001::/63','enumerate with a /48 to produce a /63');
is($p1->enumerate_with_offset(0,62),'2001:648:2001::/62','enumerate with a /48 to produce a /63');

is($p2->enumerate_with_offset(0,63),'2001:648:2001::/63','enumerate with a /49 to produce a /63');
is($p2->enumerate_with_offset(0,62),'2001:648:2001::/62','enumerate with a /49 to produce a /63');




is($p1->enumerate_with_offset(10,63),'2001:648:2001:14::/63','enumerate with a /48 to produce a /63');
is($p1->enumerate_with_offset(10,62),'2001:648:2001:28::/62','enumerate with a /48 to produce a /62');
is($p1->enumerate_with_offset(10,61),'2001:648:2001:50::/61','enumerate with a /48 to produce a /61');
is($p1->enumerate_with_offset(10,60),'2001:648:2001:a0::/60','enumerate with a /48 to produce a /60');

is($p2->enumerate_with_offset(10,63),'2001:648:2001:14::/63','enumerate with a /49 to produce a /63');
is($p2->enumerate_with_offset(10,62),'2001:648:2001:28::/62','enumerate with a /49 to produce a /62');
is($p2->enumerate_with_offset(10,61),'2001:648:2001:50::/61','enumerate with a /49 to produce a /61');
is($p2->enumerate_with_offset(10,60),'2001:648:2001:a0::/60','enumerate with a /49 to produce a /60');


is(IPv6::Address->new('2001:648:2001::/48')->contains('2001:648:2001::/64'),1,'2001:648:2001::/48 contains 2001:648:2001::/64');
isnt(IPv6::Address->new('2001:648:2001::/48')->contains('2001:648:2002::/64'),1,'2001:648:2001::/48 does not contain 2001:648:2001::/64');
is(IPv6::Address->new('::/0')->contains('2001:648:2001::/64'),1,'::/0 contains 2001:648:2001::/64');
isnt(IPv6::Address->new('2001:648:2001::/64')->contains('2001:648:2001::/48'),1,'2001:648:2001::/64 does not contain 2001:648:2001::/48');
is(IPv6::Address->new('::/0')->contains('::/0'),1,'::/0 contains ::/0');
is(IPv6::Address->new('2001:648:2001::/48')->contains('2001:648:2001::/48'),1,'2001:648:2001::/48 contains 2001:648:2001::/48');
is(IPv6::Address->new('2001:648:2001:aaaa:bbbb:cccc:dddd:eeee/48')->contains('2001:648:2001::/48'),1,'2001:648:2001:aaaa:bbbb:cccc:dddd:eeee/48 contains 2001:648:2001::/48');
is(IPv6::Address->new('2001:648:2001::/48')->contains('2001:648:2001:aaaa:bbbb:cccc:dddd:eeee/48'),1,'2001:648:2001::/48 contains 2001:648:2001:aaaa:bbbb:cccc:dddd:eeee/48');
is(IPv6::Address->new('2001:648:2001::/48')->contains('2001:648:2001:aaaa:bbbb:cccc:dddd:eeee/128'),1,'2001:648:2001::/48 contains 2001:648:2001:aaaa:bbbb:cccc:dddd:eeee/128');

eval {
	is($p2->enumerate_with_offset(65535,64),'2001:648:2001:ffff::/64');
};
ok($@,'enumerate with offset larger than the set bit length should fail');


is($p1->radius_string,'0x0030200106482001',"radius representation");
is($p2->radius_string,'0x003120010648200100',"radius representation");
is($p3->radius_string,'0x0040200106482001beef',"radius representation");


eval { IPv6::Address->new('::/0')->increment(43847) } ;
like($@,qr/cannot offset/,'Trying to increment a /0 fails');

is($p1->increment(0),'2001:648:2001::/48', 'increment a /48 by 0');
is($p1->increment(1),'2001:648:2002::/48', 'increment a /48 by 1');
is($p1->increment(255),'2001:648:2100::/48', 'increment a /48 by 255');
is($p1->increment(65535),'2001:649:2000::/48', 'increment a /48 by 65535');
eval {
	is($p1->increment(4294967295),'2002:649:2000::/48', 'increment a /48 by 2^32-1')
};
like($@,qr/address part exceeded/,'Try to increment 2001:648:2001::/48 by 2^32-1 should fail');
is(IPv6::Address->new('2001::/48')->increment(4294967295),'2001:ffff:ffff::/48', 'increment a /48 by 2^32-1 should fail except some rare cases');

is($p4->increment(0),'2001:648:2001:be00::/56', 'increment a /56 by 0');
is($p4->increment(1),'2001:648:2001:bf00::/56', 'increment a /56 by 1');
is($p4->increment(255),'2001:648:2002:bd00::/56', 'increment a /56 by 255');
is($p4->increment(65535),'2001:648:2101:bd00::/56', 'increment a /56 by 65535');

is($p5->increment(0),'2001:648:2001:beef::/128', 'increment a /128 by 0');
is($p5->increment(1),'2001:648:2001:beef::1/128', 'increment a /128 by 1');
is($p5->increment(255),'2001:648:2001:beef::ff/128', 'increment a /128 by 255');
is($p5->increment(65535),'2001:648:2001:beef::ffff/128', 'increment a /128 by 65535');


ok( $p1->n_cmp($p2) == 0 , 'equality of prefixes with method');
ok( $p2->n_cmp($p4) < 0 , 'prefix smaller that another prefix with method');
ok( $p5->n_cmp($p4) > 0 , 'prefix bigger than another prefix with method');

ok( ( $p1 <=> $p2 ) == 0 , 'equality of prefixes with 3-way comparison operator');
ok( ( $p2 <=> $p4 ) < 0 , 'prefix smaller that another prefix with 3-way comparison operator');
ok( ( $p5 <=> $p4 ) > 0 , 'prefix bigger than another prefix with 3-way comparison operator');

ok(  $p1 == $p2  , 'equality of prefixes with normal operator');
ok( $p2 < $p4  , 'prefix smaller that another prefix with normal operator');
ok( $p5 > $p4 , 'prefix bigger than another prefix with normal operator');


my @a = IPv6::Address::n_sort( $p1, $p2, $p3, $p4, $p5 );
ok( ( $a[0] == $p1 ) && ( $a[1] == $p2 ) && ( $a[2] == $p4 ) && ( $a[3] == $p3 ) && ( $a[4] == $p5 ) , 'sort array of prefixes');

#reminder
#my $p1 = IPv6::Address->new('2001:648:2001::/48');
#my $p2 = IPv6::Address->new('2001:648:2001::/49');
#my $p3 = IPv6::Address->new('2001:648:2001:beef::/64');
#my $p4 = IPv6::Address->new('2001:648:2001:be00::/56');
#my $p5 = IPv6::Address->new('2001:648:2001:beef::/128');
my $alt = IPv4Subnet->new_from_start_stop('147.102.0.0','147.102.255.255');
my $str = $alt->to_string;
ok( $str eq '147.102.0.0/16', 'new from start/stop seems to be working');

my @aaa = IPv4Subnet->new('147.102.1.0/24')->enumerate;

ok( @aaa == 256, 'enumerate returns correct number of items' );

is( $aaa[0],'147.102.1.0' , 'first item of enumeration is correct' );
is( $aaa[9],'147.102.1.9' , 'item of enumeration is correct' );
is( $aaa[255],'147.102.1.255' , 'last item of enumeration is correct' );
