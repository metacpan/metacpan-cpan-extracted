##@file
# OpenIDConnect authentication backend file

##@class
# OpenIDConnect authentication backend class
package Lemonldap::NG::Portal::AuthOpenIDConnect;

use strict;
use Lemonldap::NG::Portal::Simple;
use MIME::Base64;
use base qw(Lemonldap::NG::Portal::_OpenIDConnect);

our $VERSION = '1.9.6';

## @apmethod int authInit()
# Get configuration data
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    return PE_ERROR unless $self->loadOPs;
    return PE_ERROR unless $self->refreshJWKSdata;

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set _user, authenticationLevel and OIDC values in session
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;
    my $op   = $self->{_oidcOPCurrent};

    $self->{sessionInfo}->{'_user'} = $self->{user};
    $self->{sessionInfo}->{authenticationLevel} = $self->{oidcAuthnLevel};

    $self->{sessionInfo}->{OpenIDConnect_OP} = $op;
    $self->{sessionInfo}->{OpenIDConnect_access_token} =
      $self->{tmp}->{access_token};

    # Keep ID Token in session
    my $store_IDToken =
      $self->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsStoreIDToken};
    if ($store_IDToken) {
        $self->lmLog( "Store ID Token in session", 'debug' );
        $self->{sessionInfo}->{OpenIDConnect_IDToken} =
          $self->{tmp}->{id_token};
    }
    else {
        $self->lmLog( "ID Token will not be stored in session", 'debug' );
    }

    PE_OK;
}

