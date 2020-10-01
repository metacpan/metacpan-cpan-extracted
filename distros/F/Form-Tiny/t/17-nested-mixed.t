use v5.10; use warnings;
use Test::More;
use Data::Dumper;
use Form::Tiny;

{

	package InnerForm;
	use Moo;
	use Types::Standard qw(Undef);
	use Types::Common::String qw(SimpleStr);

	with "Form::Tiny";

	sub build_fields
	{
		(
			{
				name => "nested",
				type => SimpleStr->plus_coercions(Undef, q{ '' }),
				coerce => 1,
				required => "soft",
			},
		);
	}

	1;
}

{

	package OuterForm;
	use Moo;

	with "Form::Tiny";

	sub build_fields
	{
		{name => "form.inner", type => InnerForm->new},
			{name => "form.inner.something"},;
	}
}

my @data = (
	[1, {form => {inner => {nested => "asdf"}}}],
	[1, {form => {inner => {nested => undef, something => "aa"}}}],
	[0, {form => {inner => {something => "aa"}}}],
);

for my $aref (@data) {
	my ($result, $input) = @$aref;
	my $form = OuterForm->new(input => $input);
	is !!$form->valid, !!$result, "validation output ok";
	note Dumper($input);
	note Dumper($form->errors);
}

done_testing();
