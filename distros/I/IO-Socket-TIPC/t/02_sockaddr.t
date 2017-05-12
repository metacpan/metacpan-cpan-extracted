use strict;
use warnings;
use IO::Socket::TIPC ':all';
use Test::More;
my $tests;
BEGIN { $tests = 0 };

eval "use Test::Exception;";
my $test_exception_loaded = defined($Test::Exception::VERSION);

## NAME
# basic
my $sockaddr = IO::Socket::TIPC::Sockaddr->new('{1,3}');
ok($sockaddr,                                  'simple name returned a value');
is(ref($sockaddr),'IO::Socket::TIPC::Sockaddr','blessed into the right class');
is($sockaddr->stringify(),   '{1, 3}',         'stringify gives me back the same name');
is($sockaddr->get_family(),  AF_TIPC,          'address family is right');
BEGIN { $tests += 4 };

# spaces don't matter in string names
$sockaddr = IO::Socket::TIPC::Sockaddr->new('{1, 3}');
ok($sockaddr,                                  'new() handles strings with spaces');
is($sockaddr->stringify(),   '{1, 3}',         'parse names which contain spaces');
BEGIN { $tests += 2 };

# editing an existing addr
$sockaddr->set_ntype(2);
$sockaddr->set_instance(4);
is($sockaddr->stringify(),   '{2, 4}',         'can change name fields (ntype)');
$sockaddr->set_type(5);
is($sockaddr->stringify(),   '{5, 4}',         'can change name fields (type)');
is($sockaddr->get_ntype(),   5,                'get_ntype works');
is($sockaddr->get_type(),    5,                'get_type works');
BEGIN { $tests += 4 };

# specify by pieces
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 4242, Instance => 100);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{4242, 100}',    'pieces parsed correctly');
is($sockaddr->get_type(),    4242,             'type is 4242');
is($sockaddr->get_instance(),100,              'instance is 100');
BEGIN { $tests += 4 };

# omit the AddrType
$sockaddr = IO::Socket::TIPC::Sockaddr->new(Type => 4242, Instance => 100);
ok($sockaddr,                                  'pieces were accepted without AddrType');
is($sockaddr->stringify(),   '{4242, 100}',    'parsed AddrType=name correctly');
is($sockaddr->get_addrtype(),TIPC_ADDR_NAME,   'guessed AddrType=name correctly');
BEGIN { $tests += 3 };

# also pass in a Scope and an integer literal Domain
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Scope => 3, Domain => 0x01001001);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_domain(),  0x01001001,       'domain is set properly');
is($sockaddr->get_scope(),   3,                'scope is set properly');
BEGIN { $tests += 4 };

# try a dotted-tri string Domain
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Domain => '<1.2.3>');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_domain(),  0x01002003,       'domain is set properly');
BEGIN { $tests += 3 };

# try a decimal string Domain
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Domain => '16785411');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_domain(),  0x01002003,       'domain is set properly');
BEGIN { $tests += 3 };

# try a hex string Domain
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Domain => '0x01002003');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_domain(),  0x01002003,       'domain is set properly');
BEGIN { $tests += 3 };

# try using a constant for the Scope
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Scope => TIPC_NODE_SCOPE);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_scope(),   TIPC_NODE_SCOPE,  'scope is set properly');
BEGIN { $tests += 3 };

# try using a string for the Scope
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Scope => 'node');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_scope(),   TIPC_NODE_SCOPE,  'scope is set properly');
BEGIN { $tests += 3 };

# try changing the domain on an existing sockaddr
$sockaddr->set_domain(0x04005006);
is($sockaddr->get_domain(),  0x04005006,       'can set domain (hex)');
$sockaddr->set_domain('<7.8.9>');
is($sockaddr->get_domain(),  0x07008009,       'can set domain (string)');
BEGIN { $tests += 2 };

# try the string Scopes
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Scope => 'zone');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_scope(),   TIPC_ZONE_SCOPE,  'scope is set properly');
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Scope => 'cluster');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_scope(),   TIPC_CLUSTER_SCOPE,'scope is set properly');
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 42420, Instance => 10, Scope => 'node');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{42420, 10}',    'pieces parsed correctly');
is($sockaddr->get_scope(),   TIPC_NODE_SCOPE,  'scope is set properly');
BEGIN { $tests += 9 };

SKIP: {
	skip 'need Test::Exception', 4 unless $test_exception_loaded;
	# catch forgetting to pass Type arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name',Instance => 100)
		}, qr/requires a Type value/,          'catches a forgotten Type argument');
	
	# catch the wrong AddrType
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Type => 4242, Instance => 100)
		}, qr/not valid for AddrType id/,      'catches an incorrect AddrType');
	
	# catch mistakenly passing in Upper arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 4242, Instance => 100, Upper => 1000)
		}, qr/Upper not valid for AddrType name/,'catches a mistaken Upper argument');
	
	# catch mistakenly passing in Nonexistent arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 4242, Instance => 100, Nonexistent => 1000)
		}, qr/unknown argument Nonexistent/,   'catches an erroneous Nonexistent argument');
}
BEGIN { $tests += 4 };

