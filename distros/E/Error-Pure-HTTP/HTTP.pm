package Error::Pure::HTTP;

use strict;
use warnings;

# Version.
our $VERSION = 0.16;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::HTTP - Error::Pure module over HTTP.

=head1 DESCRIPTION

 List of modules:

=over 8

=item C<Error::Pure::HTTP::AllError>

Print full backtrace over HTTP.

=item C<Error::Pure::HTTP::Error>

Print error on one line over HTTP.

=item C<Error::Pure::HTTP::ErrorList>

Print list of errors over HTTP. Each error on one line.

=item C<Error::Pure::HTTP::Print>

Print error as simple string over HTTP.

=back

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Error-Pure-HTTP>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2012-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.16

=cut
