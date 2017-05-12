use strict;
use warnings;
use Scalar::Util 'blessed';
use Test::Simple tests => 29;

use Farly::ASA::Parser;

my $parser = Farly::ASA::Parser->new();

ok( defined($parser), "constructor" );

my $string;
my $tree;
my $actual;
my $expected;

#
# hostname
#

$string = q{hostname test_fw};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'hostname' => 1,
	'STRING'   => 1
};

ok( equals( $expected, $actual ), "hostname" );

#
# name
#

$string = q{name 192.168.10.0 net1 description This is a test};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'REMARKS'      => 1,
	'named_ip'     => 1,
	'NAME_ID'      => 1,
	'name'         => 1,
	'name_comment' => 1,
	'IPADDRESS'    => 1
};

ok( equals( $expected, $actual ), "name" );

#
# interface nameif
#

$string = q{
interface Vlan2
 nameif outside
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'if_name'           => 1,
	'interface_options' => 2,
	'interface'         => 1,
	'STRING'            => 2
};

ok( equals( $expected, $actual ), "interface nameif" );

#
# interface ip
#

$string = q{
interface Vlan2
 ip address 10.2.19.8 255.255.255.248 standby 10.2.19.9
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'if_ip'             => 1,
	'if_mask'           => 1,
	'interface_options' => 2,
	'if_addr'           => 1,
	'interface'         => 1,
	'if_standby'        => 1,
	'MASK'              => 1,
	'IPADDRESS'         => 2,
	'STRING'            => 1
};

ok( equals( $expected, $actual ), "interface ip" );

#
# interface security-level
#

$string = q{
interface Vlan2
 security-level 0
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'DIGIT'             => 1,
	'sec_level'         => 1,
	'interface_options' => 2,
	'interface'         => 1,
	'STRING'            => 1
};

ok( equals( $expected, $actual ), "interface security-level" );

#
# object host
#

$string = q{
object network TestFW
 host 192.168.5.219
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'object'         => 1,
	'object_address' => 1,
	'STRING'         => 1,
	'OBJECT_ENTRY'    => 1,
	'object_id'      => 1,
	'OBJECT_TYPE'    => 1,
	'IPADDRESS'      => 1
};

ok( equals( $expected, $actual ), "object host" );

#
# object subnet
#

$string = q{
object network test_net1
 subnet 10.1.2.0 255.255.255.0
};

$tree = $parser->parse($string);

$actual = productions($tree);


$expected = {
	'object'         => 1,
	'IPNETWORK'      => 1,
	'object_address' => 1,
	'STRING'         => 1,
	'OBJECT_ENTRY'    => 1,
	'object_id'      => 1,
	'OBJECT_TYPE'    => 1
};

ok( equals( $expected, $actual ), "object subnet" );

#
# object range
#

$string = q{
object network test_net1_range
 range 10.1.2.13 10.1.2.28
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'IPRANGE'        => 1,
	'object'         => 1,
	'OBJECT_ENTRY'    => 1,
	'object_address' => 1,
	'object_id'      => 1,
	'OBJECT_TYPE'    => 1,
	'STRING'         => 1
};

ok( equals( $expected, $actual ), "object range" );

#
# object service src dst
#

$string = q{
object service web_https
 service tcp source gt 1024 destination eq 443
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'                 => 1,
	'object_service_protocol' => 1,
	'object'                  => 1,
	'port_gt'                 => 1,
	'object_service'          => 1,
	'PROTOCOL'                => 1,
	'PORT_ID'                 => 1,
	'port'                    => 2,
	'object_service_src'      => 1,
	'PORT_GT'                 => 1,
	'STRING'                  => 1,
	'OBJECT_ENTRY'             => 1,
	'object_service_dst'      => 1,
	'object_id'               => 1,
	'OBJECT_TYPE'             => 1
};

ok( equals( $expected, $actual ), "object service src dst" );

#
# object-group service src
#

