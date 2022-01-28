use v5.10;
use strict;
use warnings;

{

	package MetaForm;

	# Moo for easy role mixing and a constructor
	use Moo;

	# gives us create_form_meta function
	use Form::Tiny::Utils qw(:meta_handlers);

	# mixing in Form::Tiny early will give us form_meta method
	# proper form_meta will setup the metamodel for a form
	with 'Form::Tiny';

	# meta roles go into the qw()
	# class roles goes into set_form_roles method call
	create_form_meta(__PACKAGE__, qw())
		->set_form_roles(['Form::Tiny::Form']);

	# add a requried field
	__PACKAGE__->form_meta->add_field(
		'field-name' => (
			required => 1,
		)
	);

	1;
}

my $form = MetaForm->new(
	input => {
		'field-name' => 42,
	}
);

# just for testing
$form;
