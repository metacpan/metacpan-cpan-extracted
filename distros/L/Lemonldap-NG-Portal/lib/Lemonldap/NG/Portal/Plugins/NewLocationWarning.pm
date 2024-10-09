package Lemonldap::NG::Portal::Plugins::NewLocationWarning;

use strict;
use Mouse;
use POSIX qw(strftime);
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);
use List::MoreUtils qw/uniq/;

our $VERSION = '2.17.0';

has locationAttribute        => ( is => 'rw' );
has locationDisplayAttribute => ( is => 'rw' );
has locationMaxValues        => ( is => 'rw' );
has mailSessionKey => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return
             $_[0]->{conf}->{newLocationWarningMailAttribute}
          || $_[0]->{conf}->{mailSessionKey}
          || 'mail';
    }
);

extends qw(
  Lemonldap::NG::Portal::Lib::SMTP
  Lemonldap::NG::Portal::Main::Plugin
);

# Entrypoint
use constant afterSub => { setLocalGroups => 'checkNewLocation' };
use constant endAuth  => 'sendWarningEmail';

sub init {
    my ($self) = @_;

    if ( $self->conf->{disablePersistentStorage} ) {
        $self->logger->error(
'"NewLocationWarning" plugin enabled WITHOUT persistent session storage"'
        );
        return 0;
    }
    unless ( $self->conf->{loginHistoryEnabled} ) {
        $self->logger->error(
            '"NewLocationWarning" plugin enabled WITHOUT "History" plugin');
        return 0;
    }

    $self->locationAttribute( $self->conf->{newLocationWarningLocationAttribute}
          || 'ipAddr' );
    $self->locationDisplayAttribute(
             $self->conf->{newLocationWarningLocationDisplayAttribute}
          || $self->locationAttribute );
    $self->locationMaxValues( $self->conf->{newLocationWarningMaxValues} || 0 );

    return 1;
}

sub checkNewLocation {
    my ( $self, $req ) = @_;
    my $successLogin = $req->sessionInfo->{_loginHistory}->{successLogin} || [];
    my $location     = $req->sessionInfo->{ $self->locationAttribute };
    my $user         = $req->sessionInfo->{ $self->conf->{whatToTrace} };

    $self->logger->debug( "Could not find location of user " . $user )
      unless $location;

    # Get all non-empty, unique values of location attribute through list of
    # successful logins
    my @envHistory =
      grep { $_ // "" }
      uniq( map { $_->{ $self->locationAttribute } // "" } @{$successLogin} );

    # Only consider some of the past unique locations
    my $maxLocations = $self->locationMaxValues;
    splice @envHistory, $maxLocations
      if ( $maxLocations and ( scalar @envHistory > $maxLocations ) );

    if ( grep { $_ eq $location } @envHistory ) {
        $self->userLogger->debug(
            "User $user logged in from known location $location");
    }
    else {
        # Not the first location in history, warn if new location
        if (@envHistory) {
            $self->userLogger->info(
                "User $user logged in from unknown location $location");
            my $riskLevel = ( $req->sessionInfo->{_riskLevel} || 0 ) + 1;
            $req->sessionInfo->{_riskLevel} = $riskLevel;
            $req->sessionInfo->{_riskDetails}->{newLocation} =
              $req->sessionInfo->{ $self->locationDisplayAttribute };
        }
        else {
            $self->userLogger->info(
                    "User $user logged with empty location history "
                  . "from location $location" );
        }
    }
    return PE_OK;
}

sub sendWarningEmail {
    my ( $self, $req ) = @_;

    if ( $req->sessionInfo->{_riskDetails}->{newLocation} ) {
        my $mail = $req->sessionInfo->{ $self->mailSessionKey };
        my $user = $req->sessionInfo->{ $self->conf->{whatToTrace} };
        if ($mail) {
            $self->userLogger->info(
                "User $user is signing in from a new location");
            return $self->_sendMail( $req, $mail );
        }
        else {
            $self->logger->warn( "User $user is signing in from a new location"
                  . " but has no configured email" );
        }
    }

    return PE_OK;
}

sub _sendMail {
    my ( $self, $req, $mail ) = @_;
    my $date     = strftime( '%F %X (UTC%z)', localtime );
    my $location = $req->sessionInfo->{_riskDetails}->{newLocation};
    my $ua       = $req->env->{HTTP_USER_AGENT};

    $self->sendEmail(
        $req,
        subject       => $self->conf->{newLocationWarningMailSubject},
        subject_trmsg => 'newLocationWarningMailSubject',
        body          => $self->conf->{newLocationWarningMailBody},
        body_template => 'mail_new_location_warning',
        dest          => $mail,
        params        => {
            location => $location,
            date     => $date,
            ua       => $ua
        },
    );

    return PE_OK;
}

1;
