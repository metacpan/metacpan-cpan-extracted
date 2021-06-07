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

	form_field sub {
		my ($self) = @_;

		return {
			name => 'number',
			type => Int,
			required => $self->number_required,
		};
	};

	form_cleaner sub {
		my ($self, $data) = @_;

		$data->{name} .= ($data->{number} // '-');
	};

	form_hook cleanup => sub {
		my ($self, $data) = @_;

		$data->{name} .= '!';
	};

	form_filter Int, sub {
		abs shift;
	};
}

my $form = TestForm->new;

is scalar @{$form->form_meta->fields}, 2, 'field defs ok';
is scalar @{$form->form_meta->filters}, 1, 'field filters ok';
is scalar @{$form->form_meta->hooks->{cleanup}}, 2, 'form cleaners ok';

my @data = (
	[1, {name => ' test', number => -3}, {name => ' test3!', number => 3}],
	[0, {name => ' test', number => '-test-'}],
);

for my $aref (@data) {
	$form->set_input($aref->[1]);
	is !!$form->valid, !!$aref->[0], 'validation ok';
	if ($aref->[0]) {
		is_deeply $form->fields, $aref->[2], "default value ok";
	}
}

done_testing();
