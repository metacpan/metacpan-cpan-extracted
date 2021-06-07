use v5.10;
use warnings;

{

	package PrettyRegistationForm;
	use Form::Tiny;
	use Types::Standard qw(Enum);
	use Types::Common::Numeric qw(IntRange);
	use Types::Common::String qw(SimpleStr StrongPassword StrLength);

	my %password = (
		type => StrongPassword,
		required => 1,
	);

	form_field "username" => (
		type => SimpleStr & StrLength [4, 30],
		required => 1,
		adjust => sub { ucfirst shift },
	);

	form_field "password" => %password;
	form_field "repeat_password" => %password;

	# can be a full date with Types::DateTime
	form_field "year_of_birth" => (
		type => IntRange [1900, 1900 + (localtime)[5]],
		required => 1,
	);

	form_field "sex" => (
		type => Enum [qw(male female other)],
		required => 1,
	);

	form_cleaner sub {
		my ($self, $data) = @_;

		$self->add_error("passwords are not identical")
			if $data->{password} ne $data->{repeat_password};
	};

	1;
}
