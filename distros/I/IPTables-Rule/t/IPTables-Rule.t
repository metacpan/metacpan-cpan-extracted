# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IPTables-Rule.t'

#########################

use strict;
use warnings;

use Test::More tests => 205;
BEGIN {
	use_ok('IPTables::Rule')
};

#########################

# variables to use in tests
my $good_fqdn = 'www.google.com';
my $good_ipv4_addr = '192.168.100.100';
my $good_ipv4_cidr = '192.168.100.100/24';
my $good_ipv6_short_addr = '2a01:4f8:140:6224::abcd';
my $good_ipv6_short_cidr = '2a01:4f8:140:6224::abcd/64';
my $good_ipv6_full_addr = '2a01:04f8:0140:6224:0000:0000:0000:abcd';
my $good_ipv6_full_cidr = '2a01:04f8:0140:6224:0000:0000:0000:abcd/64';
my $bad_fqdn = 'www.google.com/notafqdn';	# fqdn can not have a path
my $bad_ipv4_addr = '192.168.100.299';		# 299 is invalid nibble
my $bad_ipv4_cidr = '192.168.100.100/48';	# 48 is invalid cidr
my $bad_ipv6_short_addr = '2a01:4f8:140:6224::wxyz';		# wxyz are invalid hex chars
my $bad_ipv6_short_cidr = '2a01:4f8:140:6224::abcd/129';	# 129 is invalid cidr
my $bad_ipv6_full_addr = '2a01:04f8:0140:6224:0000:0000:0000:wxyz';		# wxyz are invalid hex chars
my $bad_ipv6_full_cidr = '2a01:04f8:0140:6224:0000:0000:0000:abcd/129';	# 129 is invalid cidr
my $good_numeric_port		= '80';
my $good_numeric_port_range	= '80:88';
my $good_multiport			= '80,443';
my $good_named_port			= 'http';
my $good_named_multiport	= 'http,https';
my $bad_numeric_port		= '100000';		# too high
my $bad_numeric_port_range	= '80:40';		# min > max
my $bad_multiport			= '80;443';		# semicolon not a valid separator
my $bad_named_port			= 'tcp#$';		# bad characters
my $bad_named_multiport		= 'http/https';	# slash not a valid separator
my $good_mac	= '1c:6f:65:4e:99:b0';
my $bad_mac1	= '1c:6f:65:4e:99:xx';		# xx invalid hex
my $bad_mac2	= '1c:6f:65:4e:99';			# too short
my $bad_mac3	= '1c:6f:65:4e:99:b0:ab';	# too long
my $good_comment1 = 'This is a comment';
my $good_comment2 = 'Comment 123';
my $good_comment3 = 'ACCEPT traffic from internet for SSH';
my $bad_comment1 = 'This comment has "quotes" in it';	# no quotes
my $bad_comment2 = 'A' x 257;	# too long
my $good_logprefix1 = 'DROPPED:';
my $good_logprefix2 = 'Script Kiddies bruteforcing';
my $good_logprefix3 = '[SSH Accept]';
my $bad_logprefix1 = 'This comment has "quotes" in it';	# no quotes
my $bad_logprefix2 = 'A' x 30;	# too long


# test 'ip4binary' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->ip4binary('/usr/sbin/iptables'), '/usr/sbin/iptables', 'valid ip4binary 1' );
	is( $ipt_rule->ip4binary('/sbin/iptables'),     '/sbin/iptables',     'valid ip4binary 2' );
	isnt( $ipt_rule->ip4binary('sbin/iptables'),    'sbin/iptables',      'invalid ip4binary: not absolute' );
}
# test 'ip6binary' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->ip6binary('/usr/sbin/ip6tables'),  '/usr/sbin/ip6tables',  'valid ip6binary 1' );
	is( $ipt_rule->ip6binary('/sbin/ip6tables'),      '/sbin/ip6tables',      'valid ip6binary 2' );
	isnt( $ipt_rule->ip6binary('sbin/ip6tables'),     'sbin/ip6tables',       'invalid ip6binary: not absolute' );
}

