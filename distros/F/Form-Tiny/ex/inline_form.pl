use v5.10;
use strict;
use warnings;
use Form::Tiny::Inline;
use Types::Common::String qw(SimpleStr);

my $form = Form::Tiny::Inline->is(qw/strict/)->new(
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

		$self->add_error("input and output is the same file")
			if $data->{output_file} && $data->{input_file} eq $data->{output_file};
	},
);

$form->set_input(
	{
		input_file => "/home/user/test",
		output_file => "/home/user/test_out",
	}
);

if ($form->valid) {
	print "Yes, it works\n";
}

# just for testing
$form;
