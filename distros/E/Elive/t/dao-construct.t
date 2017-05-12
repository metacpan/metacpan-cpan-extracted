#!perl -T
use warnings; use strict;
use Test::More tests => 87;
use Test::Warn;

use Carp;
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::confess;

use Elive::Connection;
use Elive::Entity::ParticipantList;
use Elive::Entity::Group;
use Elive::Entity::Meeting;
use Elive::Entity::User;

use lib '.';
use t::Elive::MockConnection;

Elive->connection( t::Elive::MockConnection->connect() );

my $participant_list = Elive::Entity::ParticipantList->construct(
    {
	meetingId => 123456,
	participants => [
	    { # [0]
		user => {userId => 112233,
			 loginName => 'test_user',
		},
		role => {roleId => 2},
	    },
	    { # [1]
		user => {userId => 223344,
			 loginName => 'test_user2',
		},
		role => {roleId => 3}, # sans coercement
	    },
	    { # [2] user
		user => {userId => 'dave',
			 loginName => 'test_user3',
		},
		role => 3,             # with coercement
	    },
	    { # [3]  group
		group => {
		    groupId => 'test_group',
		    name => 'test Group',
		    members => [qw(888888 999999)],
		},
		role => 2,
	    },
	    { # [4] invited guest
		guest => {
		    loginName => 'alice@acme.com',
		    displayName => 'Alice',
		},
		role => 3,
	    },
	    { # [5] user - shorter form
		user => 'bob',
		role => 3,
	    },
	    ],
    },
    );

isa_ok($participant_list, 'Elive::Entity::ParticipantList', 'participant');
is($participant_list->stringify, "123456", 'participant list stringifies to meeting id');

is_deeply($participant_list->participants->[2], {
                type => 0,
    		user => {userId => 'dave',
			 loginName => 'test_user3',
		},
		role => {roleId => 3},,
	  }, "construction/coercement sanity");

is_deeply($participant_list->participants->[5], {
                type => 0,
    		user => {userId => 'bob',
		},
		role => {roleId => 3},,
	  }, "construction/coercement sanity");

$participant_list->participants->[2]->role(2);

is_deeply($participant_list->participants->[2]->role, {roleId => 2},
	  "set/get sanity");

$participant_list->participants->[2]->role(3);
is_deeply($participant_list->participants->[2]->role, {roleId => 3},
	  "revert sanity");

can_ok($participant_list, 'meetingId');
can_ok($participant_list, 'participants');

my $participants = $participant_list->participants;
isa_ok($participants, 'Elive::Entity::Participants');
is(scalar @$participants, 6, 'all participants constructed');

isa_ok($participants->[0], 'Elive::Entity::Participant');
is(Elive::Entity::Participants->stringify( [$participants->[0]] ),
   '112233=2', 'one element array stringification');
is(Elive::Entity::Participants->stringify( $participants->[0] ),
   '112233=2', 'one element scalar stringification');

$participants->add({
    type => 0,
    user => {userId => 'late_comer',
	     loginName => 'late_comer',
	 },
    role => {roleId => 3},
});

is(scalar @$participants, 7, 'participants added');
isa_ok($participants->[-1], 'Elive::Entity::Participant');
is($participants->[-1]->user->userId, 'late_comer', 'added participant value');

$participant_list->revert;

is($participants->[0]->user->stringify, '112233', 'user stringified');

is($participants->[0]->role->stringify, '2', 'role stringified');

is($participants->[0]->stringify, '112233=2', 'user participant stringified');
is($participants->[0]->participant->stringify, '112233', 'user stringified (user)');
ok($participants->[0]->is_moderator, 'is_moderator() on moderator');

is($participants->[2]->stringify, 'dave=3', 'user participant stringified');
ok(! $participants->[2]->is_moderator, 'is_moderator() on regular participant');

is($participants->[3]->stringify, '*test_group=2', 'group participant stringified');
is($participants->[3]->participant->stringify, '*test_group', 'group stringified');
is($participants->[4]->stringify, 'Alice (alice@acme.com)', 'guest participant stringified');
is($participants->[4]->participant->stringify, 'Alice (alice@acme.com)', 'guest stringified');

# upgrade/downgrade tests on moderator privileges

ok( $participants->[2]->is_moderator(1), 'is_moderator() upgrade');
is($participants->[2]->stringify, 'dave=2', 'upgraded participant stringified');

