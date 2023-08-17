use v5.10;
use strict;
use warnings;
use Test::More;

# This behavior is documented in the Manual.
# TODO: how could this be more meaningful?
{

	package Form::Nested;

	use Form::Tiny;
	use Types::Standard qw(Int);

	form_field value1 => (
		type => Int,
	);

	form_field value2 => (
		type => Int,
	);
}

{

	package Form::Parent;

	use Form::Tiny;

	form_field subform => (
		type => Form::Nested->new,
		message => 'replaces both',
	);
}

my $form = Form::Parent->new;
$form->set_input(
	{
		subform => {
			value1 => 'not an int',
			value2 => 'not an int',
		},
	}
);

ok !$form->valid, 'form not valid ok';

my $errors = $form->errors;
is scalar @$errors, 1, 'error count ok';
is $errors->[0]->field, 'subform', 'error field ok';
is $errors->[0]->error, 'replaces both', 'error ok';

done_testing;

