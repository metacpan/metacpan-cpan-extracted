use v5.10;
use warnings;
use Test::More;
use Form::Tiny::Inline;
use Test::Exception;
use Types::Standard qw(CodeRef);

{

	package TestForm;
	use Form::Tiny -base;
	use Types::Common::String qw(LowerCaseStr);
	use Types::Standard qw(Int Str Num);

	form_field "string" => (
		type => LowerCaseStr->plus_coercions(Str, q{ lc $_ }),
		coerce => 1,
	);

	form_field "integer" => (
		type => Int->plus_coercions(Num, q{ int($_) }),
		coerce => 1,
	);

	form_field "err" => (
		type => Int->plus_coercions(Str, q{ 1/0 }),
		coerce => 1,
	);

	1;
}

my @data = (
	[1, {string => "UPPERCASE", integer => 8.5}],
	[1, {string => "Expr: 2 + 3", integer => -0xf3}],
	[1, {err => 5}],
	[0, {integer => "not an integer"}],
	[0, {integer => "1not an integer"}],
	[0, {string => undef}],
	[0, {err => 'aoeu'}],
);

for my $aref (@data) {
	my ($result, $input) = @$aref;
	my $form = TestForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";

	for my $field (keys %$input) {
		is defined $form->input->{$field}, defined $input->{$field}, "definedness for `$field` ok";
		is $form->input->{$field}, $input->{$field}, "raw value for `$field` ok";
		if ($form->valid) {
			my $wanted_field = $field eq "string" ? lc $input->{$field} : int($input->{$field});
			is $form->fields->{$field}, $wanted_field, "coerced value for `$field` ok";
			note $wanted_field;
		}
	}

	if (!$form->valid) {
		for my $error (@{$form->errors}) {
			isa_ok($error, "Form::Tiny::Error::DoesNotValidate");
		}
	}
}

for my $type (undef, CodeRef) {
	dies_ok {
		Form::Tiny::Inline->new(
			field_defs => [
				{
					name => 'test',
					(defined $type ? (type => $type) : ()),
					coerce => 1,
				}
			],
		);
	}
	"invalid coerce configuration dies";
}

done_testing();
