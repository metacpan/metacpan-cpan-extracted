use LINQ 'LINQ';
use Test::Modern;

my $departments = LINQ(
	[
		{ dept_name => 'Accounts',  cost_code => 1 },
		{ dept_name => 'IT',        cost_code => 7 },
		{ dept_name => 'Marketing', cost_code => 8 },
	]
);

my $people = LINQ(
	[
		{ name => "Alice", dept => 'Marketing' },
		{ name => "Bob",   dept => 'IT' },
		{ name => "Carol", dept => 'IT' },
	]
);

my $BY_HASH_KEY = sub {
	my ( $key ) = @_;
	return $_->{$key};
};

my $joined = $departments->group_join(
	$people,
	-left,                            # left join
	[ $BY_HASH_KEY, 'dept_name' ],    # select from $departments by hash key
	[ $BY_HASH_KEY, 'dept' ],         # select from $people by hash key
	sub {
		my ( $dept, $people ) = @_;
		return {
			dept      => $dept->{dept_name},
			cost_code => $dept->{cost_code},
			people    => $people->select( $BY_HASH_KEY, 'name' )->to_array,
		};
	},
);

is_deeply(
	$joined->to_array,
	[
		{
			'cost_code' => 1,
			'dept'      => 'Accounts',
			'people'    => []
		},
		{
			'cost_code' => 7,
			'dept'      => 'IT',
			'people'    => [ 'Bob', 'Carol' ]
		},
		{
			'cost_code' => 8,
			'dept'      => 'Marketing',
			'people'    => ['Alice']
		}
	],
	'group_join example from the documentation works'
);

done_testing;
