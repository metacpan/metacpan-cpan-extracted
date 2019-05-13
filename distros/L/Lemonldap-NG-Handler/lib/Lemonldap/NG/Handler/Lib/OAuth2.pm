package Lemonldap::NG::Handler::Lib::OAuth2;

use strict;

our $VERSION = '2.0.4';

sub fetchId {
    my ( $class, $req ) = @_;

    my $access_token;
    my $authorization = $req->{env}->{HTTP_AUTHORIZATION};

    if ( $authorization
        and ( ($access_token) = ( $authorization =~ /^Bearer (.+)$/i ) ) )
    {
        $class->logger->debug( 'Found OAuth2 access token ' . $access_token );
    }
    else {
        return $class->Lemonldap::NG::Handler::Main::fetchId($req);
    }

    # Get access token session
    my $infos = $class->getOIDCInfos($access_token);
    if ( my $_session_id = $infos->{user_session_id} ) {
        $class->logger->debug( 'Get user session id ' . $_session_id );
        return $_session_id;
    }

    return $class->Lemonldap::NG::Handler::Main::fetchId($req);
}

## @rmethod protected hash getOIDCInfos(id)
# Tries to retrieve the OIDC session, get infos
# @return OIDC session infos
sub getOIDCInfos {
    my ( $class, $id ) = @_;
    my $infos = {};

    # Get the session
    my $oidcSession = Lemonldap::NG::Common::Session->new( {
            storageModule        => $class->tsv->{oidcStorageModule},
            storageModuleOptions => $class->tsv->{oidcStorageOptions},
            cacheModule          => $class->tsv->{sessionCacheModule},
            cacheModuleOptions   => $class->tsv->{sessionCacheOptions},
            id                   => $id,
            kind                 => "OIDCI",
        }
    );

    unless ( $oidcSession->error ) {
        $class->logger->debug("Get OIDC session $id");

        $infos->{user_session_id} = $oidcSession->data->{user_session_id};
    }
    else {
        $class->logger->info("OIDC Session $id can't be retrieved");
        $class->logger->info( $oidcSession->error );
    }

    return $infos;
}

1;
