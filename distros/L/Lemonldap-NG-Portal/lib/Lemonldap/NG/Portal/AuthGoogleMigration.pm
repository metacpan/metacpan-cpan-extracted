##@file
# Google authentication backend file - Migration to OpenID Connect

##@class
# Google authentication backend class.
package Lemonldap::NG::Portal::AuthGoogleMigration;

#== Disclaimer
# This module provides a quick and unsafe solution to
# migrate from old Google module (OpenID 2.0)
# It will be replaced by AuthOpenIDConnect in next
# major version
#==

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_Browser;
use URI::Escape;
use JSON;
use MIME::Base64
  qw/encode_base64url encode_base64 decode_base64url decode_base64/;
our @ISA = (qw(Lemonldap::NG::Portal::_Browser));

our $VERSION = '1.4.4';

## @apmethod int authInit()
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    unless ( $self->{googleClientId} and $self->{googleClientSecret} ) {
        $self->lmLog(
"You need to register this application and configure client ID and client secret",
            'error'
        );
        return PE_ERROR;
    }
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username return by Google authentication system.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    my $response_type = "code";
    my $scope         = "openid email";
    my $client_id     = $self->{googleClientId};
    my $client_secret = $self->{googleClientSecret};
    my $redirect_uri  = $self->{portal} . "?googlecb=1";
    my $state         = encode_base64url( $self->{urldc} );

    # Ask for profile if googleExportedVars requested
    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{googleExportedVars} } );
    if (%vars) {
        $scope .= " profile";
    }

    my $callback = $self->param("googlecb");

    if ($callback) {
        my $code  = $self->param("code");
        my $error = $self->param("error");

        if ($error) {
            $self->lmLog( "Error returned by Google: $error", 'error' );
            return PE_ERROR;
        }

        my %form;
        $form{"code"}          = $code;
        $form{"redirect_uri"}  = $redirect_uri;
        $form{"grant_type"}    = "authorization_code";
        $form{"client_id"}     = $client_id;
        $form{"client_secret"} = $client_secret;
        my $response =
          $self->ua->post( "https://www.googleapis.com/oauth2/v3/token",
            \%form, "Content-Type" => 'application/x-www-form-urlencoded' );

        if ( $response->is_error ) {
            $self->lmLog( "Error returned by Google: " . $response->message,
                'error' );
            return PE_ERROR;
        }

        my $content = $response->decoded_content;

        my $json;
        eval { $json = decode_json $content; };

        my $access_token = $json->{access_token};
        my $id_token     = $json->{id_token};

        my ( $id_token_header, $id_token_payload, $id_token_signature ) =
          split( /\./, $id_token );

        my $id_token_payload_raw = decode_base64url($id_token_payload);

        my $id_token_payload_hash;
        eval { $id_token_payload_hash = decode_json $id_token_payload_raw; };

        $self->{user} = $id_token_payload_hash->{email};

        if ( $self->param("state") ) {
            $self->{urldc} = decode_base64url( $self->param("state") );
        }

        if (%vars) {

            # Request UserInfo
            my $ui_response = $self->ua->get(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                "Authorization" => "Bearer $access_token"
            );
            my $ui_content = $ui_response->decoded_content;

            my $ui_json;
            eval { $ui_json = decode_json($ui_content); };

            # Convert OpenID attribute name into OIDC UserInfo field
            my $convertAttr = {
                "firstname" => "given_name",
                "lastname"  => "family_name",
                "language"  => "locale",
                "email"     => "email",
            };

            # Store attributes in session
            while ( my ( $k, $v ) = each %vars ) {
                my $attr = $k;
                $attr =~ s/^!//;
                my $oidc_attr = $convertAttr->{$v};
                $self->{sessionInfo}->{$attr} = $ui_json->{$oidc_attr};
            }
        }

        return PE_OK;
    }

    my $redirect_url =
        "https://accounts.google.com/o/oauth2/auth"
      . "?response_type="
      . uri_escape($response_type)
      . "&client_id="
      . uri_escape($client_id)
      . "&scope="
      . uri_escape($scope)
      . "&redirect_uri="
      . uri_escape($redirect_uri)
      . "&state="
      . uri_escape($state);

    $self->{urldc} = $redirect_url;
    $self->lmLog( "Redirect user to $redirect_url", 'debug' );
    $self->_sub('autoRedirect');
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{'_user'} = $self->{user};

    $self->{sessionInfo}->{authenticationLevel} = $self->{googleAuthnLevel};

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    PE_OK;
}

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "logo";
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthGoogle - Perl extension for building Lemonldap::NG
compatible portals with Google authentication (migration to OpenID Connect).

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'GoogleMigration',
         googleClientId => '...',
         googleClientSecret => '...',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "...";
  }
  else {
    # If the user enters here, IT MEANS THAT CAS REDIRECTION DOES NOT WORK
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
Google authentication mechanism.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>,
L<https://developers.google.com/accounts/docs/OpenID>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2013 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2013 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

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

