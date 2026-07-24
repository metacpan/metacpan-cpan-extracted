package Lemonldap::NG::Portal::Plugins::OIDC::PasswordGrant;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SENDRESPONSE
  PE_FIRSTACCESS
);

our $VERSION = '2.23.1';

extends 'Lemonldap::NG::Portal::Lib::OIDCPlugin';

use constant hook => { oidcGotTokenRequest => 'handlePasswordGrant' };

sub handlePasswordGrant {
    my ( $self, $req, $rp, $grant_type ) = @_;
    return PE_OK unless $grant_type eq 'password';

    unless (
        $self->oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowPasswordGrant}
      )
    {
        $self->logger->warn(
            "Access to grant_type=password, is not allowed for RP $rp");
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

    my $client_id = $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};
    my $req_scope = $req->param('scope') || '';
    my $username  = $req->param('username');
    my $password  = $req->param('password');

    unless ( $username and $password ) {
        $self->logger->error("Missing username or password");
        return $oidc->sendOIDCError( $req, 'invalid_request', 400 );
    }

    ####
    # Authenticate user by running through the regular login process
    # minus the buildCookie step
    $req->parameters->{user}     = ($username);
    $req->parameters->{password} = $password;
    $req->data->{skipToken}      = 1;

    # This makes Auth::Choice use authChoiceAuthBasic if defined
    $req->data->{_pwdCheck} = 1;

    $req->steps( [
            @{ $self->p->beforeAuth },
            $self->p->authProcess,
            @{ $self->p->betweenAuthAndData },
            $self->p->sessionData,
            @{ $self->p->afterData },
            'storeHistory',
            @{ $self->p->endAuth },
        ]
    );
    my $result = $self->p->process($req);

    if (    ( $result == PE_FIRSTACCESS )
        and ( $self->conf->{authentication} eq "Choice" ) )
    {
        $self->logger->warn(
                "Choice module did not know which module to choose. "
              . "You should define authChoiceAuthBasic or specify desired module in the URL"
        );
    }

    $self->logger->debug( "Credentials check returned "
          . $self->p->_formatProcessResult($result) )
      if $result;

    ## Make sure we returned successfuly from the process AND we were able to create a session
    return $oidc->sendOIDCError( $req, 'invalid_grant', 400 )
      unless ( $result == PE_OK and $req->id and $req->user );

    ## Make sure the current user is allowed to use this RP
    if ( my $rule = $oidc->rpRules->{$rp} ) {
        my $ruleVariables =
          { %{ $req->sessionInfo || {} }, _oidc_grant_type => "password", };
        unless ( $rule->( $req, $ruleVariables ) ) {
            $self->userLogger->warn( 'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is not authorized to access $rp" );
            $self->p->deleteSession($req);
            return $oidc->sendOIDCError( $req, 'invalid_grant', 400 );
        }
    }

    my $user = $req->sessionInfo->{ $self->conf->{whatToTrace} };

    # Resolve scopes
    my $scope = $oidc->getScope( $req, $rp, $req_scope );
    unless ($scope) {
        $self->userLogger->warn( "User $user was not granted"
              . "  any requested scopes ($req_scope) for $rp" );
        return $oidc->sendOIDCError( $req, 'invalid_scope', 400 );
    }

    my $user_id = $oidc->getUserIDForRP( $req, $rp, $req->sessionInfo );

    $self->logger->debug(
        $user_id
        ? "Found corresponding user: $user_id"
        : 'Corresponding user not found'
    );

    # Generate access_token
    my $access_token = $oidc->newAccessToken(
        $req, $rp, $scope,
        $req->sessionInfo,
        {
            grant_type      => "password",
            user_session_id => $req->id,
        }
    );

    unless ($access_token) {
        $self->userLogger->error("Unable to create Access Token");
        return $oidc->sendOIDCError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Generated access token: $access_token");

    # Generate refresh_token
    my $refresh_token = undef;

    if ( $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsRefreshToken} ) {
        my $refreshTokenSession = $oidc->_generateRefreshToken(
            $req, $rp,
            {
                scope                      => $scope,
                client_id                  => $client_id,
                user_session_id            => $req->id,
                grant_type                 => "password",
                $self->conf->{whatToTrace} => $user,
                _oidc_logout_sub =>
                  $oidc->getUserIDForRP( $req, $rp, $req->userData ),
            },
            0,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $oidc->sendOIDCError( $req,
                'Could not create refresh token session', 500 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated refresh token: $refresh_token");
    }

    # Generate ID token
    my $id_token = undef;
    if ( $oidc->_hasScope( "openid", $scope ) ) {

        # Compute hash to store in at_hash
        my $alg =
          $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
        my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
        my $at_hash = $oidc->createHash( $access_token, $hash_level )
          if $hash_level;

        $id_token =
          $oidc->_generateIDToken( $req, $rp, $scope, $req->sessionInfo, 0,
            { ( $at_hash ? ( at_hash => $at_hash ) : () ), } );

        unless ($id_token) {
            $self->logger->error(
                "Failed to generate ID Token for service: $client_id");
            return $oidc->sendOIDCError( $req, 'server_error', 500 );
        }
    }

    # Send token response
    my $expires_in =
         $oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => "$access_token",
        token_type   => 'Bearer',
        expires_in   => $expires_in + 0,
        ( ( $scope ne $req_scope ) ? ( scope => "$scope" )       : () ),
        ( $refresh_token ? ( refresh_token => "$refresh_token" ) : () ),
        ( $id_token      ? ( id_token      => "$id_token" )      : () ),
    };

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );
}

package Lemonldap::NG::Portal::Plugins::OIDCPasswordGrant;

our @ISA = ('Lemonldap::NG::Portal::Plugins::OIDC::PasswordGrant');

1;
