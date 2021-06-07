use v5.10;
use warnings;
use Test::More;
use lib 't/lib';
use Data::Dumper;
use TestForm;

my @data = (
	[1, {"not.nested" => 1}, {"not.nested" => 1}],
	[1, {"is\\" => {nested => 1}}, {"is\\" => {nested => 1}}],
	[1, {"not\\.nested" => 1}, {"not\\.nested" => 1}],
	[1, {not => {'*' => {nested_array => 5}}}, {not => {'*' => {nested_array => 5}}}],
);

for my $aref (@data) {
	my ($result, $input, $expected) = @$aref;
	$expected //= $input;

	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	if ($form->valid && $result) {
		note Dumper($form->fields);
		is_deeply $form->fields, $expected, "fields copied ok";
	}

	note Dumper($input);
	note Dumper($form->errors);
}

done_testing;
