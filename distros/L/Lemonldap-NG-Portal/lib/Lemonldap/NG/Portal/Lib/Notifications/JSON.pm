package Lemonldap::NG::Portal::Lib::Notifications::JSON;

use strict;
use Mouse;
use JSON qw(from_json);

our $VERSION = '2.0.0';

no warnings 'redefine';

# Lemonldap::NG::Portal::Main::Plugin provides addAuthRoute() and
# addUnauthRoute() methods in addition of Lemonldap::NG::Common::Module.
extends 'Lemonldap::NG::Portal::Main::Plugin';

# PROPERTIES

# Underlying notifications storage object (File, DBI, LDAP,...)
has notifObject => ( is => 'rw' );

# INITIALIZATION

sub init {
    1;
}

# Search for notifications and if any, returns HTML fragment.
sub checkForNotifications {
    my ( $self, $req ) = @_;

    # Look for pending notifications in database
    my $uid = $req->sessionInfo->{ $self->notifObject->notifField };
    my ( $notifs, $forUser ) = $self->notifObject->getNotifications($uid);
    my $form;
    return 0 unless ($notifs);

    # Transform notifications
    my $i = 0;    #Files count
    foreach my $file ( values %$notifs ) {
        my $json = from_json( $file, { allow_nonref => 1 } );
        my $j = 0;    #Notifications count
        my @res;
        $json = [$json] unless ( ref $json eq 'ARRAY' );
      LOOP: foreach my $notif ( @{$json} ) {

            # Get the reference
            my $reference = $notif->{reference};

            $self->logger->debug("Get reference $reference");

            # Check it in session
            if ( exists $req->{sessionInfo}->{"notification_$reference"} ) {

                # The notification was already accepted
                $self->logger->debug(
                    "Notification $reference was already accepted");
                next LOOP;
            }
            push @res, $notif;
            $j++;
        }

        # Go to next file if no notification found
        next unless $j;
        $i++;
        $form .= $self->toForm( $req, @res );
    }

    # Stop here if nothing to display
    return 0 unless $i;

    # Returns HTML fragment
    return $form;
}

sub getNotifBack {
    my ( $self, $req, $name ) = @_;

    # Look if all notifications have been accepted. If not, redirects to
    # portal

    # Search for Lemonldap::NG cookie (ciphered)
    my $id;
    unless ( $id = $req->cookies->{ $self->{conf}->{cookieName} } ) {
        return $self->p->sendError( $req, 'No cookie found', 401 );
    }
    $id = $self->p->HANDLER->tsv->{cipher}->decrypt($id)
      or return $self->p->sendError( $req, 'Unable to decrypt', 400 );

    # Verify that session exists
    $req->userData( $self->p->HANDLER->retrieveSession( $req, $id ) )
      or return $self->p->sendError( $req, 'Unknown session', 401 );

    # Restore data
    $self->p->importHandlerData($req);
    my $uid = $req->sessionInfo->{ $self->notifObject->notifField };

    my ( $notifs, $forUser );
    eval { ( $notifs, $forUser ) = $self->notifObject->getNotifications($uid) };
    return $self->p->sendError( $req, $@, 500 ) if ($@);

    if ($notifs) {

        # Get accepted notifications
        my ( $refs, $checks ) = ( {}, {} );
        my $prms = $req->parameters;
        foreach ( keys %$prms ) {
            my $v = $prms->{$_};
            if (s/^reference//) {
                $refs->{$v} = $_;
            }
            elsif ( s/^check// and /^(\d+x\d+)x(\d+)$/ and $v eq 'accepted' ) {
                push @{ $checks->{$1} }, $2;
            }
        }

        my $result = 1;
        foreach my $fileName ( keys %$notifs ) {
            my $file       = $notifs->{$fileName};
            my $fileResult = 1;
            my $json       = from_json( $file, { allow_nonref => 1 } );
            $json = [$json] unless ( ref $json eq 'ARRAY' );

            # Get pending notifications and verify that they have been accepted
            foreach my $notif (@$json) {
                my $reference = $notif->{reference};

                # Check if this pending notification has been seen
                if ( my $refId = $refs->{$reference} ) {

                    # Verity that checkboxes have been checked
                    if ( $notif->{check} ) {
                        if ( my $toCheckCount = @{ $notif->{check} } ) {
                            unless ($checks->{$refId}
                                and $toCheckCount == @{ $checks->{$refId} } )
                            {
                                $self->userLogger->notice(
"$uid has not accepted notification $reference"
                                );
                                $result = $fileResult = 0;
                                next;
                            }
                        }
                    }
                }
                else {
                    # Current pending notification has not been found in
                    # request
                    $result = $fileResult = 0;
                    $self->logger->debug(
                        'Current pending notification has not been found');
                    next;
                }

                # Register acceptation
                $self->userLogger->notice(
                    "$uid has accepted notification $reference");
                $self->p->updatePersistentSession( $req,
                    { "notification_$reference" => time() } );
                $self->logger->debug(
                    "Notification $reference registered in persistent session");
            }

        # Notifications accepted for this file, delete it unless it's a wildcard
            if ( $fileResult and exists $forUser->{$fileName} ) {
                $self->logger->debug("Notification file deleted");
                $self->notifObject->delete($fileName);
            }
        }
        unless ($result) {

            # One pending notification has been found and not accepted,
            # restart process to display pending notifications
            # TODO: is it a good idea to launch all 'endAuth' subs ?
            $self->logger->debug(
                'Pending notification has been found and not accepted');
            return $self->p->do( $req, [ @{ $self->p->endAuth } ] );
        }

        # All pending notifications have been accepted, restore cookies and
        # launch 'controlUrl' to restore "urldc" using do()
        $self->logger->debug('All pending notifications have been accepted');
        $self->p->rebuildCookies($req);
        return $self->p->do( $req, ['controlUrl'] );
    }
    else {
        # No notifications checked here, this entry point must not be called.
        # Redirecting to portal
        $self->logger->debug('No notifications checked');
        $req->mustRedirect(1);
        return $self->p->do( $req, [] );
    }
}

sub toForm {
    my ( $self, $req, @notifs ) = @_;
    my $i = 0;
    @notifs = map {
        $i++;
        if ( $_->{check} ) {
            my $j = 0;
            $_->{check} =
              [ map { $j++; { id => '1x' . $i . 'x' . $j, value => $_ } }
                  @{ $_->{check} } ];
        }
        $_->{id} = "1x$i";
        $_;
    } @notifs;
    return $self->loadTemplate( $req, 'notifinclude',
        params => { notifications => \@notifs } );
}

sub notificationServer {
    my ( $self, $req ) = @_;
    return $self->p->sendError( $req, 'Only JSON requests here', 400 )
      unless ( $req->wantJSON );
    my $res = eval { $self->notifObject->newNotification( $req->content ) };
    return $self->p->sendError( $req, $@, 500 ) if ($@);
    return $self->p->sendError( $req, 'Bad request', 400 ) unless ($res);
    return $self->p->sendJSONresponse( $req, { result => $res } );
}

1;
