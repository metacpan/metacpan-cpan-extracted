package Lemonldap::NG::Portal::Lib::Notifications::XML;

use strict;
use Mouse;
use XML::LibXML;
use XML::LibXSLT;

our $VERSION = '2.0.0';

# Lemonldap::NG::Portal::Main::Plugin provides addAuthRoute() and
# addUnauthRoute() methods in addition of Lemonldap::NG::Common::Module.
extends 'Lemonldap::NG::Portal::Main::Plugin';

# PROPERTIES

# XML parser
has parser => (
    is      => 'rw',
    builder => sub {
        return XML::LibXML->new( load_ext_dtd => 0, expand_entities => 0 );
    }
);

# XSLT document
has stylesheet => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = $_[0];
        my $xslt = XML::LibXSLT->new();
        my $styleFile =
          ( $self->conf->{notificationXSLTfile}
              and -e $self->conf->{notificationXSLTfile} )
          ? $self->conf->{notificationXSLTfile}
          : $self->conf->{templateDir} . '/common/notification.xsl';
        unless ( -e $styleFile ) {
            $self->{logger}->error("$styleFile not found, aborting");
            die "$styleFile not found";
        }
        return $xslt->parse_stylesheet( $self->parser->parse_file($styleFile) );
    }
);

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
        my $xml = $self->parser->parse_string($file);
        my $j   = 0;                                    #Notifications count
      LOOP: foreach my $notif (
            eval {
                $xml->documentElement->getElementsByTagName('notification');
            }
          )
        {

            # Get the reference
            my $reference = $notif->getAttribute('reference');

            $self->logger->debug("Get reference $reference");

            # Check it in session
            if ( exists $req->{sessionInfo}->{"notification_$reference"} ) {

                # The notification was already accepted
                $self->logger->debug(
                    "Notification $reference was already accepted");

                # Remove it from XML
                $notif->unbindNode();
                next LOOP;
            }

            # Check condition if any
            my $condition = $notif->getAttribute('condition');

            if ($condition) {

                $self->logger->debug("Get condition $condition");
                $condition = $self->p->HANDLER->substitute($condition);
                unless ( $condition = $self->p->HANDLER->buildSub($condition) )
                {
                    $self->logger->error( 'Notification condition error: '
                          . $self->p->HANDLER->tsv->{jail}->error );
                    $notif->unbindNode();
                    next LOOP;
                }

                unless ( $condition->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug(
                        'Notification condition not authorized');

                    # Remove it from XML
                    $notif->unbindNode();
                    next LOOP;
                }
            }

            $j++;
        }

        # Go to next file if no notification found
        next unless $j;
        $i++;

        # Transform XML into HTML
        my $results = $self->stylesheet->transform( $xml, start => $i );
        $form .= $self->stylesheet->output_string($results);
    }
    if ($@) {
        $self->userLogger->warn(
            "Bad XML file: a notification for $uid was not done ($@)");
        return 0;
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
      or return $self->sendError( $req, 'Unable to decrypt', 500 );

    # Verify that session exists
    $req->userData( $self->p->HANDLER->retrieveSession( $req, $id ) )
      or return $self->sendError( $req, 'Unknown session', 401 );

    # Restore data
    $self->p->importHandlerData($req);
    my $uid = $req->sessionInfo->{ $self->notifObject->notifField };

    my ( $notifs, $forUser ) = $self->notifObject->getNotifications($uid);
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
            my $xml        = $self->parser->parse_string($file);

            # Get pending notifications and verify that they have been accepted
            foreach my $notif (
                $xml->documentElement->getElementsByTagName('notification') )
            {
                my $reference = $notif->getAttribute('reference');

                # Check if this pending notification has been seen
                if ( my $refId = $refs->{$reference} ) {

                    # Verity that checkboxes have been checked
                    my @toCheck = $notif->getElementsByTagName('check');
                    if ( my $toCheckCount = @toCheck ) {
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

has imported => ( is => 'rw', default => 0 );
has server => ( is => 'rw' );

sub notificationServer {
    my ( $self, $req ) = @_;
    unless ( $self->imported ) {
        eval {
            require Lemonldap::NG::Common::PSGI::SOAPServer;
            require Lemonldap::NG::Common::PSGI::SOAPService;
        };
        if ($@) {
            return $self->p->sendError( $req, $@, 500 );
        }
        $self->server( Lemonldap::NG::Common::PSGI::SOAPServer->new );
        $self->imported(1);
    }
    unless ( $req->env->{HTTP_SOAPACTION} ) {
        return $self->p->sendError( $req, 'SOAP requests only', 400 );
    }
    return $self->server->dispatch_to(
        Lemonldap::NG::Common::PSGI::SOAPService->new(
            $self, $req, 'newNotification',
        )
    )->handle($req);
}

sub newNotification {
    my ( $self, $req, $xml ) = @_;
    return $self->notifObject->newNotification($xml);
}

1;