# test 'iptaction' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->iptaction('-A'),	'-A',	'iptaction: -A' );	# Append Rule
	is( $ipt_rule->iptaction('-D'),	'-D',	'iptaction: -D' );	# Delete Rule
	is( $ipt_rule->iptaction('-I'),	'-I',	'iptaction: -I' );	# Insert Rule
	is( $ipt_rule->iptaction('-R'),	'-R',	'iptaction: -R' );	# Replace Rule
	is( $ipt_rule->iptaction('-L'),	'-L',	'iptaction: -L' );	# List Rules
	is( $ipt_rule->iptaction('-S'),	'-S',	'iptaction: -S' );	# List Rules
	is( $ipt_rule->iptaction('-F'),	'-F',	'iptaction: -F' );	# Flush
	is( $ipt_rule->iptaction('-Z'),	'-Z',	'iptaction: -Z' );	# Zero Counters
	is( $ipt_rule->iptaction('-N'),	'-N',	'iptaction: -N' );	# New Chain
	is( $ipt_rule->iptaction('-X'),	'-X',	'iptaction: -X' );	# Delete Chain
	is( $ipt_rule->iptaction('-P'),	'-P',	'iptaction: -P' );	# Policy
	is( $ipt_rule->iptaction('-E'),	'-E',	'iptaction: -E' );	# Rename Chain
	isnt( $ipt_rule->iptaction('-Ax'),	'-Ax',	'iptaction: -Ax' );
	isnt( $ipt_rule->iptaction('-Q'),	'-Q',	'iptaction: -Q' );
}

# test 'ipversion' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->ipversion('4'),		'4',	'ipversion 4' );
	is( $ipt_rule->ipversion('6'),		'6',	'ipversion 6' );
	isnt( $ipt_rule->ipversion('x'),	'x',	'ipversion x' );
	isnt( $ipt_rule->ipversion('44'),	'44',	'ipversion 44' );
	isnt( $ipt_rule->ipversion('66'),	'66',	'ipversion 66' );
	isnt( $ipt_rule->ipversion('46'),	'46',	'ipversion 46' );
}

# test 'table' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	$ipt_rule->ipversion(4);
	is( $ipt_rule->table('filter'),	'filter',	'ip4 table filter' );
	is( $ipt_rule->table('nat'),	'nat',		'ip4 table filter' );
	is( $ipt_rule->table('mangle'),	'mangle',	'ip4 table filter' );
	is( $ipt_rule->table('raw'),	'raw',		'ip4 table filter' );
	$ipt_rule->ipversion(6);
	is( $ipt_rule->table('filter'),	'filter',	'ip6 table filter' );
	is( $ipt_rule->table('mangle'),	'mangle',	'ip6 table filter' );
	is( $ipt_rule->table('raw'),	'raw',		'ip6 table filter' );
}

# test 'chain' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->chain('INPUT'),	'INPUT',	'chain INPUT' );
	is( $ipt_rule->chain('FORWARD'),'FORWARD',	'chain FORWARD' );
	is( $ipt_rule->chain('OUTPUT'),	'OUTPUT',	'chain OUTPUT' );
}

# test 'target' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->target('ACCEPT'),	'ACCEPT',	'target ACCEPT' );
	is( $ipt_rule->target('DROP'),		'DROP',		'target DROP' );
	is( $ipt_rule->target('REJECT'),	'REJECT',	'target REJECT' );
	is( $ipt_rule->target('LOG'),		'LOG',		'target LOG' );
}

# test src address methods
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	# test valid arguments succeed
	is( $ipt_rule->src($good_fqdn),				$good_fqdn,				'src addr => valid FQDN' );
	is( $ipt_rule->src($good_ipv4_addr),		$good_ipv4_addr,		'src addr => valid IPv4' );
	is( $ipt_rule->src($good_ipv4_cidr),		$good_ipv4_cidr,		'src addr => valid IPv4+CIDR' );
	is( $ipt_rule->src($good_ipv6_short_addr),	$good_ipv6_short_addr,	'src addr => valid IPv6 shortened' );
	is( $ipt_rule->src($good_ipv6_short_cidr),	$good_ipv6_short_cidr,	'src addr => valid IPv6+CIDR shortened' );
	is( $ipt_rule->src($good_ipv6_full_addr),	$good_ipv6_full_addr,	'src addr => valid IPv6 full' );
	is( $ipt_rule->src($good_ipv6_full_cidr),	$good_ipv6_full_cidr,	'src addr => valid IPv6+CIDR full' );
	# test invalid arguments fail
	isnt( $ipt_rule->src($bad_fqdn),			$bad_fqdn,				'src addr => invalid FQDN' );
	isnt( $ipt_rule->src($bad_ipv4_addr),		$bad_ipv4_addr,			'src addr => invalid IPv4' );
	isnt( $ipt_rule->src($bad_ipv4_cidr),		$bad_ipv4_cidr,			'src addr => invalid IPv4+CIDR' );
	isnt( $ipt_rule->src($bad_ipv6_short_addr),	$bad_ipv6_short_addr,	'src addr => invalid IPv6 shortened' );
	isnt( $ipt_rule->src($bad_ipv6_short_cidr),	$bad_ipv6_short_cidr,	'src addr => invalid IPv6+CIDR shortened' );
	isnt( $ipt_rule->src($bad_ipv6_full_addr),	$bad_ipv6_full_addr,	'src addr => invalid IPv6 full' );
	isnt( $ipt_rule->src($bad_ipv6_full_cidr),	$bad_ipv6_full_cidr,	'src addr => invalid IPv6+CIDR full' );
	# test method aliases too
	is( $ipt_rule->source($good_fqdn),		$good_fqdn,		'src alias: source' );
}

