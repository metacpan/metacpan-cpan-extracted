package Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason;
# ABSTRACT: general Bankwest session failure exception
$Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason
    extends Finance::Bank::Bankwest::Error::NotLoggedIn
    with Finance::Bank::Bankwest::Error::WithResponse
{
    method MESSAGE {
        'a Bankwest Online Banking session cannot be established '
            . 'for an unknown reason'
    }
}

__END__

=pod

=for :stopwords Alex Peters initialised

=head1 NAME

Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason - general Bankwest session failure exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception may be thrown on calls to
L<Finance::Bank::Bankwest/login> or various methods of
L<Finance::Bank::Bankwest::Session> when for an unanticipated reason, a
Bankwest Online Banking session cannot be initialised or has been
terminated.

This exception is likely to occur when a Personal Access Number (PAN)
has been suspended, or when Bankwest Online Banking is undergoing some
sort of maintenance (but still presenting a login form).

=head1 ATTRIBUTES

=head2 response

An L<HTTP::Response> object holding the response causing the exception
to be thrown.  May be useful for diagnosing the cause of the problem.

This attribute is made available via
L<Finance::Bank::Bankwest::Error::WithResponse>.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest/login>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn>

=item *

L<Finance::Bank::Bankwest::Error::WithResponse>

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
