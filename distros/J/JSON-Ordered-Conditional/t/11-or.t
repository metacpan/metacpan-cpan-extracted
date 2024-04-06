use Test::More;

use JSON::Ordered::Conditional;

my $json = '{
	"if": {
		"m": "test",
		"key": "test",
		"then": {
			"abc": 123
		},
		"or": {
			"key": "test",
			"m": "other",
			"or": {
				"key": "test",
				"m": "thing"
			}
		}
	}
}';

my $compiled = JSON::Ordered::Conditional->new->compile($json, { test => "thing" }, 1);

my $expected = {
	"abc" => 123
};

is_deeply($compiled, $expected);

done_testing;
