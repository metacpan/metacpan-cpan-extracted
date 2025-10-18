package Lemonldap::NG::Portal::Plugins::AdminLogout;

use strict;
use Lemonldap::NG::Portal::Issuer::OpenIDConnect;
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.22.0';

has oidc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]
          ->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};
    }
);

sub init {
    my ($self) = @_;
    unless ( $self->conf->{issuerDBOpenIDConnectActivation} ) {
        $self->logger->error(
            'This plugin can be used only if OIDC server is enabled');
        return 0;
    }

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
    my $sessionData = $self->p->HANDLER->retrieveSession( $req, $id );
    $req->userData( $req->sessionInfo($sessionData) );
    return $self->p->do( $req,
        [ @{ $self->p->beforeLogout }, 'authLogout', 'deleteSession' ] );
}

1;
