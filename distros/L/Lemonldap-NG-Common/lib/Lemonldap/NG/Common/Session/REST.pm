package Lemonldap::NG::Common::Session::REST;

use strict;
use Mouse;
use Lemonldap::NG::Common::Util qw(isHiddenAttr);
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::Util qw/display2F getPSessionID/;
use JSON qw(from_json to_json);

our $VERSION = '2.19.0';

has sessionTypes => ( is => 'rw' );

# Boolean value to tell if storage ID is hashed or not
has hashedSessionStore => ( is => 'rw' );

sub setTypes {
    my ( $self, $conf ) = @_;
    foreach my $type (@sessionTypes) {
        if ( my $tmp =
            $self->{ $type . 'Storage' } || $conf->{ $type . 'Storage' } )
        {
            $self->{sessionTypes}->{$type}->{module} = $tmp;
            $self->{sessionTypes}->{$type}->{options} =
                 $self->{ $type . 'StorageOptions' }
              || $conf->{ $type . 'StorageOptions' }
              || {};
            $self->{sessionTypes}->{$type}->{kind} =
              ( $type eq 'global' ? 'SSO' : ucfirst($type) );
        }
    }

    my $offlinebackend = $self->{sessionTypes}->{oidc} ? 'oidc' : 'global';
    $self->{sessionTypes}->{offline}->{module} =
      $self->{sessionTypes}->{$offlinebackend}->{module};
    $self->{sessionTypes}->{offline}->{options} =
      $self->{sessionTypes}->{$offlinebackend}->{options};
    $self->{sessionTypes}->{offline}->{kind} = "OIDCI";
    $self->hashedSessionStore( $conf->{hashedSessionStore} );
}

### SEE LEMONLDAP::NG::COMMON::SESSION FOR AVAILABLE FUNCTIONS

sub delSession {
    my ( $self, $req ) = @_;
    my $type = $req->params('sessionType');
    my $mod  = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );
    my $session = $self->getApacheSession( $mod, $id );
    $self->auditLog(
        $req,
        message => "Deleted $type session: $id",
        code    => "SESSION_DELETED",
        type    => $type,
        id      => $id
    );
    $session->remove;

    Lemonldap::NG::Handler::PSGI::Main->localUnlog( $req, $id );
    return $session->error
      ? $self->sendError( $req, $session->error, 200 )
      : $self->sendJSONresponse( $req, { result => 1 } );
}

sub deleteOIDCConsent {
    my ( $self, $req ) = @_;
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );

    # Try to read session
    $self->logger->debug("Loading session: $id");
    my $session = $self->getApacheSession( $mod, $id )
      or return $self->sendError( $req, undef, 400 );

    # Try to read OIDC Consent parameters
    $self->logger->debug("Reading parameters...");
    my $params = $req->parameters();
    my $rp     = $params->{rp}
      or
      return $self->sendError( $req, 'OIDC consent "RP" parameter is missing',
        400 );
    my $epoch = $params->{epoch}
      or return $self->sendError( $req,
        'OIDC consent "epoch" parameter is missing', 400 );

    # Try to load OIDC Consents from session
    $self->logger->debug("Looking for OIDC consent(s)...");
    my $_oidcConsents;
    if ( $session->data->{_oidcConsents} ) {
        $_oidcConsents = eval {
            from_json( $session->data->{_oidcConsents}, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Corrupted session (_oidcConsents): $@");
            return $self->p->sendError( $req, "Corrupted session", 500 );
        }
    }
    else {
        $self->logger->debug("No OIDC consent found");
        $_oidcConsents = [];
    }

    # Delete OIDC Consent
    $self->logger->debug("Reading OIDC consent(s)...");
    my @keep = ();
    while (@$_oidcConsents) {
        my $element = shift @$_oidcConsents;

        $self->logger->debug(
            "Searching for OIDC Consent to delete -> $rp / $epoch...");
        if ( defined $element->{rp} && defined $element->{epoch} ) {
            push @keep, $element
              unless ( ( $element->{rp} eq $rp )
                and ( $element->{epoch} eq $epoch ) );
        }
        else {
            $self->logger->error("Corrupted OIDC consent");
        }
    }

    # Update session
    $self->logger->debug("Saving OIDC consents...");
    $session->data->{_oidcConsents} = to_json( \@keep );
    $self->logger->debug("Update session");
    $session->update( \%{ $session->data } );

    Lemonldap::NG::Handler::PSGI::Main->localUnlog( $req, $id );
    return $session->error
      ? $self->sendError( $req, $session->error, 200 )
      : $self->sendJSONresponse( $req, { result => 1 } );
}

