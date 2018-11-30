package Lemonldap::NG::Portal::Lib::SOAPProxy;

use strict;
use Mouse;
use SOAP::Lite;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_BADCREDENTIALS);

our $VERSION = '2.0.0';

# INITIALIZATION

sub init {
    my ($self) = @_;
    $self->conf->{remoteCookieName}    ||= $self->conf->{cookieName};
    $self->conf->{proxySessionService} ||= $self->conf->{proxyAuthService};

    unless ( defined $self->conf->{proxyAuthService} ) {
        $self->error("Missing proxyAuthService parameter");
        return 0;
    }
    return 1;
}

# RUNNING METHODS

no warnings 'once';

*authenticate = *getUser;

sub getUser {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_proxyQueryDone} );
    my $soap = SOAP::Lite->proxy( $self->conf->{proxyAuthService} )
      ->uri('urn:Lemonldap/NG/Common/PSGI/SOAPService');
    my $r = $soap->getCookies( $req->{user}, $req->data->{password} );
    if ( $r->fault ) {
        $self->logger->error( "Unable to query authentication service: "
              . $r->fault->{faultstring} );
        return PE_ERROR;
    }
    my $res = $r->result();

    # If authentication failed, display error
    if ( $res->{errorCode} ) {
        $self->userLogger->warn(
            "Authentication failed for $req->{user}: error $res->{errorCode}");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    unless ( $req->data->{_remoteId} =
        $res->{cookies}->{ $self->conf->{remoteCookieName} } )
    {
        $self->logger->error("No cookie named $self->{remoteCookieName}");
        return PE_ERROR;
    }
    $req->data->{_proxyQueryDone}++;
    PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_setSessionInfoDone} );
    my $soap = SOAP::Lite->proxy( $self->conf->{proxySessionService} )
      ->uri('urn:Lemonldap/NG/Common/PSGI/SOAPService');
    my $r = $soap->getAttributes( $req->data->{_remoteId} );
    if ( $r->fault ) {
        $self->logger->error( "Unable to query authentication service"
              . $r->fault->{faultstring} );
    }
    my $res = $r->result();
    if ( $res->{error} ) {
        $self->userLogger->warn("Unable to get attributes for $self->{user} ");
        return PE_ERROR;
    }
    foreach ( keys %{ $res->{attributes} } ) {
        $req->{sessionInfo}->{$_} ||= $res->{attributes}->{$_}
          unless (/^_/);
    }
    $req->data->{_setSessionInfoDone}++;
    PE_OK;
}

sub authLogout {
    PE_OK;
}

1;
