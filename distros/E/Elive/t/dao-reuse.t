#!perl -T
use warnings; use strict;
use Test::More tests => 14;
use Test::Warn;

use Elive::Connection;
use Elive::Entity::Group;
use Elive::Entity::ParticipantList;
use Elive::DAO;

use Scalar::Util;

use lib '.';
use t::Elive::MockConnection;

Elive->connection( t::Elive::MockConnection->connect() );

our $cache = Elive::DAO->live_entities;

do {
    my $group = Elive::Entity::Group->construct(
	{
	    groupId => 111111,
	    name => 'test group',
	    members => [
		123456, 112233
		]
	},
	);

    isa_ok($group, 'Elive::Entity::Group', 'group');
    is($group->members->[1], 112233, 'can access group members');

    my $user1 =  Elive::Entity::User->construct(
	{userId => 11111,
	 loginName => 'pete',
	 role => {roleId => 3},
	},
	);

    my $user1_again = Elive::Entity::User->retrieve(11111, reuse => 1);

    is(_ref($user1), _ref($user1_again), 'basic entity reuse');

    my $user1_copy =  Elive::Entity::User->construct(
	{userId => 11111,
	 loginName => 'repeat',
	 firstName => 'Pete',
	 role => {roleId => 3},
	},
	copy => 1,
	);

    isnt(_ref($user1), _ref($user1_copy), 'copy is distinct from original');
    ok(! $user1->_is_copy, '$obj->is_copy - false on original');
    ok( $user1_copy->_is_copy, '$obj->is_copy - true on copy');

    ok(! $user1->role->_is_copy && $user1_copy->role->_is_copy,
       'copy is applied recursively');

    $user1_copy->firstName( $user1_copy->firstName . 'r' );

    ok(! $user1->is_changed && $user1_copy->is_changed,
       'is_changed on copy object');

    $user1_copy->revert;

    ok(! $user1->is_changed && ! $user1_copy->is_changed,
       'is_changed on copy object - after revert');

    my $user2 =  Elive::Entity::User->construct(
	{userId => 22222,
	 loginName => 'pete'},
	);

    my $participant_list = Elive::Entity::ParticipantList->construct(
	{
	    meetingId => 9999,
	    participants => [
		{
		    user => {userId => 22222,
			     loginName => 'refetched',
		    },
		    role => {roleId => 2},
		},
		{
		    user => {userId => 33333,
			     loginName => 'test_user3',
		    },
		    role => {roleId => 3},
		}
		],
	},
    );

    my $user2_again = $participant_list->participants->[0]{user};

    is(_ref($user2), _ref($user2_again), 'object references unified');
    is( $user2_again->loginName, 'refetched', 'object accessor 1');
    is( $user2->loginName, 'refetched', 'object accessor 2');

    ok( (grep {$_} values %$cache), 'cache populated when objects are in scope');
};

#
# everything is now out of scope, their should be nothing left in the cache

ok(! (grep {$_} values %$cache), 'cached cleared when objects destroyed');
_dump_objs(); # should do nothing

########################################################################

sub _dump_objs {
    my $live_objects = Elive::Entity->live_entities;

    my $first;

    foreach (keys %$live_objects) {
	my $o = $live_objects->{$_};
	if ($o) {
	    diag "Elive Objects:\n" if $first++;
	    
	    diag "\t$_ = ".Scalar::Util::refaddr($o)
	}
    }
    print "\n";
}

sub _ref {
    return Scalar::Util::refaddr(shift);
}

