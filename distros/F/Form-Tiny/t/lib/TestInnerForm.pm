package TestInnerForm;

use Form::Tiny -strict;
use Types::Standard qw(Int);

form_field "optional";
form_field "int" => (
	type => Int,
	required => 1
);

1;
