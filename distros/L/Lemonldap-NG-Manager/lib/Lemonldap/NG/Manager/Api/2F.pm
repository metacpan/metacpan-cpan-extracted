package Lemonldap::NG::Manager::Api::2F;

our $VERSION = '2.19.0';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;
use JSON;

use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Util qw/genId2F display2F filterKey2F/;

sub getSecondFactors {
    my ( $self, $req ) = @_;
    my ( $uid, $res );

    $uid = $req->params('_uid')
      or return $self->searchSecondFactors($req);

    $self->logger->debug("[API] 2F for $uid requested");

    $res = $self->_get2F($uid);

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, $res->{secondFactors} );
}

sub getSecondFactorsByType {
    my ( $self, $req ) = @_;
    my ( $uid, $type, $res );

    $uid = $req->params('_uid')
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

    $uid = $req->params('_uid')
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
    my ( $self, $req, @path ) = @_;
    my ( $uid, $res );

    # Return an error on
    @path
      and return $self->sendError( $req, 'Invalid URI, provide /id/ or /type/',
        400 );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $self->logger->debug("[API] Delete all 2F for $uid requested");

    $res = $self->_delete2F( $req, $uid );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, { message => $res->{msg} } );
}

sub searchSecondFactors {
    my ( $self, $req ) = @_;

    my $uid   = $req->param('uid') || '*';
    my @types = $req->parameters->get_all('type');
    use Hash::MultiValue;
    my $search_params =
      Hash::MultiValue->from_mixed( { _session_uid => $uid, type => \@types } );

    my $res = $self->search2F( $req, $self->_getPersistentMod, "Persistent",
        $search_params, 1 );

    if ( $res->{result} ) {
        my $api_result = [];

        my @sorted_results =
          sort { $a->{userId} cmp $b->{userId} } @{ $res->{values} || [] };
        for my $result (@sorted_results) {
            push @$api_result, {
                uid           => $result->{userId},
                secondFactors => [
                    map {
                        {
                            id   => genId2F($_),
                            type => $_->{type},
                            name => $_->{name}
                        }
                    } @{ $result->{_2fDevices} || [] }
                ]

            };
        }
        return $self->sendJSONresponse( $req, $api_result );
    }
    else {
        return $self->sendError( $req, $res->{msg}, $res->{code} );
    }
}

