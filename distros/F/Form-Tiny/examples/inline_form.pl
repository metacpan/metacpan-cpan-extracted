use v5.10; use warnings;
use Test::More;
use Form::Tiny::Inline;
use Types::Common::String qw(SimpleStr);
use Form::Tiny::Error;

my $form = Form::Tiny::Inline->new(
	is => [qw(Strict)],

	field_defs => [
		{
			name => "input_file",
			type => SimpleStr,
			required => 1,
		},
		{
			name => "output_file",
			type => SimpleStr,
		},
	],

	cleaner => sub {
		my ($self, $data) = @_;

		$self->add_error(
			Form::Tiny::Error::DoesNotValidate->new(error => "input and output is the same file")
		) if $data->{output_file} && $data->{input_file} eq $data->{output_file};
	},
);

$form->set_input({
		input_file => "/home/user/test",
		output_file => "/home/user/test_out",
	}
);

ok($form->valid, "The form has been validated successfully");

done_testing();
