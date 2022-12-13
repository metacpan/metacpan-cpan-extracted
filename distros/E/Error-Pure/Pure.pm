package Error::Pure;

use base qw(Exporter);
use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw();
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err);
Readonly::Scalar my $TYPE_DEFAULT => 'Die';
Readonly::Scalar my $LEVEL_DEFAULT => 4;

our $VERSION = 0.28;

# Type of error.
our $TYPE;

# Level for this class.
our $LEVEL = $LEVEL_DEFAULT;

# Process error.
sub err {
	my @msg = @_;
	$Error::Pure::Utils::LEVEL = $LEVEL;
	my $class;
	if (defined $TYPE) {
		$class = 'Error::Pure::'.$TYPE;
	} elsif ($ENV{'ERROR_PURE_TYPE'}) {
		$class = 'Error::Pure::'.
			$ENV{'ERROR_PURE_TYPE'};
	} else {
		$class = 'Error::Pure::'.$TYPE_DEFAULT;
	}
	eval "require $class";
	if ($EVAL_ERROR) {

		# Switch to default, module doesn't exist.
		$class = 'Error::Pure::'.$TYPE_DEFAULT;
		eval "require $class";
		if ($EVAL_ERROR) {
			my $err = $EVAL_ERROR;
			$err =~ s/\ at.*$//ms;
			die $err;
		}
	}
	eval $class.'::err @msg';
	if ($EVAL_ERROR) {
		die $EVAL_ERROR;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure - Perl module for structured errors.

=head1 SYNOPSIS

 use Error::Pure qw(err);

 err 'This is a fatal error', 'name', 'value';

=head1 SUBROUTINES

=head2 C<err>

 err 'This is a fatal error', 'name', 'value';

Process error with message(s). There is key => value list after first message.

=head1 VARIABLES

=over 8

=item C<$LEVEL>

 Error level for Error::Pure.
 Default value is 4.

=item C<$TYPE>

 Available are last names in Error::Pure::* modules.
 Error::Pure::ErrorList means 'ErrorList'.
 If does defined ENV variable 'ERROR_PURE_TYPE', system use it.
 Default value is 'Die'.

 Precedence:
 1) $Error::Pure::TYPE
 2) $ENV{'ERROR_PURE_TYPE'}
 3) $Error::Pure::TYPE_DEFAULT = 'Die'

=back

=head1 EXAMPLE1

=for comment filename=err_with_die.pl

 use strict;
 use warnings;

 use Error::Pure qw(err);

 # Set env error type.
 $ENV{'ERROR_PURE_TYPE'} = 'Die';

 # Error.
 err '1';

 # Output:
 # 1 at example1.pl line 9.

=head1 EXAMPLE2

=for comment filename=err_with_error_list.pl

 use strict;
 use warnings;

 use Error::Pure qw(err);

 # Set env error type.
 $ENV{'ERROR_PURE_TYPE'} = 'ErrorList';

 # Error.
 err '1';

 # Output something like:
 # #Error [path_to_script:12] 1

=head1 EXAMPLE3

=for comment filename=err_with_all_error.pl

 use strict;
 use warnings;

 use Error::Pure qw(err);

 # Set error type.
 $Error::Pure::TYPE = 'AllError';

 # Error.
 err '1';

 # Output something like:
 # ERROR: 1
 # main  err  path_to_script  12

=head1 EXAMPLE4

=for comment filename=die_via_err.pl

 use strict;
 use warnings;

 use Error::Pure qw(err);

 $SIG{__DIE__} = sub {
         my $err = shift;
         $err =~ s/ at .*\n//ms;
         $Error::Pure::LEVEL = 5;
         $Error::Pure::TYPE = 'ErrorList';
         err $err;
 };

 # Error.
 die 'Error';

 # Output.
 # #Error [path_to_script.pl:17] Error

=head1 EXAMPLE5

=for comment filename=err_in_eval_and_print.pl

 use strict;
 use warnings;

 use English qw(-no_match_vars);
 use Error::Pure qw(err);
 use Error::Pure::Utils qw(err_msg_hr);

 # Eval block.
 eval {
        err 'Error',
               'Key1', 'Value1',
               'Key2', 'Value2';
 };
 if ($EVAL_ERROR) {
        print $EVAL_ERROR;
        my $err_msg_hr = err_msg_hr();
        foreach my $key (sort keys %{$err_msg_hr}) {
               print "$key: $err_msg_hr->{$key}\n";
        }
 }

 # Output.
 # Error
 # Key1: Value1
 # Key2: Value2

=head1 DEPENDENCIES

L<English>,
L<Error::Pure::Utils>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 ACKNOWLEDGMENTS

Jakub Špičak and his Masser (L<http://masser.sf.net>).

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2008-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.28

=cut
