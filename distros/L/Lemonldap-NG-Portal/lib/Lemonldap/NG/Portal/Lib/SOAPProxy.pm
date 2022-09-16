package Lemonldap::NG::Portal::Lib::SOAPProxy;

use strict;
use Mouse;
use SOAP::Lite;
use Lemonldap::NG::Portal::Main::Constants qw(
  URIRE
  PE_OK
  PE_ERROR
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.14';

# INITIALIZATION

has cookieName     => ( is => 'rw' );
has sessionService => ( is => 'rw' );
has urn => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{soapProxyUrn};
    }
);

sub init {
    my ($self) = @_;

    unless ( defined $self->conf->{proxyAuthService}
        && $self->conf->{proxyAuthService} =~ URIRE )
    {
        $self->error("Bad or missing proxyAuthService parameter");
        return 0;
    }

    my $sessionService = $self->conf->{proxySessionService}
      || $self->conf->{proxyAuthService};
    unless ( $sessionService =~ URIRE ) {
        $self->error("Malformed proxySessionService parameter");
        return 0;
    }
    $self->sessionService($sessionService);
    $self->cookieName( $self->conf->{proxyCookieName}
          || $self->conf->{cookieName} );

    return 1;
}

# RUNNING METHODS

no warnings 'once';
*authenticate = *getUser;

sub getUser {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_proxyQueryDone} );
    $self->logger->debug(
        'Proxy push auth to ' . $self->conf->{proxyAuthService} );
    my $soap =
      SOAP::Lite->proxy( $self->conf->{proxyAuthService} )->uri( $self->urn );
    my $r = $soap->getCookies( $req->{user}, $req->data->{password} );
    if ( $r->fault ) {
        $self->logger->error( "Unable to query authentication service: "
              . $r->fault->{faultstring} );
        return PE_ERROR;
    }
    $self->logger->debug('Proxy gets a response');
    my $res = $r->result();

    # If authentication failed, display error
    if ( $res->{errorCode} ) {
        $self->userLogger->warn(
            "Authentication failed for $req->{user}: error $res->{errorCode}");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    unless ( $req->data->{_remoteId} = $res->{cookies}->{ $self->cookieName } )
    {
        $self->logger->error("No cookie named $self->{remoteCookieName}");
        return PE_ERROR;
    }
    $req->data->{_proxyQueryDone}++;

    return PE_OK;
}

sub findUser {

    # Nothing to do here
    return PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_setSessionInfoDone} );
    $self->logger->debug(
        'Proxy requests sessionInfo to ' . $self->sessionService . '/global' );
    my $soap = SOAP::Lite->proxy( $self->sessionService )->uri( $self->urn );
    my $r    = $soap->getAttributes( $req->data->{_remoteId} );
    $self->logger->error(
        "Unable to query session service: " . $r->fault->{faultstring} )
      if ( $r->fault );

    my $res = $r->result();
    if ( $res->{error} ) {
        $self->userLogger->warn("Unable to get attributes for $self->{user}");
        return PE_ERROR;
    }
    foreach ( keys %{ $res->{attributes} } ) {
        $req->{sessionInfo}->{$_} ||= $res->{attributes}->{$_}
          unless (/^_/);
    }
    $req->data->{_setSessionInfoDone}++;

    return PE_OK;
}

sub authLogout {

    # Nothing to do here
    return PE_OK;
}

1;
