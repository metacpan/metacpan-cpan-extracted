use v5.10;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use ExampleHelpers;
use Data::Dumper;

lives_and {
	do_example 'regular_form';

	my $form = PrettyRegistationForm->new(
		input => {
			username => "perl",
			password => "meperl-5",
			repeat_password => "meperl-5",
			year_of_birth => 1987,
			sex => "other",
		}
	);

	ok($form->valid, "Registration successful");

	if (!$form->valid) {
		note Dumper($form->errors);
	}

	$form->set_input(
		{
			%{$form->input},
			repeat_password => "eperl-55",
		}
	);

	ok(!$form->valid, "passwords do not match");

	note Dumper($form->errors);
};

done_testing();
