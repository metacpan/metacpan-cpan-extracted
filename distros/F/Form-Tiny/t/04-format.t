use v5.10; use warnings;
use Test::More;
use Form::Tiny::Inline;

# test for invalid format rejection
for my $input ([], 0, "", "a", \1, sub { }) {
	my $form = Form::Tiny::Inline->new(
		field_defs => [],
		input => $input,
	);
	ok !$form->valid, "non-hashref is not accepted";
	my $errors = $form->errors;
	is scalar @$errors, 1, "only one error reported";
	isa_ok shift @$errors, "Form::Tiny::Error::InvalidFormat",
		"error type matches";
}

done_testing;
