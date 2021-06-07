package GrandparentForm;

# a complicated strict form with no required fields

use Form::Tiny -base;

form_field 'field1';

form_hook cleanup => sub { };

1;
