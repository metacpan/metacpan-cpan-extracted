package Lemonldap::NG::Portal::Plugins::OIDCInternalTokenExchange;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Lib::OIDCTokenExchange';

our $VERSION = '2.20.0';

sub validateAudience {
    my ( $self, $req, $rp, $target, $requestedTokenType ) = @_;

    if ( $requestedTokenType and $requestedTokenType ne 'access_token' ) {
        $self->logger->debug("Requested token isn't declared as access_token");
        return 0;
    }

    unless ( $target->{audience} ) {
        $target->{rp} = $rp;
        return 1;
    }

    unless ( $target->{rp} ) {
        $self->logger->debug(
            "Token exchange request for an unexistent RP $target->{audience}");
        return 0;
    }

    return 1 if $target->{rp} eq $rp;

    my $list = $self->oidc->rpOptions->{ $target->{rp} }
      ->{oidcRPMetaDataOptionsTokenXAuthorizedRP};
    unless ( $list and grep { $_ eq $rp } split /[,;\s]+/, $list ) {
        $self->logger->debug(
            "Token exchange for an unauthorized RP ($rp => $target->{rp})");
        return 0;
    }
    return 1;
}

sub getUid {
    my ( $self, $req, $rp, $subjectToken, $subjectTokenType ) = @_;

    if ( $subjectTokenType and $subjectTokenType ne 'access_token' ) {
        $self->logger->error("Given token isn't declared as access_token");
        return 0;
    }

    my $accessTokenSession = $self->oidc->getAccessToken($subjectToken);
    unless ($accessTokenSession) {
        $self->logger->debug("Unable to validate subject_token $subjectToken");
        return 0;
    }

    unless ( $rp eq $accessTokenSession->data->{rp} ) {
        $self->logger->debug( "subject_token rp isn't $rp ("
              . $accessTokenSession->data->{rp}
              . ')s' );
        return 0;
    }

    my $id      = $accessTokenSession->data->{user_session_id};
    my $session = $self->p->getApacheSession($id);
    return $session->data->{ $self->conf->{whatToTrace} };
}

1;
