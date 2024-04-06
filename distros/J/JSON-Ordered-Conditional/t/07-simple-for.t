use Test::More;

use JSON::Ordered::Conditional;

my $json = '{
	"for": {
		"key": "testing",
		"each": "testing",
		"abc": 123
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
		{ abc => 123 },
		{ abc => 123 },
		{ abc => 123 },
		{ abc => 123 },
	]
};

is_deeply($compiled, $expected);

done_testing;
