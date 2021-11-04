use v5.10;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Form::Tiny::Inline;

{

	package TestForm;
	use Form::Tiny;
	use Types::Standard qw(Int);

	form_field 'no_message' => (
		type => Int,
	);

	form_field 'plain_message' => (
		type => Int,
		message => 'just a string',
	);

	form_field 'stringified_message' => (
		type => Int,
		message => Form::Tiny::Error->new(error => 'it stringifies'),
	);
}

my $form = TestForm->new;
$form->set_input(
	{
		no_message => 0.5,
		plain_message => 0.5,
		stringified_message => 0.5,
	}
);

ok !$form->valid, 'validation failed ok';
for my $error (@{$form->errors}) {
	my $no_message_error;

	for ($error->field) {
		if (/no_message/) {
			$no_message_error = $error->error;
		}
		elsif (/plain_message/) {
			isnt $error->error, $no_message_error, 'error message is not default';
			like $error->error, qr/just a string/, 'error message ok';
		}
		elsif (/stringified_message/) {
			isnt $error->error, $no_message_error, 'error message is not default';
			like $error->error, qr/it stringifies/, 'error message ok';
		}
	}
}

dies_ok {
	Form::Tiny::Inline->new(
		field_defs => [
			{
				name => 'that_doesnt_stringify',
				message => Form::Tiny::Inline->new(),
			}
		],
	);
};

done_testing();