## @apmethod int extractFormInfo()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    # Check callback
    my $callback_get_param = $self->{oidcRPCallbackGetParam};
    my $callback           = $self->param($callback_get_param);

    if ($callback) {

        $self->lmLog(
            "OpenIDConnect callback URI detected: "
              . $self->url( -path_info => 1, -query => 1 ),
            'debug'
        );

        # AuthN Response
        my $state = $self->param("state");

        # Restore state
        if ($state) {
            if ( $self->extractState($state) ) {
                $self->lmLog( "State $state extracted", 'debug' );
            }
            else {
                $self->lmLog( "Unable to extract state $state", 'error' );
                return PE_ERROR;
            }
        }

        # Get OpenID Provider
        my $op = $self->{_oidcOPCurrent};

        unless ($op) {
            $self->lmLog( "OpenID Provider not found", 'error' );
            return PE_ERROR;
        }

        $self->lmLog( "Using OpenID Provider $op", 'debug' );

        # Check error
        my $error = $self->param("error");
        if ($error) {
            my $error_description = $self->param("error_description");
            my $error_uri         = $self->param("error_uri");

            $self->lmLog( "Error returned by $op Provider: $error", 'error' );
            $self->lmLog( "Error description: $error_description",  'error' )
              if $error_description;
            $self->lmLog( "Error URI: $error_uri", 'error' ) if $error_uri;

            return PE_ERROR;
        }

        # Get access_token and id_token
        my $code = $self->param("code");
        my $auth_method =
          $self->{oidcOPMetaDataOptions}->{$op}
          ->{oidcOPMetaDataOptionsTokenEndpointAuthMethod};

        my $content =
          $self->getAuthorizationCodeAccessToken( $op, $code, $auth_method );
        return PE_ERROR unless $content;

        my $json = $self->decodeJSON($content);

        if ( $json->{error} ) {
            $self->lmLog( "Error in token response:" . $json->{error},
                'error' );
            return PE_ERROR;
        }

        # Check validity of token response
        unless ( $self->checkTokenResponseValidity($json) ) {
            $self->lmLog( "Token response is not valid", 'error' );
            return PE_ERROR;
        }
        else {
            $self->lmLog( "Token response is valid", 'debug' );
        }

        my $access_token = $json->{access_token};
        my $id_token     = $json->{id_token};

        $self->lmLog( "Access token: $access_token", 'debug' );
        $self->lmLog( "ID token: $id_token",         'debug' );

        # Verify JWT signature
        if ( $self->{oidcOPMetaDataOptions}->{$op}
            ->{oidcOPMetaDataOptionsCheckJWTSignature} )
        {
            unless ( $self->verifyJWTSignature( $id_token, $op ) ) {
                $self->lmLog( "JWT signature verification failed", 'error' );
                return PE_ERROR;
            }
            $self->lmLog( "JWT signature verified", 'debug' );
        }
        else {
            $self->lmLog( "JWT signature check disabled", 'debug' );
        }

        my $id_token_payload = $self->extractJWT($id_token)->[1];

        my $id_token_payload_hash =
          $self->decodeJSON( decode_base64($id_token_payload) );

        # Check validity of Access Token (optional)
        my $at_hash = $id_token_payload_hash->{'at_hash'};
        if ($at_hash) {
            unless ( $self->verifyHash( $access_token, $at_hash, $id_token ) ) {
                $self->lmLog( "Access token hash verification failed",
                    'error' );
                return PE_ERROR;
            }
            $self->lmLog( "Access token hash verified", 'debug' );
        }
        else {
            $self->lmLog(
                "No at_hash in ID Token, access token will not be verified",
                'debug' );
        }

        # Check validity of ID Token
        unless ( $self->checkIDTokenValidity( $op, $id_token_payload_hash ) ) {
            $self->lmLog( "ID Token not valid", 'error' );
            return PE_ERROR;
        }
        else {
            $self->lmLog( "ID Token is valid", 'debug' );
            $self->_dump($id_token_payload_hash);
        }

        # Get user id defined in 'sub' field
        my $user_id = $id_token_payload_hash->{sub};

        # Remember tokens
        $self->{tmp}->{access_token} = $access_token;
        $self->{tmp}->{id_token}     = $id_token;

        $self->lmLog( "Found user_id: " . $user_id, 'debug' );
        $self->{user} = $user_id;

        return PE_OK;
    }

    # No callback, choose Provider and send authn request
    my $op;

    unless ( $op = $self->param("idp") ) {
        $self->lmLog( "Redirecting user to OP list", 'debug' );

        # Control url parameter
        my $urlcheck = $self->controlUrlOrigin();
        return $urlcheck unless ( $urlcheck == PE_OK );

        my @oplist = sort keys %{ $self->{_oidcOPList} };

        # Error if no provider configured
        if ( $#oplist == -1 ) {
            $self->lmLog( "No OP configured", 'error' );
            return PE_ERROR;
        }

        # Auto select provider if there is only one
        if ( $#oplist == 0 ) {
            $op = shift @oplist;
            $self->lmLog( "Selecting the only defined OP: $op", 'debug' );
        }

        else {

            # IDP list
            my @list = ();

            my $portalPath = $self->{portal};
            $portalPath =~ s#^https?://[^/]+/?#/#;
            $portalPath =~ s#[^/]+\.pl$##;

            foreach (@oplist) {
                my $name = $self->{oidcOPMetaDataOptions}->{$_}
                  ->{oidcOPMetaDataOptionsDisplayName};
                my $icon = $self->{oidcOPMetaDataOptions}->{$_}
                  ->{oidcOPMetaDataOptionsIcon};
                my $img_src;

                if ($icon) {
                    $img_src =
                      ( $icon =~ m#^https?://# )
                      ? $icon
                      : $portalPath . "skins/common/" . $icon;
                }

                push @list,
                  {
                    val   => $_,
                    name  => $name,
                    icon  => $img_src,
                    class => "openidconnect",
                  };
            }
            $self->{list}            = \@list;
            $self->{confirmRemember} = 0;

            $self->{login} = 1;
            return PE_CONFIRM;
        }
    }

    # Provider is choosen
    $self->lmLog( "OpenID Provider $op choosen", 'debug' );

    $self->{_oidcOPCurrent} = $op;

    # AuthN Request
    $self->lmLog( "Build OpenIDConnect AuthN Request", 'debug' );

    # Save state
    my $state = $self->storeState(qw/urldc checkLogins _oidcOPCurrent/);

    my $stateSession = $self->storeState();

    # Authorization Code Flow
    $self->{urldc} = $self->buildAuthorizationCodeAuthnRequest( $op, $state );

    $self->lmLog( "Redirect user to " . $self->{urldc}, 'debug' );

    return $self->_subProcess(qw(autoRedirect));

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
# Send request to endsession endpoint
# @return Lemonldap::NG::Portal constant
sub authLogout {
    my $self = shift;

    my $op = $self->{sessionInfo}->{OpenIDConnect_OP};

    # Find endession endpoint
    my $endsession_endpoint =
      $self->{_oidcOPList}->{$op}->{conf}->{end_session_endpoint};

    if ($endsession_endpoint) {
        my $logout_url = $self->{portal};
        $logout_url =~ s#/$##;
        $logout_url .= "/?logout=1";
        my $logout_request =
          $self->buildLogoutRequest( $endsession_endpoint,
            $self->{sessionInfo}->{OpenIDConnect_IDToken}, $logout_url );

        $self->lmLog(
            "OpenID Connect logout to $op will be done on $logout_request",
            'debug' );

        $self->{urldc} = $logout_request;
    }
    else {
        $self->lmLog( "No end session endpoint found for $op", 'debug' );
    }

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

Lemonldap::NG::Portal::AuthOpenIDConnect - Perl extension for building Lemonldap::NG
compatible portals with OpenID Connect.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'OpenIDConnect',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

OpenID Connect authentication module.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2014-2016 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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

