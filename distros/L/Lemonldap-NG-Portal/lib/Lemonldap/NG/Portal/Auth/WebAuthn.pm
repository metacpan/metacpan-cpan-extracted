package Lemonldap::NG::Portal::Auth::WebAuthn;

use strict;
use Mouse;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_WEBAUTHNFAILED
  PE_FIRSTACCESS
  PE_SENDRESPONSE
  PE_TOKENEXPIRED
  PE_OK
);

our $VERSION = '2.19.0';

extends 'Lemonldap::NG::Portal::Auth::_WebForm';

has auth_id => ( is => 'ro', default => 'webauthn' );
has type    => ( is => 'ro', default => 'WebAuthn' );

with 'Lemonldap::NG::Portal::Lib::WebAuthn';

sub initDisplay {
    my ( $self, $req, $auto_start ) = @_;

    my $request = $self->get_challenge($req);

    if ($request) {

        my $data = to_json( {
                request            => $request,
                webauthn_autostart => ( $auto_start ? \1 : \0 )
            }
        );

        $req->data->{customScript} .= <<EOF;
<script type="application/init">
$data
</script>
EOF
    }
    else {
        die "Could not generate WebAuthn challenge";
    }

    $req->data->{customScript} .= <<"EOF";
<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/webauthn-json.browser-global.min.js"></script>
<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/webauthncheck.min.js"></script>
EOF
}

# INITIALIZATION

sub init {
    my $self = shift;

    $self->authnLevel( $self->conf->{webauthnAuthnLevel} );

    unless ( $self->p->unAuthRoutes->{GET}->{webauthn} ) {
        $self->addUnauthRoute(
            webauthn => 'init_challenge',
            ['POST']
        );

        # Used for session upgrade/reauthn
        $self->addAuthRoute(
            webauthn => 'init_challenge',
            ['POST']
        );
    }
    return $self->SUPER::init;
}

sub auth_route {
    my ( $self, $req ) = @_;

}

sub get_challenge {
    my ( $self, $req ) = @_;

    my $request = $self->generateDiscoverableChallenge($req);
    if ($request) {

        # Request is persisted on the server
        #
        my $webauthn_data = { authentication_options => $request, };
        if ( my $token = $req->token ) {
            $self->ott->updateToken( $token, "webauthn", $webauthn_data );

        }
        else {
            $req->token(
                $self->ott->createToken( {
                        webauthn => $webauthn_data
                    }
                )
            );
        }

        return $request;
    }
    return;
}

sub extractFormInfo {
    my ( $self, $req ) = @_;
    if (    my $credential = $req->param('credential')
        and my $token = $req->param('token') )
    {

        my $token = $self->ott->getToken($token);
        if ($token) {
            $req->data->{webauthn_credential} = $credential;
            $req->data->{webauthn_options} =
              $token->{webauthn}->{authentication_options};
            my $user_data = $self->getUserFromCredential( $req, $credential );
            if ($user_data) {
                $req->user( $user_data->{uid} );
                $req->data->{webauthn__2fDevices} = $user_data->{_2fDevices};
                $req->data->{webauthn__webAuthnUserHandle} =
                  $user_data->{_webAuthnUserHandle};
                return PE_OK;
            }
            else {
                return PE_WEBAUTHNFAILED;
            }
        }
        else {
            return PE_TOKENEXPIRED;
        }
    }
    else {

        $self->initDisplay( $req, 0 );
        return PE_FIRSTACCESS;
    }
}

sub authenticate {
    my ( $self, $req ) = @_;

    my $user = $req->user;

    my $authentication_options = $req->data->{webauthn_options};
    if ( !$authentication_options ) {
        $self->logger->error(
            "WebAuthn: missing authentication options for $user");
        return PE_WEBAUTHNFAILED;
    }
    my $_2fDevices = $req->data->{webauthn__2fDevices};
    if ( !$_2fDevices ) {
        $self->logger->error("WebAuthn: no 2FA registrations for $user");
        return PE_WEBAUTHNFAILED;
    }
    my $session_info = {
        _2fDevices          => $_2fDevices,
        _webAuthnUserHandle => $req->data->{webauthn__webAuthnUserHandle},
    };

    my $credential_json = $req->data->{webauthn_credential};
    if ( !$credential_json ) {
        $self->logger->error("WebAuthn: missing credential for $user");
        return PE_WEBAUTHNFAILED;
    }

    my $validation_result = eval {
        $self->validateAssertion( $req, $session_info, $authentication_options,
            $credential_json );
    };
    if ($@) {
        $self->logger->error("WebAuthn: validation error for $user ($@)");
        return PE_WEBAUTHNFAILED;
    }
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->authnLevel;
    return PE_OK;
}

sub getDisplayType {
    return "webauthnform";
}

# Define which error codes will stop Combination process
# @param res error code
# @return result 1 if stop is needed
sub stop {
    my ( $self, $res ) = @_;

    return 1
      if ( $res == PE_FIRSTACCESS );
    return 0;
}

1;
