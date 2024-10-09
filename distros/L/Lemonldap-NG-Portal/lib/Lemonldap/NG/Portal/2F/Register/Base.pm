# Base package for 2F Register modules
package Lemonldap::NG::Portal::2F::Register::Base;

use strict;
use Lemonldap::NG::Portal::Main::Constants qw/PE_OK PE_ERROR/;
use Mouse;

our $VERSION = '2.20.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

has logo          => ( is => 'rw', default => '2f.png' );
has label         => ( is => 'rw' );
has authnLevel    => ( is => 'rw' );
has userCanRemove => ( is => 'rw' );

# 'type' field of stored _2fDevices
# Defaults to the last component of the package name
# But can be overriden by sfExtra
has type => (
    is      => 'rw',
    default => sub {
        ( split( '::', ref( $_[0] ) ) )[-1];
    }
);

has rule => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->conf->{ $_[0]->prefix . '2fSelfRegistration' };
    }
);

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{sfLoginTimeout}
              || $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;

    # Set logo if overridden
    $self->logo( $self->conf->{ $self->prefix . "2fLogo" } )
      if $self->conf->{ $self->prefix . "2fLogo" };

    # Set label if provided, translation files will be used otherwise
    $self->label( $self->conf->{ $self->prefix . "2fLabel" } )
      if $self->conf->{ $self->prefix . "2fLabel" };

    $self->authnLevel( $self->conf->{ $self->prefix . "2fAuthnLevel" } )
      if $self->conf->{ $self->prefix . "2fAuthnLevel" };

    # Set whether the user can remove this registration
    $self->userCanRemove(
        $self->conf->{ $self->prefix . '2fUserCanRemoveKey' } )
      if $self->conf->{ $self->prefix . '2fUserCanRemoveKey' };

    return 1;
}

# Legacy
sub canUpdateSfa {
    my ( $self, $req ) = @_;
    $self->logger->warn(
            ref($self)
          . "::canUpdateSfa is deprecated,"
          . " this check is now performed by the 2F Engine,"
          . " you can remove it from your custom module" );

    return;
}

# Check characters and truncate SFA name if too long
sub checkNameSfa {
    my ( $self, $req, $type, $name ) = @_;

    $name ||= "My$type";
    unless ( $name =~ /^[\w\s-]+$/ ) {
        $self->userLogger->error("$type name with bad character(s)");
        return;
    }
    $name = substr( $name, 0, $self->conf->{max2FDevicesNameLength} );
    $self->logger->debug("Return $type name: $name");

    return $name;
}

# Update request with newly registered device
sub markRegistered {
    my ( $self, $req, $authnLevel ) = @_;
    $req->data->{_2fRegistered}                     = 1;
    $req->userData->{_2f}                           = $self->prefix;
    $req->userData->{registeredAuthenticationLevel} = $authnLevel
      // $self->authnLevel;
}

# Default run method, for modules that don't want to implement it themselves
sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    return $self->p->sendError( $req, 'PE82', 400 )
      unless $user;

    if ( $self->can('supportedActions')
        and my $actions = $self->supportedActions($req) )
    {
        if ( my $sub = $actions->{$action} ) {
            return $self->$sub($req);
        }
    }
    $self->logger->error( $self->prefix . "2f: unknown action ($action)" );
    return $self->p->sendError( $req, 'unknownAction', 400 );
}

sub delete {
    my ( $self, $req ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };

    # Check if unregistration is allowed
    return $self->p->sendError( $req, 'notAuthorized', 400 )
      unless $self->userCanRemove;

    $self->checkCsrfToken($req)
      or return $self->p->sendError( $req, 'csrfToken', 400 );

    my $epoch = $req->param('epoch')
      or return $self->p->sendError( $req,
        $self->prefix . '2f: "epoch" parameter is missing', 400 );
    if ( $self->del2fDevice( $req, $req->userData, $self->type, $epoch ) ) {
        return $self->p->sendJSONresponse( $req, { result => 1 } );
    }
    $self->logger->error( $self->prefix . "2f: device not found" );
    return $self->p->sendError( $req, '2FDeviceNotFound', 400 );
}

sub failHtmlResponse {
    my ( $self, $req, $error ) = @_;
    my $uid = $req->userData->{ $self->conf->{whatToTrace} };

    $self->auditLog(
        $req,
        message => (
            $self->type . " 2F device registration failed for $uid : $error"
        ),
        code         => "2FA_DEVICE_REGISTRATION_FAILED",
        type         => $self->prefix,
        portal_error => $error,
        user         => $uid,
    );

    return $self->p->sendHtml(
        $req, 'error',
        params => {
            RAW_ERROR       => $error,
            AUTH_ERROR_TYPE => 'error',
        }
    );
}

sub failResponse {
    my ( $self, $req, $error, $code ) = @_;
    my $uid = $req->userData->{ $self->conf->{whatToTrace} };

    $self->auditLog(
        $req,
        message => (
            $self->type . " 2F device registration failed for $uid : $error"
        ),
        code         => "2FA_DEVICE_REGISTRATION_FAILED",
        type         => $self->prefix,
        portal_error => $error,
        user         => $uid,
    );

    return $self->p->sendError( $req, $error, $code );
}

sub successResponse {
    my ( $self, $req, $info ) = @_;
    return $self->p->sendJSONresponse( $req, $info );
}

sub registerDevice {
    my ( $self, $req, $info, $device ) = @_;

    my $registration_state = { authenticationLevel => $self->authnLevel, };

    my $h = $self->p->processHook( $req, 'sfRegisterDevice', $info, $device,
        $registration_state );
    return $h if ( $h != PE_OK );

    if ( $self->add2fDevice( $req, $info, $device ) ) {
        $self->markRegistered( $req,
            $registration_state->{authenticationLevel} );
        return PE_OK;
    }
    else {
        return PE_ERROR;
    }
}

sub checkCsrfToken {
    my ( $self, $req ) = @_;

    return $self->ott->getToken( $req->param('csrf_token') );
}

1;