ok(!  $participants->[2]->is_moderator(0), 'is_moderator() downgrade');
is($participants->[2]->stringify, 'dave=3', 'downgraded participant stringified');

is($participants->stringify, '*test_group=2;112233=2;223344=3;Alice (alice@acme.com);bob=3;dave=3;late_comer=3',
   'participants stringification');

is($participant_list->participants->[0]->user->loginName, 'test_user',
   'participant dereference');

#
# test preformatted participant list
#
my $participant_list_2 = Elive::Entity::ParticipantList->construct(
    {
	meetingId => 234567,
	participants => '1111;2222=2;alice=3;Robert(bob@test.org);*the_team'
    });

my $participants_2 = $participant_list_2->participants;
is(scalar @$participants_2, 5, 'Participant count as expected');

do {
    my ($_guests,$_moderators,$_participants) = $participants_2->tidied;
    is_deeply($_guests, ['Robert (bob@test.org)'], '...tidied guests');
    is_deeply($_moderators, ['2222'], '...tidied moderators');
    is_deeply($_participants, ['*the_team', '1111', 'alice'], '...tidied participants');
};

do {
    my $user_participant = $participants_2->[0];

    ok( ! $user_participant->type, "participant type (user)");
    ok(     $user_participant->user
       && ! $user_participant->group
       && ! $user_participant->guest, "participant user/group/guest (user)");

    is($user_participant->user->userId, 1111, 'participant list user[0]');
    is($user_participant->role->roleId, 3, 'participant list role[0] (defaulted)');
};

is($participants_2->[1]->user->userId, 2222, 'participant list user[1]');
is($participants_2->[1]->role->roleId, 2, 'participant list role[1] (explicit)');
is($participants_2->[2]->user->userId,'alice', 'participant list user[2] (alphanumeric - ldap compat)');

do {
    my $guest_participant = $participants_2->[3];
    is($guest_participant->type, 2, 'Invited guest detected');
    ok(    ! $guest_participant->user
	&& ! $guest_participant->group
	&&   $guest_participant->guest, "participant user/group/guest (guest)");

    is_deeply($guest_participant->guest, {loginName => 'bob@test.org',
					    displayName => 'Robert'},
	      'invited guest contents');
    ok( ! $guest_participant->is_moderator(1), 'cannot promote guest to moderator');
    is( $guest_participant->stringify, 'Robert (bob@test.org)', 'guest stringification');
};

do {
    my $group_participant = $participants_2->[4];

    is($group_participant->type, 1, 'Group detected');
    ok(    ! $group_participant->user
	&&   $group_participant->group
	&& ! $group_participant->guest, "participant user/group/guest (group)");
    
    is_deeply($group_participant->group, {groupId => 'the_team'},
	      'group contents');
    ok( $group_participant->is_moderator(1), 'can promote group to moderators');
    ok( $group_participant->is_moderator && $group_participant->role->roleId == 2, 'group promotion persistance');
    ok( ! $group_participant->is_moderator(0), 'can demote group to participants');
    ok( ! $group_participant->is_moderator && $group_participant->role->roleId == 3, 'group demotion persistance');
};

my $participant_list_3 = Elive::Entity::ParticipantList->construct(
    {
	meetingId => 345678,
	participants => [1122,'2233=2']
    });

my $participants_3 = $participant_list_3->participants;
is($participants_3->[0]->user->userId , 1122, 'participant list user');
is($participants_3->[0]->role->roleId , 3, 'participant list role (defaulted)');
is($participants_3->[1]->user->userId , 2233, 'participant list user');
is($participants_3->[1]->role->roleId , 2, 'participant list role (explicit)');

is_deeply(
    Elive::Entity::ParticipantList->construct(
	{meetingId => 234568, participants => ''}
    ), {meetingId => 234568, participants => []}, 'empty participant string construction');

is_deeply(
    Elive::Entity::ParticipantList->construct(
	{meetingId => 234569, participants => []}
    ), {meetingId => 234569, participants => []}, 'empty participant array construction');

is_deeply(
    Elive::Entity::ParticipantList->construct(
	{meetingId => 234570,}
    ), {meetingId => 234570}, 'missing participants construction');

my $member_list_1 = Elive::Entity::Group->construct(    
    {        groupId => 54321,
	     name => 'group_1',
	     members => '212121,222222,fred'
    });