sub get2F {
    my ( $self, $req, $session, $skey ) = @_;

    # Case 1: only one session is required
    if ($session) {
        return $self->session( $req, $session, $skey );
    }

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, 'Bad mode', 400 );
    my $params = $req->parameters();
    my $type   = delete $params->{sessionType};
    $type = ucfirst($type);

    # Case 2: list of sessions
    my $res = $self->search2F( $req, $mod, $type, $params );

    if ( $res->{result} ) {
        return $self->sendJSONresponse( $req, $res );
    }
    else {
        my $code = $res->{code} || 500;
        my $msg  = $res->{msg}  || "Failed to search 2FAs";
        return $self->sendError( $req, $msg, $code );
    }
}

sub search2F {
    my ( $self, $req, $mod, $type, $params, $return_devices ) = @_;

    my $whatToTrace = Lemonldap::NG::Handler::PSGI::Main->tsv->{whatToTrace};

    # 2.1 Get fields to require
    my @fields = ( '_httpSessionType', $whatToTrace, '_2fDevices' );
    if ( my $groupBy = $params->{groupBy} ) {
        $groupBy =~ s/^substr\((\w+)(?:,\d+(?:,\d+)?)?\)$/$1/;
        $groupBy =~ s/^_whatToTrace$/$whatToTrace/o
          or push @fields, $groupBy;
    }
    else {
        push @fields, '_utime';
    }

    # 2.2 Restrict query if possible: search for filters (any query arg that is
    #     not a keyword)
    my $moduleOptions = $mod->{options};
    $moduleOptions->{backend} = $mod->{module};

    my @display_types = $params->get_all('type');
    $params->remove('type');

    my %filters = map {
        my $s = $_;
        $s =~ s/\b_whatToTrace\b/$whatToTrace/o;
        /^groupBy$/
          ? ()
          : ( $s => $params->{$_} );
    } keys %$params;
    $filters{_session_kind} = $type;

    push @fields, keys(%filters);
    {
        my %seen;
        @fields = grep { !$seen{$_}++ } @fields;
    }

    # For now, only one argument can be passed to
    # Lemonldap::NG::Common::Apache::Session so just the first filter is
    # used
    my ($firstFilter) = sort {
            $filters{$a} =~ m#^[\w:]+/\d+\*?$# ? 1
          : $filters{$b} =~ m#^[\w:]+/\d+\*?$# ? -1
          : $a eq '_session_kind'              ? 1
          : $b eq '_session_kind'              ? -1
          : $a cmp $b
    } keys %filters;

    # Check if a '*' is required
    my $function = 'searchOn';
    $function = 'searchOnExpr'
      if ( grep { /\*/ and not m#^[\w:]+/\d+\*?$# }
        ( $filters{$firstFilter} ) );
    $self->logger->debug(
        "First filter: $firstFilter = $filters{$firstFilter} ($function)");

    my $res =
      Lemonldap::NG::Common::Apache::Session->$function( $moduleOptions,
        $firstFilter, $filters{$firstFilter}, @fields );

    return {
        result => 1,
        count  => 0,
        total  => 0,
        values => []
      }
      unless ( $res and %$res );

    delete $filters{$firstFilter}
      unless ( grep { /\*/ and not m#^[\w:]+/\d+\*?$# }
        ( $filters{$firstFilter} ) );
    foreach my $k ( keys %filters ) {
        $self->logger->debug("Removing unless $k =~ /^$filters{$k}\$/");
        $filters{$k} =~ s/\./\\./g;
        $filters{$k} =~ s/\*/\.\*/g;
        foreach my $session ( keys %$res ) {
            if ( $res->{$session}->{$k} ) {
                delete $res->{$session}
                  unless ( $res->{$session}->{$k} =~ /^$filters{$k}$/ );
            }
        }
    }

    # Remove sessions without at least one 2F device(s)
    $self->logger->debug(
        "Removing sessions without at least one 2F device(s)...");
    foreach my $session ( keys %$res ) {
        delete $res->{$session}
          unless ( defined $res->{$session}->{_2fDevices}
            and $res->{$session}->{_2fDevices} =~ /"type"/s );
    }

    my $all = ( keys %$res );

    # Filter 2FA sessions if needed
    if (@display_types) {
        $self->logger->debug("Filtering 2F sessions...");
        foreach (@display_types) {
            foreach my $session ( keys %$res ) {
                delete $res->{$session}
                  unless ( defined $res->{$session}->{_2fDevices}
                    and $res->{$session}->{_2fDevices} =~ /"type":\s*"$_"/s );
            }
            $self->logger->debug(
                "Removing sessions unless a $_ device is registered");
        }
    }

    my $total = ( keys %$res );
    $self->logger->debug("2FA session(s) left : $total / $all");

    if ( my $group = $req->params('groupBy') ) {
        my $r;
        $group =~ s/\b_whatToTrace\b/$whatToTrace/o;

        # Substrings
        if ( $group =~ /^substr\((\w+)(?:,(\d+)(?:,(\d+))?)?\)$/ ) {
            my ( $field, $length, $start ) = ( $1, $2, $3 );
            $start ||= 0;
            $length = 1 if ( $length < 1 );
            foreach my $k ( keys %$res ) {
                $r->{ substr $res->{$k}->{$field}, $start, $length }++
                  if ( $res->{$k}->{$field} );
            }
            $group = $field;
        }

        # Simple field groupBy query
        elsif ( $group =~ /^\w+$/ ) {
            eval {
                foreach my $k ( keys %$res ) {
                    $r->{ $res->{$k}->{$group} }++;
                }
            };
            return {
                result => 0,
                msg    =>
qq{Use of an uninitialized attribute "$group" to group sessions},
                code => 400,
              }
              if ($@);
        }
        else {
            return {
                result => 0,
                msg    => 'Syntax error in groupBy',
                code   => 400,
            };
        }

        # Build result
        $res = [
            sort {
                my @a = ( $a->{value} =~ /^(\d+)(?:\.(\d+))*$/ );
                my @b = ( $b->{value} =~ /^(\d+)(?:\.(\d+))*$/ );
                ( @a and @b )
                  ? ( $a[0] <=> $b[0]
                      or $a[1] <=> $b[1]
                      or $a[2] <=> $b[2]
                      or $a[3] <=> $b[3] )
                  : $a->{value} cmp $b->{value}
              }
              map { { value => $_, count => $r->{$_} } } keys %$r
        ];
    }

    # Else, $res elements will be like:
    #   { session => <sessionId>, userId => <_session_uid> }
    else {
        $res = [
            map {
                {
                    session => $_,
                    userId  => $res->{$_}->{_session_uid},
                    (
                        $return_devices
                        ? (
                            _2fDevices => eval {
                                from_json(
                                    $res->{$_}->{_2fDevices},
                                    { allow_nonref => 1 }
                                );
                            }
                          )
                        : ()
                    )
                }
              }
              keys %$res
        ];
    }

    return {
        result => 1,
        count  => scalar(@$res),
        total  => $total,
        values => $res
    };
}

sub delete2F {
    my ( $self, $req ) = @_;
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );

    # Try to read session
    $self->logger->debug("Loading session : $id");
    my $session = $self->getApacheSession( $mod, $id )
      or return $self->sendError( $req, undef, 400 );

    # Try to read 2F parameters
    $self->logger->debug("Reading parameters...");
    my $params = $req->parameters();
    my $type   = $params->{type}
      or return $self->sendError( $req, '2F device "type" parameter is missing',
        400 );
    my $epoch = $params->{epoch}
      or
      return $self->sendError( $req, '2F device "epoch" parameter is missing',
        400 );

    # Try to load 2F device(s) from session
    $self->logger->debug("Looking for 2F device(s)...");
    my $_2fDevices;
    if ( $session->data->{_2fDevices} ) {
        $_2fDevices = eval {
            from_json( $session->data->{_2fDevices}, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Corrupted session (_2fDevices) : $@");
            return $self->p->sendError( $req, "Corrupted session", 500 );
        }
    }
    else {
        $self->logger->debug("No 2F device found");
        $_2fDevices = [];
    }

    # Delete 2F device
    $self->logger->debug("Reading 2F device(s)...");
    my @keep = ();
    while (@$_2fDevices) {
        my $element = shift @$_2fDevices;

        $self->logger->debug("Looking for 2F device to delete: [$type]$epoch");
        if ( defined $element->{type} && defined $element->{epoch} ) {
            if (    ( $element->{type} eq $type )
                and ( $element->{epoch} eq $epoch ) )
            {
                my $uid = $session->data->{_session_uid};
                $self->auditLog(
                    $req,
                    message =>
                      ( "2FA deletion for $uid: " . display2F($element) ),
                    code => "2FA_DELETED",
                    user => $uid,
                    sfa  => display2F($element)
                );
            }
            else {
                push @keep, $element;
            }
        }
        else {
            $self->logger->error("Corrupted _2fDevice");
        }
    }

    # Update session
    $self->logger->debug("Saving 2F devices...");
    $session->data->{_2fDevices} = to_json( \@keep );
    $self->logger->debug("Update session");
    $session->update( \%{ $session->data } );

    Lemonldap::NG::Handler::PSGI::Main->localUnlog( $req, $id );
    return $session->error
      ? $self->sendError( $req, $session->error, 200 )
      : $self->sendJSONresponse( $req, { result => 1 } );
}

sub _session {
    my ( $self, $raw, $req, $id, $skey ) = @_;
    my ( %h, $res );

    # When requesting a session, depending on the context, the cann can be
    # with the storage ID or the cookie value. the "hash=1' parameter indicates
    # that the query uses the cookie value
    return $self->sendError( $req, 'Bad request', 400 ) unless $id;
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );

    # Try to read session
    my $apacheSession = $self->getApacheSession( $mod, $id, hashStore => 0 )
      or return $self->sendError( $req, undef, 400 );

    my %session = %{ $apacheSession->data };
    unless ($raw) {
        foreach ( keys %session ) {
            $session{$_} = '******' if isHiddenAttr( $self->conf, $_ );
        }
    }

    if ($skey) {
        if ( $skey =~ s/^\[(.*)\]$/$1/ ) {
            my @sk  = split /,/, $skey;
            my $res = {};
            $res->{$_} = $session{$_} foreach (@sk);
            return $self->sendJSONresponse( $req, $res );
        }
        return $self->sendJSONresponse( $req, $session{$skey} );
    }
    else {
        return $self->sendJSONresponse( $req, \%session );
    }

    # TODO: check for utf-8 problems
}

sub session {
    my $self = shift;
    return $self->_session( 0, @_ );
}

sub rawSession {
    my $self = shift;
    return $self->_session( 1, @_ );
}

sub getApacheSession {
    my ( $self, $mod, $id, %args ) = @_;
    my $apacheSession = Lemonldap::NG::Common::Session->new( {

            # The request is done with the storage ID by default unless
            # hashStore is explicitly set to a true value
            hashStore     => $args{hashStore} && $self->hashedSessionStore,
            storageModule => $mod->{module},
            storageModuleOptions => $mod->{options},
            cacheModule          =>
              Lemonldap::NG::Handler::PSGI::Main->tsv->{sessionCacheModule},
            cacheModuleOptions =>
              Lemonldap::NG::Handler::PSGI::Main->tsv->{sessionCacheOptions},
            id    => $id,
            force => $args{force},
            ( $id         ? () : ( kind => $mod->{kind} ) ),
            ( $args{info} ? ( info => $args{info} ) : () ),
        }
    );
    if ( $apacheSession->error ) {
        $self->logger->error( $apacheSession->error );
        return undef;
    }
    $self->logger->debug("Get session $id from Common::Session::REST") if ($id);
    return $apacheSession;
}

sub getPersistentSession {
    my ( $self, $mod, $uid, $info ) = @_;

    # Compute persistent identifier
    my $pid = getPSessionID($uid);

    $info->{_session_uid} = $uid;

    my $ps = Lemonldap::NG::Common::Session->new( {
            storageModule        => $mod->{module},
            storageModuleOptions => $mod->{options},
            id                   => $pid,
            force                => 1,
            kind                 => "Persistent",
            ( $info ? ( info => $info ) : () ),
        }
    );

    if ( $ps->error ) {
        $self->logger->error( $ps->error );
        return undef;
    }
    else {

        # Set _session_uid if not already present
        unless ( defined $ps->data->{_session_uid} ) {
            $ps->update( { _session_uid => $uid } );
        }

        # Set _utime if not already present
        unless ( defined $ps->data->{_utime} ) {
            $ps->update( { _utime => time } );
        }
    }
    return $ps;
}

sub getMod {
    my ( $self, $req ) = @_;
    my ( $s, $m );
    unless ( $s = $req->params('sessionType') ) {
        $self->error( $req->error('Session type is required') );
        return ();
    }
    unless ( $m = $self->sessionTypes->{$s} ) {
        $self->error( $req->error('Unknown (or unconfigured) session type') );
        return ();
    }
    if ( my $kind = $req->params('kind') ) {
        $m->{kind} = $kind;
    }
    return $m;
}

sub getGlobal {
    my ($self) = @_;
    return $self->sessionTypes->{global};
}

1;
