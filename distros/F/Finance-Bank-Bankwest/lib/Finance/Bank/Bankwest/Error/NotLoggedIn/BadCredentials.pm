package Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials;
# ABSTRACT: invalid PAN/access code combination exception
$Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials
    extends Finance::Bank::Bankwest::Error::NotLoggedIn
{
    method MESSAGE {
        'could not log into Bankwest Online Banking; '
            . 'invalid PAN/access code combination'
    }
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials - invalid PAN/access code combination exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception may be thrown on calls to
L<Finance::Bank::Bankwest/login> (or more specifically,
L<Finance::Bank::Bankwest::SessionFromLogin/session>) when the Bankwest
Online Banking server rejects the Personal Access Number (PAN)/access
code combination supplied to it.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest/login>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn>

=item *

L<Finance::Bank::Bankwest::SessionFromLogin/session>

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
