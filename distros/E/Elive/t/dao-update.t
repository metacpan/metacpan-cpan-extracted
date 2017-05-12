#!perl -T
use warnings; use strict;
use Test::More tests => 57;
use Test::Warn;
use Test::Fatal;

use Elive;
use Elive::Connection;
use Elive::Entity;
use Elive::Entity::User;
use Elive::Entity::Role;
use Elive::Entity::Meeting;
use Elive::Entity::Recording;
use Elive::Entity::Session;

use lib '.';
use t::Elive::MockConnection;

Elive->connection( t::Elive::MockConnection->connect() );

my %user_props = (map {$_ => 1} Elive::Entity::User->properties);

ok(exists $user_props{userId}
   && exists $user_props{loginName}
   && exists $user_props{loginPassword},
   'user entity class sane');

my $LOGIN_NAME = 'test_user';
my $LOGIN_PASS = 'test_pass';
my $USER_ID = '1234';

my $user1 = Elive::Entity::User->construct({
	userId => $USER_ID,
	loginName => $LOGIN_NAME,
	loginPassword => $LOGIN_PASS,
	role => {roleId => 1},
     },
    );

my $role2 = Elive::Entity::Role->construct({roleId => 2});

isa_ok($user1, 'Elive::Entity::User');
ok(!$user1->is_changed, 'freshly constructed user - !changed');
is($user1->userId, $USER_ID, 'user - userId accessor');
is($user1->loginName,  $LOGIN_NAME, 'constructed user - loginName accessor');
ok($user1->_db_data, 'user1 has db data');

ok(!$user1->is_changed, 'is_changed returns false before change');

do {
    # some tests on sub record changes - pick on user/role/roleId
    ok($user1->role->_db_data, 'user role has db data');

    ok( !$user1->role->is_changed, 'sub record (role) before change');
    ok($user1->role($role2), "role change");

    ok(!$user1->role->is_changed,  'sub record (role) replaced, not changed');

    ok($user1->is_changed, 'sub record primary key change - detected in main record');

    is( exception {$user1->revert} => undef, 'sub record revert - lives');
    is( $user1->role->{roleId}, 1, 'sub record (role) value after revert');
    ok( !$user1->is_changed, 'is_changed() after revert');

    $user1->set(loginName => $user1->loginName . '_1');

    is($user1->loginName,  $LOGIN_NAME .'_1', 'non-key update');
    ok($user1->is_changed, 'is_changed returns true after change');
};

$user1->set(email => 'user@test.org');

is_deeply([sort $user1->is_changed], [qw/email loginName/], 'is_changed properties');

$user1->revert('email');

is_deeply([sort $user1->is_changed], [qw/loginName/], 'is_changed after partial revert');

$user1->revert;

ok(!$user1->is_changed, 'is_changed after full revert');
is($user1->loginName,  $LOGIN_NAME, 'attribute value reverted');

my $user2 = Elive::Entity::User->construct({
	userId => $USER_ID +2,
	loginName => $LOGIN_NAME . '_2',
	loginPassword => $LOGIN_PASS,
	role => {roleId => 0},
     },
    );

is($user2->userId,  $USER_ID +2, 'second constructed user has correct userId value');
is($user2->loginName,  $LOGIN_NAME.'_2', 'second constructed user has correct loginName value');

my $user3 = Elive::Entity::User->construct({
        userId => $USER_ID,  # Note sharing primary key with $user1
        loginName => $LOGIN_NAME .'_3',
        loginPassword => $LOGIN_PASS
      },
    );

ok(!$user3->is_changed, 'is_changed returns false after reconstruction');

is($user3->_refaddr, $user1->_refaddr, 'Objects with common primary key are unified'); 
isnt($user3->_refaddr, $user2->_refaddr, 'Objects with distinct primary are distinguished');

is($user3->userId, $USER_ID, 'object reconstruction - key field saved');
is($user3->loginName, $LOGIN_NAME . '_3', 'object reconstruction - non-key field saved');

