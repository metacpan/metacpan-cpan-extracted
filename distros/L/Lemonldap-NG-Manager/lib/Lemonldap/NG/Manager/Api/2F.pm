package Lemonldap::NG::Manager::Api::2F;

our $VERSION = '2.0.10';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;
use JSON;

use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Util qw/genId2F/;

sub getSecondFactors {
    my ( $self, $req ) = @_;
    my ( $uid, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $self->logger->debug("[API] 2F for $uid requested");

    $res = $self->_get2F($uid);

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, $res->{secondFactors} );
}

sub getSecondFactorsByType {
    my ( $self, $req ) = @_;
    my ( $uid, $type, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'Uid is missing', 400 );

    $type = $req->params('type')
      or return $self->sendError( $req, 'Type is missing', 400 );

    $self->logger->debug("[API] 2F for $uid with type $type requested");

    $res = $self->_get2F( $uid, uc $type );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, $res->{secondFactors} );
}

sub getSecondFactorsById {
    my ( $self, $req ) = @_;
    my ( $uid, $id, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $id = $req->params('id')
      or return $self->sendError( $req, 'id is missing', 400 );

    $self->logger->debug("[API] 2F for $uid with id $id requested");

    $res = $self->_get2F( $uid, undef, $id );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendError( $req, "2F id '$id' not found for user '$uid'",
        404 )
      unless ( scalar @{ $res->{secondFactors} } > 0 );

    return $self->sendJSONresponse( $req, @{ $res->{secondFactors} }[0] );
}

sub deleteSecondFactors {
    my ( $self, $req ) = @_;
    my ( $uid, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $self->logger->debug("[API] Delete all 2F for $uid requested");

    $res = $self->_delete2F($uid);

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, { message => $res->{msg} } );
}

sub deleteSecondFactorsById {
    my ( $self, $req ) = @_;
    my ( $uid, $id, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $id = $req->params('id')
      or return $self->sendError( $req, 'id is missing', 400 );

    $self->logger->debug("[API] Delete 2F for $uid with id $id requested");

    $res = $self->_delete2F( $uid, undef, $id );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendError( $req, "2F id '$id' not found for user '$uid'",
        404 )
      unless ( $res->{removed} > 0 );

    return $self->sendJSONresponse( $req, { message => $res->{msg} } );
}

sub deleteSecondFactorsByType {
    my ( $self, $req ) = @_;
    my ( $uid, $type, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $type = $req->params('type')
      or return $self->sendError( $req, 'type is missing', 400 );

    $self->logger->debug(
        "[API] Delete all 2F for $uid with type $type requested");

    $res = $self->_delete2F( $uid, uc $type );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, { message => $res->{msg} } );
}

sub _get2F {
    my ( $self, $uid, $type, $id ) = @_;
    my ( $res, $psessions, @secondFactors );

    $psessions = $self->_getSessions2F( $self->_getPersistentMod, 'Persistent',
        '_session_uid', $uid );

    foreach ( keys %$psessions ) {
        my $devices = $self->_getDevicesFromSessionData( $psessions->{$_} );
        foreach my $device ( @{$devices} ) {
            $self->logger->debug(
"Check device [epoch=$device->{epoch}, type=$device->{type}, name=$device->{name}]"
            );
            push @secondFactors,
              {
                id   => genId2F($device),
                type => $device->{type},
                name => $device->{name}
              }
              unless ( ( defined $type and uc($type) ne uc( $device->{type} ) )
                or ( defined $id and $id ne genId2F($device) ) );
        }
    }
    $self->logger->debug(
        "Found " . scalar @secondFactors . " 2F devices for uid $uid." );
    return { res => 'ok', secondFactors => [@secondFactors] };
}

sub _getSessions2F {
    my ( $self, $mod, $kind, $key, $uid ) = @_;
    $self->logger->debug("Looking for sessions for uid $uid ...");
    my $sessions =
      Lemonldap::NG::Common::Apache::Session->searchOn( $mod->{options}, $key,
        $uid,
        ( '_session_kind', '_session_uid', '_session_id', '_2fDevices' ) );
    foreach ( keys %$sessions ) {
        delete $sessions->{$_}
          unless ( $sessions->{$_}->{_session_kind} eq $kind );
    }
    $self->logger->debug( "Found "
          . scalar( keys %$sessions )
          . " $kind sessions for uid $uid." );

    return $sessions;
}

sub _getSession2F {
    my ( $self, $sessionId, $mod ) = @_;
    $self->logger->debug("Looking for session with sessionId $sessionId ...");
    my $session = $self->getApacheSession( $mod, $sessionId );
    $self->logger->debug(
        defined $session
        ? "Session $sessionId found."
        : " No session found for sessionId $sessionId"
    );

    return $session;
}

sub _delete2FFromSessions {
    my ( $self, $uid, $type, $id, $mod, $kind, $key ) = @_;
    my ( $sessions, $session, $devices, @keep, $removed,
        $total, $module, $localStorage );
    $sessions = $self->_getSessions2F( $mod, $kind, $key, $uid );
    foreach ( keys %$sessions ) {

        $session = $self->_getSession2F( $_, $mod )
          or return { res => 'ko', code => 500, msg => $@ };

        $self->logger->debug(
            "Looking for 2F Device(s) attached to sessionId $_");

        if ( $session->data->{_2fDevices} ) {
            $devices = $self->_getDevicesFromSessionData( $session->data );
            $total   = scalar @$devices;

            $self->logger->debug(
                "Found $total 2F devices attached to sessionId $_");

            @keep = ();
            while (@$devices) {
                my $element = shift @$devices;
                if (
                    ( defined $type or defined $id )
                    and ( (
                            defined $type
                            and uc($type) ne uc( $element->{type} )
                        )
                        or ( defined $id and $id ne genId2F($element) )
                    )
                  )
                {
                    push @keep, $element;
                }
                else {
                    $removed->{ genId2F($element) } = "removed";
                }
            }
            if ( ( $total - scalar @keep ) > 0 ) {

                # Update session
                $self->logger->debug( "Removing "
                      . ( $total - scalar @keep )
                      . " 2F device(s) attached to sessionId $_ ..." );
                $session->data->{_2fDevices} = to_json( \@keep );
                $session->update( $session->data );

                # Delete from local cache
                if ( $session->{options}->{localStorage} ) {
                    $module = $session->{options}->{localStorage};
                    eval "use $module;";
                    $localStorage =
                      $module->new(
                        $session->{options}->{localStorageOptions} );
                    if ( $localStorage->get($_) ) {
                        $self->logger->debug(
                            "Delete local cache for session $_");
                        $localStorage->remove($_);
                    }
                }
            }
            else {
                $self->logger->debug(
"No matching 2F devices attached to sessionId $_ were selected for removal."
                );
            }
        }
        else {
            $self->logger->debug(
                "No 2F devices attached to sessionId $_ were found.");
        }
    }

    return { res => 'ok', removed => $removed };
}

sub _delete2F {
    my ( $self, $uid, $type, $id ) = @_;
    my ( $res, $removed, $count );

    $res =
      $self->_delete2FFromSessions( $uid, $type, $id, $self->_getPersistentMod,
        'Persistent', '_session_uid' );
    return $res if ( $res->{res} ne 'ok' );
    $removed = $res->{removed} || {};

    my $whatToTrace = Lemonldap::NG::Handler::PSGI::Main->tsv->{whatToTrace};
    $res =
      $self->_delete2FFromSessions( $uid, $type, $id, $self->_getSSOMod, 'SSO',
        $whatToTrace );
    return $res if ( $res->{res} ne 'ok' );
    $res->{removed} ||= {};

    # merge results
    $removed = { %$removed, %{ $res->{removed} } };
    $count   = scalar( keys %$removed );

    return {
        res     => 'ok',
        removed => $count,
        msg     => $count > 0
        ? "Successful operation: " . $count . " 2F were removed"
        : "No operation performed"
    };
}

sub _getDevicesFromSessionData {
    my ( $self, $sessiondata ) = @_;
    if ( $sessiondata->{_2fDevices} ) {
        my $devices;
        eval { $devices = from_json( $sessiondata->{_2fDevices} ); };
        if ($@) {
            $self->logger->warn("Error deserializing _2fDevices: $@");
        }
        else {
            if ( ref($devices) eq "ARRAY" ) {
                return $devices;
            }
            else {
                $self->logger->warn(
                    "Error deserializing _2fDevices: not a JSON Array");
            }
        }
    }
    return [];
}

1;
