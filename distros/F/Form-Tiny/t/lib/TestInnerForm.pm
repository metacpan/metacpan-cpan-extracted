package TestInnerForm;

use Moo;
use Types::Standard qw(Int);
use Form::Tiny::Error;

with qw/Form::Tiny Form::Tiny::Strict/;

sub build_fields
{
	{name => "optional"},
		{name => "int", type => Int, required => 1},;
}

1;
