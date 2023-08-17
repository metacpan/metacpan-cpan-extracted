package Error::Pure::JSON::Advance;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Output::JSON qw(err_json);
use Error::Pure::Utils qw(err_helper);
use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';

our $VERSION = 0.08;

# Global variables.
our %ERR_PARAMETERS;

# Ignore die signal.
$SIG{__DIE__} = 'IGNORE';

# Process error.
sub err {
	my @msg = @_;

	# Get errors structure.
	my @errors = err_helper(@msg);

	# Finalize in main on last err.
	my $stack_ar = $errors[-1]->{'stack'};
	if ($stack_ar->[-1]->{'class'} eq 'main'
		&& none { $_ eq $EVAL || $_ =~ /^eval '/ms }
		map { $_->{'sub'} } @{$stack_ar}) {

		my $err_hr = {
			'error-pure' => \@errors,
		};
		foreach my $key (keys %ERR_PARAMETERS) {
			$err_hr->{$key} = $ERR_PARAMETERS{$key};
		}
		die err_json($err_hr)."\n";

	# Die for eval.
	} else {
		die "$errors[-1]->{'msg'}->[0]\n";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::JSON::Advance - Error::Pure module for JSON output with additional parameters.

=head1 SYNOPSIS

 use Error::Pure::JSON::Advance qw(err);
 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=over 8

=item C<err(@messages)>

 Process error in JSON format with messages @messages.
 Output affects $Error::Pure::Output::JSON::PRETTY variable.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Error::Pure::JSON::Advance qw(err);

 # Additional parameters.
 %Error::Pure::JSON::Advance::ERR_PARAMETERS = (
         'status' => 1,
         'message' => 'Foo bar',
 );

 # Error.
 err '1';

 # Output like:
 # {"status":1,"error-pure":[{"msg":["1"],"stack":[{"sub":"err","prog":"example1.pl","args":"(1)","class":"main","line":17}]}],"message":"Foo bar"}

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Error::Pure::JSON::Advance qw(err);

 # Additional parameters.
 %Error::Pure::JSON::Advance::ERR_PARAMETERS = (
         'status' => 1,
         'message' => 'Foo bar',
 );

 # Error.
 err '1', '2', '3';

 # Output like:
 # {"status":1,"error-pure":[{"msg":["1","2","3"],"stack":[{"sub":"err","prog":"example2.pl","args":"(1, 2, 3)","class":"main","line":17}]}],"message":"Foo bar"}

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Error::Pure::Output::JSON;
 use Error::Pure::JSON::Advance qw(err);

 # Additional parameters.
 %Error::Pure::JSON::Advance::ERR_PARAMETERS = (
         'status' => 1,
         'message' => 'Foo bar',
 );

 # Pretty print.
 $Error::Pure::Output::JSON::PRETTY = 1;

 # Error.
 err '1';

 # Output like:
 # {
 #    "status" : 1,
 #    "error-pure" : [
 #       {
 #          "msg" : [
 #             "1"
 #          ],
 #          "stack" : [
 #             {
 #                "sub" : "err",
 #                "prog" : "example3.pl",
 #                "args" : "(1)",
 #                "class" : "main",
 #                "line" : 21
 #             }
 #          ]
 #       }
 #    ],
 #    "message" : "Foo bar"
 # }

=head1 DEPENDENCIES

L<Error::Pure::Utils>,
L<Error::Pure::Output::JSON>,
L<Exporter>,
L<List::MoreUtils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-JSON>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
