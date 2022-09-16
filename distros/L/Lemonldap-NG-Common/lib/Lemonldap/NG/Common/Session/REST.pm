package Lemonldap::NG::Common::Session::REST;

use strict;
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use JSON qw(from_json to_json);

our $VERSION = '2.0.15';

has sessionTypes => ( is => 'rw' );

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
}

sub separator {
    $_[0]->{multiValuesSeparator} || $_[0]->conf->{multiValuesSeparator};
}

sub hAttr {
    $_[0]->{hiddenAttributes} || $_[0]->conf->{hiddenAttributes};
}

### SEE LEMONLDAP::NG::COMMON::SESSION FOR AVAILABLE FUNCTIONS

sub delSession {
    my ( $self, $req ) = @_;
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );
    my $session = $self->getApacheSession( $mod, $id );
    $self->logger->debug("Delete session : $id");
    $session->remove;
    Lemonldap::NG::Handler::PSGI::Main->localUnlog( $req, $id );

    if ( $session->error ) {
        return $self->sendError( $req, $session->error, 200 );
    }
    return $self->sendJSONresponse( $req, { result => 1 } );
}

sub deleteOIDCConsent {
    my ( $self, $req ) = @_;
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );

    # Try to read session
    $self->logger->debug("Loading session : $id");
    my $session = $self->getApacheSession( $mod, $id )
      or return $self->sendError( $req, undef, 400 );

    # Try to read OIDC Consent parameters
    $self->logger->debug("Reading parameters ...");
    my $params = $req->parameters();
    my $rp     = $params->{rp}
      or
      return $self->sendError( $req, 'OIDC Consent "RP" parameter is missing',
        400 );
    my $epoch = $params->{epoch}
      or return $self->sendError( $req,
        'OIDC Consent "epoch" parameter is missing', 400 );

    # Try to load OIDC Consents from session
    $self->logger->debug("Looking for OIDC Consent(s) ...");
    my $_oidcConsents;
    if ( $session->data->{_oidcConsents} ) {
        $_oidcConsents = eval {
            from_json( $session->data->{_oidcConsents}, { allow_nonref => 1 } );
        };
        if ($@) {
            $self->logger->error("Corrupted session (_oidcConsents) : $@");
            return $self->p->sendError( $req, "Corrupted session", 500 );
        }
    }
    else {
        $self->logger->debug("No OIDC Consent found");
        $_oidcConsents = [];
    }

    # Delete OIDC Consent
    $self->logger->debug("Reading OIDC Consent(s) ...");
    my @keep = ();
    while (@$_oidcConsents) {
        my $element = shift @$_oidcConsents;

        $self->logger->debug(
            "Searching for OIDC Consent to delete -> $rp / $epoch ...");
        if ( defined $element->{rp} && defined $element->{epoch} ) {
            push @keep, $element
              unless ( ( $element->{rp} eq $rp )
                and ( $element->{epoch} eq $epoch ) );
        }
        else {
            $self->logger->error("Corrupted OIDC Consent");
        }
    }

    # Update session
    $self->logger->debug("Saving OIDC Consents ...");
    $session->data->{_oidcConsents} = to_json( \@keep );
    $self->logger->debug("Updating session ...");
    $session->update( \%{ $session->data } );

    Lemonldap::NG::Handler::PSGI::Main->localUnlog( $req, $id );
    if ( $session->error ) {
        return $self->sendError( $req, $session->error, 200 );
    }
    return $self->sendJSONresponse( $req, { result => 1 } );
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
    $self->logger->debug("Reading parameters ...");
    my $params = $req->parameters();
    my $type   = $params->{type}
      or return $self->sendError( $req, '2F device "type" parameter is missing',
        400 );
    my $epoch = $params->{epoch}
      or
      return $self->sendError( $req, '2F device "epoch" parameter is missing',
        400 );

    # Try to load 2F Device(s) from session
    $self->logger->debug("Looking for 2F Device(s) ...");
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
        $self->logger->debug("No 2F Device found");
        $_2fDevices = [];
    }

    # Delete 2F device
    $self->logger->debug("Reading 2F device(s) ...");
    my @keep = ();
    while (@$_2fDevices) {
        my $element = shift @$_2fDevices;

        $self->logger->debug(
            "Searching for 2F device to delete -> $type / $epoch ...");
        if ( defined $element->{type} && defined $element->{epoch} ) {
            push @keep, $element
              unless ( ( $element->{type} eq $type )
                and ( $element->{epoch} eq $epoch ) );
        }
        else {
            $self->logger->error("Corrupted _2fDevice");
        }
    }

    # Update session
    $self->logger->debug("Saving 2F Devices ...");
    $session->data->{_2fDevices} = to_json( \@keep );
    $self->logger->debug("Updating session ...");
    $session->update( \%{ $session->data } );

    Lemonldap::NG::Handler::PSGI::Main->localUnlog( $req, $id );
    if ( $session->error ) {
        return $self->sendError( $req, $session->error, 200 );
    }
    return $self->sendJSONresponse( $req, { result => 1 } );
}

sub _session {
    my ( $self, $raw, $req, $id, $skey ) = @_;
    my ( %h, $res );
    return $self->sendError( $req, 'Bad request', 400 ) unless ($id);
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );

    # Try to read session
    my $apacheSession = $self->getApacheSession( $mod, $id )
      or return $self->sendError( $req, undef, 400 );

    my %session = %{ $apacheSession->data };
    unless ($raw) {
        foreach my $k ( keys %session ) {
            $session{$k} = '**********'
              if ( $self->hAttr =~ /\b$k\b/ );
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
    my ( $self, $mod, $id, $info, $force ) = @_;
    my $apacheSession = Lemonldap::NG::Common::Session->new( {
            storageModule        => $mod->{module},
            storageModuleOptions => $mod->{options},
            cacheModule          =>
              Lemonldap::NG::Handler::PSGI::Main->tsv->{sessionCacheModule},
            cacheModuleOptions =>
              Lemonldap::NG::Handler::PSGI::Main->tsv->{sessionCacheOptions},
            id    => $id,
            force => $force,
            ( $id   ? ()                : ( kind => $mod->{kind} ) ),
            ( $info ? ( info => $info ) : () ),
        }
    );
    if ( $apacheSession->error ) {
        $self->error( $apacheSession->error );
        return undef;
    }
    $self->logger->debug("Get session $id from Common::Session::REST") if ($id);
    return $apacheSession;
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