# test dst address methods
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	# test valid arguments succeed
	is( $ipt_rule->dst($good_fqdn),				$good_fqdn,				'dst addr => valid FQDN' );
	is( $ipt_rule->dst($good_ipv4_addr),		$good_ipv4_addr,		'dst addr => valid IPv4' );
	is( $ipt_rule->dst($good_ipv4_cidr),		$good_ipv4_cidr,		'dst addr => valid IPv4+CIDR' );
	is( $ipt_rule->dst($good_ipv6_short_addr),	$good_ipv6_short_addr,	'dst addr => valid IPv6 shortened' );
	is( $ipt_rule->dst($good_ipv6_short_cidr),	$good_ipv6_short_cidr,	'dst addr => valid IPv6+CIDR shortened' );
	is( $ipt_rule->dst($good_ipv6_full_addr),	$good_ipv6_full_addr,	'dst addr => valid IPv6 full' );
	is( $ipt_rule->dst($good_ipv6_full_cidr),	$good_ipv6_full_cidr,	'dst addr => valid IPv6+CIDR full' );
	# test invalid arguments fail
	isnt( $ipt_rule->dst($bad_fqdn),			$bad_fqdn,				'dst addr => invalid FQDN' );
	isnt( $ipt_rule->dst($bad_ipv4_addr),		$bad_ipv4_addr,			'dst addr => invalid IPv4' );
	isnt( $ipt_rule->dst($bad_ipv4_cidr),		$bad_ipv4_cidr,			'dst addr => invalid IPv4+CIDR' );
	isnt( $ipt_rule->dst($bad_ipv6_short_addr),	$bad_ipv6_short_addr,	'dst addr => invalid IPv6 shortened' );
	isnt( $ipt_rule->dst($bad_ipv6_short_cidr),	$bad_ipv6_short_cidr,	'dst addr => invalid IPv6+CIDR shortened' );
	isnt( $ipt_rule->dst($bad_ipv6_full_addr),	$bad_ipv6_full_addr,	'dst addr => invalid IPv6 full' );
	isnt( $ipt_rule->dst($bad_ipv6_full_cidr),	$bad_ipv6_full_cidr,	'dst addr => invalid IPv6+CIDR full' );
	# test method aliases too
	is( $ipt_rule->dest($good_fqdn),		$good_fqdn,		'dst alias: dest' );
	is( $ipt_rule->destination($good_fqdn),	$good_fqdn,		'dst alias: destination' );
}

# test dst port methods
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->dpt($good_numeric_port),			$good_numeric_port,			'dst port => valid numeric port' );
	is( $ipt_rule->dpt($good_numeric_port_range),	$good_numeric_port_range,	'dst port => valid numeric port range' );
	is( $ipt_rule->dpt($good_multiport),			$good_multiport,			'dst port => valid numeric multiport' );
	is( $ipt_rule->dpt($good_named_port),			$good_named_port,			'dst port => valid named port' );
	is( $ipt_rule->dpt($good_named_multiport),		$good_named_multiport,		'dst port => valid named multiport' );
	#
	isnt( $ipt_rule->dpt($bad_numeric_port),		$bad_numeric_port,			'dst port => invalid numeric port' );
	isnt( $ipt_rule->dpt($bad_numeric_port_range),	$bad_numeric_port_range,	'dst port => invalid numeric port range' );
	isnt( $ipt_rule->dpt($bad_multiport),			$bad_multiport,				'dst port => invalid numeric multiport' );
	isnt( $ipt_rule->dpt($bad_named_port),			$bad_named_port,			'dst port => invalid named port' );
	isnt( $ipt_rule->dpt($bad_named_multiport),		$bad_named_multiport,		'dst port => invalid named multiport' );
	# test method aliases too
	is( $ipt_rule->port($good_numeric_port),		$good_numeric_port,			'dst port alias: port' );
	is( $ipt_rule->dport($good_numeric_port),		$good_numeric_port,			'dst port alias: dport' );
}

