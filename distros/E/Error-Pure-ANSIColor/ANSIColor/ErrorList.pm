package Error::Pure::ANSIColor::ErrorList;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Utils qw(err_helper);
use Error::Pure::Output::ANSIColor qw(err_line_all);
use List::Util qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';

our $VERSION = 0.29;

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

		die err_line_all(@errors);

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

Error::Pure::ANSIColor::ErrorList - Error::Pure module with list of errors in one line
with informations.

=head1 SYNOPSIS

 use Error::Pure::ANSIColor::ErrorList qw(err);

 err "This is a fatal error.", "name", "value";

 # __or__

 use Error::Pure qw(err);

 $ENV{'ERROR_PURE_TYPE'} = 'ANSIColor::ErrorList';

 err "This is a fatal error.", "name", "value";

=head1 SUBROUTINES

=head2 B<err>

 err 'This is a fatal error', 'name', 'value';

Process error with messages (error, error_key/value pairs).

=head1 EXAMPLE1

=for comment filename=err_via_ansicolor_error_list.pl

 use strict;
 use warnings;

 use Error::Pure::ANSIColor::ErrorList qw(err);

 # Error.
 err '1';

 # Output:
 # #Error [example1.pl:9] 1

=head1 EXAMPLE2

=for comment filename=err_via_ansicolor_error_list_with_params.pl

 use strict;
 use warnings;

 use Error::Pure::ANSIColor::ErrorList qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # #Error [example2.pl:9] 1

=head1 EXAMPLE3

=for comment filename=err_via_ansicolor_error_list_in_eval_plus_err.pl

 use strict;
 use warnings;

 use English qw(-no_match_vars);
 use Error::Pure::ANSIColor::ErrorList qw(err);

 # Error.
 eval { err "1"; };
 if ($EVAL_ERROR) {
        err "2";
 }

 # Output:
 # #Error [example3.pl:10] 1
 # #Error [example3.pl:11] 2

=head1 DEPENDENCIES

L<Error::Pure::Utils>,
L<Error::Pure::Output::Text>,
L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-ANSIColor>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.29

=cut