$string = q{object-group service NFS
 service-object 6 source eq 2046
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'           => 1,
	'og_service_object' => 1,
	'PROTOCOL'          => 1,
	'og_so_protocol'    => 1,
	'PORT_ID'           => 1,
	'object_group'      => 1,
	'port'              => 1,
	'STRING'            => 1,
	'og_id'             => 1,
	'og_so_src_port'    => 1,
	'OBJECT_TYPE'       => 1,
	'og_object'         => 1,
	'GROUP_TYPE'        => 1
};

ok( equals( $expected, $actual ), "object-group service src" );

#
# object-group protocol
#

$string = q{
object-group protocol test65
 protocol-object tcp
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'og_id'              => 1,
	'OBJECT_TYPE'        => 1,
	'PROTOCOL'           => 1,
	'og_protocol_object' => 1,
	'og_object'          => 1,
	'object_group'       => 1,
	'GROUP_TYPE'         => 1,
	'STRING'             => 1
};

ok( equals( $expected, $actual ), "object-group protocol" );

#
# network-object named host
#
$string = q{
object-group network test_net
 network-object host server1
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'NAME'              => 1,
	'object_group'      => 1,
	'STRING'            => 1,
	'og_id'             => 1,
	'og_network_object' => 1,
	'OBJECT_TYPE'       => 1,
	'og_object'         => 1,
	'address'           => 1,
	'GROUP_TYPE'        => 1
};

ok( equals( $expected, $actual ), "network-object named host" );

#
# port-object
#

$string = q{
object-group service web tcp
 port-object eq www
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'        => 1,
	'PORT_ID'        => 1,
	'GROUP_PROTOCOL' => 1,
	'object_group'   => 1,
	'port'           => 1,
	'og_port_object' => 1,
	'STRING'         => 1,
	'og_protocol'    => 1,
	'og_id'          => 1,
	'OBJECT_TYPE'    => 1,
	'og_object'      => 1,
	'GROUP_TYPE'     => 1
};

ok( equals( $expected, $actual ), "port-object" );

#
# network group-object
#

$string = q{
object-group network test_net
 group-object server1
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'object_group'    => 1,
	'GROUP_REF'       => 1,
	'STRING'          => 1,
	'og_id'           => 1,
	'OBJECT_TYPE'     => 1,
	'og_group_object' => 1,
	'og_object'       => 1,
	'GROUP_TYPE'      => 1
};

ok( equals( $expected, $actual ), "network group-object" );

#
# object-group description
#

$string = q{
object-group network test_net
 description test network
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'REMARKS'        => 1,
	'og_id'          => 1,
	'OBJECT_TYPE'    => 1,
	'og_object'      => 1,
	'object_group'   => 1,
	'og_description' => 1,
	'GROUP_TYPE'     => 1,
	'STRING'         => 1
};

ok( equals( $expected, $actual ), "object-group description" );

#
# object-group service dst
#

$string = q{object-group service NFS
 service-object 6 destination eq 2046
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'           => 1,
	'og_service_object' => 1,
	'PROTOCOL'          => 1,
	'og_so_protocol'    => 1,
	'PORT_ID'           => 1,
	'object_group'      => 1,
	'port'              => 1,
	'og_so_dst_port'    => 1,
	'STRING'            => 1,
	'og_id'             => 1,
	'OBJECT_TYPE'       => 1,
	'og_object'         => 1,
	'GROUP_TYPE'        => 1
};

ok( equals( $expected, $actual ), "object-group service dst" );

#
# object-group service
#

$string = q{
object-group service www tcp
 group-object web
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'GROUP_PROTOCOL'  => 1,
	'object_group'    => 1,
	'GROUP_REF'       => 1,
	'STRING'          => 1,
	'og_protocol'     => 1,
	'og_id'           => 1,
	'OBJECT_TYPE'     => 1,
	'og_group_object' => 1,
	'og_object'       => 1,
	'GROUP_TYPE'      => 1
};

ok( equals( $expected, $actual ), "object-group service" );

#
# access-list 1
#

