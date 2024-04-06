use Test::More;

use JSON::Ordered::Conditional;

my $json = '{
	"if": {
		"m": "test",
		"key": "test",
		"then": {
			"abc": 123
		},
		"and": {
			"key": "testing",
			"m": "other",
			"and": {
				"key": "tester",
				"m": "thing"
			}
		}
	}
}';

my $compiled = JSON::Ordered::Conditional->new->compile($json, { test => "test", testing => "other", tester => "thing" }, 1);

my $expected = {
	"abc" => 123
};

is_deeply($compiled, $expected);

done_testing;
