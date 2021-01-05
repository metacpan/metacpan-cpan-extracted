use v5.10;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -strict, -filtered;
	use Types::Standard qw(Str Int);

	form_field 'name' => (
		type => Str,
		required => 1,
	);

	form_field 'number' => (
		type => Int,
		required => 1,
	);

	form_cleaner sub {
		my ($self, $data) = @_;

		$data->{name} .= $data->{number};
	};

	form_filter Int, sub {
		abs shift;
	};
}

{

	package BaseTestForm;
	use Form::Tiny -base;

	form_field 'test';

}

my $form_base = BaseTestForm->new;
ok $form_base->DOES('Form::Tiny'), 'base role ok';
ok !$form_base->DOES('Form::Tiny::Strict'), 'strict role ok';
ok !$form_base->DOES('Form::Tiny::Filtered'), 'filtered role ok';

my $form = TestForm->new;
ok $form->DOES('Form::Tiny'), 'base role ok';
ok $form->DOES('Form::Tiny::Strict'), 'strict role ok';
ok $form->DOES('Form::Tiny::Filtered'), 'filtered role ok';

is scalar @{$form->field_defs}, 2, 'field defs ok';
is scalar @{$form->filters}, 2, 'field filters ok';
isa_ok $form->cleaner, 'CODE';

$form->set_input(
	{
		'name' => ' test',
		'number' => -3,
	}
);

ok $form->valid, 'validation ok';

if ($form->valid) {
	is $form->fields->{name}, 'test3', 'form name ok';
	is $form->fields->{number}, 3, 'form number ok';
}

done_testing();
