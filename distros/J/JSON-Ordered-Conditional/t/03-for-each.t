use Test::More;

use JSON::Ordered::Conditional;

my $json = '{
	"for": {
		"key": "testing",
		"each": "testing",
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
	}
}';

my $compiled = JSON::Ordered::Conditional->new->compile($json, {
	testing => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	]
}, 1);

my $expected = {
	testing => [
		{ def => 456 },
		{ abc => 123 },
		{ def => 456 },
		{ ghi => 789 },
	]
};

is_deeply($compiled, $expected);

done_testing;
