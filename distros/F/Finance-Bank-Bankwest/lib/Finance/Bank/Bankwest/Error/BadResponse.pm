package Finance::Bank::Bankwest::Error::BadResponse;
# ABSTRACT: unexpected remote server response exception
$Finance::Bank::Bankwest::Error::BadResponse::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::BadResponse
    extends Finance::Bank::Bankwest::Error
    with Finance::Bank::Bankwest::Error::WithResponse
{
    method MESSAGE {
        'the Bankwest Online Banking server returned an unexpected response'
    }
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error::BadResponse - unexpected remote server response exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception may be thrown by L<Finance::Bank::Bankwest::Parsers> (or
a L<Finance::Bank::Bankwest::Parser>-consuming class) when the Bankwest
Online Banking server returns a response that is not expected.

This may be due to the remote server being down, some sort of
temporary pop-up being implemented (like an ad), or a change to
the structure of the web interface.

=head1 ATTRIBUTES

=head2 response

An L<HTTP::Response> object holding the response causing the exception
to be thrown.  May be useful for diagnosing the cause of the problem.

This attribute is made available via
L<Finance::Bank::Bankwest::Error::WithResponse>.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error>

=item *

L<Finance::Bank::Bankwest::Error::WithResponse>

=item *

L<Finance::Bank::Bankwest::Parser>

=item *

L<Finance::Bank::Bankwest::Parsers>

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
