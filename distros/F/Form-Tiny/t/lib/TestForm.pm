package TestForm;

# a complicated strict form with no required fields

use Form::Tiny -strict;
use Types::Standard qw(Int Num Str Undef Bool);
use Types::Common::String qw(SimpleStr);
use TestInnerForm;

form_field "no_type";
form_field "sub_coerced" => (
	coerce => sub { pop() // 'undef' }
);
form_field "int" => (type => Int->where(q{$_ >= 0}));
form_field "int_coerced" => (type => Int->plus_coercions(Num, q{ int($_) }), coerce => 1);
form_field "str" => (type => SimpleStr);
form_field "str_adjusted" => (
	type => Str,
	adjust => sub { ">>" . pop }
);
form_field "bool_cleaned" => (type => Bool);
form_field "nested.name";
form_field "nested.second.name";
form_field "not\\.nested";
form_field "is\\\\.nested";
form_field "not\\\\\\.nested";
form_field "not.\\*.nested_array";
form_field "nested_form" => (type => TestInnerForm->new);
form_field "nested_form_unadjusted" => (
	type => TestInnerForm->new,
	adjust => sub { pop }
);
form_field "array.*.name";
form_field "array.*.second.*.name";
form_field "marray.*.*" => (type => Int);

form_cleaner sub {
	my ($self, $data) = @_;

	if (exists $data->{bool_cleaned}) {
		$self->add_error(
			Form::Tiny::Error->new(field => "bool_cleaned", error => "bool needs to be true")
		) unless $data->{bool_cleaned};
		$data->{bool_cleaned} = "Yes";
	}
};

1;