# test src port methods
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->spt($good_numeric_port),			$good_numeric_port,			'src port => valid numeric port' );
	is( $ipt_rule->spt($good_numeric_port_range),	$good_numeric_port_range,	'src port => valid numeric port range' );
	is( $ipt_rule->spt($good_multiport),			$good_multiport,			'src port => valid numeric multiport' );
	is( $ipt_rule->spt($good_named_port),			$good_named_port,			'src port => valid named port' );
	is( $ipt_rule->spt($good_named_multiport),		$good_named_multiport,		'src port => valid named multiport' );
	#
	isnt( $ipt_rule->spt($bad_numeric_port),		$bad_numeric_port,			'src port => invalid numeric port' );
	isnt( $ipt_rule->spt($bad_numeric_port_range),	$bad_numeric_port_range,	'src port => invalid numeric port range' );
	isnt( $ipt_rule->spt($bad_multiport),			$bad_multiport,				'src port => invalid numeric multiport' );
	isnt( $ipt_rule->spt($bad_named_port),			$bad_named_port,			'src port => invalid named port' );
	isnt( $ipt_rule->spt($bad_named_multiport),		$bad_named_multiport,		'src port => invalid named multiport' );
	# test method aliases too
	is( $ipt_rule->sport($good_numeric_port),		$good_numeric_port,			'src port alias: sport' );
}

# test 'protocol' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->proto('tcp'),	'tcp',	'proto; tcp' );
	is( $ipt_rule->proto('udp'),	'udp',	'proto; udp' );
	is( $ipt_rule->proto('icmp'),	'icmp',	'proto; icmp' );
	is( $ipt_rule->proto('47'),		'47',	'proto; numeric)' );
	# test method aliases too
	is( $ipt_rule->protocol('tcp'),	'tcp',	'proto alias: protocol' );
}

# test 'in' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->in('eth0'),		'eth0',		'in interface: eth0' );		# Normal
	is( $ipt_rule->in('eth11'),		'eth11',	'in interface: eth11' );	# Lots of eths
	is( $ipt_rule->in('tun0'),		'tun0',		'in interface: tun0' );		# TUN
	is( $ipt_rule->in('ppp200'),	'ppp200',	'in interface: ppp200' );	# PPP
	is( $ipt_rule->in('br0'),		'br0',		'in interface: br0' );		# Bridge
	is( $ipt_rule->in('eth0.11'),	'eth0.11',	'in interface: eth0.11' );	# VLAN
	is( $ipt_rule->in('xenNET'),	'xenNET',	'in interface: xenNET' );	# Custom Name
}

# test 'out' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->out('eth0'),		'eth0',		'in interface: eth0' );		# Normal
	is( $ipt_rule->out('eth11'),	'eth11',	'in interface: eth11' );	# Lots of eths
	is( $ipt_rule->out('tun0'),		'tun0',		'in interface: tun0' );		# TUN
	is( $ipt_rule->out('ppp200'),	'ppp200',	'in interface: ppp200' );	# PPP
	is( $ipt_rule->out('br0'),		'br0',		'in interface: br0' );		# Bridge
	is( $ipt_rule->out('eth0.11'),	'eth0.11',	'in interface: eth0.11' );	# VLAN
	is( $ipt_rule->out('xenNET'),	'xenNET',	'in interface: xenNET' );	# Custom Name
}

# test 'mac' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->mac($good_mac),		$good_mac,	'valid mac addr' );
	isnt( $ipt_rule->mac($bad_mac1),	$bad_mac1,	'invalid mac addr 1' );
	isnt( $ipt_rule->mac($bad_mac2),	$bad_mac2,	'invalid mac addr 2' );
	isnt( $ipt_rule->mac($bad_mac3),	$bad_mac3,	'invalid mac addr 3' );
}

