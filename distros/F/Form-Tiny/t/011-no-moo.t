use v5.10;
use warnings;
use Test::More;

{

	package TestForm;

	use Form::Tiny -nomoo;

	form_field 'test';

	sub new
	{
		my ($self) = @_;
		return bless {}, $self;
	}
}

my $form = TestForm->new;
$form->set_input({test => 5, unknown => 1});
ok $form->valid, 'form valid ok';
is_deeply $form->fields, {test => 5}, 'form output ok';

done_testing();
