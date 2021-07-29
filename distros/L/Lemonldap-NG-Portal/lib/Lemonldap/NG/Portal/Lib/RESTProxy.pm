package Lemonldap::NG::Portal::Lib::RESTProxy;

use strict;
use JSON;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_BADCREDENTIALS);
use Lemonldap::NG::Common::FormEncode;

our $VERSION = '2.0.12';

has ua => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;
    $self->conf->{remoteCookieName} ||= $self->conf->{cookieName};
    $self->conf->{proxySessionService} ||=
      $self->conf->{proxyAuthService} . '/session/my';
    $self->conf->{proxySessionService} =~ s#/*$##;
    $self->ua( Lemonldap::NG::Common::UserAgent->new( $self->conf ) );
    $self->ua->default_header( Accept => 'application/json' );

    unless ( defined $self->conf->{proxyAuthService} ) {
        $self->error("Missing proxyAuthService parameter");
        return 0;
    }
    return 1;
}

no warnings 'once';
*authenticate = \&getUser;

sub getUser {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_proxyQueryDone} );
    $self->logger->debug(
        'Proxy push auth to ' . $self->conf->{proxyAuthService} );
    my $resp = $self->ua->post( $self->conf->{proxyAuthService},
        { user => $req->{user}, password => $req->data->{password} } );
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
    $req->sessionInfo->{_proxyQueryDone}++;
    unless ( $res->{result} ) {
        $self->userLogger->notice("Authentication refused for $req->{user}");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    $req->sessionInfo->{_proxyCookies} = join '; ',
      map { s/;.*$//; $_ } $resp->header('Set-Cookie');
    $self->logger->debug( 'Store remote cookies in session ('
          . $req->sessionInfo->{_proxyCookies}
          . ')' );

    return PE_OK;
}

sub findUser {

    # Nothing to do here
    return PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{_setSessionInfoDone} );
    my $q = HTTP::Request->new(
        GET => $self->conf->{proxySessionService} . '/global',
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
    
    return PE_OK;
}

1;

