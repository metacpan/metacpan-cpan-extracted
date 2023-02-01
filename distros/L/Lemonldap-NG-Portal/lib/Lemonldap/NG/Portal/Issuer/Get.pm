package Lemonldap::NG::Portal::Issuer::Get;

use strict;
use Mouse;
use URI::Escape;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_UNAUTHORIZEDURL
  PE_GET_SERVICE_NOT_ALLOWED URIRE
);

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Main::Issuer';

has rule => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug( "GET rule -> " . $self->conf->{issuerDBGetRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{issuerDBGetRule} ) );
    unless ($rule) {
        my $error = $hd->tsv->{jail}->error || '???';
        $self->error("Bad GET activation rule -> $error");
        return 0;
    }
    $self->{rule} = $rule;
    return 0 unless $self->SUPER::init();
    return 1;
}

# RUNNING METHODS

sub run {
    my ( $self, $req ) = @_;

    # Check activation rule
    unless ( $self->rule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->error('GET service not authorized');
        return PE_GET_SERVICE_NOT_ALLOWED;
    }

    # Session ID
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->id;

    # Session creation timestamp
    my $time = $req->{sessionInfo}->{_utime} || time();
    $req->path =~ m#^$self->{conf}->{issuerDBGetPath}/(log(?:in|out))#;
    my $logInOut = $1 || 'login';
    if ( $logInOut eq 'login' ) {
        $self->logger->debug("IssuerGet: request for login");
        $self->computeGetParams($req);
        return PE_OK;
    }
    elsif ( $logInOut eq 'logout' ) {
        $self->logger->debug("IssuerGet: request for logout");

        # TODO
        # Display a link to the provided URL
        return PE_OK;
    }
    else {
        $self->logger->error("IssuerGet: bad url");
        return PE_UNAUTHORIZEDURL;
    }
}

# Nothing to do here for now
sub logout {
    return PE_OK;
}

# INTERNAL METHODS

sub computeGetParams {
    my ( $self, $req ) = @_;

    # Additional GET variables
    my %getPrms;
    if ( exists $self->conf->{issuerDBGetParameters} ) {
        unless ( $req->urldc =~ URIRE ) {
            $self->logger->error("Malformed url $req->urldc");
            return;
        }
        my $vhost = $3 . ( $4 ? ":$4" : '' );
        my $prms  = $self->conf->{issuerDBGetParameters}->{$vhost};
        unless ($prms) {
            $self->logger->warn("IssuerGet: $vhost has no configuration");
            return '';
        }
        foreach my $param ( keys %$prms ) {
            my $value = $req->{sessionInfo}->{ $prms->{$param} };
            $value =~ s/[\r\n\t]//;
            $getPrms{$param} = $value;
        }
        $self->userLogger->notice( 'User '
              . $req->sessionInfo->{ $self->conf->{whatToTrace} }
              . " is authorized to access to $vhost" );
    }
    else {
        $self->logger->warn("IssuerGet: no configuration");
        return;
    }
    my $getVars = build_urlencoded(%getPrms);

    # If there are some GET variables to send
    # Add them to URL string
    if ( $getVars ne "" ) {
        my $urldc = $req->urldc;

        $urldc .= ( $urldc =~ /\?\w/ )
          ?

          # there are already get variables
          "&" . $getVars
          :

          # there are no get variables
          "?" . $getVars;
        $req->urldc($urldc);
    }
}

1;