sub deleteSecondFactorsById {
    my ( $self, $req ) = @_;
    my ( $uid, $id, $res );

    $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $id = $req->params('id')
      or return $self->sendError( $req, 'id is missing', 400 );

    $self->logger->debug("[API] Delete 2F for $uid with id $id requested");

    $res = $self->_delete2F( $req, $uid, undef, $id );

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

    $res = $self->_delete2F( $req, $uid, uc $type );

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
            if (    ( !defined $type or uc($type) eq uc( $device->{type} ) )
                and ( !defined $id or $id eq genId2F($device) ) )
            {
                push @secondFactors,
                  { %{ filterKey2F($device) }, id => genId2F($device), };
            }
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
                    $removed->{ genId2F($element) } = $element;
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
    my ( $self, $req, $uid, $type, $id ) = @_;
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
    if ($count) {
        my @list_log = map { display2F( $removed->{$_} ) } keys %$removed;
        my $list_log = join( ",", @list_log );
        $self->auditLog(
            $req,
            code        => "API_2FA_DELETED",
            message     => ("[API] 2FA deletion for $uid: $list_log"),
            user        => $uid,
            removed_2fa => \@list_log,
        );
    }

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

sub addSecondFactor {
    my ( $self, $req ) = @_;

    my $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    $self->logger->debug("[API] Add 2F for $uid");

    my $add = $req->jsonBodyToObj;
    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ( $add and ref($add) eq "HASH" );

    return $self->sendError( $req, 'Invalid input: type is missing', 400 )
      unless ( defined $add->{type} );

    return $self->sendError( $req, 'Invalid input: epoch is forbidden', 400 )
      if ( defined $add->{epoch} );

    my $allow_create =
      (      $req->params('create')
          && $req->params('create') ne "false"
          && $req->params('create') ne "0" );

    my $res = $self->_add2F( $uid, undef, $add, $allow_create );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      if ( $res->{res} ne 'ok' );
    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub addSecondFactorByType {
    my ( $self, $req ) = @_;

    my $uid = $req->params('uid')
      or return $self->sendError( $req, 'uid is missing', 400 );

    my $type = $req->params('type')
      or return $self->sendError( $req, 'type is missing', 400 );

    my $add = $req->jsonBodyToObj;
    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ( $add and ref($add) eq "HASH" );

    $self->logger->debug("[API] Add $type 2F for $uid");

    my $allow_create =
      (      $req->params('create')
          && $req->params('create') ne "false"
          && $req->params('create') ne "0" );

    my $res = $self->_add2F( $uid, $type, $add, $allow_create );

    return $self->sendError( $req, $res->{msg}, $res->{code} )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub _transformNew2f {
    my ( $self, $type, $add ) = @_;

    # Generic API, no transformation is done
    if ( !defined($type) ) {
        return {
            res    => "ok",
            device => $add,
        };
    }

    if ( uc($type) eq "TOTP" ) {
        return $self->_transformNew2fTotp( $type, $add );
    }

    else {
        return {
            res  => "ko",
            code => 400,
            msg  => "Invalid type: $type",
        };
    }
}

sub _transformNew2fTotp {
    my ( $self, $type, $add ) = @_;

    if ( !$add->{key} ) {
        return {
            res  => "ko",
            code => 400,
            msg  => "Invalid input: missing \"key\" parameter",
        };
    }

    my $secret = $self->_totpKeyToSecret( $add->{key} );
    if ( !$secret ) {
        return {
            res  => "ko",
            code => 400,
            msg  => "Invalid secret: you must provide a base32-encoded key",
        };
    }

    my $newdevice = {
        type => "TOTP",
        ( $add->{name} ? ( name => $add->{name} ) : () ),
        _secret => $secret,
    };

    return {
        res    => "ok",
        device => $newdevice,
    };
}

sub _totpKeyToSecret {
    my ( $self, $key ) = @_;

    return unless $key;

    # Make sure only BASE32 characters are present
    if ( uc($key) =~ /^[ABCDEFGHIJKLMNOPQRSTUVWXYZ234567\s]*$/ ) {

        # Trim spaces and normalize to lowercase
        my $newKey = $key =~ s/\s//gr;
        return $self->totp_encrypt->get_storable_secret( lc($newKey) );
    }

    return undef;
}

sub _add2F {
    my ( $self, $uid, $type, $add, $allow_create ) = @_;

    my $res = $self->_transformNew2f( $type, $add );
    return $res if ( $res->{res} ne 'ok' );

    my $device = $res->{device};

    $device->{epoch} = time();

    $res =
      $self->_add2FToSessions( $uid, $device, $self->_getPersistentMod,
        'Persistent', '_session_uid', $allow_create );
    return $res if ( $res->{res} ne 'ok' );

    # Add to existing sessions
    my $whatToTrace = Lemonldap::NG::Handler::PSGI::Main->tsv->{whatToTrace};
    $res =
      $self->_add2FToSessions( $uid, $device, $self->_getSSOMod, 'SSO',
        $whatToTrace );

    return { res => "ok" };
}

sub _add2FToSessions {
    my ( $self, $uid, $add, $mod, $kind, $key, $allow_create ) = @_;

    my ( $sessions, $session, $devices, @keep, $removed,
        $total, $module, $localStorage );
    $sessions = $self->_getSessions2F( $mod, $kind, $key, $uid );
    my $found = keys %$sessions;

    if ( !$found and $allow_create ) {
        my $ps = $self->getPersistentSession( $mod, $uid );
        $sessions = { $ps->id => { _2fDevices => undef } };
        $found    = 1;
    }

    foreach ( keys %$sessions ) {
        $session = $self->_getSession2F( $_, $mod )
          or return { res => 'ko', code => 500, msg => $@ };

        $devices = $self->_getDevicesFromSessionData( $session->data );
        push @$devices, $add;

        # Update session
        $self->logger->debug(
            "Adding " . display2F($add) . " to sessionId $_" );
        $session->data->{_2fDevices} = to_json($devices);
        $session->update( $session->data );
    }
    return {
        res     => "notfound",
        message => "User $uid was not found",
        code    => 404
      }
      if !$found;

    return { res => 'ok' };
}

1;
