package Finance::Bank::Bankwest::SessionFromLogin;
# ABSTRACT: create a session using a PAN and access code
$Finance::Bank::Bankwest::SessionFromLogin::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::SessionFromLogin {

    use Finance::Bank::Bankwest::Parsers ();
    use Finance::Bank::Bankwest::Session ();
    use MooseX::StrictConstructor; # no exports
    use TryCatch; # for "try" and "catch"
    use WWW::Mechanize ();


    has 'pan' => (
        is          => 'ro',
        isa         => 'Str',
        required    => 1,
    );


    has 'access_code' => (
        is          => 'ro',
        isa         => 'Str',
        required    => 1,
    );


    has 'session' => (
        init_arg    => undef,
        is          => 'ro',
        isa         => 'Finance::Bank::Bankwest::Session',
        lazy_build  => 1,
    );
    method _build_session {
        my $ua = WWW::Mechanize->new(
            stack_depth     => 0,
            cookie_jar      => { hide_cookie2 => 1 },
        );
        $ua->get($self->login_uri);

        # Is this actually a login page?
        try {
            Finance::Bank::Bankwest::Parsers->handle($ua->res);
        }
        catch (Finance::Bank::Bankwest::Error::NotLoggedIn $e) {
            # Generally the appearance of a login page is a bad thing,
            # but because we are currently trying to log in, it's not.
        }

        # The "__EVENTTARGET" parameter is normally set via JavaScript.
        $ua->submit_form(
            form_id => 'Form1',
            fields => {
                'AuthUC$txtUserID'  => $self->pan,
                'AuthUC$txtData'    => $self->access_code,
                '__EVENTTARGET'     => 'AuthUC$btnLogin',
            },
        );

        # In most cases the Account Balances page will be returned.
        # Handle the occasional "service message" popping up first, but
        # let any other exception be determined and propagated.
        try {
            Finance::Bank::Bankwest::Parsers->handle(
                $ua->res,
                qw{ Accounts ServiceMessage },
            );
        }
        catch (Finance::Bank::Bankwest::Error::ServiceMessage $e) {
            $ua->click('btnStartBanking');
            Finance::Bank::Bankwest::Parsers->handle(
                $ua->res,
                qw{ Accounts },
            );
        }

        # If this point is reached, the session is established.
        return Finance::Bank::Bankwest::Session->new( $ua );
    }


    has 'login_uri' => (
        is          => 'ro',
        isa         => 'Str',
        default     => 'https://ibs.bankwest.com.au/BWLogin/rib.aspx',
    );
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::SessionFromLogin - create a session using a PAN and access code

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 SYNOPSIS

    my $from_login = Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 12345678,
        access_code => 'LetMeIn123',
    );
    # returns a Finance::Bank::Bankwest::Session object
    my $session = $from_login->session;

=head1 DESCRIPTION

This module logs into Bankwest Online Banking using a supplied PAN
(Personal Access Number) and access code, and sets up a
L<Finance::Bank::Bankwest::Session> object with the newly-created
session.

L<Finance::Bank::Bankwest/login> provides a slightly more convenient
wrapper for this functionality.

=head1 ATTRIBUTES

=head2 pan

The Personal Access Number (PAN).  Required.

=head2 access_code

The access code associated with the provided PAN.  Required.

=head2 session

If login with the provided credentials is successful, a
L<Finance::Bank::Bankwest::Session> instance.

May throw one of the following exceptions on failure:

=over 4

=item L<Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials>

if the remote server rejects the supplied PAN/access code combination.

=item L<Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason>

or

=item L<Finance::Bank::Bankwest::Error::BadResponse>

if the remote server returns something unexpected, such as an "offline
for maintenance" message or some sort of intermediate advertising
pop-up.  In both cases the remote server's response is available as an
L<HTTP::Response> object; see
L<Finance::Bank::Bankwest::Error::WithResponse/response>.

=back

=head2 login_uri

The location of the resource that accepts the provided PAN and access
code and establishes the banking session.  Use the default value during
normal operation.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest/login>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason>

=item *

L<Finance::Bank::Bankwest::Error::BadResponse>

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
