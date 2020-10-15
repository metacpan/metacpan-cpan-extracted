package Error::Pure::NoDie;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Utils qw(err_helper);
use List::MoreUtils qw(none);
use Readonly;

our $VERSION = 0.05;

Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $EVAL => 'eval {...}';

# Ignore die signal.
$SIG{__DIE__} = 'IGNORE';

# Process error.
sub err {
	my @msg = @_;

	# Get errors structure.
	my @errors = err_helper(@msg);

	# Error messages.
	chomp $errors[-1]->{'msg'}->[0];

	# Finalize in main on last err.
	my $stack_ar = $errors[-1]->{'stack'};
	if ($stack_ar->[-1]->{'class'} eq 'main'
		&& none { $_ eq $EVAL || $_ =~ /^eval '/ms }
		map { $_->{'sub'} } @{$stack_ar}) {

		print join $EMPTY_STR, @{$errors[-1]->{'msg'}}, "\n";

	# Die for eval.
	} else {
		my $e = $errors[-1]->{'msg'}->[0];
		die "$e\n";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::NoDie - Error::Pure module for simple print instead die.

=head1 SYNOPSIS

 use Error::Pure::NoDie qw(err);

 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=head2 C<err>

 err 'This is a fatal error', 'name', 'value';

Process error with messages @messages.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Error::Pure::NoDie qw(err);

 # Error.
 err '1';

 # Output:
 # 1

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Error::Pure::NoDie qw(err);

 # Error.
 err '1';
 err '2';

 # Output:
 # 1
 # 2

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Error::Pure::NoDie qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # 1

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Dumpvalue;
 use Error::Pure::NoDie qw(err);
 use Error::Pure::Utils qw(err_get);

 # Error in eval.
 eval { err '1', '2', '3'; };

 # Error structure.
 my @err = err_get();

 # Dump.
 my $dump = Dumpvalue->new;
 $dump->dumpValues(\@err);

 # In \@err:
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

L<Exporter>,
L<List::MoreUtils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-NoDie>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>

http://skim.cz

=head1 LICENSE AND COPYRIGHT

© 2011-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
