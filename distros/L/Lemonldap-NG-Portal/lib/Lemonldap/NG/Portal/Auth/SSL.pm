package Lemonldap::NG::Portal::Auth::SSL;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCERTIFICATE
  PE_CERTIFICATEREQUIRED
  PE_FIRSTACCESS
  PE_OK
);

our $VERSION = '2.0.8';

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

    # If this is the ajax query, allow response to contain HTML code
    # to update the portal error message
    if ( $req->wantJSON ) {
        $req->wantErrorRender(1);
    }

    my $field = $self->conf->{SSLVar};
    if ( $req->env->{SSL_CLIENT_I_DN} ) {
        $self->logger->debug(
            'Received SSL issuer ' . $req->env->{SSL_CLIENT_I_DN} );

        if ( my $tmp =
            $self->conf->{SSLVarIf}->{ $req->env->{SSL_CLIENT_I_DN} } )
        {
            $field = $tmp;
        }
    }
    $req->env->{$field}
      ? $self->logger->debug("Using SSL environment variable $field")
      : $self->logger->notice(
        "No name found in certificate, check your configuration");
    if ( $req->env->{$field} and $req->user( $req->env->{$field} ) ) {
        $self->userLogger->notice( "GoodSSL authentication for " . $req->user );
        return PE_OK;
    }
    elsif ( $req->env->{SSL_CLIENT_S_DN} ) {
        $self->userLogger->warn("$field was not found in user certificate");
        return PE_BADCERTIFICATE;
    }
    elsif ( $self->conf->{sslByAjax} and not $req->param('nossl') ) {

        # If this is the AJAX query
        if ( $req->wantJSON ) {
            return PE_CERTIFICATEREQUIRED;
        }

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
            return PE_BADCERTIFICATE;
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