# test 'state' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	# Note we test a mix of UPPER and lower case; it shouldn't matter to the method
	is( $ipt_rule->state('NEW'),          'NEW',          'state: new' );
	is( $ipt_rule->state('established'),  'established',  'state: established' );
	is( $ipt_rule->state('Related'),      'Related',      'state: related' );
	is( $ipt_rule->state('InVaLiD'),      'InVaLiD',      'state: invalid' );
	is( $ipt_rule->state('UNtracked'),    'UNtracked',    'state: untracked' );
	is( $ipt_rule->state('ESTABLISHED,RELATED'),'ESTABLISHED,RELATED',    'state: established or related' );
	is( $ipt_rule->state('new,ESTABLISHED'),    'new,ESTABLISHED',        'state: new or established');
	isnt( $ipt_rule->state('FOOBAR'),			      'FOOBAR',		        'invalid state' );
	isnt( $ipt_rule->state('HAPPY,FUN,BALLS'),	'HAPPY,FUN,BALLS',	'invalid state' );
	isnt( $ipt_rule->state('INVALID,FOOBAR'),	  'INVALID,FOOBAR',	  'invalid state' );
}

# test 'limit' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	# Note we test a mix of UPPER and lower case; it shouldn't matter to the method
	is( $ipt_rule->limit('1/s'),		'1/s',		'valid limit: 1/s' );
	is( $ipt_rule->limit('1/sec'),		'1/sec',	'valid limit: 1/sec' );
	is( $ipt_rule->limit('1/second'),	'1/second',	'valid limit: 1/second' );
	is( $ipt_rule->limit('2/M'),		'2/M',		'valid limit: 2/M' );
	is( $ipt_rule->limit('2/MIN'),		'2/MIN',	'valid limit: 2/MIN' );
	is( $ipt_rule->limit('2/MINUTE'),	'2/MINUTE',	'valid limit: 2/MINUTE' );
	is( $ipt_rule->limit('3/h'),		'3/h',		'valid limit: 3/h' );
	is( $ipt_rule->limit('3/hour'),		'3/hour',	'valid limit: 3/hour' );
	is( $ipt_rule->limit('4/d'),		'4/d',		'valid limit: 4/d' );
	is( $ipt_rule->limit('4/Day'),		'4/Day',	'valid limit: 4/Day' );
	isnt( $ipt_rule->limit('5/Y'),		'5/Y',		'invalid limit: 5/Y' );
	isnt( $ipt_rule->limit('5/year'),	'5/year',	'invalid limit: 5/year' );
	isnt( $ipt_rule->limit('five/sec'),	'five/sec',	'invalid limit: five/sec' );
	isnt( $ipt_rule->limit('6/86400'),	'6/86400',	'invalid limit: 6/86400' );
	isnt( $ipt_rule->limit('1 per sec'),'1 per sec','invalid limit: 1 per sec' );
	isnt( $ipt_rule->limit('notvalid'),	'notvalid',	'invalid limit: notvalid' );
	# test method aliases too
	is( $ipt_rule->rate_limit('1/s'),	'1/s',		'limit alias: rate_limit' );
}

# test 'icmp_type' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	$ipt_rule->ipversion('4');
	$ipt_rule->protocol('icmp');
	isnt( $ipt_rule->protocol('icmpv6'),				'icmpv6',					'ipver 4 != protocol icmpv6' );
	is( $ipt_rule->icmp_type('echo-request'),			'echo-request',				'icmp_type: named type' );
	is( $ipt_rule->icmp_type('redirect/host-redirect'),	'redirect/host-redirect',	'icmp_type: named type/subtype' );
	is( $ipt_rule->icmp_type('3'),						'3',						'icmp_type: numeric type' );
	is( $ipt_rule->icmp_type('3/1'),					'3/1',						'icmp_type: numeric type/subtype' );
	isnt( $ipt_rule->icmp_type('1/2/3'),				'1/2/3',					'icmp_type: invalid string' );

	$ipt_rule->ipversion('6');
	$ipt_rule->protocol('icmpv6');
	isnt( $ipt_rule->protocol('icmp'),					'icmp',						'ipver 6 != protocol icmp' );
	is( $ipt_rule->icmp_type('echo-request'),			'echo-request',				'icmpv6_type: named type' );
	is( $ipt_rule->icmp_type('redirect/host-redirect'),	'redirect/host-redirect',	'icmpv6_type: named type/subtype' );
	is( $ipt_rule->icmp_type('3'),						'3',						'icmpv6_type: numeric type' );
	is( $ipt_rule->icmp_type('3/1'),					'3/1',						'icmpv6_type: numeric type/subtype' );
	isnt( $ipt_rule->icmp_type('1/2/3'),				'1/2/3',					'icmpv6_type: invalid string' );
}

