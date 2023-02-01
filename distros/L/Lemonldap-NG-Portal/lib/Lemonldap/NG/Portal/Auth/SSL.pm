package Lemonldap::NG::Portal::Auth::SSL;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_CERTIFICATEREQUIRED
  PE_ERROR
  PE_BADCERTIFICATE
  PE_FIRSTACCESS
  PE_OK
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Auth';

# INITIALIZATION

has AjaxInitScript => ( is => 'rw', default => '' );
has Name           => ( is => 'ro', default => 'SSL' );

has auth_id => ( is => 'ro', default => 'ssl' );

has subject_var =>
  ( is => 'rw', lazy => 1, default => sub { $_[0]->conf->{SSLVar} } );
has issuer_var =>
  ( is => 'rw', lazy => 1, default => sub { $_[0]->conf->{SSLIssuerVar} } );

with 'Lemonldap::NG::Portal::Auth::_Ajax';

sub init {
    my ($self) = @_;
    $self->AjaxInitScript( '<script type="application/init">{"sslHost":"'
          . $self->conf->{sslHost}
          . '"}</script>' )
      if $self->conf->{sslByAjax};
    return 1;
}

# Create authentication token so you can use 2FA, notifications, etc, with Ajax
sub auth_route {
    my ( $self, $req ) = @_;

    my $ssl_user = $self->get_user_from_req($req);
    if ($ssl_user) {
        return $self->ajax_success(
            $req,
            $ssl_user,
            {
                _Issuer => $req->env->{ $self->issuer_var },
            }
        );
    }
    else {
        $req->wantErrorRender(1);
        return $self->p->do( $req, [ sub { PE_CERTIFICATEREQUIRED } ] );
    }
}

sub get_user_from_req {
    my ( $self, $req ) = @_;

    my $field      = $self->subject_var;
    my $issuer_var = $self->issuer_var;
    if ( $req->env->{$issuer_var} ) {
        $self->logger->debug(
            'Received SSL issuer ' . $req->env->{$issuer_var} );

        if ( my $tmp = $self->conf->{SSLVarIf}->{ $req->env->{$issuer_var} } ) {
            $field = $tmp;
        }
    }
    my $value = $req->env->{$field};
    if ($value) {
        $self->logger->debug("Using SSL environment variable $field");
    }
    else {
        $self->logger->notice(
            "No name found in certificate, check your configuration");
    }

    return $value;
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

    my $token_id = $req->param('ajax_auth_token');
    if ($token_id) {
        my $token = $self->get_auth_token( $req, $token_id );
        if ( $token->{user} ) {
            my $user = $token->{user};
            $self->userLogger->notice( "GoodSSL authentication for " . $user );
            $req->user($user);
            $req->data->{_Issuer} = $token->{extraInfo}->{_Issuer};
            return PE_OK;
        }
        else {
            return PE_ERROR;
        }
    }

    my $ssl_user = $self->get_user_from_req($req);

    if ( $ssl_user and $req->user($ssl_user) ) {
        $self->userLogger->notice( "GoodSSL authentication for " . $req->user );
        $req->data->{_Issuer} = $req->env->{ $self->issuer_var };
        return PE_OK;
    }
    elsif ( $req->env->{SSL_CLIENT_S_DN} ) {
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

        eval( $self->InitCmd );
        die 'Unable to launch init commmand ' . $self->{InitCmd} if ($@);
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
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->sessionInfo->{authenticationLevel} = $self->conf->{SSLAuthnLevel};
    $req->sessionInfo->{_Issuer}             = $req->data->{_Issuer};
    return PE_OK;
}

sub getDisplayType {
    my ($self) = @_;
    return ( $self->{conf}->{sslByAjax} ? "sslform" : "logo" );
}

sub authLogout {
    return PE_OK;
}

1;
