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
is scalar @{$form->errors}, 3;
is $form->errors->[0]->error, 'error 1';
is $form->errors->[1]->field, 'field';
is $form->errors->[1]->error, 'error 2';
is $form->errors->[2]->error, 'error 3';

done_testing;
