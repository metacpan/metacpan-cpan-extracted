package Lemonldap::NG::Portal::Main::Request;

# Developpers, be careful: new() is never called so default values will not be
# taken in account (see Portal::Run::handler()): set default values in init()

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants ':all';

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Common::PSGI::Request';

# List of methods to call
has steps => ( is => 'rw' );

# Authentication result
has authResult => ( is => 'rw' );

# Session data when created
has id          => ( is => 'rw' );
has sessionInfo => ( is => 'rw' );
has user        => ( is => 'rw' );

# Persistent data (stored in cookie during auth, erased when auth is ready)
has pdata => ( is => 'rw' );

# Response cookies (list of strings built by cookie())
has respCookies => ( is => 'rw' );

# Embedded response
has response => ( is => 'rw' );

# Template to display (if not defined, login or menu)
has template => ( is => 'rw' );

# Custom template parameters
has customParameters => ( is => 'rw' );

# Boolean to indicate that response must be a redirection
has mustRedirect => ( is => 'rw' );

# Boolean to indicate that login form must not be displayed (used to reset
# authentication)
has noLoginDisplay => ( is => 'rw' );

# Store URL for redirections
has urldc                  => ( is => 'rw' );
has postUrl                => ( is => 'rw' );
has postFields             => ( is => 'rw' );
has portalHiddenFormValues => ( is => 'rw' );

# Flag that permit to a auth module to return PE_OK without setting $user
has continue => ( is => 'rw' );

# "check logins "flag"
has checkLogins => ( is => 'rw' );

# Boolean to indicate that url isn't Base64 encoded
has urlNotBase64   => ( is => 'rw' );
has maybeNotBase64 => ( is => 'rw' );

# Menu error
has menuError => ( is => 'rw' );

# Frame flag (used by Run to not send Content-Security-Policy header)
has frame => ( is => 'rw' );

# Refresh flag to avoid double cookies sessions to be renewed
has refresh => ( is => 'rw' );

# Scalar to display lock time
has lockTime => ( is => 'rw' );

# Security
#
# Captcha HTML code to display in forms
has captchaHtml => ( is => 'rw' );

# DEPRECATED: 2.0 captcha compatibility
has captcha => ( is => 'rw' );

# Token
has token => ( is => 'rw' );

# Whether or not to include a HTML render of the error message
# in error responses
has wantErrorRender => ( is => 'rw' );

# Error type

sub error_role {
    my $req = shift;
    return $req->error_type(@_) eq 'negative' ? 'alert' : 'status';
}

sub error_type {
    my $req  = shift;
    my $code = shift || $req->error;
    $req->error($code);

    # Positive errors
    return "positive"
      if (
        scalar(
            grep { /^$code$/ } (
                PE_REDIRECT,        PE_DONE,
                PE_OK,              PE_PASSWORD_OK,
                PE_MAILOK,          PE_LOGOUT_OK,
                PE_MAILFIRSTACCESS, PE_PASSWORDFIRSTACCESS,
                PE_MAILCONFIRMOK,   PE_REGISTERFIRSTACCESS,
                PE_RESETCERTIFICATE_FIRSTACCESS,
            )
        )
      );

    # Warning errors
    return "warning"
      if (
        scalar(
            grep { /^$code$/ } (
                PE_INFO,
                PE_SESSIONEXPIRED,
                PE_FORMEMPTY,
                PE_FIRSTACCESS,
                PE_PP_GRACE,
                PE_PP_EXP_WARNING,
                PE_NOTIFICATION,
                PE_BADURL,
                PE_CONFIRM,
                PE_MAILFORMEMPTY,
                PE_MAILCONFIRMATION_ALREADY_SENT,
                PE_PASSWORDFORMEMPTY,
                PE_CAPTCHAEMPTY,
                PE_REGISTERFORMEMPTY,
                PE_PP_CHANGE_AFTER_RESET,
                PE_RESETCERTIFICATE_FORMEMPTY,
            )
        )
      );

    # Negative errors (default)
    return "negative";

    #TODO
}

sub init {
    my ( $self, $conf ) = @_;
    $self->{$_} = {} foreach (qw(data customParameters sessionInfo pdata));
    $self->{$_} = [] foreach (qw(respCookies));
    if ( my $tmp = $self->userData->{ $conf->{whatToTrace} } ) {
        $self->user($tmp);
    }
}

sub errorString {
    print STDERR "TODO Request::errorString()\n";
}

sub loginInfo {
    print STDERR "TODO Request::loginInfo()\n";
}

sub setInfo {
    my ( $self, $info ) = @_;
    $self->data->{_info} = $info if ( defined $info );
    return $self->data->{_info};
}

sub info {
    my ( $self, $info ) = @_;
    $self->data->{_info} .= $info if ( defined $info );
    return $self->data->{_info};
}

sub addCookie {
    my ( $self, $cookie ) = @_;
    push @{ $self->respHeaders }, 'Set-Cookie' => $cookie;
}

sub delCookie {
    my ( $self, $cookieName ) = @_;
    my $i = 0;
    @{ $self->respHeaders } = map {

        # Look for a Set-Cookie header
        if ( $_ =~ /^Set-Cookie$/i ) {
            $i = 1;
            return ();
        }
        elsif ($i) {

            # Keep other cookies
            unless (/^$cookieName\s*=/i) {
                $i = 0;
                return ( 'Set-Cookie' => $_ );
            }

            #Value is hidden here
            return ();
        }
        return $_;
    } @{ $self->respHeaders };
}

# TODO: oldpassword
1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Main::Request - HTTP request object used in LLNG
portal methods.

=head1 SYNOPSIS

  # Somewhere in a plugin...
  sub run {
      my ( $self, $req ) = @_;
      # $req is a Lemonldap::NG::Portal::Main::Request object
      ...
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::Main::Request extends
L<Lemonldap::NG::Common::PSGI::Request> to add all parameters needed to manage
portal jobs.

=head1 METHODS

=head2 Accessors

=head3 steps()

Stack of methods to call for this requests. It can be modified to change
authentication process

=head3 data()

Free hash ref where plugins can store their data (during one request). Using it
is a LLNG best practice

=head3 pdata

Free hash ref where plugins can store some persistent data: data are kept
during auth process and cleaned after successful authentication, except if
C<$req-E<gt>pdata-E<gt>{keepPdata}> is set to an array of values. In this
case, module that has set these values must remove them after its job ends.

=head3 User information

=head4 id()

Session id (main cookie value).

=head4 sessionInfo()

Hash ref that will be stored in session DB.

=head4 user()

Username given by authentication module, used by userDB module.

=head3 mustRedirect()

Boolean to indicate that response must be a redirection (used for example when
request is a POST).

=head3 urlNotBase64

Boolean to indicate that url isn't Base64 encoded.

=head2 Other methods

=head3 info()

Store info to display in response.

=head3 menuError()

=head3 notification()

see notification plugin.

=head3 errorType()

Returns positive/warning/negative depending on value stored in error property.

=head2 Cookie methods

=over

=item addCookie(string $cookie): add cookie in $req response headers. String
is a complete cookie string, ex: "lemonldap=xxx"

=item delCookie(string $cookieName): remove cookie from $req response headers.
It doesn't remove navigator cookie but remove a "Set-Cookie" header if value
match "L<lt>cookieNameL<gt>=..."

=back

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Common::PSGI::Request>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
