package Lemonldap::NG::Portal::Plugins::OIDC::ClientCredentialsGrant;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.23.0';

extends 'Lemonldap::NG::Portal::Lib::OIDCPlugin';

use constant hook => { oidcGotTokenRequest => 'handleClientCredentialsGrant' };

sub handleClientCredentialsGrant {
    my ( $self, $req, $rp, $grant_type ) = @_;
    return PE_OK unless $grant_type eq 'client_credentials';

    unless ( $self->oidc->rpOptions->{$rp}
        ->{oidcRPMetaDataOptionsAllowClientCredentialsGrant} )
    {
        $self->logger->warn(
            "Access to Client Credentials grant is not allowed for RP $rp");
        $req->response(
            $self->oidc->sendOIDCError( $req, 'unauthorized_client', 400 ) );
        return PE_SENDRESPONSE;
    }

    $req->response( $self->_run( $req, $rp ) );
    return PE_SENDRESPONSE;
}

sub _run {
    my ( $self, $req, $rp ) = @_;
    my $oidc = $self->oidc;

    # The client credentials grant type MUST only be used by confidential
    # clients.
    if ( $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsPublic} ) {
        $self->logger->error(
            "Client Credentials grant cannot be used on public clients");
        return $oidc->sendOIDCError( $req, 'unauthorized_client', 400 );
    }
    my $client_id = $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};

    # Populate minimal session info
    my $req_scope = $req->param('scope') || '';
    my $scope     = $oidc->getScope( $req, $rp, $req_scope );

    unless ($scope) {
        $self->userLogger->warn( 'Client '
              . $client_id
              . " was not granted any requested scopes ($req_scope) for $rp" );
        return $oidc->sendOIDCError( $req, 'invalid_scope', 400 );
    }

    my $infos = {
        $self->conf->{whatToTrace} => $client_id,
        _clientId                  => $client_id,
        _clientConfKey             => $rp,
        _scope                     => $scope,
        _utime                     => time,
    };

    my $h = $self->p->processHook( $req, 'oidcGotClientCredentialsGrant',
        $infos, $rp );
    return $oidc->sendOIDCError( $req, 'server_error', 500 )
      if ( $h != PE_OK );

    # Update scope in case hook changed it
    $scope = $infos->{_scope};

    # Run rule against session info
    if ( my $rule = $oidc->rpRules->{$rp} ) {
        my $ruleVariables =
          { %{ $infos || {} }, _oidc_grant_type => "clientcredentials", };
        unless ( $rule->( $req, $ruleVariables ) ) {
            $self->userLogger->warn(
                    "Relying party $rp did not validate the provided "
                  . "Access Rule during Client Credentials Grant" );
            return $oidc->sendOIDCError( $req, 'invalid_grant', 400 );
        }
    }

    # Create access token
    my $session = $self->p->getApacheSession( undef, info => $infos );
    unless ($session) {
        $self->logger->error("Unable to create session");
        return $oidc->sendOIDCError( $req, 'server_error', 500 );
    }

    my $access_token = $oidc->newAccessToken(
        $req, $rp, $scope,
        $session->data,
        {
            scope           => $scope,
            rp              => $rp,
            user_session_id => $session->id,
            grant_type      => "clientcredentials",
        }
    );
    unless ($access_token) {
        $self->userLogger->error("Unable to create Access Token");
        return $oidc->sendOIDCError( $req, 'Unable to create Access Token',
            500 );
    }

    my $expires_in =
         $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => "$access_token",
        token_type   => 'Bearer',
        expires_in   => $expires_in + 0,
        ( ( $req_scope ne $scope ) ? ( scope => "$scope" ) : () ),
    };

    $self->logger->debug("Send token response");
    return $self->p->sendJSONresponse( $req, $token_response );
}

package Lemonldap::NG::Portal::Plugins::OIDCClientCredentialsGrant;

our @ISA = ('Lemonldap::NG::Portal::Plugins::OIDC::ClientCredentialsGrant');

1;
