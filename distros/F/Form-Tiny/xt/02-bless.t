use v5.10;
use warnings;
use Test::More;

package ParentForm
{
	use Form::Tiny -nomoo;

	form_field 'f1';

	sub new
	{
		my ($class) = @_;
		return bless {}, $class;
	}
}

package ChildForm
{
	use Form::Tiny -nomoo;

	use parent -norequire, ParentForm;

	form_field 'f2';
}

my $form = ChildForm->new;
$form->set_input({
	f1 => 'field f1',
	f2 => 'field f2',
});

ok $form->valid;
ok $form->DOES('Form::Tiny::Form');
is $form->fields->{f1}, 'field f1';
is $form->fields->{f2}, 'field f2';

done_testing;
