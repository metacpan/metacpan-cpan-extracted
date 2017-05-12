package Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout;
# ABSTRACT: Bankwest session timeout exception
$Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout
    extends Finance::Bank::Bankwest::Error::NotLoggedIn
{
    method MESSAGE {
        'the Bankwest Online Banking session has timed out '
            . 'due to inactivity'
    }
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout - Bankwest session timeout exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception may be thrown on calls to various methods of
L<Finance::Bank::Bankwest::Session> when the Bankwest Online Banking
session has been terminated due to inactivity.

At the time of writing, the remote server appears to terminate sessions
after 15 minutes of inactivity.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn>

=item *

L<Finance::Bank::Bankwest::Session>

=back

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