# test 'logprefix' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->logprefix($good_logprefix1),		$good_logprefix1,	'valid logprefix 1' );
	is( $ipt_rule->logprefix($good_logprefix2),		$good_logprefix2,	'valid logprefix 2' );
	is( $ipt_rule->logprefix($good_logprefix3),		$good_logprefix3,	'valid logprefix 3' );
	isnt( $ipt_rule->logprefix($bad_logprefix1),	$bad_logprefix1,	'invalid logprefix 1' );
	isnt( $ipt_rule->logprefix($bad_logprefix2),	$bad_logprefix2,	'invalid logprefix 2' );
}

# test 'comment' method
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	is( $ipt_rule->comment($good_comment1),		$good_comment1,	'valid comment 1' );
	is( $ipt_rule->comment($good_comment2),		$good_comment2,	'valid comment 2' );
	is( $ipt_rule->comment($good_comment3),		$good_comment3,	'valid comment 3' );
	isnt( $ipt_rule->comment($bad_comment1),	$bad_comment1,	'invalid comment 1' );
	isnt( $ipt_rule->comment($bad_comment2),	$bad_comment2,	'invalid comment 2' );
}

# test errstr
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	$ipt_rule->logprefix($bad_logprefix2);
	isnt( $ipt_rule->errstr,	undef,	'errstr' );
}

# test dump
{
	my $ipt_rule = new_ok( 'IPTables::Rule' );
	$ipt_rule->protocol('tcp');
	$ipt_rule->port('80');
	$ipt_rule->target('ACCEPT');
	my $dump_hash_ref = $ipt_rule->dump();
	is( $dump_hash_ref->{proto},	'tcp',		'dump() test: proto' );
	is( $dump_hash_ref->{dpt},		'80',		'dump() test: dpt' );
	is( $dump_hash_ref->{target},	'ACCEPT',	'dump() test: target' );
	is( $dump_hash_ref->{comment},	undef,		'dump() test: undefed' );
}

###############################################################################
# test some full rules
my $test_rule1 = 'iptables -t mangle -A cmn_SPOOF -i bond0.12 -m comment --comment "test rule 01" -j DROP';
my $test_rule2 = 'iptables -A FORWARD -i bond0 -o bond0.16 -m conntrack --ctstate NEW -j x_LEG_WLS';
my $test_rule3 = 'iptables -A tgt_SAMBA -p udp --dport 138 -m comment --comment "test rule 3" -j ACCEPT';
{
	my $rule1 = new_ok( 'IPTables::Rule' );
	$rule1->table('mangle');
	$rule1->chain('cmn_SPOOF');
	$rule1->target('DROP');
	$rule1->in('bond0.12');
	$rule1->comment('test rule 01');
	is( $rule1->generate, $test_rule1, 'test rule 1' );
	# test method aliases too
	is( $rule1->compile, $test_rule1, 'generate alias: compile' );
}
{
	my $rule2 = new_ok( 'IPTables::Rule' );
	$rule2->chain('FORWARD');
	$rule2->target('x_LEG_WLS');
	$rule2->in('bond0');
	$rule2->out('bond0.16');
	$rule2->state('NEW');
	is( $rule2->generate, $test_rule2, 'test rule 2' );
}
{
	my $rule3 = new_ok( 'IPTables::Rule' );
	$rule3->chain('tgt_SAMBA');
	$rule3->target('ACCEPT');
	$rule3->proto('udp');
	$rule3->dpt('138');
	$rule3->comment('test rule 3');
	is( $rule3->generate, $test_rule3, 'test rule 3' );
}
{
	my $rule4 = new_ok( 'IPTables::Rule' );
	$rule4->chain('INPUT');
	$rule4->target('ACCEPT');
	$rule4->ipversion(4);
	$rule4->src('fe80::20d:61ff:fec5:cebc/64');
	is( $rule4->generate, undef, 'test rule 4' );
}
{
	my $rule5 = new_ok( 'IPTables::Rule' );
	$rule5->chain('INPUT');
	$rule5->target('ACCEPT');
	$rule5->ipversion(6);
	$rule5->src('192.168.0.1');
	is( $rule5->generate, undef, 'test rule 5' );
}
