use v5.10;
use warnings;

{
	package MetaForm;

	# Moo for easy role mixing and a constructor
	use Moo;

	# gives us create_form_meta function
	use Form::Tiny::Utils qw(:meta_handlers);

	# we need this role mixed in
	with qw(Form::Tiny::Form);

	# meta roles go into the qw()
	create_form_meta(__PACKAGE__, qw());

	# add a requried field
	__PACKAGE__->form_meta->add_field('field-name' => (
		required => 1,
	));

	1;
}

my $form = MetaForm->new(
	input => {
		'field-name' => 42,
	}
);

# just for testing
$form;
