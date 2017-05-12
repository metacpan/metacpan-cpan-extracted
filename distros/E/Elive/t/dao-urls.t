#!perl -T
use warnings; use strict;
use Test::More tests => 4;
use Test::Warn;

package main;

use Elive::Connection;
use Elive::Entity::Group;
use Elive::Entity::ParticipantList;

use Scalar::Util;

my $URL1 = 'http://user:pass@test1.org';
my $URL1_no_auth = 'http://test1.org';

my $K1 = '1256168907389';
my $K2 = '112233445566';
my $K3 = '111222333444';
my $C1 = Elive::Connection->_connect($URL1);
my $C2 = Elive::Connection->_connect($URL1_no_auth);

is ($C1->url, $C2->url, 'credentials stripped from url');

Elive->connection($C1);

my $user_k1 =  Elive::Entity::User->construct(
    {userId => $K1,
     loginName => 'pete'},
    );

my $user_k2 =  Elive::Entity::User->construct(
    {userId => $K2,
     loginName => 'repeat'},
    );

is(substr($user_k1->url, 0, length($URL1_no_auth)), $URL1_no_auth, 'object url is based on connection url');

my $group_k1 = Elive::Entity::Group->construct(
    {
	groupId => $K1,
	name => 'test group',
	members => [$K2, $K3]
    },
    );

isnt($user_k1->url, $user_k2->url, 'distinct entities have distinct urls');
isnt($user_k1->url, $group_k1->url, 'urls distinct between entity classes');
