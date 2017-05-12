package Error::Pure::Print;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use Error::Pure::Output::Text qw(err_print);
use Error::Pure::Utils qw(err_helper);
use List::MoreUtils qw(none);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $EVAL => 'eval {...}';

# Version.
our $VERSION = 0.24;

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

		die err_print(@errors)."\n";

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

Error::Pure::Print - Error::Pure module for simple error print.

=head1 SYNOPSIS

 use Error::Pure::Print qw(err);
 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=over 8

=item C<err(@messages)>

 Process error with messages @messages.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Print qw(err);

 # Error.
 err '1';

 # Output:
 # 1

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Print qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # 1

=head1 EXAMPLE3

 package Example3;
 
 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Print qw(err);

 # Test with error.
 sub test {
         err '1', '2', '3';
 };

 package main;

 # Pragmas.
 use strict;
 use warnings;

 # Run.
 Example3::test();

 # Output:
 # Example3: 1

=head1 DEPENDENCIES

L<Error::Pure::Output::Text>,
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

L<https://github.com/tupinek/Error-Pure>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2008-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.24

=cut
