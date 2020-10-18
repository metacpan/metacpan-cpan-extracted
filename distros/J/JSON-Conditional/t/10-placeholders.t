use Test::More;

use JSON::Conditional;

my $json = '{
	"other": "{testing}",
	"nested": {
		"nested": {
			"other": "{testing}"
		}
	},
	"for": {
		"key": "testing",
		"each": "testing",
		"remap": "{test}",
		"abc": 123
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
	other => [ 
		{ test => "other" },
		{ test => "test" },
		{ test => "other" },
		{ test => "thing" },
	],
	nested => {
		nested => {
			other => [ 
				{ test => "other" },
				{ test => "test" },
				{ test => "other" },
				{ test => "thing" },
			]
		}
	},
	testing => [
		{ abc => 123, remap => "other" },
		{ abc => 123, remap => "test" },
		{ abc => 123, remap => "other" },
		{ abc => 123, remap => "thing" },
	]
};

is_deeply($compiled, $expected);

done_testing;
