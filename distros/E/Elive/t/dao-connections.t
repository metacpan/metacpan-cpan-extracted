#!perl -T
use warnings; use strict;
use Test::More tests => 42;
use Test::Warn;
use Scalar::Util;

package main;

use Elive::Connection;
use Elive::Entity::Group;

use Scalar::Util;
use lib '.';
use t::Elive::MockConnection;

use Carp; $SIG{__DIE__} = \&Carp::confess;
my $URL1 = 'http://test1.org';
my $URL2 = 'https://xxx:yyy@test2.org/test_instance';
my $URL2_soap = 'https://test2.org/test_instance';
my $URL2_restful = 'http://test2.org/test_instance';

my $K1 = '123456123456';
my $K2 = '112233445566';
my $K3 = '111222333444';

for my $class(qw{Elive::Connection t::Elive::MockConnection}) {

    # Check our normalizations. These paths should be equivalent
    # /test_instance, /test_instance/webservice.event, /test_instance/v2/webservice.event

    my $C1 = $class->_connect($URL1.'/');
    is($C1->url, $URL1, 'connection 1 - has expected url');

    my $C2 = $class->_connect($URL2.'/webservice.event');
    is($C2->url, $URL2_soap, 'connection 2 - has expected url');

    my $C2_dup = $class->_connect($URL2.'/v2/webservice.event');
    is($C2_dup->url, $URL2_soap, 'connection 2 dup - has expected url');

    isnt(Scalar::Util::refaddr($C2), Scalar::Util::refaddr($C2_dup),
       'distinct connections on common url => distinct objects');

    is($C2->url, $C2_dup->url,
       'distinct connections on common url => common url');

    my $group_c1 = Elive::Entity::Group->construct(
	{
	    groupId => $K1,
	    name => 'c1 group',
	    members => [$K2, $K3]
	},
	connection => $C1,
	);
    
    isa_ok($group_c1, 'Elive::Entity::Group', 'constructed ');
    is_deeply($group_c1->connection, $C1, 'group 1 associated with connection 1');

#
# Check for basic caching
#
    my $group_c1_from_cache
	= Elive::Entity::Group->retrieve($K1,connection => $C1, reuse => 1);
    
    is(Scalar::Util::refaddr($group_c1), Scalar::Util::refaddr($group_c1_from_cache),
       'basic cacheing on connection 1');
    
#
# Same as $group_c1, except for the connection
#
    my $group_c2 = Elive::Entity::Group->construct(
	{
	    groupId => $K1,
	    name => 'c2 group',
	    members => [$K3, $K2]
	},
    connection => $C2,
	);

    isa_ok($group_c2, 'Elive::Entity::Group', 'group');
    is_deeply($group_c2->connection, $C2, 'group 2 associated with connection 2');
    my $group2_url = $URL2_restful . "/Group/".$K1;
    is($group_c2->url, $group2_url, 'group 2 url');

    my $group_c2_from_cache
	= Elive::Entity::Group->retrieve($K1, connection => $C2, reuse => 1);
    
    is(Scalar::Util::refaddr($group_c2), Scalar::Util::refaddr($group_c2_from_cache),
    'basic cacheing on connection 1');

    isnt(Scalar::Util::refaddr($group_c1), Scalar::Util::refaddr($group_c2),
    'distinct caches maintained on connections with distinct urls');

    my $group_c2_dup_from_cache = Elive::Entity::Group->retrieve($K1, connection => $C2_dup, reuse => 1);

    is(Scalar::Util::refaddr($group_c2_dup_from_cache), Scalar::Util::refaddr($group_c2_from_cache),
    'connections with common urls share a common cache');

    is($group_c1->name, 'c1 group', 'connection 1 object - name as expected');
    is($group_c1->members->[1], $K3, 'connection 1 object - first member as expected');

    is($group_c2->name, 'c2 group', 'connection 2 object - name as expected');
    is($group_c2->members->[1], $K2, 'connection 2 object - first member as expected');
    
    is(substr($group_c1->url, 0, length($URL1)), $URL1, '1st connection: object url is based on connection url');
    is(substr($group_c2->url, 0, length($URL2_restful)), $URL2_restful, '2nd connection: object url is based on connection url');

    is(substr($group_c1->url, length($URL1)), substr($group_c2->url, length($URL2_restful)), 'common path between connections');
    
    $C1->disconnect;
    $C2->disconnect;
    $C2_dup->disconnect;
}
