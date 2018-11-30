##@file
# Web form authentication backend file

##@class
# Web form authentication backend class
package Lemonldap::NG::Portal::Auth::_WebForm;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_CAPTCHAEMPTY
  PE_CAPTCHAERROR
  PE_FIRSTACCESS
  PE_FORMEMPTY
  PE_NOTOKEN
  PE_OK
  PE_PASSWORDFORMEMPTY
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::Auth';

has authnLevel => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $conf = $_[0]->{conf};
        return ( $conf->{portal} =~ /^https/ ? 2 : 1 );
    },
);

has captcha => ( is => 'rw' );
has ott     => ( is => 'rw' );

# INITIALIZATION

sub init {
    if ( $_[0]->{conf}->{captcha_login_enabled} ) {
        $_[0]->captcha( $_[0]->p->loadModule('::Lib::Captcha') ) or return 0;
    }
    elsif ( $_[0]->{conf}->{requireToken} ) {
        $_[0]->ott( $_[0]->p->loadModule('::Lib::OneTimeToken') ) or return 0;
        $_[0]->ott->timeout( $_[0]->conf->{formTimeout} );
    }
    return 1;
}

# RUNNING METHODS

# Read username and password from POST data
sub extractFormInfo {
    my ( $self, $req ) = @_;

    # Detect first access and empty forms
    my $defUser        = defined $req->param('user');
    my $defPassword    = defined $req->param('password');
    my $defOldPassword = defined $req->param('oldpassword');
    my $res            = PE_OK;

    # 1. No user defined at all -> first access
    unless ( $defUser and $req->method =~ /^POST$/i ) {
        $res = PE_FIRSTACCESS;
    }

    # 2. If user and password defined -> login form
    elsif ( $defUser and $defPassword ) {
        $res = PE_FORMEMPTY
          unless ( ( $req->{user} = $req->param('user') )
            && ( $req->data->{password} = $req->param('password') ) );
    }

    # 3. If user and oldpassword defined -> password form
    elsif ( $defUser and $defOldPassword ) {
        $res = PE_PASSWORDFORMEMPTY
          unless ( ( $req->{user} = $req->param('user') )
            && ( $req->data->{oldpassword} = $req->param('oldpassword') )
            && ( $req->data->{newpassword} = $req->param('newpassword') )
            && ( $req->data->{confirmpassword} =
                $req->param('confirmpassword') ) );
    }

    # If form seems empty
    if ( $res != PE_OK ) {
        $self->setSecurity($req);
        return $res;
    }

    # Security: check for captcha or token
    if ( $self->captcha or $self->ott ) {
        my $token;
        unless ( $token = $req->param('token') ) {
            $self->userLogger->error('Authentication tried without token');
            $self->ott->setToken($req);
            return PE_NOTOKEN;
        }
        if ( $self->captcha ) {
            my $code = $req->param('captcha');
            unless ($code) {
                $self->captcha->setCaptcha($req);
                return PE_CAPTCHAEMPTY;
            }
            unless ( $self->captcha->validateCaptcha( $token, $code ) ) {
                $self->captcha->setCaptcha($req);
                $self->userLogger->warn(
                    "Captcha failed: wrong or expired code");
                return PE_CAPTCHAERROR;
            }
            $self->logger->debug("Captcha code verified");
        }
        elsif ( $self->ott ) {
            unless ( $req->data->{tokenVerified}
                or $self->ott->getToken($token) )
            {
                $self->ott->setToken($req);
                $self->userLogger->warn('Token expired');
                return PE_TOKENEXPIRED;
            }
            $req->data->{tokenVerified} = 1;
        }
    }

    # Other parameters
    $req->data->{timezone} = $req->param('timezone');

    PE_OK;
}

# Set password in session data if wanted.
sub setAuthSessionInfo {
    my ( $self, $req ) = @_;

    # authenticationLevel
    $req->{sessionInfo}->{authenticationLevel} = $self->authnLevel;

    # Store submitted password if set in configuration
    # WARNING: it can be a security hole
    if ( $self->conf->{storePassword} ) {
        $req->{sessionInfo}->{'_password'} = $req->data->{'newpassword'}
          || $req->data->{'password'};
    }

    # Store user timezone
    $req->{sessionInfo}->{'_timezone'} = $self->{'timezone'};

    PE_OK;
}

# @return display type
sub getDisplayType {
    return "standardform";
}

sub setSecurity {
    my ( $self, $req ) = @_;

    # If captcha is enable, prepare it
    if ( $self->captcha ) {
        $self->captcha->setCaptcha($req);
    }

    # Else get token
    elsif ( $self->ott ) {
        $self->ott->setToken($req);
    }
}

1;
