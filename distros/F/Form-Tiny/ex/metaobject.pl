use v5.10;
use strict;
use warnings;

{

	package MetaForm;

	# Moo for easy role mixing and a constructor
	use Moo;

	# gives us create_form_meta function
	use Form::Tiny::Utils qw(:meta_handlers);

	# meta roles go into the qw()
	# class roles goes into set_form_roles method call
	my $meta = create_form_meta(__PACKAGE__, qw())
		->set_form_roles(['Form::Tiny::Form']);

	# if you would like to add superclasses, this is the place to do so
	# extends '...';

	# you could use $meta directly, but you would first have to call ->bootstrap on it
	# the from_meta method will automatically find the proper meta for this package and
	# call that method
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
