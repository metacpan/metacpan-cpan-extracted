use v5.10;
use strict;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny;
	use Types::Standard qw(Int);

	form_field 'val' => (
		type => Int,
		message => 'not_int',
	);

	field_validator 'not_even' => sub {
		shift() % 2 == 0;
	};

	field_validator 'not_positive' => sub {
		shift() > 0;
	};
}

my @data = (
	[1, {val => 6}],
	[0, {val => 'test'}, ['not_int']],
	[0, {val => 5}, ['not_even']],
	[0, {val => -4}, ['not_positive']],
	[0, {val => -5}, ['not_even', 'not_positive']],
);

for my $aref (@data) {
	my ($result, $input, $wanted_error) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	for my $error (@{$form->errors}) {
		is($error->error, shift @{$wanted_error}, "error valid");
	}
}

done_testing;
