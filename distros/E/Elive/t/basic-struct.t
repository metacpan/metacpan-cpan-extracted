#!perl -T
use warnings; use strict;
use Test::More tests => 57;
use Test::Warn;

use Elive::DAO;
use Elive::DAO::Array;
use Elive::Entity::Role;
use Elive::Entity::Participants;

use Carp; $SIG{__DIE__} = \&Carp::confess;

my $class = 'Elive::DAO';

ok($class->_cmp_col('Int', 10, 20) < 0, '_cmp Int <');
ok($class->_cmp_col('Int', 20, 20) == 0, '_cmp Int ==');
ok($class->_cmp_col('Int', 20, '020') == 0, '_cmp Int ==');
ok($class->_cmp_col('Int', 20, 10) > 0, '_cmp Int >');
ok(! defined ($class->_cmp_col('Int', undef, 10)), '_cmp Int undef');
ok(! defined ($class->_cmp_col('Int', 10, undef)), '_cmp undef Int');
ok(! defined ($class->_cmp_col('Int', undef, undef)), '_cmp undef undef');

ok($class->_cmp_col('HiResDate', '1251063623412', '1251063623413') < 0, '_cmp HiResDate <');
ok($class->_cmp_col('HiResDate', '1251063623413', '1251063623413') == 0, '_cmp HiResDate ==');
ok($class->_cmp_col('HiResDate', '01251063623413', '1251063623413') == 0, '_cmp HiResDate ==');
ok($class->_cmp_col('HiResDate', '1251063623414', '1251063623413') > 0, '_cmp HiResDate >');


ok($class->_cmp_col('Str', 'aaa', 'bbb') < 0, '_cmp Str <');
ok($class->_cmp_col('Str', 'aaa', 'aaa') == 0, '_cmp Str ==');
isnt($class->_cmp_col('Str', 'aaa', 'AAA'), 0, '_cmp Str <>');
isnt($class->_cmp_col('Str', '    aaa bbb    ', ' AAA BBB '), 0, '_cmp Str white space');
isnt($class->_cmp_col('Str', ' aaa bbb ', 'AAA BBB'), 0, '_cmp Str white space lhs');
isnt($class->_cmp_col('Str', 'aaa bbb', ' AAA BBB '), 0, '_cmp Str white space rhs');
ok($class->_cmp_col('Str', 'aaa', 'AAA', case_insensitive => 1) == 0, '_cmp Str == -i');


ok($class->_cmp_col('enumRecordingStates', 'off', 'off') == 0, '_cmp enum ==');
ok($class->_cmp_col('enumRecordingStates', 'Off', 'off') == 0, '_cmp enum == (case insensitve)');
isnt($class->_cmp_col('enumRecordingStates', 'off', 'on'), 0, '_cmp enum !=');

ok($class->_cmp_col('Elive::DAO::Array', [1,2,3],[1,2,3]) == 0, '_cmp array ==');
ok($class->_cmp_col('Elive::DAO::Array', [1,2,3],[3,2,1]) == 0, '_cmp array == (unordered)');
ok($class->_cmp_col('Elive::DAO::Array', [2,3,4],[1,2,3]) > 0, '_cmp array >');
ok($class->_cmp_col('Elive::DAO::Array', [1,2,3],[2,3,4]) < 0, '_cmp array <');

ok($class->_cmp_col('Elive::Entity::Role', {roleId => 2},{roleId => 2}) == 0, '_cmp Entity ==');
ok($class->_cmp_col('Elive::Entity::Role', {roleId => 3},{roleId => 2}) > 0, '_cmp Entity >');
ok($class->_cmp_col('Elive::Entity::Role', {roleId => 2},{roleId => 3}) < 0, '_cmp Entity <');

_participant_array_tests('strings','aaaa','mmmm', 'zzzz');

_participant_array_tests('shallow structs',
			 {user => 'aaaa', role => 3},
			 {user => 'mmmm', role => 3},
			 {user => 'zzzz', role => 3});

_participant_array_tests('deep structs',
			 {user => {userId => 'aaaa'}, role => {roleId => 3}},
			 {user => {userId => 'mmmm'}, role => {roleId => 3}},
			 {user => {userId => 'zzzz'}, role => {roleId => 3}},
    );

_participant_array_tests('mixed',
			 'aaaa',
			 {user => 'mmmm', role => 3},
			 {user => {userId => 'zzzz'}, role => {roleId => 3}},
    );


ok(! $class->_cmp_col('Elive::Entity::Participants',
		      'a;b;c', 'c;b;a'),
   '_cmp entity array == (stringified)');

ok( $class->_cmp_col('Elive::Entity::Participants',
		      'a;b;c', 'x;b;a'),
   '_cmp entity array != (stringified)');

ok(! $class->_cmp_col('Elive::Entity::Participants',
		      'a=3;b;c=3', 'c;b=3;a'),
   '_cmp entity array != (defaulted roles)');

ok(! $class->_cmp_col('Elive::Entity::Participants',
		      'a=2;b;c', 'c;b;a=2'),
   '_cmp entity array == (similar roles)');

ok( $class->_cmp_col('Elive::Entity::Participants',
		      'a=2;b;c', 'c;b;a=3'),
   '_cmp entity array != (differing roles)');

########################################################################

sub _participant_array_tests {
    my $type = shift;
    my $low    = shift;
    my $medium = shift;
    my $high   = shift;
 
    ok(! $class->_cmp_col('Elive::Entity::Participants', [$low, $high], [$low, $high]), "_cmp entity array == (simple $type)");

    ok(! $class->_cmp_col('Elive::Entity::Participants', [$high, $low], [$low, $high]), "_cmp entity array == (reordered $type)");

    ok(! $class->_cmp_col('Elive::Entity::Participants', [], []), "_cmp entity array == (empty $type)");

   ok($class->_cmp_col('Elive::Entity::Participants', [$low], [$low, $high]), "_cmp entity array != (different length $type)");

    ok($class->_cmp_col('Elive::Entity::Participants', [$low, $medium], [$low, $high]) < 0, "_cmp entity array < (simple $type)");

    ok($class->_cmp_col('Elive::Entity::Participants', [$low, $high], [$low, $medium]) > 0, "_cmp entity array > (simple $type)");

};

