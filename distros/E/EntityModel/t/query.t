use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Deep;
use EntityModel::Query;

# Test cases are based on EntityModel::Query in PostgreSQL mode, so the quoting style for identifiers uses " characters.

# Want to preserve order so we use a hash-shaped array
my @cases = (
# Basic select functionality, no tables
	q{select id} => {
		prepared => q{select id},
		parameters => [],
		query => [
			select	=> 'id'
		]
	},
# Select with table definition
	q{select id from table} => {
		prepared => q{select id from table},
		parameters => [],
		query => [
			select	=> 'id',
			from	=> 'table'
		]
	},
# Select, table definition, where clause
	q{select id from table where id = 3} => {
		prepared => q{select id from table where id = $1},
		parameters => [3],
		query => [
			select	=> 'id',
			from	=> 'table',
			where	=> { id => 3 }
		]
	},
	q{select id from table where (name = 'test' and id = 3)} => {
		prepared => q{select id from table where (name = $1 and id = $2)},
		parameters => ['test', 3],
		query => [
			select	=> 'id',
			from	=> 'table',
			where	=> [
				name	=> 'test',
			-and =>	id	=> 3
			]
		]
	},
# Group
	q{select sum(total) as total from table group by category} => {
		prepared => q{select sum(total) as total from table group by category},
		parameters => [],
		query => [
			select	=> { total => \'sum(total)' },
			from	=> 'table',
			group	=> 'category'
		]
	},
	q{select sum(total) as total from table where created > '2010-01-01' group by category} => {
		prepared => q{select sum(total) as total from table where created > $1 group by category},
		parameters => ['2010-01-01'],
		query => [
			select	=> { total => \'sum(total)' },
			from	=> 'table',
			where	=> [
				created => { '>' => '2010-01-01' }
			],
			group	=> 'category'
		]
	},
	q{select category, sum(total) as total from table where created > '2010-01-01' group by category order by category} => {
		prepared => q{select category, sum(total) as total from table where created > $1 group by category order by category},
		parameters => ['2010-01-01'],
		query => [
			select	=> [ 'category', { total => \'sum(total)' } ],
			from	=> 'table',
			where	=> [
				created => { '>' => '2010-01-01' }
			],
			group	=> 'category',
			order	=> 'category',
		]
	},
	q{select category, sum(total) as total from table where created > '2010-01-01' group by category order by category desc limit 5} => {
		prepared => q{select category, sum(total) as total from table where created > $1 group by category order by category desc limit 5},
		parameters => ['2010-01-01'],
		query => [
			select	=> [ 'category', { total => \'sum(total)' } ],
			from	=> 'table',
			where	=> [
				created => { '>' => '2010-01-01' }
			],
			group	=> 'category',
			order	=> { desc => 'category' },
			limit	=> 5,
		]
	},
# Insert
	q{insert into table (id, something) values (3, 'test')} => {
		prepared => q{insert into table (id, something) values ($1, $2)},
		parameters => [3, 'test'],
		query => [
			'insert into'	=> 'table',
			values		=> {
				id		=> 3,
				something	=> 'test',
			}
		]
	},
	q{insert into table (id, something) values (3, 'test') returning id} => {
		prepared => q{insert into table (id, something) values ($1, $2) returning id},
		parameters => [3, 'test'],
		query => [
			'insert into'	=> 'table',
			values		=> {
				id		=> 3,
				something	=> 'test',
			},
			'returning'	=> [ 'id' ],
		]
	},
# Update
	q{update table set something = 3, other = 'test' where id = 2} => {
		prepared => q{update table set something = $1, other = $2 where id = $3},
		parameters => [3, 'test', 2],
		query => [
			'update'	=> 'table',
			fields		=> [
				something	=> 3,
				other		=> 'test',
			],
			where		=> [
				id	=> 2
			]
		]
	},
);
plan tests => 6 * (scalar(@cases) / 2);

while(@cases) {
	my $k = shift(@cases);
	my $v = shift(@cases);
	note "Try $k";
	ok(my $q = EntityModel::Query->new(@{$v->{query}}), "$k - generate query") or die "failed to parse";
	isa_ok($q, 'EntityModel::Query');
	ok($q->type, 'have valid type for query');
	is($q->sqlString, $k, "$k - query string matches");
	my ($sql, @bind) = $q->sqlAndParameters;
	is($sql, $v->{prepared}, '->prepare string matches');
	cmp_deeply(\@bind, $v->{parameters}, 'parameters match') or die "mismatch";
}

