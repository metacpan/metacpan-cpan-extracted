package Finance::Bank::Bankwest::Error::ServiceMessage;
# ABSTRACT: service message intercept exception
$Finance::Bank::Bankwest::Error::ServiceMessage::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::ServiceMessage
    extends Finance::Bank::Bankwest::Error
    with Finance::Bank::Bankwest::Error::WithResponse
{
    method MESSAGE {
        'the Bankwest Online Banking server presented a service '
            . 'message page'
    }
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error::ServiceMessage - service message intercept exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception may be thrown (but internally caught) on calls to
L<Finance::Bank::Bankwest/login> (or more specifically,
L<Finance::Bank::Bankwest::SessionFromLogin/session>) if the Bankwest
Online Banking server presents a "service message" page after logging
in.

This exception should never propagate outside this distribution.

=head1 ATTRIBUTES

=head2 response

An L<HTTP::Response> object holding the response causing the exception
to be thrown.  May be useful for diagnostic purposes.

This attribute is made available via
L<Finance::Bank::Bankwest::Error::WithResponse>.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest/login>

=item *

L<Finance::Bank::Bankwest::Error>

=item *

L<Finance::Bank::Bankwest::Error::WithResponse>

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