## NAMESEQ
# string
$sockaddr = IO::Socket::TIPC::Sockaddr->new('{1,3,3}');
ok($sockaddr,                                  'simple nameseq returned a value');
is(ref($sockaddr),'IO::Socket::TIPC::Sockaddr','blessed into the right class');
is($sockaddr->stringify(),   '{1, 3, 3}',      'stringify gives me back the same nameseq');
BEGIN { $tests += 3 };

# spaces don't matter in string names
$sockaddr = IO::Socket::TIPC::Sockaddr->new('{1, 3, 3}');
ok($sockaddr,                                  'returned a value even with a space in it');
is($sockaddr->stringify(),   '{1, 3, 3}',      'nameseq parsed right with a space in it');
BEGIN { $tests += 2 };

# try editing an existing address
$sockaddr->set_stype(4);
$sockaddr->set_lower(5);
$sockaddr->set_upper(6);
is($sockaddr->stringify(),   '{4, 5, 6}',      'can edit fields (stype)');
$sockaddr->set_type(7);
is($sockaddr->stringify(),   '{7, 5, 6}',      'can edit fields (type)');
is($sockaddr->get_stype(),   7,                'get_stype works');
is($sockaddr->get_type(),    7,                'get_type works');
BEGIN { $tests += 4 };

# specify by pieces
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'nameseq', Type => 4242, Lower => 99, Upper => 100);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{4242, 99, 100}','pieces parsed correctly');
is($sockaddr->get_type(),    4242,             'type is 4242');
is($sockaddr->get_lower(),   99,               'lower is 99');
is($sockaddr->get_upper(),   100,              'upper is 100');
BEGIN { $tests += 5 };

# omit the AddrType
$sockaddr = IO::Socket::TIPC::Sockaddr->new(Type => 4242, Lower => 99, Upper => 100);
ok($sockaddr,                                  'pieces were accepted without AddrType');
is($sockaddr->stringify(),   '{4242, 99, 100}','parsed AddrType=nameseq correctly');
is($sockaddr->get_addrtype(),TIPC_ADDR_NAMESEQ,'guessed AddrType=nameseq correctly');
BEGIN { $tests += 3 };

# omit the AddrType and Upper
$sockaddr = IO::Socket::TIPC::Sockaddr->new(Type => 4242, Lower => 99);
ok($sockaddr,                                  'pieces were accepted without AddrType, and without Upper');
is($sockaddr->stringify(),   '{4242, 99, 99}', 'parsed AddrType=nameseq correctly, Upper=Lower');
is($sockaddr->get_addrtype(),TIPC_ADDR_NAMESEQ,'guessed AddrType=nameseq correctly');
BEGIN { $tests += 3 };

# also pass in a Scope
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'nameseq', Type => 424, Lower => 101, Upper => 102, Scope => 3);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '{424, 101, 102}','pieces parsed correctly');
is($sockaddr->get_scope(),   3,                'scope is set properly');
BEGIN { $tests += 3 };

SKIP: {
	skip 'need Test::Exception', 4 unless $test_exception_loaded;
	# catch forgetting to pass Type arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'nameseq',Lower => 100)
		}, qr/requires a Type value/,          'catches a forgotten Type argument');
	
	# catch the wrong AddrType
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Type => 4242, Lower => 100)
		}, qr/not valid for AddrType name/,    'catches an incorrect AddrType');
	
	# catch mistakenly passing in Ref arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'nameseq', Type => 4242, Lower => 100, Ref => 1000)
		}, qr/Ref not valid for AddrType nameseq/, 'catches a mistaken Ref argument');
	
	# catch mistakenly passing in Nonexistent arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'nameseq', Type => 4242, Lower => 100, Nonexistent => 1000)
		}, qr/unknown argument Nonexistent/,   'catches an erroneous Nonexistent argument');
}
BEGIN { $tests += 4 };


## ID
# string
$sockaddr = IO::Socket::TIPC::Sockaddr->new('<1.2.3:4>');
ok($sockaddr,                                  'simple id returned a value');
is(ref($sockaddr),'IO::Socket::TIPC::Sockaddr','blessed into the right class');
is($sockaddr->stringify(),   '<1.2.3:4>',      'stringify gives me back the same id');
BEGIN { $tests += 3 };

# specify by pieces
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Zone => 1, Cluster => 2, Node => 3, Ref => 4);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '<1.2.3:4>',      'pieces parsed correctly');
is($sockaddr->get_zone(),    1,                'zone is 1');
is($sockaddr->get_cluster(), 2,                'cluster is 2');
is($sockaddr->get_node(),    3,                'node is 3');
is($sockaddr->get_ref(),     4,                'ref is 4');
BEGIN { $tests += 6 };

