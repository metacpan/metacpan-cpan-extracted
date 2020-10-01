use v5.10; use warnings;
use Test::More;
use lib 't/lib';
use Data::Dumper;
use TestForm;

my @data = (
	[1, {array => [{name => "a"}, {name => "b"}]}],
	[
		1,

		# since not every array element meets our criteria, we ignore the field altogether
		{array => [{name => "a"}, {}, {name => "b"}]},
		{},
	],
	[
		1, {
			array => [
				{name => "Han", second => [{name => "Wookie"}, {name => "Leia"}]},
				{name => "Luke", second => [{name => "R2D2"}]}
			]
		}
	],

	[1, {marray => [[1, 2], [3, 4]]}],
	[1, {marray => [[], [3, 4, -1]]}, {marray => [[], [3, 4, -1]]}],

	# we still keep it strict
	[0, {array => [{name => "x", unknown_name => "a"}, {name => "b"}]}],
	[0, {array => [{name => "x", second => [{unknown => "a"}]}, {name => "b"}]}],
	[0, {marray => [[3, 4, -1], {a => 5}]}],

	# we wanted an array
	[0, {array => {name => "x"}}],

	[0, {marray => [[3, 4, -1], ["test"]]}],
	[0, {marray => {}}],
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
