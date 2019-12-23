# Notifications plugin.
#
# Two entry points for notifications:
#  * a new route "/notifback" for checking accepted notifications
#    (sub getNotifBack). It launch then autoRedirect() with "mustRedirect"
#    set to 1 because underlying handler has not seen user as authenticated
#    so data are not set;
#  * a callback inserted in process steps after authentication process,
#    This callback launches checkForNotifications to get notification and
#    cipher LemonLDAP::NG cookies.

package Lemonldap::NG::Portal::Plugins::Notifications;

use strict;
use Mouse;
use MIME::Base64;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_NOTIFICATION
  PE_OK
);

our $VERSION = '2.0.6';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INTERFACE

# Declare additional process steps
use constant endAuth => 'checkNotifDuringAuth';

# For now, notifications are done only during authentication process
#sub forAuthUser { 'checkNotifForAuthUser' }

# PROPERTIES

has module => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Declare new route
    $self->addUnauthRoute( 'notifback' => 'getNotifBack', [ 'POST', 'GET' ] );
    $self->addAuthRoute( 'notifback' => 'getNotifBack', ['POST'] );

    if ( $self->conf->{notificationServer} ) {
        $self->logger->debug('Notification server enable');

        $self->addUnauthRoute(
            notifications => 'notificationServer',
            ['POST']
        ) if ( $self->conf->{notificationServerPOST} // 1 );

        $self->addUnauthRoute(
            notifications => { '*' => 'notificationServer' },
            ['GET']
        ) if ( $self->conf->{notificationServerGET} );

        $self->addUnauthRoute(
            notifications =>
              { ':uid' => { ':reference' => 'notificationServer' } },
            ['DELETE']
        ) if ( $self->conf->{notificationServerDELETE} );
    }

    # Search for configuration options
    my $type = $self->conf->{notificationStorage};
    unless ($type) {
        $self->error('notificationStorage is not defined, aborting');
        return 0;
    }

    # Initialize notifications storage object
    $type = "Lemonldap::NG::Common::Notifications::$type";
    eval "require $type";
    if ($@) {
        $self->error(
            "Unable to load Lemonldap::NG::Common::Notifications::$type: $@");
        return 0;
    }
    $type->import( $self->conf->{oldNotifFormat} ? 'XML' : 'JSON' );

    # TODO: use conf database?
    my $prms = {
        %{ $self->conf->{notificationStorageOptions} },
        p    => $self->p,
        conf => $self->p->conf
    };

    if ( $self->conf->{oldNotifFormat} ) {
        $self->module( $self->p->loadModule('::Lib::Notifications::XML') )
          or return 0;
    }
    else {
        $self->module( $self->p->loadModule('::Lib::Notifications::JSON') )
          or return 0;
    }
    unless ( eval { $self->module->notifObject( $type->new($prms) ); } ) {
        $self->error($@);
        return 0;
    }
    1;
}

#sub checkNotifForAuthUser {
#    my ( $self, $req ) = @_;
#    if ( my $notif = $self->checkForNotifications($req) ) {
#
#        # Cipher cookies
#        return PE_NOTIFICATION;
#    }
#    else {
#        return PE_OK;
#    }
#}

# RUNNING METHODS

sub checkNotifDuringAuth {
    my ( $self, $req ) = @_;
    eval {
        $req->{data}->{notification} =
          $self->module->checkForNotifications($req);
    };
    if ($@) {
        $self->logger->error($@);
        return PE_ERROR;
    }
    if ( $req->{data}->{notification} ) {

        # Cipher id
        $req->id( $self->p->HANDLER->tsv->{cipher}->encrypt( $req->id ) );
        $self->p->rebuildCookies($req);
        if (    not $req->pdata->{_url}
            and not $req->data->{_url}
            and $req->env->{PATH_INFO} ne '/' )
        {
            $req->data->{_url} =
              encode_base64( $self->conf->{portal} . $req->env->{PATH_INFO},
                '' );
        }

        # Restore and cipher cookies
        return PE_NOTIFICATION;
    }
    else {
        return PE_OK;
    }
}

sub getNotifBack {
    my $self = shift;
    return $self->module->getNotifBack(@_);
}

sub notificationServer {
    my ( $self, $req, @args ) = @_;
    return $self->module->notificationServer( $req, @args );
}

1;
