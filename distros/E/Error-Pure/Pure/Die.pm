package Error::Pure::Die;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure::Utils qw(err_helper);
use List::Util qw(none);
use Readonly;

our $VERSION = 0.31;

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

		my $die = (join $EMPTY_STR, @{$errors[-1]->{'msg'}}).
			" at $stack_ar->[0]->{'prog'} line ".
			"$stack_ar->[0]->{'line'}.";
		die "$die\n";

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

Error::Pure::Die - Error::Pure module with classic die.

=head1 SYNOPSIS

 use Error::Pure::Die qw(err);

 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=head2 C<err>

 err 'This is a fatal error', 'name', 'value';

Process error with message(s). There is key => value list after first message.

=head1 EXAMPLE1

=for comment filename=err_via_die.pl

 use strict;
 use warnings;

 use Error::Pure::Die qw(err);

 # Error.
 err '1';

 # Output:
 # 1 at example1.pl line 9.

=head1 EXAMPLE2

=for comment filename=err_via_die_with_params.pl

 use strict;
 use warnings;

 use Error::Pure::Die qw(err);

 # Error.
 err '1', '2', '3';

 # Output:
 # 1 at example2.pl line 9.

=head1 EXAMPLE3

=for comment filename=err_via_die_with_params_in_eval_and_dump.pl

 use strict;
 use warnings;

 use Dumpvalue;
 use Error::Pure::Die qw(err);
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

© 2008-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.31

=cut