$string =
q{access-list acl-outside permit tcp OG_NETWORK customerX range 1024 65535 host server1 eq 80};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'      => 1,
	'PORT_RANGE'   => 1,
	'ACTIONS'      => 1,
	'PROTOCOL'     => 1,
	'acl_options'  => 1,
	'GROUP_REF'    => 1,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'address'      => 2,
	'port_range'   => 1,
	'NAME'         => 1,
	'acl_dst_ip'   => 1,
	'PORT_ID'      => 1,
	'port'         => 2,
	'acl_dst_port' => 1,
	'access_list'  => 1,
	'acl_src_ip'   => 1
};

ok( equals( $expected, $actual ), "access-list 1" );

#
# access-list 2
#

$string =
q{access-list acl-outside line 1 extended permit ip host server1 eq 1024 any eq 80};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'      => 2,
	'ACTIONS'      => 1,
	'PROTOCOL'     => 1,
	'ACL_TYPES'    => 1,
	'acl_options'  => 1,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'ANY'          => 1,
	'address'      => 2,
	'NAME'         => 1,
	'acl_dst_ip'   => 1,
	'PORT_ID'      => 2,
	'port'         => 2,
	'acl_dst_port' => 1,
	'DIGIT'        => 1,
	'acl_line'     => 1,
	'access_list'  => 1,
	'acl_src_ip'   => 1,
	'acl_type'     => 1
};

ok( equals( $expected, $actual ), "access-list 2" );

#
# access-list 3
#

$string =
q{access-list acl-outside permit tcp OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'      => 1,
	'ACTIONS'      => 1,
	'PROTOCOL'     => 1,
	'acl_options'  => 1,
	'GROUP_REF'    => 2,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'address'      => 2,
	'NAME'         => 1,
	'acl_dst_ip'   => 1,
	'PORT_ID'      => 1,
	'port'         => 2,
	'acl_dst_port' => 1,
	'access_list'  => 1,
	'acl_src_ip'   => 1
};

ok( equals( $expected, $actual ), "access-list 3" );

#
# access-list 4
#

$string =
q{access-list acl-outside permit OG_SERVICE srv2 OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'      => 1,
	'NAME'         => 1,
	'acl_dst_ip'   => 1,
	'ACTIONS'      => 1,
	'PORT_ID'      => 1,
	'port'         => 2,
	'acl_options'  => 1,
	'GROUP_REF'    => 3,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_dst_port' => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'access_list'  => 1,
	'address'      => 2,
	'acl_src_ip'   => 1
};

ok( equals( $expected, $actual ), "access-list 4" );

#
# access-list 5
#

$string =
  q{access-list acl-outside permit object citrix any OG_NETWORK citrix_servers};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'acl_dst_ip'   => 1,
	'ACTIONS'      => 1,
	'OBJECT_REF'   => 1,
	'GROUP_REF'    => 1,
	'acl_options'  => 1,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_protocol' => 1,
	'access_list'  => 1,
	'ANY'          => 1,
	'address'      => 2,
	'acl_src_ip'   => 1
};

ok( equals( $expected, $actual ), "access-list 5" );

#
# access-list 6
#

$string =
q{access-list acl-outside permit OG_SERVICE srv2 OG_NETWORK customerX OG_SERVICE high_ports net1 255.255.255.0 eq www};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'port_eq'      => 1,
	'NAMED_NET'    => 1,
	'acl_dst_ip'   => 1,
	'ACTIONS'      => 1,
	'PORT_ID'      => 1,
	'port'         => 2,
	'acl_options'  => 1,
	'GROUP_REF'    => 3,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_dst_port' => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'access_list'  => 1,
	'address'      => 2,
	'acl_src_ip'   => 1
};

ok( equals( $expected, $actual ), "access-list 6" );

#
# access-list 7
#

$string =
  q{access-list acl-outside permit ip any range 1024 65535 host server1 gt www};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'PORT_RANGE'   => 1,
	'ACTIONS'      => 1,
	'PROTOCOL'     => 1,
	'acl_options'  => 1,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'ANY'          => 1,
	'address'      => 2,
	'port_range'   => 1,
	'NAME'         => 1,
	'port_gt'      => 1,
	'acl_dst_ip'   => 1,
	'port'         => 2,
	'PORT_GT'      => 1,
	'acl_dst_port' => 1,
	'access_list'  => 1,
	'acl_src_ip'   => 1
};

