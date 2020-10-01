use v5.10; use warnings;
use Test::More;

BEGIN { use_ok('Form::Tiny') }

{

	package TestForm;
	use Moo;

	with "Form::Tiny";

	sub build_fields
	{
		(
			{name => "name"},
			{name => "value"}
		)
	}

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
