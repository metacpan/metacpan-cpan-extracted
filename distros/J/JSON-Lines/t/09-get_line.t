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

my @back;
open my $fh, '<', $file or die $!;
while (my $line = $jsonl->get_line($fh)) {
	push @back, $line; 
};
is_deeply(\@back, \@data);


unlink $file;

done_testing();
