use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	pretty => 1,
	canonical => 1,
);

my @data = (
	[qw/a b c/],
	[{"one" => "one"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
);

my $expected = q|[
   "a",
   "b",
   "c"
]
[
   {
      "one" : "one"
   },
   {
      "two" : "two"
   },
   [
      "three",
      "three"
   ]
]
[
   {
      "four" : "four"
   },
   {
      "five" : "five"
   },
   [
      "six",
      "six"
   ]
]
|;

my $string = $jsonl->encode(@data);

is($string, $expected);

my $back = $jsonl->decode($string);

is_deeply($back, \@data);

done_testing();
