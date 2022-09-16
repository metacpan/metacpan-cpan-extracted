package Lemonldap::NG::Portal::Plugins::NewLocationWarning;

use strict;
use Mouse;
use POSIX qw(strftime);
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);
use List::MoreUtils qw/uniq/;

our $VERSION = '2.0.14';

has locationAttribute        => ( is => 'rw' );
has locationDisplayAttribute => ( is => 'rw' );
has locationMaxValues        => ( is => 'rw' );
has mailSessionKey => (
    is      => 'rw',
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

    $self->logger->debug( "Could not find location of user " . $req->user )
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
            "User " . $req->user . " logged in from known location $location" );
    }
    else {
        # Not the first location in history, warn if new location
        if (@envHistory) {
            $self->userLogger->info( "User "
                  . $req->user
                  . " logged in from unknown location $location" );
            my $riskLevel = ( $req->sessionInfo->{_riskLevel} || 0 ) + 1;
            $req->sessionInfo->{_riskLevel} = $riskLevel;
            $req->sessionInfo->{_riskDetails}->{newLocation} =
              $req->sessionInfo->{ $self->locationDisplayAttribute };
        }
        else {
            $self->userLogger->info( "User "
                  . $req->user
                  . " logged with empty location history from location $location"
            );
        }
    }
    return PE_OK;
}

sub sendWarningEmail {
    my ( $self, $req ) = @_;
    return $self->_sendMail($req)
      if $req->sessionInfo->{_riskDetails}->{newLocation};

    return PE_OK;
}

sub _sendMail {
    my ( $self, $req ) = @_;
    my $date     = strftime( '%F %X', localtime );
    my $location = $req->sessionInfo->{_riskDetails}->{newLocation};
    my $ua       = $req->env->{HTTP_USER_AGENT};
    my $mail     = $req->sessionInfo->{ $self->mailSessionKey };

    # Build mail content
    my $tr      = $self->translate($req);
    my $subject = $self->conf->{newLocationWarningMailSubject};
    unless ($subject) {
        $self->logger->debug('Use default warning subject');
        $subject = 'newLocationWarningMailSubject';
        $tr->( \$subject );
    }
    my ( $body, $html );
    if ( $self->conf->{newLocationWarningMailBody} ) {

        # We use a specific text message, no html
        $self->logger->debug('Use specific warning body message');
        $body = $self->conf->{newLocationWarningMailBody};

        # Replace variables in body
        $body =~ s/\$ua\b/$ua/ge;
        $body =~ s/\$location\b/$location/ge;
        $body =~ s/\$date\b/$date/ge;
        $body =~ s/\$(\w+)/$req->{sessionInfo}->{$1} || ''/ge;
    }
    else {

        # Use HTML template
        $body = $self->loadMailTemplate(
            $req,
            'mail_new_location_warning',
            filter => $tr,
            params => {
                location => $location,
                date     => $date,
                ua       => $ua
            },
        );
        $html = 1;
    }
    if ( $mail && $subject && $body ) {
        $self->logger->warn("User $mail is signing in from a new location");

        # Send mail
        $self->logger->debug('Unable to send new location warning mail')
          unless ( $self->send_mail( $mail, $subject, $body, $html ) );
    }
    else {
        $self->logger->error(
            'Unable to send new location warning mail: missing parameter(s)');
    }
    return PE_OK;
}

1;
