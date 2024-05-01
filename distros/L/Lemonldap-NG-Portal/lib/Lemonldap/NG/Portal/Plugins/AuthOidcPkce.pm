package Lemonldap::NG::Portal::Plugins::AuthOidcPkce;

use strict;
use Digest::SHA qw(sha256);
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR);
use MIME::Base64 'encode_base64url';
use Mouse;
use String::Random 'random_string';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has oidc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->p->loadedModules->{'Lemonldap::NG::Portal::Auth::OpenIDConnect'};
    }
);

use constant hook => {
    oidcGenerateAuthenticationRequest => 'setChallenge',
    oidcGenerateTokenRequest          => 'setPkce'
};

use constant RS_MSK => 's' x 16;

sub init { 1 }

sub setChallenge {
    my ( $self, $req, $op, $token_request_params ) = @_;
    unless ( $self->oidc ) {
        $self->logger->error('Authentication is not OIDC, aborting');
        return PE_ERROR;
    }
    if (    $self->oidc->opOptions->{$op}
        and $self->oidc->opOptions->{$op}->{oidcOPMetaDataOptionsRequirePkce} )
    {
        my $code = random_string(RS_MSK);
        my $realState =
          $self->oidc->state_ott->getToken( $token_request_params->{state}, 1 );
        $realState->{state}->{data__auth_pkce} = $code;
        $self->oidc->state_ott->updateToken( $token_request_params->{state},
            state => $realState->{state} );
        my $challenge = encode_base64url( sha256($code) );
        $token_request_params->{code_challenge}        = $challenge;
        $token_request_params->{code_challenge_method} = 'S256';
    }
    return PE_OK;
}

sub setPkce {
    my ( $self, $req, $op, $authorize_request_params ) = @_;
    if ( $req->data->{_auth_pkce} ) {
        $authorize_request_params->{code_verifier} = $req->data->{_auth_pkce};
    }
    return PE_OK;
}

1;
