#!perl -T
use warnings; use strict;
use Test::More tests => 23;
use Test::Fatal;

use lib '.';
use t::Elive;

use Carp;
$SIG{__DIE__} = \&Carp::confess;

#
# Some rough tests that we can handle multiple connections.
# Look for evidence of 'crossed wires'. e.g. in the cache, entity
# updates or comparison functions.
# 

use Elive;
use Elive::Entity::Preload;

my $class = 'Elive::Entity::Preload' ;

SKIP: {

    my $Skip = 23;

    my %result = t::Elive->test_connection();
    my $auth = $result{auth};

    my %result_2 = t::Elive->test_connection(suffix => '_2');
    my $auth_2 = $result_2{auth};

    skip('$ELIVE_TEST_URL and ELIVE_TEST_URL_2 are the same!',
	 $Skip)
	if ($auth->[0] eq $auth_2->[0]);

    skip('$ELIVE_TEST_USER and ELIVE_TEST_USER_2 are the same!',
	 $Skip)
	if ($auth->[1] eq $auth_2->[1]);

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth);

    ok($connection, 'got first connection');
    isa_ok($connection, 'Elive::Connection','connection')
	or die "unable to get first connection";

    my $connection_class_2 = $result_2{class};
    my $connection_2 = $connection_class_2->connect(@$auth_2);

    ok($connection_2, 'got second connection');
    isa_ok($connection_2, 'Elive::Connection','connection')
	or die "unable to get second connection";

    isnt($connection->url, $connection_2->url, 'connections have distinct urls');
    ok(my $user = $connection->login, 'connection login');
    isa_ok($user, 'Elive::Entity::User','login');

    ok(my $user_2 = $connection_2->login, 'connection_2 login');
    isa_ok($user_2, 'Elive::Entity::User','login_2');

    isnt(Scalar::Util::refaddr($user), Scalar::Util::refaddr($user_2), 'users are distinct objects');

    is_deeply($user->connection, $connection, 'first entity/connection association');
    is_deeply($user_2->connection, $connection_2, 'second entity/connection association');

    #
    # LDAP login names may be case insensitive
    #
    is(uc($user->loginName), uc($auth->[1]), 'login name for first connection as expected');
    is(uc($user_2->loginName), uc($auth_2->[1]), 'login name for second connection as expected');

    ok(my $server_details = $connection->server_details, 'can get server details');
    die "unable to get server details - are all services running?"
	unless $server_details;
    isa_ok($server_details, 'Elive::Entity::ServerDetails','server_details');

    ok(!$user->is_changed, 'login not yet changed');

    my $userName_old = $user->loginName;
	
    my $userName_new = $userName_old.'x';
    $user->loginName($userName_new);

    is($user->loginName, $userName_new, 'login name changed enacted');
    ok($user->is_changed, 'user object showing as changed');

    ok(!$user_2->is_changed, 'user on second connection - not affected');

    $user->revert;
    ok(!$user->is_changed, 'user revert');

    is( exception {$connection->disconnect} => undef,
	     'disconnect first connection - lives');

    is( exception {$connection_2->disconnect} => undef,
	     'disconnect second connection - lives');
    
}

