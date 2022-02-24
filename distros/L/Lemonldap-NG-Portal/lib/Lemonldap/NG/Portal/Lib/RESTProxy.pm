package Lemonldap::NG::Portal::Lib::RESTProxy;

use strict;
use JSON;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  URIRE
  PE_OK
  PE_ERROR
  PE_BADCREDENTIALS
);
use Lemonldap::NG::Common::FormEncode;

our $VERSION = '2.0.14';

has ua             => ( is => 'rw' );
has cookieName     => ( is => 'rw' );
has sessionService => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;

    unless ( defined $self->conf->{proxyAuthService}
        && $self->conf->{proxyAuthService} =~ URIRE )
    {
        $self->error("Bad or missing proxyAuthService parameter");
        return 0;
    }

    my $sessionService = $self->conf->{proxySessionService}
      || $self->conf->{proxyAuthService} . '/session/my';
    $sessionService =~ s#/*$##;
    unless ( $sessionService =~ URIRE ) {
        $self->error("Malformed proxySessionService parameter");
        return 0;
    }
    $self->sessionService($sessionService);
    $self->ua( Lemonldap::NG::Common::UserAgent->new( $self->conf ) );
    $self->ua->default_header( Accept => 'application/json' );
    $self->cookieName( $self->conf->{proxyCookieName}
          || $self->conf->{cookieName} );

    return 1;
}

no warnings 'once';
*authenticate = \&getUser;

sub getUser {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_proxyQueryDone} );
    $self->logger->debug(
        'Proxy push auth to ' . $self->conf->{proxyAuthService} );
    my $resp = $self->ua->post(
        $self->conf->{proxyAuthService},
        {
            user     => $req->{user},
            password => $req->data->{password},
            (
                $self->conf->{proxyAuthServiceChoiceParam}
                  && $self->conf->{proxyAuthServiceChoiceValue}
                ? ( $self->conf->{proxyAuthServiceChoiceParam} =>
                      $self->conf->{proxyAuthServiceChoiceValue} )
                : ()
            ),
            (
                $self->conf->{proxyAuthServiceImpersonation}
                  && $req->param('spoofId')
                ? ( spoofId => $req->param('spoofId') )
                : ()
            )
        }
    );
    unless ( $resp->is_success ) {
        $self->logger->error(
            'Unable to query authentication service: ' . $resp->status_line );
        return PE_ERROR;
    }
    $self->logger->debug('Proxy gets a response');
    my $res = eval { JSON::from_json( $resp->content, { allow_nonref => 1 } ) };
    if ($@) {
        $self->logger->error("Bad content: $@");
        return PE_ERROR;
    }
    unless ( $res->{result} ) {
        $self->userLogger->warn("Authentication failed for $req->{user}");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    my $name = $self->cookieName;
    unless ( grep /\b$name=/, $resp->header('Set-Cookie') ) {
        $self->logger->error("No cookie named '$name'");
        return PE_ERROR;
    }

    $req->sessionInfo->{_proxyCookies} = join '; ',
      map { s/;.*$//; $_ } $resp->header('Set-Cookie');
    $self->logger->debug( 'Store remote cookies in session ('
          . $req->sessionInfo->{_proxyCookies}
          . ')' );
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
    my $q = HTTP::Request->new(
        GET => $self->sessionService . '/global',
        [
            Cookie => $req->sessionInfo->{_proxyCookies},
            Accept => 'application/json'
        ]
    );
    my $resp = $self->ua->request($q);
    unless ( $resp->is_success ) {
        $self->logger->error(
            'Unable to query session service: ' . $resp->status_line );
        return PE_ERROR;
    }
    $self->logger->debug('Proxy gets a response');
    my $res = eval { JSON::from_json( $resp->content, { allow_nonref => 1 } ) };
    if ($@) {
        $self->logger->error("Bad content: $@");
        return PE_ERROR;
    }
    foreach ( keys %$res ) {
        $req->{sessionInfo}->{$_} ||= $res->{$_} unless (/^_/);
    }
    $req->data->{_setSessionInfoDone}++;

    return PE_OK;
}

sub authLogout {
    my ( $self, $req ) = @_;
    $self->logger->debug(
        'Proxy ask logout to ' . $self->conf->{proxyAuthService} );
    my $q = HTTP::Request->new(
        GET => $self->conf->{proxyAuthService} . '?logout=1',
        [
            Cookie => $req->sessionInfo->{_proxyCookies},
            Accept => 'application/json'
        ]
    );
    my $resp = $self->ua->request($q);
    unless ( $resp->is_success ) {
        $self->logger->error(
            'Unable to query authentication service: ' . $resp->status_line );
        return PE_OK;
    }
    $self->logger->debug('Proxy gets a response');
    my $res = eval { JSON::from_json( $resp->content, { allow_nonref => 1 } ) };
    if ($@) {
        $self->logger->error("Bad content: $@");
        return PE_OK;
    }
    my $user = $req->{sessionInfo}->{ $self->conf->{whatToTrace} };
    unless ( $res->{result} ) {
        $self->userLogger->warn("Internal Portal logout failed for $user")
          if $user;
        return PE_OK;
    }
    $self->userLogger->notice(
        "User $user has been disconnected from internal Portal")
      if $user;

    return PE_OK;
}

1;

