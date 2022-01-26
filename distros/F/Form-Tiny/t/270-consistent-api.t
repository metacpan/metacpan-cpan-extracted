use v5.10;
use strict;
use warnings;
use Test::More;

my $tester = sub {
	my ($stage) = @_;

	return sub {
		my ($self, $value) = @_;

		note "testing $stage";
		is scalar @_, 2;
		isa_ok $self, 'TestForm';
		is $value, 'value';

		return $value;
	};
};

{

	package TestForm;
	use Form::Tiny -filtered;
	use Types::Standard qw(Str);

	form_trim_strings;
	form_filter Str, $tester->('global filter');

	form_field 'val' => (
		coerce => $tester->('coercing'),
		adjust => $tester->('adjusting'),
	);

	field_filter Str, $tester->('local filter');
	field_validator 'testing' => $tester->('validator');
}

my $form = TestForm->new;
$form->set_input({val => 'value'});
ok $form->valid, 'validation ok';

done_testing 16;
