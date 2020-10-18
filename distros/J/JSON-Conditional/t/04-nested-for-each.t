use Test::More;

use JSON::Conditional;

my $json = '{
	"thing": {
		"for": {
			"key": "testing",
			"each": "abc",
			"if": {
				"m": "test",
				"key": "test",
				"then": {
					"abc": 123
				}
			},
			"elsif": {
				"m": "other",
				"key": "test",
				"then": {
					"def": 456
				}
			},
			"else": {
				"then": {
					"ghi": 789
				}
			}
		},
		"def" : 123
	}
}';

my $compiled = JSON::Conditional->new->compile($json, {
	testing => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	]
}, 1);

my $expected = {
	thing => {
		abc => [
			{ def => 456 },
			{ abc => 123 },
			{ def => 456 },
			{ ghi => 789 },
		],
		def => 123
	}
};

is_deeply($compiled, $expected);

done_testing;
