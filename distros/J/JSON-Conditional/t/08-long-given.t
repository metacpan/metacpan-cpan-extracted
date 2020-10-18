use Test::More;

use JSON::Conditional;


my $json = '{
	"given": {
		"key": "test",
		"default": {
			"ghi": 789
		},
		"when": [
			{
				"m": "test",
				"then": {
					"abc": 123
				}
			},
			{
				"m": "other",
				"then": {
					"def": 456
				}
			}
		]
	},
	"overlord": 1
}';

my $compiled = JSON::Conditional->new->compile($json, { 
	test => "other", 
	again => "yay" 
}, 1);

my $hash = {
	overlord => 1,
	def => 456,
};

is_deeply($compiled, $hash);

$compiled = JSON::Conditional->new->compile($json, { 
	test => "again", 
	again => "yay" 
}, 1);

my $hash = {
	overlord => 1,
	ghi => 789,
};

is_deeply($compiled, $hash);

done_testing;
