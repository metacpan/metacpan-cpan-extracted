package Lemonldap::NG::Portal::Plugins::AdminLogout;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Lib::OIDCPlugin';

our $VERSION = '2.23.4';

sub init {
    my ($self) = @_;

    return unless $self->SUPER::init;

    $self->addUnauthRoute( admintokenrevoke => 'adminTokenRevoke', ['POST'] );
    1;
}

sub adminTokenRevoke {
    my ( $self, $req ) = @_;
    my $auth = $req->env->{HTTP_AUTHORIZATION};
    unless ($auth
        and $auth eq "Bearer " . $self->conf->{adminLogoutServerSecret} )
    {
        return $self->p->sendError( $req, 'Bad credentials', 401 );
    }

    my $type = $req->param('token_hint');
    if ( $type eq 'SSO' ) {
        return $self->ssoLogout($req);
    }

    if ( $type =~ /^(?:refresh|access)_token$/ ) {
        return $self->oidc->_revokeToken(
            $req,
            sub {
                my ($session) = @_;
                return (
                    $self->oidc->getRP( $session->data->{client_id} ),
                    $session->data->{ $self->conf->{whatToTrace} }
                );
            },
            'OIDCTokenRevokeServer',
            $req->param('raw'),
        );
    }

    return $self->sendError( $req, "Unknown token_hint '$type'", 400 );
}

sub ssoLogout {
    my ( $self, $req ) = @_;
    my $id = $req->param('token')
      or return $self->sendError( $req, 'Missing token', 400 );

    # Like for tokens, the caller may give a storage identifier instead of a
    # session one. This is what the Manager does, since it collects sessions
    # using searchOn()
    my $raw = $req->param('raw');

    my $session =
      $self->p->getApacheSession( $id, ( $raw ? ( hashStore => 0 ) : () ) );
    unless ($session) {
        return $self->sendError( $req, "Session $id not found", 400 );
    }

    $req->userData( $req->sessionInfo( $session->data ) );
    return $self->p->do(
        $req,
        [
            @{ $self->p->beforeLogout },
            'authLogout',
            ( $raw ? [ 'deleteSession', rawSessionId => 1 ] : 'deleteSession' ),
        ]
    );
}

1;