$user1->revert;

my $EMAIL = 'tester@test.org';
$user1->set(email => $EMAIL);

is($user1->email, $EMAIL, 'can set additional attributes');
is_deeply([$user1->is_changed], ['email'], 'Setting additional attributes shows as a change');

$user1->set(email => undef);
ok(!$user1->is_changed, 'Undefing newly added attribute undoes change');

$user1->revert;

ok(!$user1->is_changed, 'Revert 1');
$user1->role(3);
is_deeply([$user1->is_changed], ['role'], 'Compound field (role) change recognised');

$user1->revert;
ok(!$user1->is_changed, 'Revert 2');

$user1->deleted(1);
ok($user1->deleted, 'deleted user => deleted');
is_deeply([$user1->is_changed],['deleted'], 'deleted user => changed');

$user1->revert;
ok(!$user1->is_changed, 'Revert 3');
ok(!$user1->deleted, 'undeleted user => !deleted');
ok(!$user1->is_changed, 'undeleted user => !changed');

$user1->revert;

my $meetingId1 = '112233445566';
my $meetingId2 = '223344556677';

my $recording =  Elive::Entity::Recording->construct({
    recordingId => '123456789000_987654321000',
    meetingId => $meetingId1,
    creationDate => time().'000',
    size => '1024',
});

my $meeting_obj =  Elive::Entity::Meeting->construct({
    meetingId => $meetingId2,
    name => 'test meeting',
    start => '1234567890123',
    end => '1231231230123',
});

#
# test setting of object foreign key via reference_object
#
 
ok(!$recording->is_changed, 'recording - not changed before update');

is( exception {$recording->set(meetingId => $meeting_obj)} => undef, 'setting foreign key via object - lives');

ok($recording->is_changed, 'recording - changed after update');
is($recording->meetingId, $meetingId2,'recording meetingId before revert');

is( exception {$recording->revert} => undef, 'recording revert - lives');

is($recording->meetingId, $meetingId1,'recording meetingId after revert');
ok(!$recording->is_changed, 'recording - is_changed is false after revert');

my $session;
is( exception {
    $session = Elive::Entity::Session->construct({
	id => 12345,
	meeting => {
	    meetingId => 12345,
	    start => '1234567890123',
	    end => '1231231230123',
	    name => 'test session'
	  },
	  meetingParameters => {
	    meetingId => 12345,
	    userNotes => 'testing',
	  },
	  serverParameters => {
	    meetingId => 12345,
	    fullPermissions => 0,
          },
	  participantList => {
	    meetingId => 12345,
	    participants =>
		[{
		    user => $user1,
		    role => 3
		 },
		 {
		    user => $user2,
		    role => 2
		 },]
          },
     })
  } => undef, 'session construct - lives');

note explain {session_constructed => $session};

$session->name( $session->name.'X' );
$session->userNotes( $session->userNotes.'X' );

is_deeply( [$session->is_changed], [qw(name userNotes)], 'session->is_changed() - sane');

$session->revert;
is_deeply( [$session->is_changed], [], 'session->is_changed() after revert');

is_deeply( [ do {$session->enableTeleconferencing(1); $session->is_changed} ],
	   ['enableTelephony'], 'session update via freeze alias');

$session->revert;

ok(!$session->is_changed, 'ression revert');

is($session->participants->[1]->role->roleId, 2, 'participant role (pre-update)');
$session->participants->[1]->role(3);

is($session->participants->[1]->role->roleId, 3, 'participant role (post-update)');

ok($session->participants->[1]->is_changed, 'single participant is_changed()');
ok($session->participantList->is_changed, 'participants is_changed()');

$session->participantList->revert;

ok(!$session->participantList->is_changed, 'participantList is_changed() (post-revert)');
is($session->participants->[1]->role->roleId, 2, 'participant role (post-revert)');
