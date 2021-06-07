package ParentForm;

# a complicated strict form with no required fields

use Form::Tiny -filtered;
use Types::Standard qw(Int);

extends 'GrandparentForm';

form_field 'field2';

form_hook cleanup => sub { };
form_trim_strings;
form_filter Int, sub { };

1;
