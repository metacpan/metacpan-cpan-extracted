use v5.10;
use strict;
use warnings;
use Test::More;

use Form::Tiny::Utils qw(try);

{

	package Form::Nested;

	use Form::Tiny;
	use Types::Standard qw(Str);

	form_field value1 => (
		type => Str,
		default => sub { 'a default' },
	);

	form_field value2 => (
		default => sub { 'another default' },
	);
}

{

	package Form::Parent;

	use Form::Tiny;

	has 'subform_default' => (
		is => 'ro',
		default => sub {
			{
				value2 => '!',
			}
		},
	);

	form_field sub {
		my ($self) = @_;

		return {
			name => 'subform',
			type => Form::Nested->new,
			default => sub { $self->subform_default },
		};
	};
}

subtest 'testing default' => sub {
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
};

subtest 'testing default with error' => sub {
	my $form = Form::Parent->new(subform_default => { value1 => [] });
	$form->set_input({});

	my $err = try sub {
		$form->valid;
	};

	ok $err, 'error present ok';
	like $err, qr/\$errors\s*=\s*\{/, 'error has error hash dump';
	note $err;
};

done_testing;

