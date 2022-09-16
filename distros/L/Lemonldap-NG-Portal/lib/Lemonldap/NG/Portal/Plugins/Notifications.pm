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
  PE_OK
  PE_ERROR
  PE_NOTIFICATION
);

our $VERSION = '2.0.15';

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

    # Declare new routes
    $self->addUnauthRoute( notifback => 'getNotifBack', [ 'POST', 'GET' ] )
      ->addAuthRoute( notifback => 'getNotifBack', ['POST'] );
    $self->addAuthRouteWithRedirect(
        mynotifications => { '*' => 'myNotifs' },
        ['GET']
    ) if $self->conf->{notificationsExplorer};

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

    return 1;
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

sub myNotifs {
    my ( $self, $req, $ref ) = @_;

    if ($ref) {
        return $self->sendJSONresponse( $req,
            { error => 'Missing epoch parameter' } )
          unless $req->param('epoch');

        # Retrieve notification reference=$ref with epoch
        my $notif = $self->_viewNotif( $req, $ref, $req->param('epoch') );
        $notif =~ s/"checkbox"/"checkbox" checked disabled/g;

        # Return HTML fragment
        return $self->sendJSONresponse( $req,
            { notification => $notif, result => ( $notif ? 1 : 0 ) } );
    }

    my $_notifications = $self->retrieveNotifs($req);
    my $nbr            = @$_notifications;
    my $msg            = $nbr ? 'myNotification' : 'noNotification';
    $msg .= 's' if ( $nbr > 1 );

    $self->logger->debug("$nbr accepted notification(s) found");

    # Build template
    my $params = {
        NOTIFICATIONS => $_notifications,
        MSG           => $msg
    };
    return $self->sendJSONresponse( $req, { %$params, result => $nbr } )
      if ( $req->wantJSON );

    # Display template
    return $self->p->sendHtml( $req, 'notifications', params => $params );
}

sub retrieveNotifs {
    my ( $self, $req ) = @_;

    # Retrieve user's accepted notifications
    $self->logger->debug( 'Searching for "'
          . $req->userData->{ $self->conf->{whatToTrace} }
          . '" accepted notification(s)' );
    my @_notifications = sort {
             $b->{epoch} <=> $a->{epoch}
          or $a->{reference} cmp $b->{reference}
    } (
        map {
            /^notification_(.+)$/
              ? { reference => $1, epoch => $req->{userData}->{$_} }
              : ()
          }
          keys %{ $req->{userData} }
    );
    splice @_notifications, $self->conf->{notificationsMaxRetrieve};

    return \@_notifications;
}

sub _viewNotif {
    my ( $self, $req, $ref, $epoch ) = @_;

    $self->logger->debug(
        "Retrieve notification with reference: \"$ref\" and epoch: \"$epoch\"");
    my $notif = eval { $self->module->viewNotification( $req, $ref, $epoch ); };
    if ($@) {
        $self->logger->debug("Notification not found");
        $self->logger->error($@);
        return '';
    }

    return $notif;
}

sub displayLink {
    my ( $self, $req ) = @_;
    my $_notifications = $self->retrieveNotifs($req);

    return ( $self->conf->{notificationsExplorer} && scalar @$_notifications );
}

1;
