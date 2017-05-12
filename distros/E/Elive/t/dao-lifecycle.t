#!perl -T
use warnings; use strict;
use Test::More tests => 5;
use Test::Warn;

package main;

use Elive;
use Elive::Connection;
use Elive::Entity;
use Elive::Entity::User;

use Scalar::Util;

use lib '.';
use t::Elive::MockConnection;

my $meta_data_tab = \%Elive::DAO::_Base::Meta_Data;

my $URL1 = 'http://test1.org';

my $USER = 'test_user';

my $K1 = 123456123456;
my $C1 = t::Elive::MockConnection->connect($URL1, $USER);

Elive->connection($C1);

my $user =  Elive::Entity::User->construct(
    {userId => $K1,
     loginName => 'pete'},
    );

my $url = $user->url;
my $is_live = defined(Elive::Entity->live_entity($url));
ok($is_live, 'entity is live');

#
# NB _refaddr uses Scalar::Util::refaddr - doesn't count as a reference.
#
my $refaddr = $user->_refaddr;;

ok(defined($meta_data_tab->{$refaddr}), 'entity has metadata');

#
# right, lets get rid of the object
#

$user = undef;

ok($refaddr, 'object destroyed => refaddr still valid');

my $is_dead = !(Elive::Entity->live_entity($url));
ok($is_dead, 'object destroyed => entity is dead');
ok(!defined($meta_data_tab->{$refaddr}), 'object destroyed => entity metadata purged');

