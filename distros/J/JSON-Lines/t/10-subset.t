use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	canonical => 1,
);

my @data = (
	[qw/a b c/],
	[{"one" => "😁"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
	[{"one" => "😁"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
	[{"one" => "😁"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
	[{"one" => "😁"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
	[{"one" => "😁"}, {"two_slice" => "two_slice"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
	[{"one" => "😁"}, {"two_no" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
);

my $file = $jsonl->encode_file('test.jsonl', @data);

is($file, 'test.jsonl');

open my $fh, '<', $file or die $!;
my $front = $jsonl->get_subset($fh, 0, 1);
my $inside = $jsonl->get_subset($fh, 9, 10);
close $fh;

is_deeply($front, [ [ qw/a b c/], [ { one => "😁" }, { two => "two" }, ["three", "three"] ] ]);
is_deeply($inside, [
	[{"one" => "😁"}, {"two_slice" => "two_slice"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
]);

unlink $file;

done_testing();