# specify node-address as a string
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Id => '<1.2.3>', Ref => 4);
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '<1.2.3:4>',      'pieces parsed correctly');
is($sockaddr->get_zone(),    1,                'zone is 1');
is($sockaddr->get_cluster(), 2,                'cluster is 2');
is($sockaddr->get_node(),    3,                'node is 3');
is($sockaddr->get_ref(),     4,                'ref is 4');
BEGIN { $tests += 6 };

# specify the whole thing as a string
$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Id => '<1.2.3:4>');
ok($sockaddr,                                  'pieces were accepted');
is($sockaddr->stringify(),   '<1.2.3:4>',      'pieces parsed correctly');
is($sockaddr->get_zone(),    1,                'zone is 1');
is($sockaddr->get_cluster(), 2,                'cluster is 2');
is($sockaddr->get_node(),    3,                'node is 3');
is($sockaddr->get_ref(),     4,                'ref is 4');
BEGIN { $tests += 6 };

# make sure changing things works
$sockaddr->set_zone   (5);
$sockaddr->set_cluster(6);
$sockaddr->set_node   (7);
$sockaddr->set_ref    (8);
is($sockaddr->stringify(),   '<5.6.7:8>',      'set_* pieces works');
$sockaddr->set_id("<1.2.3>");
is($sockaddr->stringify(),   '<1.2.3:8>',      'set_id (string) works');
$sockaddr->set_id(0x04005006);
is($sockaddr->stringify(),   '<4.5.6:8>',      'set_id (hex) works');
BEGIN { $tests += 3 };

# omit the AddrType
$sockaddr = IO::Socket::TIPC::Sockaddr->new(Id => '<1.2.3:4>');
ok($sockaddr,                                  'pieces were accepted without AddrType');
is($sockaddr->stringify(),   '<1.2.3:4>',      'parsed AddrType=id correctly');
is($sockaddr->get_addrtype(),TIPC_ADDR_ID,     'guessed AddrType=id correctly');
BEGIN { $tests += 3 };

# omit the AddrType and Ref
$sockaddr = IO::Socket::TIPC::Sockaddr->new(Id => '<1.2.3>');
ok($sockaddr,                                  'pieces were accepted without AddrType');
is($sockaddr->stringify(),   '<1.2.3:0>',      'Reference is 0 by default');
is($sockaddr->get_addrtype(),TIPC_ADDR_ID,     'guessed AddrType=id correctly');
BEGIN { $tests += 3 };

SKIP: {
	skip 'need Test::Exception', 4 unless $test_exception_loaded;
	# catch forgetting to pass Node arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Zone => 1, Cluster => 2, Ref => 4);
		}, qr/requires a Node value/,          'catches a forgotten Node argument');
	
	# catch the wrong AddrType
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'name', Zone => 1, Cluster => 2, Node => 3, Ref => 4);
		}, qr/not valid for AddrType name/,    'catches an incorrect AddrType');
	
	# catch mistakenly passing in Upper arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Zone => 1, Cluster => 2, Node => 3, Ref => 4, Upper => 1000);
		}, qr/Upper not valid for AddrType id/,'catches a mistaken Upper argument');
	
	# catch mistakenly passing in Nonexistent arg
	throws_ok( sub {
		$sockaddr = IO::Socket::TIPC::Sockaddr->new(AddrType => 'id', Zone => 1, Cluster => 2, Node => 3, Ref => 4, Nonexistent => 1000);
		}, qr/unknown argument Nonexistent/,   'catches an erroneous Nonexistent argument');
}
BEGIN { $tests += 4 };


# test the low-level accessor functions.
# make sure they've been exported properly...
SKIP: {
	skip 'need Test::Exception', 4 unless $test_exception_loaded;
	lives_ok(sub {tipc_addr   (1,2,3     ) }, "tipc_addr lives");
	lives_ok(sub {tipc_zone   (0x01002003) }, "tipc_zone lives");
	lives_ok(sub {tipc_cluster(0x01002003) }, "tipc_cluster lives");
	lives_ok(sub {tipc_node   (0x01002003) }, "tipc_node lives");
}
is(tipc_addr(1,2,3     ), 0x01002003, "tipc_addr (integer) works");
is(tipc_addr("<1.2.3>" ), 0x01002003, "tipc_addr (string) works");
is(tipc_zone(0x01002003), 1         , "tipc_zone (integer) works");
is(tipc_zone("<1.2.3>" ), 1         , "tipc_zone (string) works");
is(tipc_cluster(0x01002003), 2      , "tipc_cluster (integer) works");
is(tipc_cluster("<1.2.3>" ), 2      , "tipc_cluster (string) works");
is(tipc_node(0x01002003), 3         , "tipc_node (integer) works");
is(tipc_node("<1.2.3>" ), 3         , "tipc_node (string) works");
BEGIN { $tests += 12 };


BEGIN { plan tests => $tests };
