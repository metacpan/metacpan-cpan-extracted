package Lemonldap::NG::Handler::Lib::OAuth2;
use Lemonldap::NG::Common::JWT qw(getAccessTokenSessionId);

use strict;

our $VERSION = '2.0.14';

sub retrieveSession {
    my ( $class, $req, $id ) = @_;
    my ($offlineId) = $id =~ /^O-(.*)/;

    # Retrieve regular session if this is not an offline access token
    unless ($offlineId) {
        my $data =
          $class->Lemonldap::NG::Handler::Main::retrieveSession( $req, $id );
        if ( ref($data) eq "HASH" ) {
            $data = { %{$data}, $class->_getTokenAttributes($req) };

            # Update cache
            $class->data($data);
        }
        else {
            $req->data->{oauth2_error} = 'invalid_token';
        }
        return $data;
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

        my $data = { %{ $session->data }, $class->_getTokenAttributes($req) };

        $class->data($data);

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

        return $data;
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
    my $access_token_sid = getAccessTokenSessionId($access_token);
    unless ($access_token_sid) {
        $req->data->{oauth2_error} = 'invalid_token';
        return;
    }
    my $infos = $class->getOIDCInfos($access_token_sid);
    unless ($infos) {
        $req->data->{oauth2_error} = 'invalid_token';
        return;
    }

    # Store scope and rpid for future session attributes
    if ( $infos->{rp} ) {
        my $rp = $infos->{rp};
        $req->data->{_scope}           = $infos->{scope};
        $req->data->{_oidc_grant_type} = $infos->{grant_type};
        $req->data->{_clientConfKey}   = $rp;
        if (    $class->tsv->{oauth2Options}->{$rp}
            and $class->tsv->{oauth2Options}->{$rp}->{clientId} )
        {
            $req->data->{_clientId} =
              $class->tsv->{oauth2Options}->{$rp}->{clientId};
        }
    }

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

    my $value = $class->Lemonldap::NG::Handler::Main::fetchId($req);
    unless ($value) {
        $req->data->{oauth2_error} = 'invalid_token';
    }
    return $value;
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

        # Verify that session is valid
        unless ( $oidcSession->data->{_utime} ) {
            $class->logger->error("_utime missing from Access Token session");
            return;
        }

        my $ttl = $class->tsv->{timeout} - time + $oidcSession->data->{_utime};
        $class->logger->debug( "Session TTL = " . $ttl );

        if ( time - $oidcSession->data->{_utime} > $class->tsv->{timeout} ) {
            $class->logger->info("Access Token session $id expired");
            return;
        }

        $infos = { %{ $oidcSession->data } };
    }
    else {
        $class->logger->info("OIDC Session $id can't be retrieved");
        $class->logger->info( $oidcSession->error );
    }

    return $infos;
}

## The OAuth2 handler does not redirect, we simply return a 401 with relevant
# information as described in https://tools.ietf.org/html/rfc6750#section-3
sub goToPortal {
    my ( $class, $req, $url, $arg, $path ) = @_;

    my $oauth2_error = '';
    if ( $req->data->{oauth2_error} ) {
        $oauth2_error = ' error="' . $req->data->{oauth2_error} . '"';
    }
    $class->set_header_out( $req,
        'WWW-Authenticate' => "Bearer" . $oauth2_error );
    return $class->HTTP_UNAUTHORIZED;
}

sub _getTokenAttributes {
    my ( $class, $req ) = @_;
    my %res;
    for my $attr (qw/_scope _clientConfKey _clientId _oidc_grant_type/) {
        if ( $req->data->{$attr} ) {
            $res{$attr} = $req->data->{$attr};
        }
    }
    return %res;
}

1;
