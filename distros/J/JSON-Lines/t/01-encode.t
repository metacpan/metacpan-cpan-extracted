use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	canonical => 1,
);

my @data = (
	[qw/a b c/],
	["one", "two", "three"],
	["four", "five", "six"],
	["seven", "eight", "nine"]
);

my $string = $jsonl->encode(@data);
my $expected = q|["a","b","c"]
["one","two","three"]
["four","five","six"]
["seven","eight","nine"]
|;

is($string, $expected);

$string = $jsonl->add_line(["ten", "eleven", "twelve"]);

is($string, $expected . '["ten","eleven","twelve"]' . "\n");

my $data = [
	{
		a => "one",
		b => "two",
		c => "three",
	},
	{
		a => "four",
		b => "five",
		c => "six",
	},
	{
		a => "seven",
		b => "eight",
		c => "nine",
	}
];

$string = $jsonl->encode($data);

$expected = q|{"a":"one","b":"two","c":"three"}
{"a":"four","b":"five","c":"six"}
{"a":"seven","b":"eight","c":"nine"}
|;

is($string, $expected);

$string = $jsonl->add_line({ a => "ten", b => "eleven", c => "twelve" });
is($string, $expected . '{"a":"ten","b":"eleven","c":"twelve"}' . "\n");

done_testing();
