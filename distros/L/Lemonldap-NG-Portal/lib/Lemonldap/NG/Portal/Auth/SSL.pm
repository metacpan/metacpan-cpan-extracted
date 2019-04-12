package Lemonldap::NG::Portal::Auth::SSL;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCERTIFICATE
  PE_CERTIFICATEREQUIRED
  PE_FIRSTACCESS
  PE_OK
);

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Portal::Main::Auth';

# INITIALIZATION

has AjaxInitScript => ( is => 'rw', default => '' );
has Name           => ( is => 'ro', default => 'SSL' );

sub init {
    my ($self) = @_;
    $self->AjaxInitScript( '<script type="application/init">{"sslHost":"'
          . $self->conf->{sslHost}
          . '"}</script>' )
      if $self->conf->{sslByAjax};
    return 1;
}

# Read username in SSL environment variables, or return an error
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my ( $self, $req ) = @_;
    my $field = $self->conf->{SSLVar};
    if ( $req->env->{SSL_CLIENT_I_DN}
        and my $tmp =
        $self->conf->{SSLVarIf}->{ $req->env->{SSL_CLIENT_I_DN} } )
    {
        $field = $tmp;
    }
    if ( $req->user( $req->env->{$field} ) ) {
        $self->userLogger->notice( "GoodSSL authentication for " . $req->user );
        return PE_OK;
    }
    elsif ( $req->env->{SSL_CLIENT_S_DN} ) {
        $self->userLogger->warn("$field was not found in user certificate");
        return PE_BADCERTIFICATE;
    }
    elsif ( $self->conf->{sslByAjax} and not $req->param('nossl') ) {
        $self->logger->debug( 'Append ' . $self->{Name} . ' init/script' );
        $req->data->{customScript} .= $self->{AjaxInitScript};
        $self->logger->debug(
            "Send init/script -> " . $req->data->{customScript} );
        $req->data->{waitingMessage} = 1;
        return PE_FIRSTACCESS;
    }
    else {
        if ( $self->conf->{sslByAjax} ) {
            $self->logger->debug( 'Append ' . $self->{Name} . ' init/script' );
            $req->data->{customScript} .= $self->{AjaxInitScript};
            $self->logger->debug(
                "Send init/script -> " . $req->data->{customScript} );
        }
        $self->userLogger->warn('No certificate found');
        return PE_CERTIFICATEREQUIRED;
    }
}

sub authenticate {
    PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->sessionInfo->{authenticationLevel} = $self->conf->{SSLAuthnLevel};
    PE_OK;
}

sub getDisplayType {
    my ($self) = @_;
    return ( $self->{conf}->{sslByAjax} ? "sslform" : "logo" );
}

sub authLogout {
    PE_OK;
}

1;
