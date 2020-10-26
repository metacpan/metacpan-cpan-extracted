use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new( canonical => 1 );

my @data = (
	[qw/a b c/],
	[{"one" => "one"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
);

my $expected = q|["a","b","c"]
[{"one":"one"},{"two":"two"},["three","three"]]
[{"four":"four"},{"five":"five"},["six","six"]]
|;

my $string = $jsonl->encode(@data);

is($string, $expected);

my $back = $jsonl->decode($string);

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
$string = $jsonl->encode($data);

is($string, $expected);

my @back = $jsonl->decode( $string );

is_deeply(\@back, $data);

done_testing();
