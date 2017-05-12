package Error::Pure::ANSIColor::Error;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Output::ANSIColor qw(err_line);
use Error::Pure::Utils qw(err_helper);
use List::MoreUtils qw(none);
use Readonly;
use Term::ANSIColor;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';

our $VERSION = 0.01;

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

		die err_line(@errors);

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

Error::Pure::ANSIColor::Error - Error::Pure module with error on one line with informations.

=head1 SYNOPSIS

 use Error::Pure::ANSIColor::Error qw(err);
 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=over 8

=item B<err(@messages)>

 Process error with messages @messages.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Error::Pure::ANSIColor::Error qw(err);

 # Error.
 err '1';

 # Output:
 # #Error [example1.pl:9] 1

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Error::Pure::ANSIColor::Error qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # #Error [example2.pl:9] 1

=head1 DEPENDENCIES

L<Error::Pure::Output::ANSIColor>,
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

L<https://github.com/tupinek/Error-Pure-ANSIColor>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2013-2017 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.01

=cut
