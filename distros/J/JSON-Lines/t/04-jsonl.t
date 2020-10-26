use Test::More;

use JSON::Lines qw/jsonl/;

my @data = (
	[qw/a b c/],
	[{"one" => "one"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
);

my $expected = q|["a","b","c"]
[{"one":"one"},{"two":"two"},["three","three"]]
[{"four":"four"},{"five":"five"},["six","six"]]
|;

my $string = jsonl( encode => 1, data => \@data );

is($string, $expected);

my $back = jsonl( decode => 1, data => $string );

is_deeply($back, \@data);

my $data = [
	{
		a => { "one" => "one" },
		b => { "two" => "two" },
		c => ["three", "three" ]
	},
	{
		a => { "four" => "four" },
		b => { "five" => "five" },
		c => [ "six", "six" ]
	},
];

$expected = q|{"a":{"one":"one"},"b":{"two":"two"},"c":["three","three"]}
{"a":{"four":"four"},"b":{"five":"five"},"c":["six","six"]}
|;
$string = jsonl( canonical => 1, encode => 1, data => $data );

is($string, $expected);

my @back = jsonl( decode => 1, data => $string );

is_deeply(\@back, $data);

done_testing();
