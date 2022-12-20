use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Exception;

{

	package ParentForm;

	use Form::Tiny;
	form_field 'inherited_field';
}

{

	package ChildForm;

	use Form::Tiny;
	extends 'ParentForm';
}

{

	package ChildFormFixed;

	use Form::Tiny;
	extends 'ParentForm';

	__PACKAGE__->form_meta;
}

{

	package EmptyForm;

	use Form::Tiny;
}

{

	package EmptyFormFixed;

	use Form::Tiny;

	__PACKAGE__->form_meta;
}

throws_ok {
	ChildForm->new->field_defs;
} qr/Form ChildForm seems to be empty/;

throws_ok {
	EmptyForm->new->form_meta;
} qr/Form EmptyForm seems to be empty/;

# this dies because the form role was not yet merged
dies_ok {
	EmptyForm->new->field_defs;
} 'empty form dies on field_defs without inheritance';

lives_ok {
	ChildFormFixed->new->field_defs;
} 'empty form with inheritance and explicit form_meta ok';

lives_ok {
	EmptyFormFixed->new->field_defs;
} 'empty form without inheritance and explicit form_meta ok';

done_testing;

