package TestForm;

# a complicated strict form with no required fields

use Moo;
use Types::Standard qw(Int Num Str Undef Bool);
use Types::Common::String qw(SimpleStr);
use Form::Tiny::Error;
use TestInnerForm;

with qw/Form::Tiny Form::Tiny::Strict/;

sub build_fields
{
	(
		{name => "no_type"},
		{
			name => "sub_coerced",
			coerce => sub { shift() // 'undef' }
		},
		{name => "int", type => Int->where(q{$_ >= 0})},
		{name => "int_coerced", type => Int->plus_coercions(Num, q{ int($_) }), coerce => 1},
		{name => "str", type => SimpleStr},
		{
			name => "str_adjusted",
			type => Str,
			adjust => sub { ">>" . shift }
		},
		{name => "bool_cleaned", type => Bool},
		{name => "nested.name"},
		{name => "nested.second.name"},
		{name => "not\\.nested"},
		{name => "nested_form", type => TestInnerForm->new},
		{
			name => "nested_form_unadjusted",
			type => TestInnerForm->new,
			adjust => sub { @_ }
		},
		{name => "array.*.name"},
		{name => "array.*.second.*.name"},
		{name => "marray.*.*", type => Int},
	)
}

sub build_cleaner
{
	my ($self) = @_;

	return sub {
		my ($self, $data) = @_;

		if (exists $data->{bool_cleaned}) {
			$self->add_error(
				Form::Tiny::Error->new(field => "bool_cleaned", error => "bool needs to be true")
			) unless $data->{bool_cleaned};
			$data->{bool_cleaned} = "Yes";
		}
	};
}

1;
