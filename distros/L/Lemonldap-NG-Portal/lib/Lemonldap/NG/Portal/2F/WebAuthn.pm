# WebAuthn second factor authentication
#
# This plugin handle authentications to ask WebAuthn second factor for users that
# have registered their WebAuthn authenticators
package Lemonldap::NG::Portal::2F::WebAuthn;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::URandom;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_SENDRESPONSE
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';
with 'Lemonldap::NG::Portal::Lib::WebAuthn';

# INITIALIZATION

has rule   => ( is => 'rw' );
has prefix => ( is => 'ro', default => 'webauthn' );
has logo   => ( is => 'rw', default => 'webauthn.png' );

sub init {
    my ($self) = @_;

    # If "activation" is just set to "enabled",
    # replace the rule to detect if user has registered its key
    $self->conf->{webauthn2fActivation} = 'has2f("WebAuthn")'
      if $self->conf->{webauthn2fActivation} eq '1';

    return $self->SUPER::init() ? 1 : 0;
}

# RUNNING METHODS

# Main method
sub run {
    my ( $self, $req, $token ) = @_;
    my $request = $self->generateChallenge( $req, $req->sessionInfo );
    unless ($request) {
        $self->logger->error(
            $self->prefix . '2f: no registered device for ' . $req->user );
        return PE_ERROR;
    }

    $self->ott->updateToken( $token, _webauthn_request => $request );

    # Prepare form
    my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
    my $tmp = $self->p->sendHtml(
        $req,
        'webauthn2fcheck',
        params => {
            DATA          => to_json( { request => $request } ),
            TOKEN         => $token,
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayConnected
        }
    );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $user            = $session->{ $self->conf->{whatToTrace} };
    my $credential_json = $req->param('credential');

    unless ($credential_json) {
        $self->logger->error(
            $self->prefix . '2f: missing signature parameter' );
        return PE_ERROR;
    }

    my $signature_options = $session->{_webauthn_request};
    delete $session->{_webauthn_request};

    my $validation_result = eval {
        $self->validateAssertion( $req, $session, $signature_options,
            $credential_json );
    };
    if ($@) {
        $self->logger->error(
            $self->prefix . "2f: validation error for $user ($@)" );
        return PE_ERROR;
    }

    if ( $validation_result->{success} == 1 ) {
        return PE_OK;
    }
    else {
        $self->logger->error(
            $self->prefix . "2f: validation did not return success for $user" );
        return PE_ERROR;
    }
}

1;
