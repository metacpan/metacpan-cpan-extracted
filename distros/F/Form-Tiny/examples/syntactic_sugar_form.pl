use v5.10;
use warnings;
use Test::More;
use Data::Dumper;

{

	package PrettyRegistationForm;
	use Form::Tiny -base;
	use Types::Standard qw(Enum);
	use Types::Common::Numeric qw(IntRange);
	use Types::Common::String qw(SimpleStr StrongPassword StrLength);
	use Form::Tiny::Error;

	my %password = (
		type => StrongPassword,
		required => 1,
	);

	form_field "username" => (
		type => SimpleStr & StrLength [4, 30],
		required => 1,
		adjust => sub { ucfirst shift },
	);

	form_field "password" => (
		%password,
	);

	form_field "repeat_password" => (
		%password,
	);

	# can be a full date with Types::DateTime
	form_field "year_of_birth" => (
		type => IntRange [1900, 1900 + (localtime)[5]],
		required => 1,
	);

	form_field "sex" => (
		type => Enum ["male", "female", "other"],
		required => 1,
	);

	form_cleaner sub {
		my ($self, $data) = @_;

		$self->add_error(
			Form::Tiny::Error::DoesNotValidate->new(
				error => "passwords are not identical"
			)
		) if $data->{password} ne $data->{repeat_password};
	};

	1;
}

my $form = PrettyRegistationForm->new(
	input => {
		username => "perl",
		password => "meperl-5",
		repeat_password => "meperl-5",
		year_of_birth => 1987,
		sex => "other",
	}
);

ok($form->valid, "Registration successful");

if (!$form->valid) {
	note Dumper($form->errors);
}

$form->set_input(
	{
		%{$form->input},
		repeat_password => "eperl-55",
	}
);

ok(!$form->valid, "passwords do not match");

note Dumper($form->errors);

done_testing();
