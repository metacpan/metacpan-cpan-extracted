use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	canonical => 1,
);

my $string = q|["a","b","c"]
["one","two","three"]
["four","five","six"]
["seven","eight","nine"]|;


my @expected = (
	[qw/a b c/],
	["one", "two", "three"],
	["four", "five", "six"],
	["seven", "eight", "nine"]
);

my @data = $jsonl->decode($string);

is_deeply(\@data, \@expected);


$string = q|{"a":"one","b":"two","c":"three"}
{"a":"four","b":"five","c":"six"}
{"a":"seven","b":"eight","c":"nine"}|;

$expected = [
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

my $data = $jsonl->decode($string);

is_deeply($data, $expected);

done_testing();
