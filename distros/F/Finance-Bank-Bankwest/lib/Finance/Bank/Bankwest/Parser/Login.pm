package Finance::Bank::Bankwest::Parser::Login;
# ABSTRACT: Online Banking login web page parser
$Finance::Bank::Bankwest::Parser::Login::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
use HTTP::Response::Switch::Handler 1.000000;
class Finance::Bank::Bankwest::Parser::Login
    with HTTP::Response::Switch::Handler
{
    use Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials ();
    use Finance::Bank::Bankwest::Error::NotLoggedIn::SubsequentLogin ();
    use Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout ();
    use Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason ();
    use Web::Scraper qw{ scraper process };

    my $scraper = scraper {
        process '#Form1 h2', 'form' => 'TEXT';
        process '#additionalMessageHeading', 'heading' => 'TEXT';
        process '#AuthUC_lblMessage', 'bc' => 'TEXT';
        process '#lblAdditionalLogonMessage', 'sl' => 'TEXT';
    };
    method handle {
        my $s = $scraper->scrape($self->response);
        $self->decline
            if not defined $s->{'form'}
                or $s->{'form'} !~ m{ ^ \s* Login \s* $ }x;
        Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout->throw
            if defined $s->{'heading'}
                and $s->{'heading'} eq 'Time Out';
        Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials->throw
            if defined $s->{'bc'} and (
                index($s->{'bc'}, "PAN and secure code don't match") >= 0
                or index($s->{'bc'}, 'forgot to enter your PAN') >= 0
            );
        Finance::Bank::Bankwest::Error::NotLoggedIn::SubsequentLogin->throw
            if defined $s->{'sl'}
                and index($s->{'sl'}, 'due to a subsequent logon') >= 0;

        # The login form is being shown, with or without unanticipated
        # error messages.  In almost every case this is a bad thing, so
        # throw an exception.  If the caller is expecting a login form
        # then they can catch the exception and carry on.
        Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason
            ->throw( $self->response );
    }
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Parser::Login - Online Banking login web page parser

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This module holds the logic for identifying an L<HTTP::Response> object
as a Bankwest Online Banking login web page, and throwing appropriate
exceptions when the page indicates that something has gone wrong (e.g.
session timeout, subsequent login, bad credentials).

This module always throws an exception regardless of the content of the
response, on the basis that being presented with a login page during a
session is almost always a bad thing.  In the one foreseeable case when
a login page is good--logging in--the caller can simply catch the
exception and proceed as normal.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::SubsequentLogin>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason>

=item *

L<Finance::Bank::Bankwest::Session>

=item *

L<Finance::Bank::Bankwest::SessionFromLogin>

=item *

L<HTTP::Response::Switch::Handler>

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