my $members_1 = $member_list_1->members;
is($members_1->[0], 212121, 'member list user[0]');
is($members_1->[1], 222222, 'member list user[1]');
is($members_1->[2], 'fred', 'member list user[2] (alphanumeric - ldap compat)');
    ;

$members_1->add('late_comer');
is($members_1->[-1], 'late_comer', 'member add');
is($members_1->stringify, '212121,222222,fred,late_comer', 'member list stringification');

$member_list_1->revert;

my $member_list_2 = Elive::Entity::Group->construct(
								   {
        groupId => 65432,
	name => 'group_2',
        members => [112233,'223344','alice', Elive::Entity::User->construct({userId => 'bob', loginName => 'bob'})]
	});

my $members_2 = $member_list_2->members;
is($members_2->[0], 112233,  'member list user[0] (integer)');
is($members_2->[1], 223344,  'member list user[1] (string)');
is($members_2->[2], 'alice', 'member list user[2] (alphanumeric - ldap compat)');
is($members_2->[3], 'bob',   'member list user[3] (object cast)');

my $meeting =  Elive::Entity::Meeting->construct({
    meetingId => '112233445566',
    name => 'test meeting',
    start => '1234567890123',
    end => '1231231230123',
						 });

isa_ok($meeting, 'Elive::Entity::Meeting');
is($meeting->name, 'test meeting', 'meeting name');
is($meeting->start, '1234567890123', 'meeting start (hires coercian)');
is($meeting->end, '1231231230123', 'meeting end (hires explicit)');

#
# test uncoercian of objects to simple values (e.g. primary key).
#

my $participant_list_4 = Elive::Entity::ParticipantList->construct(
								   {
        meetingId => $meeting,
        participants => [1122,'2233=2']
	});

is($participant_list_4->meetingId , $meeting->meetingId, "object => id cast on construct (primary key)");
is($participant_list_4->participants->stringify, '1122=3;2233=2', "participants stringification");

# try out some of the modifiers '-moderator', '-facilitator', '-other'
my $participant_class = 'Elive::Entity::Participant';

my $participant_list_5 = Elive::Entity::ParticipantList->construct(
								   {
        meetingId => $meeting,
        participants => ['1122=2', '1123',
                         -moderators => [2222, $participant_class->construct(2223)],
			 -participants => '3333', $participant_class->construct('3334=2'),
			 -moderators => 4444, '*admins',
			 -others => '5555', '6666=2'
	    ]
	});

is($participant_list_5->participants->stringify, '*admins=2;1122=2;1123=3;2222=2;2223=2;3333=3;3334=3;4444=2;5555=3;6666=3', "participants stringification");

my $participant_list_6 = Elive::Entity::ParticipantList->construct(
    {
        meetingId => $meeting,
        participants => ['1122=2', '1123',]
    });
 
# try using modifiers in add method

$participant_list_6->participants->add(-moderators => 2222, -others => 2223, 2224);

is($participant_list_6->participants->stringify, '1122=2;1123=3;2222=2;2223=3;2224=3', "participants stringification");

$participant_list_6->revert;

do {

    ## tests on nested group construction

    my $user_7777_obj = Elive::Entity::User->construct({
	userId => 7777,
	loginName => 'test_user'
    });

    my $group =  Elive::Entity::Group->construct( {
	name => 'Top level group',
	groupId => '1111',
	members => [
	    2222,
	    3333,
	    {
		name => 'sub group',
		groupId => 444,
		members => [
		    '4141',
		    '4242',
		    '3333', # deliberate duplicate
		    ],
	    },
	    {   # expanded user
		userId => 6666,
		loginName => 'test_user'
	    },
	    $user_7777_obj,
	]
     });

    is($group->name, 'Top level group', 'nested group - top level name');
    is($group->groupId, '1111', 'nested group - top level id');

    my $members = $group->members;
    isa_ok($members,'ARRAY', 'group members');
    is(scalar @$members, 5, 'group members - cardinality');
    is($members->[0], '2222', 'group member - simple element');
    isa_ok($members->[2], 'Elive::Entity::Group', 'group member - subgroup');

    my @all_members = $group->expand_members;
    is_deeply(\@all_members, [2222, 3333, 4141, 4242, 6666, 7777], 'group - all_members()');
};

Elive->disconnect;
