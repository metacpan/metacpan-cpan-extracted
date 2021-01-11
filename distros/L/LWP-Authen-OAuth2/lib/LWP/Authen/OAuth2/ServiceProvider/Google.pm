package LWP::Authen::OAuth2::ServiceProvider::Google;

# ABSTRACT: Google OAuth2
our $VERSION = '0.18'; # VERSION

use strict;
use warnings;

our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider);

sub authorization_endpoint {
    return "https://accounts.google.com/o/oauth2/auth";
}

sub token_endpoint {
    return "https://accounts.google.com/o/oauth2/token";
}

sub authorization_required_params {
    my $self = shift;
    return ("scope", $self->SUPER::authorization_required_params());
}

sub authorization_optional_params {
    my $self = shift;
    return ("login_hint", $self->SUPER::authorization_optional_params());
}

my %client_type_class
    = (
          default => "WebServer",
          device => "Device",
          installed => "Installed",
          login   => "Login",
          "web server" => "WebServer",
          service => "Service",
      );

sub client_type_class {
    my ($class, $client_type) = @_;
    if (exists $client_type_class{$client_type}) {
        return "LWP::Authen::OAuth2::ServiceProvider::Google::$client_type_class{$client_type}";
    }
    else {
        my $allowed = join ", ", sort keys %client_type_class;
        Carp::croak("Flow '$client_type' not in: $allowed");
    }
}

package LWP::Authen::OAuth2::ServiceProvider::Google::Device;
our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider::Google);

sub init {
    Carp::confess(__PACKAGE__ . " is not implemented.");
}

package LWP::Authen::OAuth2::ServiceProvider::Google::Installed;
our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider::Google);

sub init {
    Carp::confess(__PACKAGE__ . " is not implemented.");
}

package LWP::Authen::OAuth2::ServiceProvider::Google::Login;
our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider::Google);

sub init {
    Carp::confess(__PACKAGE__ . " is not implemented.");
}

sub authorization_required_params {
    my $self = shift;
    return ("state", $self->SUPER::authorization_required_params());
}

sub authorization_default_params {
    my $self = shift;
    return (
        "scope" => "openid email",
        $self->SUPER::authorization_default_params()
    );
}

sub request_required_params {
    my $self = shift;
    return ("state", $self->SUPER::request_required_params());
}

sub request_default_params {
    my $self = shift;
    return (
        "scope" => "openid email",
        $self->SUPER::request_default_params()
    );
}

package LWP::Authen::OAuth2::ServiceProvider::Google::Service;
our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider::Google);

sub init {
    Carp::confess(__PACKAGE__ . " is not implemented.");
}

package LWP::Authen::OAuth2::ServiceProvider::Google::WebServer;
our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider::Google);

# Not guaranteed a refresh token, so require nothing.
sub required_init {
    return ();
}

sub optional_init {
    return qw(redirect_uri scope client_id client_secret);
}

sub authorization_optional_params {
    my $self = shift;
    return (
        "access_type", "approval_prompt",
        $self->SUPER::authorization_optional_params()
    );
}

