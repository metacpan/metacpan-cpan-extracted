use v5.10;
use warnings;
use Test::More;
use Types::Standard qw(Int);
use Form::Tiny::Inline;

my $form = Form::Tiny::Inline->is(qw(Strict))->new(
	field_defs => [{name => "test", type => Int, required => 1}],
);

my @data = (
	[[], "Form::Tiny::Error::InvalidFormat"],
	[{}, "Form::Tiny::Error::DoesNotExist"],
	[{test => 1.5}, "Form::Tiny::Error::DoesNotValidate"],
	[{test => 1, more => 1}, "Form::Tiny::Error::IsntStrict"],
);

for my $aref (@data) {
	$form->set_input($aref->[0]);
	ok !$form->valid, "an error occurs (as expected)";
	my @errors = @{$form->errors};
	is scalar @errors, 1, "a single error is present";
	isa_ok $errors[0], $aref->[1], "error type matches";
}
done_testing();
