use v5.10;
use warnings;
use Test::More;
use Data::Dumper;

{

	package TestForm;
	use Moo;

	with qw(
		Form::Tiny
	);

	sub build_fields
	{
		(
			{name => 'a.*.*', required => 1},
		)
	}
}

my @data = (
	[1, {a => [[1], [2]]}],
	[1, {a => [[{}, 1], [2, 3]]}],
	[1, {a => [[1], [], [2, 3]]}],

	[0, {a => {}}],
	[0, {a => []}],
	[0, {a => [{}]}],
	[0, {a => [[], {}]}],
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
