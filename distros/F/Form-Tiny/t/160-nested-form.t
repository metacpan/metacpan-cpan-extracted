use v5.10;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use lib 't/lib';
use TestForm;

my @data = (
	[1, {nested_form => {int => 5}}],
	[1, {nested_form => {int => 0}}],
	[1, {}],

	# nested form is strict
	[0, {nested_form => {int => 0, more => 1}}],

	# nested field needs to validate as well
	[0, {nested_form => {int => "int"}}],

	# nested field is required
	[0, {nested_form => {}}],
);

for my $aref (@data) {
	my ($result, $input) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	for my $error (@{$form->errors}) {
		like($error->field, qr/^nested_form(\..+?)*$/, "error namespace valid");
	}
	note Dumper($form->errors);
}

done_testing();
