package Error::Pure::HTTP::Error;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Utils qw(err_helper);
use Error::Pure::Output::Text qw(err_line);
use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';

# Version.
our $VERSION = 0.16;

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
		&& none { $_ eq $EVAL || $_ =~ m/^eval '/ms }
		map { $_->{'sub'} } @{$stack_ar}) {

		print "Content-type: text/plain\n\n";
		print err_line(@errors);
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
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::HTTP::Error - Error::Pure module with error on one line over HTTP.

=head1 SYNOPSIS

 use Error::Pure::HTTP::Error qw(err);

 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=over 8

=item B<err(@messages)>

 Process error with messages @messages.

=back

=head1 EXAMPLE1

=for comment filename=error.pl

 use strict;
 use warnings;

 use Error::Pure::HTTP::Error qw(err);

 # Error.
 err '1';

 # Output like this:
 # Content-type: text/plain
 #
 # #Error [script.pl:12] 1

=head1 EXAMPLE2

=for comment filename=error_with_arguments.pl

 use strict;
 use warnings;

 use Error::Pure::HTTP::Error qw(err);

 # Error.
 err '1', '2', '3';

 # Output like this:
 # Content-type: text/plain
 #
 # #Error [script.pl:12] 1

=head1 DEPENDENCIES

L<Error::Pure::Utils>,
L<Error::Pure::Output::Text>,
L<Exporter>,
L<List::MoreUtils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-HTTP>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2012-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.16

=cut
