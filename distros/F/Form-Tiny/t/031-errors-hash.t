use v5.10;
use strict;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -base;

	form_field 'field';

	form_hook cleanup => sub {
		my ($self, $data) = @_;

		$self->add_error('error 1');
		$self->add_error(field => 'error 2');
		$self->add_error(Form::Tiny::Error->new(field => 'field', error => 'error 3'));
	};
}

my $form = TestForm->new(input => {});
ok !$form->valid;

is_deeply $form->errors_hash, {
	'' => [
		'error 1'
	],
	'field' => [
		'error 2',
		'error 3'
	]
	},
	'errors hash ok';

done_testing;
