use LINQ 'LINQ';
use Test::Modern;

my $people = LINQ(
	[
		{ name => "Alice", dept => 'Marketing' },
		{ name => "Bob",   dept => 'IT' },
		{ name => "Carol", dept => 'IT' },
	]
);

my $departments = LINQ(
	[
		{ dept_name => 'Accounts',  cost_code => 1 },
		{ dept_name => 'IT',        cost_code => 7 },
		{ dept_name => 'Marketing', cost_code => 8 },
	]
);

my $BY_HASH_KEY = sub {
	my ( $key ) = @_;
	return $_->{$key};
};

my $joined = $people->join(
	$departments,
	-inner,                           # inner join
	[ $BY_HASH_KEY, 'dept' ],         # select from $people by hash key
	[ $BY_HASH_KEY, 'dept_name' ],    # select from $departments by hash key
	sub {
		my ( $person, $dept ) = @_;
		return {
			name         => $person->{name},
			dept         => $person->{dept},
			expense_code => $dept->{cost_code},
		};
	},
);

is_deeply(
	$joined->to_array,
	[
		{
			name         => 'Alice',
			dept         => 'Marketing',
			expense_code => 8,
		},
		{
			name         => 'Bob',
			dept         => 'IT',
			expense_code => 7,
		},
		{
			name         => 'Carol',
			dept         => 'IT',
			expense_code => 7,
		}
	],
	'join example from the documentation works'
);

done_testing;
