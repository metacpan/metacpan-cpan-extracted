package Finance::Bank::Bankwest::Error::NotLoggedIn;
# ABSTRACT: non-existent session exception superclass
$Finance::Bank::Bankwest::Error::NotLoggedIn::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::NotLoggedIn
    extends Finance::Bank::Bankwest::Error
{
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error::NotLoggedIn - non-existent session exception superclass

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

A subclass of this exception is thrown when the server reports that a
Bankwest Online Banking session is not set up.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::SubsequentLogin>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason>

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
