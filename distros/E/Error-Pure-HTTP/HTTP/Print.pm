package Error::Pure::HTTP::Print;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Utils qw(err_helper);
use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $EVAL => 'eval {...}';

# Version.
our $VERSION = 0.15;

# Ignore die signal.
$SIG{__DIE__} = 'IGNORE';

# Process error.
sub err {
	my @msg = @_;

	# Get errors structure.
	my @errors = err_helper(@msg);

	# Error message.
	my $e = $errors[-1]->{'msg'}->[0];
	if (! defined $e) {
		$e = 'undef';
	} else {
		chomp $e;
	}

	# Finalize in main on last err.
	my $stack_ar = $errors[-1]->{'stack'};
	if ($stack_ar->[-1]->{'class'} eq 'main'
		&& none { $_ eq $EVAL || $_ =~ /^eval '/ms }
		map { $_->{'sub'} } @{$stack_ar}) {

		my $class = $errors[-1]->{'stack'}->[0]->{'class'};
		if ($class eq 'main') {
			$class = $EMPTY_STR
		}
		if ($class) {
			$class .= ': ';
		}
		print "Content-type: text/plain\n\n";
		print $class."$e\n";
		return;

	# Die for eval.
	} else {
		die "$e\n";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::HTTP::Print - Error::Pure module for simple error print over HTTP.

=head1 SYNOPSIS

 use Error::Pure::HTTP::Print qw(err);
 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=over 8

=item B<err(@messages)>

 Process error with messages @messages.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Error::Pure::HTTP::Print qw(err);

 # Error.
 err '1';

 # Output:
 # Content-type: text/plain
 #
 # 1

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Error::Pure::HTTP::Print qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # Content-type: text/plain
 #
 # 1

=head1 DEPENDENCIES

L<Error::Pure::Utils>,
L<Exporter>,
L<List::MoreUtils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Error-Pure-HTTP>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2012-2018 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.15

=cut