ok( equals( $expected, $actual ), "access-list 7" );

#
# access-list 8
#

$string =
q{access-list acl-outside extended permit OG_PROTOCOL sip_transport OG_NETWORK voip_nets OG_SERVICE high_ports OG_NETWORK voip_srvs OG_SERVICE sip_ports};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'ACTIONS'      => 1,
	'ACL_TYPES'    => 1,
	'acl_options'  => 1,
	'GROUP_REF'    => 5,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'acl_src_port' => 1,
	'acl_protocol' => 1,
	'address'      => 2,
	'acl_dst_ip'   => 1,
	'port'         => 2,
	'acl_dst_port' => 1,
	'access_list'  => 1,
	'acl_src_ip'   => 1,
	'acl_type'     => 1
};

ok( equals( $expected, $actual ), "access-list 8" );

#
# access-list object service
#

$string =
q{access-list acl-outside line 1 extended permit object citrix object internal_net object citrix_net};

$tree   = $parser->parse($string);
$actual = productions($tree);

$expected = {
	'acl_dst_ip'   => 1,
	'ACTIONS'      => 1,
	'OBJECT_REF'   => 3,
	'ACL_TYPES'    => 1,
	'acl_options'  => 1,
	'STRING'       => 1,
	'acl_id'       => 1,
	'acl_action'   => 1,
	'DIGIT'        => 1,
	'acl_line'     => 1,
	'acl_protocol' => 1,
	'access_list'  => 1,
	'address'      => 2,
	'acl_src_ip'   => 1,
	'acl_type'     => 1
};

ok( equals( $expected, $actual ), "access-list object service" );

#
# access-list icmp-type
#

$string =
q{access-list acl-outside line 1 extended permit icmp any any OG_ICMP-TYPE safe-icmp};

$tree   = $parser->parse($string);
$actual = productions($tree);

$expected = {
	'ACTIONS'       => 1,
	'PROTOCOL'      => 1,
	'ACL_TYPES'     => 1,
	'GROUP_REF'     => 1,
	'acl_icmp_type' => 1,
	'acl_options'   => 1,
	'STRING'        => 1,
	'acl_id'        => 1,
	'acl_action'    => 1,
	'acl_protocol'  => 1,
	'ANY'           => 2,
	'address'       => 2,
	'acl_dst_ip'    => 1,
	'DIGIT'         => 1,
	'acl_dst_port'  => 1,
	'acl_line'      => 1,
	'access_list'   => 1,
	'acl_src_ip'    => 1,
	'acl_type'      => 1
};

ok( equals( $expected, $actual ), "access-list icmp-type" );

#
# access-group
#

$string = q{
access-group acl-outside in interface outside
};

$tree = $parser->parse($string);

$actual = productions($tree);

$expected = {
	'ag_interface'  => 1,
	'IF_REF'        => 1,
	'ACL_DIRECTION' => 1,
	'access_group'  => 1,
	'RULE_REF'      => 1,
	'ag_direction'  => 1,
	'ag_id'         => 1
};

ok(	equals( $expected, $actual ), "access-group" );

#
# Finished tests
#

sub productions {
	my ($node) = @_;

	my $result;

	# set s of explored vertices
	my %seen;

	#stack is all neighbors of s
	my @stack;
	push @stack, $node;

	while (@stack) {

		my $node = pop @stack;

		next if ( $seen{$node}++ );

		foreach my $key ( keys %$node ) {

			next if ( $key eq "EOL" );

			my $next = $node->{$key};

			if ( blessed($next) ) {

				$result->{ ref($next) }++;

				push @stack, $next;
			}
		}
	}

	return $result;
}

sub equals {
	my ( $hash1, $hash2 ) = @_;

	if ( scalar( keys %$hash1 ) != scalar( keys %$hash2 ) ) {
		return undef;
	}

	foreach my $key ( keys %$hash2 ) {
		if ( !defined( $hash1->{$key} ) ) {
			return undef;
		}
		if ( $hash1->{$key} ne $hash2->{$key} ) {
			return undef;
		}
	}
	return 1;
}
