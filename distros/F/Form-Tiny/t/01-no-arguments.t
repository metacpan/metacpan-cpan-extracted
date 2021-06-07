use v5.10;
use warnings;
use Test::More;

BEGIN { require_ok('Form::Tiny') }

{

	package TestForm;
	use Form::Tiny;

	form_field 'name';
	form_field 'value';

	1;
}

my @data = (
	[{},],
	[{name => "me"},],
	[{name => "you", value => "empty"},],
	[{value => "something"},],
	[{more => "more"}, {"more" => 1}],
	[{name => undef},],
);

for my $aref (@data) {
	my ($input, $ignore) = @$aref;
	my $form = TestForm->new(input => $input);
	ok $form->valid, "validation output ok";
	for my $field (keys %$input) {
		if (!defined $ignore || !$ignore->{$field}) {
			is defined $form->fields->{$field}, defined $input->{$field},
				"definedness for `$field` ok";
			is $form->fields->{$field}, $input->{$field}, "value for `$field` ok";
		}
	}
}

done_testing();
