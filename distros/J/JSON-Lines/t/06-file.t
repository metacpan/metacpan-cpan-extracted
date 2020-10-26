use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	pretty => 1,
	canonical => 1,
);

my @data = (
	[qw/a b c/],
	[{"one" => "😁"}, {"two" => "two"}, ["three", "three"]],
	[{"four" => "four"}, {"five" => "five"}, ["six", "six"]],
);

my $file = $jsonl->encode_file('test.jsonl', @data);

is($file, 'test.jsonl');

my $back = $jsonl->decode_file($file);

is_deeply($back, \@data);


open my $fh, '<', $file or die $!;
my $line = $jsonl->get_line($fh);
is_deeply($line, [qw/a b c/]);
$line = $jsonl->get_line($fh);
is_deeply($line, [{"one" => "😁"}, {"two" => "two"}, ["three", "three"]]);
$line = $jsonl->get_line($fh);
is_deeply($line, [{"four" => "four"}, {"five" => "five"}, ["six", "six"]]);
close $fh;

open my $fh, '<', $file or die $!;
my $lines = $jsonl->get_lines($fh, 10);
is_deeply($lines, \@data);
close $fh;



unlink $file;

done_testing();
