use v5.10;
use strict;
use warnings;
use Test::More;

{
	package FieldDefinitionSubtype;

	use Moo;

	extends 'Form::Tiny::FieldDefinition';

	has 'something_else' => (
		is => 'ro',
	);
}

{
	package TestForm;

	use Form::Tiny;

	form_field (FieldDefinitionSubtype->new(
		name => 'static',
		something_else => 'here1',
	));

	form_field sub {
		FieldDefinitionSubtype->new(
			name => 'dynamic',
			something_else => 'here2',
		);
	};
}

subtest 'testing fields' => sub {
	my $obj = TestForm->new;
	my @defs = @{$obj->field_defs};

	is scalar @defs, 2, 'field definitions count ok';

	isa_ok $defs[0], 'Form::Tiny::FieldDefinition';
	is $defs[0]->name, 'static', 'first field definition name ok';
	is $defs[0]->something_else, 'here1', 'first field definition custom attribute ok';

	isa_ok $defs[1], 'Form::Tiny::FieldDefinition';
	is $defs[1]->name, 'dynamic', 'second field definition name ok';
	is $defs[1]->something_else, 'here2', 'second field definition custom attribute ok';
};


done_testing;