sub request_required_params {
    my $self = shift;
    return ("redirect_uri", $self->SUPER::request_required_params());
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Google - Google OAuth2

=head1 VERSION

version 0.18

=head1 SYNOPSIS

See L<LWP::Authen::OAuth2> for basic usage.  The one general note is that
C<scope> is C<scope> is optional in the specification, but required for
Google.  Beyond that Google supports many client types, and their behavior
varies widely.

See L<https://developers.google.com/accounts/docs/OAuth2> for Google's
own documentation.  The documentation here is a Cliff Notes version of that,
so look there for any necessary clarification.

=head1 REGISTERING

Before you can use OAuth 2 with Google you need to register yourself as a
client.  For that, go to L<https://code.google.com/apis/console>.  Follow
their directions to create a project, choose your C<flow> (which is called
your C<client_type> in this document - look ahead for advice on available
types), and then you'll be given a C<client_id> and C<client_secret>.  If
you're in the Login, WebServer or Client client types you'll also need to
register a C<redirect_uri> with them, which will need to be an
C<https://...> URL under your control.

At that point you have all of the facts that you need to use this module.  Be
sure to keep your C<client_secret> secret - if someone else gets it and
starts abusing it, Google reserves the right to block you.

This module only handles the authorization step, after which it is up to you
to figure out how to use whatever API you want to access.

=head1 CLIENT TYPES

Google offers many client types.  Here is the status of each one in this
module:

=over 4

=item Login

This is for applications that want to let Google manage their logins.  See
L<https://developers.google.com/accounts/docs/OAuth2Login> for Google's
documentation.

This is not yet supported, and would require the use of JSON Web Tokens to
support.

=item Web Server Application

This is intended for applications running on web servers, with the user
sitting behind a browser interacting with you.  See
L<https://developers.google.com/accounts/docs/OAuth2WebServer> for Google's
documentation.

It can be specified in the constructor with:

    client_type => "web server",

however that is not necessary since it is also the assumed default if no
client_type is specified.

After registering yourself as a client with Google, you will need to specify
the C<redirect_uri> as an https URL under your control.  If you just need
this for one or two accounts there is no need to actually build anything at
that URL - just go through the authorization as those accounts and grab your
C<code> from the URL.  If you will support many, making that URL useful is
your responsibility.

With this client type you are not guaranteed a refresh token, so the
constructor does not require C<client_id> and C<client_secret>.  (Passing them
there is still likely to be convenient for you.) However there are several
optional arguments available to C<$oauth2-E<gt>authorization_url(...)> that
are worth taking note of:

=over 4

=item C<access_type>

Pass C<access_type =E<gt> "offline",> to C<$oauth2->request_tokens(...)> to
request offline access.  This means that you get a C<refresh_token> which can
be used to refresh the access token without help from the user.  The intent
of this option is to support things like software that delays posting a blog
entry until a particular time.

In light testing this did not work for me until I passed the next argument,
but then it worked perfectly.

=item C<approval_prompt>

Pass C<approval_prompt =E<gt> "force",> to C<$oauth2->request_tokens(...)> to
force the user to see the approval screen.  The default behavior without this
is that the user sees the approval screen the first time through, and on
subsequent times just gets an immediate redirect.

=item C<login_hint>

If you think you know who the user is, you can pass an email in this
parameter to let Google know which account you are trying to access.  Google
thinks this may be helpful if someone is logged into multiple accounts at
the same time.

=back

=item Client-side Application

This client type is only for JavaScript applications.  See
L<https://developers.google.com/accounts/docs/OAuth2UserAgent> for Google's
documentation.

This is not supported since Perl is not JavaScript.

=item Installed Application

This client type is for applications that run on the user's machine, which can
control a browser.  See
L<https://developers.google.com/accounts/docs/OAuth2InstalledApp> for
Google's documentation.

It can be specified in the constructor with:

    client_type => "installed",

On the first time it is the client's responsibility to open a browser and
send the user to C<$oauth2->authorization_url(...)>.  If you pass in
C<redirect_uri =E<gt> "http://localhost:$port",> then your application is
expected to be listening on that port.  If you instead pass in
C<redirect_uri =E<gt> "urn:ietf:wg:oauth:2.0:oob",> then the code you need
will be in the C<title> inside of the page the browser is redirected to, and
you'll need to grab it from there.

The returned tokens always give you a refresh token, so you only have to go
through this once per user.

The only special authorization argument is C<login_hint>, which means the
same thing that it does for webserver applications.

=item Devices

This client_type is for applications that run on the user's machine, which do
not control a browser.  See
L<https://developers.google.com/accounts/docs/OAuth2ForDevices> for Google's
documentation.

This client_type is not supported because I have not yet thought through how to
handle the required polling step of setting up permissions.

=item Service Account

This client_type is for applications that login to the developer's account
using the developer's credentials.  See
L<https://developers.google.com/accounts/docs/OAuth2ServiceAccount> for
Google's documentation.

This is not yet supported, and would require the use of JSON Web Tokens to
support.

=back

=head1 AUTHORS

=over 4

=item *

Ben Tilly, <btilly at gmail.com>

=item *

Thomas Klausner <domm@plix.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2021 by Ben Tilly, Rent.com, Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
