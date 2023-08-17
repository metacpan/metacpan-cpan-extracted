use v5.10;
use strict;
use warnings;
use Test::More;

{

	package Form::Nested;

	use Form::Tiny;

	form_field value1 => (
		default => sub { 'a default' },
	);

	form_field value2 => (
		default => sub { 'another default' },
	);
}

{

	package Form::Parent;

	use Form::Tiny;

	form_field subform => (
		type => Form::Nested->new,
		default => sub { {value2 => '!'} },
	);
}

my $form = Form::Parent->new;
$form->set_input({});

ok $form->valid, 'form valid ok';
is_deeply $form->fields, {
	subform => {
		value1 => 'a default',
		value2 => '!',
	},
	},
	'form fields ok';

done_testing;

