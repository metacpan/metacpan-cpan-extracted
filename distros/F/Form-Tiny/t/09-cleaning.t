use v5.10;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestForm;
use Data::Dumper;

my @data = (
	[1, {bool_cleaned => 1}, {bool_cleaned => "Yes"}],
	[0, {bool_cleaned => 0}],
	[0, {bool_cleaned => 2}],
	[0, {bool_cleaned => "Yes"}],
);

for my $aref (@data) {
	my ($result, $input, $expected) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	if ($form->valid && $expected) {
		is_deeply $form->fields, $expected, "result values ok";
	}
	for my $error (@{$form->errors}) {
		is($error->field, "bool_cleaned", "error namespace valid");
	}

	note Dumper($input);
	note Dumper($form->errors);
}

done_testing;
