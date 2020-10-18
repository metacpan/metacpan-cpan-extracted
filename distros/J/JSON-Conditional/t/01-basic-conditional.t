use Test::More;

use JSON::Conditional;

my $json = '{
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
}';

my $compiled = JSON::Conditional->new->compile($json, { test => "other" });

like($compiled, qr/456/);

done_testing;
