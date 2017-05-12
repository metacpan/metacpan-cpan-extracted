package Error::Pure::Always;

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);

# Version.
our $VERSION = 0.06;

my %OLD_SIG;

# Default error type.
$ENV{'ERROR_PURE_TYPE'} ||= 'Die';

BEGIN {
	@OLD_SIG{qw(__DIE__)} = @SIG{qw(__DIE__)};
	$SIG{__DIE__} = sub {
		my $err = shift;
		$err =~ s/ at .*\n//ms;
		$Error::Pure::LEVEL = 5;
		err $err;
	};
}

END {
	@SIG{qw(__DIE__)} = @OLD_SIG{qw(__DIE__)};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::Always - Perl module for rewrite die by err from Error::Pure module.

=head1 SYNOPSIS

 use Error::Pure::Always;

 perl -MError::Pure::Always perl_script.pl

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Always;

 # Set env error type.
 $ENV{'ERROR_PURE_TYPE'} = 'Die';

 # Error.
 die '1';

 # Output:
 # 1 at example1.pl line 9.

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Always;

 # Set env error type.
 $ENV{'ERROR_PURE_TYPE'} = 'ErrorList';

 # Error.
 die '1';

 # Output something like:
 # #Error [path_to_script:12] 1

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Always;

 # Set error type.
 $Error::Pure::TYPE = 'AllError';

 # Error.
 die '1';

 # Output something like:
 # ERROR: 1
 # main  err  path_to_script  12

=head1 DEPENDENCIES

L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 ACKNOWLEDGMENTS

Thanks for L<Carp::Always> module.

=head1 REPOSITORY

L<https://github.com/tupinek/Error-Pure-Always>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2012-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.06

=cut
