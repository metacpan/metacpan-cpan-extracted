use v5.10;
use strict;
use warnings;
use Test::More;
use Form::Tiny::Inline;

my @valid_data_hard = (
	{arg => "test"},
	{arg => 5},
	{arg => "0"},
	{arg => []},
);

my @valid_data_soft = (
	{arg => ""},
	{arg => undef},
);

my @invalid_data = (
	{},
	{argx => 33},
);

my @test_data = (
	[{name => "arg", required => 1}, [@valid_data_hard], [@valid_data_soft, @invalid_data]],
	[{name => "arg", required => "hard"}, [@valid_data_hard], [@valid_data_soft, @invalid_data]],
	[{name => "arg", required => "soft"}, [@valid_data_hard, @valid_data_soft], [@invalid_data]],
	[{name => "arg", required => 0}, [@valid_data_hard, @valid_data_soft, @invalid_data], []],
);

for my $case (@test_data) {
	my ($defs, $valid, $invalid) = @$case;
	for my $case_type ([1, @$valid], [0, @$invalid]) {
		my $result = shift @$case_type;
		for my $case_data (@$case_type) {
			my $form = Form::Tiny::Inline->new(
				field_defs => [$defs],
				input => $case_data,
			);
			is !!$form->valid, !!$result, "validation output ok";
			for my $error (@{$form->errors}) {
				isa_ok($error, "Form::Tiny::Error::DoesNotExist");
			}
		}
	}
}

done_testing();
