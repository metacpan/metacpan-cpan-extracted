package Error::Pure::ANSIColor::Die;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Output::ANSIColor qw(err_die);
use Error::Pure::Utils qw(err_helper);
use List::MoreUtils qw(none);
use Readonly;

our $VERSION = 0.27;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EVAL => 'eval {...}';
Readonly::Scalar my $EMPTY_STR => q{};

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

		die err_die(@errors)."\n";

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

Error::Pure::ANSIColor::Die - Error::Pure module with classic die.

=head1 SYNOPSIS

 use Error::Pure::ANSIColor::Die qw(err);
 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=over 8

=item B<err(@messages)>

 Process error with messages @messages.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Error::Pure::ANSIColor::Die qw(err);

 # Error.
 err '1';

 # Output:
 # 1 at example1.pl line 9.

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Error::Pure::ANSIColor::Die qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # 1 at example2.pl line 9.

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Dumpvalue;
 use Error::Pure::ANSIColor::Die qw(err);
 use Error::Pure::Utils qw(err_get);

 # Error in eval.
 eval { err '1', '2', '3'; };

 # Error structure.
 my $err_ar = err_get();

 # Dump.
 my $dump = Dumpvalue->new;
 $dump->dumpValues($err_ar);

 # In $err_ar:
 # [
 #         {
 #                 'msg' => [
 #                         '1',
 #                         '2',
 #                         '3',
 #                 ],
 #                 'stack' => [
 #                         {
 #                                 'args' => '(1)',
 #                                 'class' => 'main',
 #                                 'line' => '9',
 #                                 'prog' => 'script.pl',
 #                                 'sub' => 'err',
 #                         },
 #                         {
 #                                 'args' => '',
 #                                 'class' => 'main',
 #                                 'line' => '9',
 #                                 'prog' => 'script.pl',
 #                                 'sub' => 'eval {...}',
 #                         },
 #                 ],
 #         },
 # ],

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

L<https://github.com/michal-josef-spacek/Error-Pure-ANSIColor>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.27

=cut
