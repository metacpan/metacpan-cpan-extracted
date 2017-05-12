### 02-fancy_args.t ###########################################################
# This file tests the hash methods for setting arguments.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More;
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $eks1 = {
	test1 => {max_concurrent => 1},
	test2 => {max_concurrent => 2},
};

my @tests = (
	# list of 4 elelment lists: each contains:
	# - $ test_name (first word is also used as group name)
	# - @ env_keys
	# - % env_key_specific
	# - @ validation list
	#
	# a group is created with:
	# - name=>$test_name
	# - env_keys => $env_keys
	# - env_key_specific => $env_key_specific
	# # the resulting group is validated with the list
	# # each element of the list is a list:
	# # - method
	# # - list of validations to apply to the result of $group->$method
	# #   - test function ref (e.g. \&is \&is_deeply
	# #   - list of test function operands (in addition to $group->$method) to pass to the test function
	# #     (they should include a trailing test description)

	# LocalConfig can provide a non-zero max_concurrent
	# [
	# 	'basic0 - no keys',
	# 	undef,
	# 	$eks1,
	# 	[
	# 		[
	# 			'max_concurrent',
	# 			[
	# 				[ \&is, 0, 'no keys should leave max_concurrent at 0' ]
	# 			],
	# 		],
	# 	]
	# ],
	[
		'basic1 - one key',
		[ qw(test1) ],
		$eks1,
		[
			[
				'max_concurrent',
				[ [ \&is, 1, 'key test1 should set max_concurrent to 1' ] ],
			],
		]
	],
	[
		'basic2 - 2 keys',
		[ qw(test1 test2) ],
		$eks1,
		[
			[
				'max_concurrent',
				[ [ \&is, 2, 'keys test1+test2 should set max_concurrent to 2 (the second key)' ] ],
			],
		]
	],
);

plan tests => scalar( @tests );

for my $test (@tests) {
	my ($test_name, $env_keys, $env_key_specific, $validations) = @$test;
	my ($group_name) = $test_name =~ /^([^ ]+)/;
	subtest $test_name => sub {
		plan tests => scalar( @$validations );
		my $group = HPCI->group(
			cluster => $cluster,
			base_dir => 'scratch',
			name => $group_name,
			( defined $env_keys ? (env_keys => $env_keys) : () ),
			env_key_specific => $env_key_specific,
		);
		for my $validation (@$validations) {
			my ($method, $checks) = @$validation;
			subtest "method $method value" => sub {
				plan tests => scalar( @$checks );
				my $result = $group->$method;
				for my $check (@$checks) {
					my @operands = @$check;
					my $test_func = shift @operands;
					$test_func->( $result, @operands );
				}
			};
		}
	};
}

done_testing();

1;
