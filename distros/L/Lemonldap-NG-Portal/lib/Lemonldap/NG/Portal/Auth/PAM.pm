package Lemonldap::NG::Portal::Auth::PAM;

use strict;
use Mouse;
use Authen::PAM;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_OK
);

extends qw(Lemonldap::NG::Portal::Auth::_WebForm);

our $VERSION = '2.0.12';

# INITIALIZATION

has service => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->{conf}->{pamService} || 'login';
    }
);

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;
    no strict 'subs';

    # Handler to dial with Authen::PAM
    my $handler = sub {
        my @response = ();

        while (@_) {
            my $code = shift;
            my $msg  = shift;
            my $res;

            if ( $code == PAM_PROMPT_ECHO_ON ) {
                $res = $req->user;
            }

            elsif ( $code == PAM_PROMPT_ECHO_OFF ) {
                $res = $req->data->{password};
            }

            push( @response, PAM_SUCCESS, $res );
        }

        return ( @response, PAM_SUCCESS );
    };

    # Launch PAM service
    my $pam = Authen::PAM->new( $self->service, $req->user, $handler );
    unless ( ref $pam ) {
        $self->logger->error(
            'PAM failed: ' . Authen::PAM->pam_strerror($pam) );
        return PE_ERROR;
    }

    # Check for authentication and authorization
    foreach my $sub (qw(pam_authenticate pam_acct_mgmt)) {
        my $res = $pam->$sub;
        unless ( $res == PAM_SUCCESS ) {
            $self->userLogger->warn( "PAM failed to authenticate $req->{user}: "
                  . $pam->pam_strerror($res) );
            $self->setSecurity($req);
            return PE_BADCREDENTIALS;
        }
    }
    $self->userLogger->notice("Good PAM authentication for $req->{user}");
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->sessionInfo->{authenticationLevel} = $self->conf->{pamAuthnLevel};
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

1;
