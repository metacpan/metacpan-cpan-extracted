package Error::Pure::HTTP::JSON;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Output::JSON qw(err_json);
use Error::Pure::Utils qw(err_helper);
use List::Util 1.33 qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';

our $VERSION = 0.06;

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

		print "Content-type: application/json\n\n";
		print err_json(\@errors);
		return;

	# Die for eval.
	} else {
		my $e = $errors[-1]->{'msg'}->[0];
		if (! defined $e) {
			$e = 'undef';
		} else {
			chomp $e;
		}
		die "$e\n";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::HTTP::JSON - Error::Pure module for JSON output over HTTP.

=head1 SYNOPSIS

 use Error::Pure::HTTP::JSON qw(err);

 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=head2 C<err>

 err 'This is a fatal error', 'name', 'value';

Process error in JSON format with messages C<@messages> over HTTP.
Output affects C<$Error::Pure::Output::JSON::PRETTY> variable.

=head1 EXAMPLE1

=for comment filename=http_json_error.pl

 use strict;
 use warnings;

 use Error::Pure::HTTP::JSON qw(err);

 # Error.
 err '1';

 # Output like:
 # Content-type: application/json
 #
 # [{"msg":["1"],"stack":[{"sub":"err","prog":"example1.pl","args":"(1)","class":"main","line":11}]}]

=head1 EXAMPLE2

=for comment filename=http_json_error_with_options.pl

 use strict;
 use warnings;

 use Error::Pure::HTTP::JSON qw(err);

 # Error.
 err '1', '2', '3';

 # Output like:
 # Content-type: application/json
 #
 # [{"msg":["1","2","3"],"stack":[{"sub":"err","prog":"example2.pl","args":"(1, 2, 3)","class":"main","line":11}]}]

=head1 EXAMPLE3

=for comment filename=http_json_pretty.pl

 use strict;
 use warnings;

 use Error::Pure::Output::JSON;
 use Error::Pure::HTTP::JSON qw(err);

 # Pretty print.
 $Error::Pure::Output::JSON::PRETTY = 1;

 # Error.
 err '1';

 # Output like:
 # Content-type: application/json
 #
 # [
 #    {
 #       "msg" : [
 #          "1"
 #       ],
 #       "stack" : [
 #          {
 #             "sub" : "err",
 #             "prog" : "example3.pl",
 #             "args" : "(1)",
 #             "class" : "main",
 #             "line" : 15
 #          }
 #       ]
 #    }
 # ]

=head1 DEPENDENCIES

L<Error::Pure::Utils>,
L<Error::Pure::Output::JSON>,
L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-HTTP-JSON>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
