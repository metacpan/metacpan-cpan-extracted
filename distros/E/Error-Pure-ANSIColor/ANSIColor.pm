package Error::Pure::ANSIColor;

# Pragmas.
use strict;
use warnings;

# Version.
our $VERSION = 0.01;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::ANSIColor - Error::Pure modules with Term::ANSIColor support.

=head1 DESCRIPTION

List of modules:

=over 8

=item C<Error::Pure::ANSIColor::AllError>

Print full backtrace with Term::ANSIColor support.

=item C<Error::Pure::ANSIColor::Die>

Die with Term::ANSIColor support.

=item C<Error::Pure::ANSIColor::Error>

Print error on one line with Term::ANSIColor support.

=item C<Error::Pure::ANSIColor::ErrorList>

Print list of errors with ANSIColor support. Each error on one line.

=item C<Error::Pure::ANSIColor::Print>

Print error as simple string with ANSIColor support

=item C<Error::Pure::ANSIColor::PrintVar>

Print error with all variables as simple string with ANSIColor support

=back

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
