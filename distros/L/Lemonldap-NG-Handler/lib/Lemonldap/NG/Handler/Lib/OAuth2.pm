package Lemonldap::NG::Handler::Lib::OAuth2;

use strict;

our $VERSION = '2.0.4';

sub retrieveSession {
    my ( $class, $req, $id ) = @_;
    my ($offlineId) = $id =~ /^O-(.*)/;

    # Retrieve regular session if this is not an offline access token
    unless ($offlineId) {
        return $class->Lemonldap::NG::Handler::Main::retrieveSession( $req,
            $id );
    }

    # 2. Get the session from cache or backend
    my $session = $req->data->{session} = (
        Lemonldap::NG::Common::Session->new( {
                storageModule        => $class->tsv->{oidcStorageModule},
                storageModuleOptions => $class->tsv->{oidcStorageOptions},
                cacheModule          => $class->tsv->{sessionCacheModule},
                cacheModuleOptions   => $class->tsv->{sessionCacheOptions},
                id                   => $offlineId,
                kind                 => "OIDCI",
            }
        )
    );

    unless ( $session->error ) {

        $class->data( $session->data );
        $class->logger->debug("Get session $offlineId from Handler::Main::Run");

        # Verify that session is valid
        $class->logger->error(
"_utime is not defined. This should not happen. Check if it is well transmitted to handler"
        ) unless $session->data->{_utime};

        my $ttl = $class->tsv->{timeout} - time + $session->data->{_utime};
        $class->logger->debug( "Session TTL = " . $ttl );

        if ( time - $session->data->{_utime} > $class->tsv->{timeout} ) {
            $class->logger->info("Session $id expired");

            # Clean cached data
            $class->data( {} );
            return 0;
        }

        return $session->data;
    }
    else {
        $class->logger->info("Session $offlineId can't be retrieved");
        $class->logger->info( $session->error );

        return 0;
    }
}

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
    # If this token is tied to a regular session ID
    if ( my $_session_id = $infos->{user_session_id} ) {
        $class->logger->debug( 'Get user session id ' . $_session_id );
        return $_session_id;
    }
    # If this token is tied to an Offline session
    if ( my $_session_id = $infos->{offline_session_id} ) {
        $class->logger->debug( 'Get offline session id ' . $_session_id );
        return "O-$_session_id";
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

        $infos->{user_session_id}    = $oidcSession->data->{user_session_id};
        $infos->{offline_session_id} = $oidcSession->data->{offline_session_id};
    }
    else {
        $class->logger->info("OIDC Session $id can't be retrieved");
        $class->logger->info( $oidcSession->error );
    }

    return $infos;
}

1;
