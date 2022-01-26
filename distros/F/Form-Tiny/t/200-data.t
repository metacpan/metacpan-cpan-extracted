use v5.10;
use strict;
use warnings;
use Test::More;

{

	package TestForm;
	use Form::Tiny -base;

	form_field 'with_data' => (
		data => "data ok"
	);
}

my $form = TestForm->new;
is scalar @{$form->field_defs}, 1, "field defs ok";
ok $form->field_defs->[0]->has_data, "data ok";
is $form->field_defs->[0]->data, "data ok", "data ok";

done_testing();
