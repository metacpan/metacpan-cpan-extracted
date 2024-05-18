package Error::Pure::AllError;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Utils qw(err_helper);
use Error::Pure::Output::Text qw(err_bt_pretty);
use List::Util qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';

our $VERSION = 0.34;

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

		die scalar err_bt_pretty(@errors);

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

Error::Pure::AllError - Error::Pure module with full backtrace.

=head1 SYNOPSIS

 use Error::Pure::AllError qw(err);

 err "This is a fatal error.", "name", "value";

=head1 SUBROUTINES

=head2 C<err>

 err "This is a fatal error.", "name", "value";

Process error with message(s). There is key => value list after first message.

=head1 EXAMPLE

=for comment filename=err_via_all_error.pl

 use strict;
 use warnings;

 use Error::Pure::AllError qw(err);

 print "1\n";
 err "This is a fatal error.", "name", "value";
 print "2\n";

 # Output:
 # 1
 # ERROR: This is a fatal error.
 # name: value
 # main  err  ./script.pl  12

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

L<https://github.com/michal-josef-spacek/Error-Pure>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2008-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.34

=cut
