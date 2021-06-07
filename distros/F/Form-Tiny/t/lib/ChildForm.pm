package ChildForm;

# a complicated strict form with no required fields

use Form::Tiny -filtered;

extends 'ParentForm';

form_field 'field3';

1;
