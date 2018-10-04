#!/usr/bin/perl
use v5.14;
use warnings;

use Gruntmaster::Data;
use Test::Deep;
use Test::More;

BEGIN {
	eval {
		dbinit 'dbi:Pg:dbname=gmtest'; 1;
	} or plan skip_all => 'Cannot connect to test database. Create it by running createdb gmtest before running this test. '. "Error: $@";
	plan tests => 33;
}

note 'Setting up test database';
$ENV{PGOPTIONS} = '-c client_min_messages=WARNING';
system 'psql', 'gmtest', '-qf', 'db.sql';
system 'psql', 'gmtest', '-qf', 'testdata.sql';

note 'Running update_status';
update_status;

my $x = user_list;
is @$x, 2, 'user_list has two elements';
is_deeply $x->[0], {id => 'nobody', admin => 0, name => undef, town => undef, university => undef, country => undef, level => undef, lastjob => undef, contests => 1, solved => 2, attempted => 0}, 'user_list first element is correct';
is $x->[1]{admin}, 1, 'user_list second user is admin';

$x = user_entry 'nobody';
cmp_bag $x->{problems}, [
	{problem => 'arc', problem_name => 'Problem in archive', solved => bool 1},
	{problem => 'fca', problem_name => 'FC problem A', solved => bool 1},
], 'user_entry problems';

is_deeply $x->{contests}, [
	{contest => 'fc', contest_name => 'Finished contest', rank => 2, score => 40},
], 'user_entry contests';

sub ids { [map { $_->{id} } @$x] }

$x = problem_list;
cmp_bag ids, [qw/arc fca/], 'problem_list';

$x = problem_list private => 1;
cmp_bag ids, [qw/arc fca rca pca prv/], 'problem_list private => 1';

$x = problem_list contest => 'rc';
cmp_bag ids, [qw/rca/], q/problem_list contest => 'rc'/;

$x = problem_list contest => 'rc', solution => 1;
ok exists $x->[0]{solution}, q/problem_list contest => 'rc', solution => 1 has solution/;

$x = problem_list owner => 'nobody';
cmp_bag ids, [], q/problem_list owner => 'nobody'/;

$x = problem_entry 'arc';
cmp_bag $x->{limits}, [{format => 'C', timeout => 0.1}, {format => 'CPP', timeout => 0.1}], 'problem_entry limits';
is $x->{solution}, 'Sample Text', 'problem_entry has solution';

$x = problem_entry 'rca', 'rc';
ok !exists $x->{solution}, 'problem_entry during contest does not have solution';
ok exists $x->{contest_start}, 'problem_entry during contest has contest_start ';

$x = contest_list;
cmp_bag ids, [qw/pc rc fc/], 'contest_list';

$x = contest_entry 'fc';
cmp_deeply $x, {id => 'fc', name => 'Finished contest', start => ignore, stop => ignore, owner => 'MGV', owner_name => undef, finished => bool (1), started => bool (1), description => undef}, 'contest_entry fc';

ok contest_has_problem('rc', 'rca'), 'contest rc has problem rca';
ok contest_has_problem('rc', 'arc'), 'contest rc does not have problem arc';

my $pageinfo;
($x, $pageinfo) = job_list;
cmp_bag ids, [1..5], 'job_list';
is $pageinfo->{current_page}, 1, 'current page is 1';
is $pageinfo->{last_page}, 1, 'last page is 1';
ok !exists $pageinfo->{previous_page}, 'there is no previous page';
ok !exists $pageinfo->{next_page}, 'there is no next page';

$x = job_list private => 1;
cmp_bag ids, [1..7], 'job_list private => 1';

$x = job_list contest => 'fc';
cmp_bag ids, [1..3], 'job_list contest => fc';

$x = job_list owner => 'MGV';
cmp_bag ids, [1], 'job_ids owner => MGV';

$x = job_list problem => 'fca';
cmp_bag ids, [1..4], 'job_ids problem => fca';

$x = job_list problem => 'fca', result => 1;
cmp_bag ids, [2], 'job_ids problem => fca, result => 1';

$x = job_entry 1;
is $x->{size}, 21, 'job_entry size';
ok !exists $x->{source}, 'job_entry does not have source';
is_deeply $x->{results}, [], 'job_entry results';

$x = job_entry 7;
ok !defined $x->{result}, 'job_entry 7 has NULL result';

open_problem qw/fc fca MGV/, contest_entry('fc')->{start} + 300;

$x = standings 'fc';

is_deeply $x, [
	{rank => 1, user => 'MGV', user_name => undef, score => 80, scores => [80]},
	{rank => 2, user => 'nobody', user_name => undef, score => 40, scores => [40]},
], 'standings fc';

db->delete('opens', {contest => 'fc', problem => 'fca', owner => 'MGV'});
