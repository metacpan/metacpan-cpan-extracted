#!perl -T
use warnings; use strict;
use Test::More tests => 16;
use Test::Warn;

use Elive::Connection;
use Elive::Entity::User;
use Elive::Entity::Group;

use lib '.';
use t::Elive::MockConnection;

Elive->connection( t::Elive::MockConnection->connect() );

my @base_members = (100, 101, 102);

my %group_props = (map {$_ => 1}  Elive::Entity::Group->properties);

ok(exists $group_props{groupId}
   && exists $group_props{name}
   && exists $group_props{members},
   'group entity class sane');

my $group1 = Elive::Entity::Group->construct({
	groupId => 111,
	name => 'group_with_several_members',
	members => [ @base_members ],
     },
    );

isa_ok($group1, 'Elive::Entity::Group');
is($group1->groupId, 111, 'constructed group - id accessor');
is($group1->name, 'group_with_several_members', 'constructed group - name accessor');
isa_ok($group1->members, 'Elive::DAO::Array', 'group->members');
is_deeply([ @{$group1->members}], \@base_members, 'group members preserved');

ok(!$group1->is_changed, 'is_changed returns false before change');

$group1->members->[-1]++;
ok($group1->is_changed, 'changing array member recognised as a change');

$group1->members->[-1]--;
ok(!$group1->is_changed, 'reverting array member reverts change');

push(@{$group1->members}, 104);			 
ok($group1->is_changed, 'adding array member recognised as a change');

pop(@{$group1->members});
ok(!$group1->is_changed, 'removing member reverts change');

unshift(@{$group1->members}, pop(@{$group1->members}));
ok(!$group1->is_changed, 'shuffling members not recognised as change');

$group1->set('members' => [@{$group1->members}]);
ok(!$group1->is_changed, 're-initialise members - not recognised as a change');

$group1->revert;

my $group2 = Elive::Entity::Group->construct({
	groupId => 2,
	name => 'group_with_no_members',
	members => [],
     },
    );

ok(!$group2->is_changed, 'is_changed returns false before change');

push(@{$group2->members}, 104);			 
ok($group2->is_changed, 'adding initial member recognised as a change');

$group2->{members} = [];
ok(!$group2->is_changed, 'is_changed returns false after reinitialisation');

