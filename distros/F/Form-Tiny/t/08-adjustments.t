use v5.10;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestForm;
use Data::Dumper;

my @data = (
	[1, {}, {}],
	[1, {str_adjusted => ""}, {str_adjusted => ">>"}],
	[1, {str_adjusted => "5"}, {str_adjusted => ">>5"}],
	[1, {str_adjusted => ">>"}, {str_adjusted => ">>>>"}],
	[0, {str_adjusted => undef}],
);

for my $aref (@data) {
	my ($result, $input, $expected) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	if ($form->valid && $expected) {
		is_deeply $form->fields, $expected, "result values ok";
	}
	for my $error (@{$form->errors}) {
		is($error->field, "str_adjusted", "error namespace valid");
	}

	note Dumper($input);
	note Dumper($form->errors);
}

done_testing;
