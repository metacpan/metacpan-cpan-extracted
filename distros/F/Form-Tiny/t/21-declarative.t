use v5.10;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -strict, -filtered;
	use Types::Standard qw(Str Int);

	has 'number_required' => (
		is => 'ro',
		default => sub { 1 },
	);

	form_field 'name' => (
		type => Str,
		required => 1,
	);

	form_field 'number' => sub {
		my ($self) = @_;

		return {
			type => Int,
			required => $self->number_required,
		};
	};

	form_cleaner sub {
		my ($self, $data) = @_;

		$data->{name} .= ($data->{number} // '-');
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

my @data = (
	[1, {name => ' test', number => -3}, {name => 'test3', number => 3}],
	[0, {name => ' test', number => 'test-'}],
);

for my $aref (@data) {
	$form->set_input($aref->[1]);
	is !!$form->valid, !!$aref->[0], 'validation ok';
	if ($aref->[0]) {
		is_deeply $form->fields, $aref->[2], "default value ok";
	}
}

done_testing();
