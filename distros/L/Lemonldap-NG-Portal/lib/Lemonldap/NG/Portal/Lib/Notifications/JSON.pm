package Lemonldap::NG::Portal::Lib::Notifications::JSON;

use strict;
use Mouse;
use JSON qw(from_json);
use POSIX qw(strftime);

our $VERSION = '2.0.15';

no warnings 'redefine';

# Lemonldap::NG::Portal::Main::Plugin provides addAuthRoute() and
# addUnauthRoute() methods in addition of Lemonldap::NG::Common::Module.
extends 'Lemonldap::NG::Portal::Main::Plugin';

# PROPERTIES

# Underlying notifications storage object (File, DBI, LDAP,...)
has notifObject => ( is => 'rw' );

# INITIALIZATION

sub init {
    return 1;
}

# Search for notifications and if any, returns HTML fragment.
sub checkForNotifications {
    my ( $self, $req ) = @_;

    # Look for pending notifications in database
    my $uid = $req->sessionInfo->{ $self->notifObject->notifField };
    my ( $notifs, $forUser ) = $self->notifObject->getNotifications($uid);
    my $form;
    unless ($notifs) {
        $self->logger->info("No notification found");
        return 0;
    }

    # Transform notifications
    my $i = 0;    # Files count
    my @res;
    my $now = strftime "%Y-%m-%d", localtime;

    foreach my $file ( values %$notifs ) {
        my $json = eval { from_json( $file, { allow_nonref => 1 } ) };
        $self->userLogger->warn(
            "Bad JSON file: a notification for $uid was not done ($@)")
          if ($@);
        my $j = 0;    # Notifications count
        $json = [$json] unless ( ref $json eq 'ARRAY' );
      LOOP: foreach my $notif ( @{$json} ) {

            # Get the reference
            my $reference = $notif->{reference};
            $self->logger->debug("Get reference: $reference");

            # Check it in session
            if ( exists $req->{sessionInfo}->{"notification_$reference"} ) {

                # The notification was already accepted
                $self->logger->debug(
                    "Notification $reference was already accepted");
                next LOOP;
            }

            # Check date
            my $date = $notif->{date};
            $self->logger->debug("Get date: $date");
            unless ( $date and $date =~ /\b\d{4}-\d{2}-\d{2}\b/ ) {
                $self->logger->error('Malformed date');
                next LOOP;
            }
            unless ( $date le $now ) {
                $self->logger->debug('Notification date not reached');
                next LOOP;
            }

            # Check condition if any
            if ( my $condition = $notif->{condition} ) {
                $self->logger->debug("Get condition $condition");
                $condition = $self->p->HANDLER->substitute($condition);
                unless ( $condition = $self->p->HANDLER->buildSub($condition) )
                {
                    $self->logger->error( 'Notification condition error: '
                          . $self->p->HANDLER->tsv->{jail}->error );
                    next LOOP;
                }
                unless ( $condition->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug(
                        'Notification condition not authorized');
                    next LOOP;
                }
            }
            push @res, $notif;
            $j++;
        }

        # Go to next file if no notification found
        next unless $j;
        $i++;
    }
    @res =
      sort { $a->{date} cmp $b->{date} or $a->{reference} cmp $b->{reference} }
      @res;
    $form .= $self->toForm( $req, @res );

    # Stop here if nothing to display
    return 0 unless $i;
    $self->userLogger->info("$i pending notification(s) found for $uid");

    # Returns HTML fragment
    return $form;
}

# Search for accepted notification and if any, returns HTML fragment.
sub viewNotification {
    my ( $self, $req, $ref, $epoch ) = @_;

    # Look for accepted notifications in database
    my $uid = $req->userData->{ $self->notifObject->notifField };
    my ( $notifs, $forUser ) =
      $self->notifObject->getAcceptedNotifs( $uid, $ref );
    my $form;
    unless ($notifs) {
        $self->logger->info("No accepted notification found");
        return 0;
    }

    # Transform notifications
    my $i = 0;    # Files count
    my @res;

    foreach my $file ( values %$notifs ) {
        my $json = eval { from_json( $file, { allow_nonref => 1 } ) };
        $self->userLogger->warn(
            "Bad JSON file: a notification for $uid was not done ($@)")
          if ($@);
        my $j = 0;    # Notifications count
        $json = [$json] unless ( ref $json eq 'ARRAY' );
      LOOP: foreach my $notif ( @{$json} ) {

            # Get the reference
            my $reference = $notif->{reference};
            $self->logger->debug("Get reference: $reference");

            # Check it in session
            unless (exists $req->{userData}->{"notification_$reference"}
                and $req->{userData}->{"notification_$reference"} eq $epoch
                and $reference eq $ref )
            {

                # The notification is not already accepted
                $self->logger->debug(
                    "Notification $reference is not already accepted");
                next LOOP;
            }
            push @res, $notif;
            $j++;
        }

        # Go to next file if no notification found
        next unless $j;
        $i++;
    }
    $form .= $self->toForm( $req, @res );

    # Stop here if nothing to display
    return 0 unless $i;
    $self->userLogger->info("$i accepted notification(s) found for $uid");

    # Returns HTML fragment
    return $form;
}

sub getNotifBack {
    my ( $self, $req, $name ) = @_;

    # Search for Lemonldap::NG cookie (ciphered)
    my $id;
    return $self->p->sendError( $req, 'No cookie found', 401 )
      unless ( $id = $req->cookies->{ $self->{conf}->{cookieName} } );

    if ( $req->param('cancel') ) {
        $self->logger->debug('Cancel called -> remove ciphered cookie');
        $req->addCookie(
            $self->p->cookie(
                name    => $self->conf->{cookieName},
                value   => 0,
                domain  => $self->conf->{domain},
                secure  => $self->conf->{securedCookie},
                expires => 'Wed, 21 Oct 2015 00:00:00 GMT'
            )
        );
        $req->mustRedirect(1);
        return $self->p->do( $req, [] );
    }

    # Look if all notifications have been accepted.
    # If not, redirect to Portal

    # Try to decrypt Lemonldap::NG ciphered cookie
    $id = $self->p->HANDLER->tsv->{cipher}->decrypt($id)
      or
      return $self->p->sendError( $req, 'Unable to decrypt ciphered id', 400 );

    # Check that session exists
    $req->userData( $self->p->HANDLER->retrieveSession( $req, $id ) )
      or return $self->p->sendError( $req, 'Unknown session', 401 );

    # Restore data
    $self->p->importHandlerData($req);
    my $uid = $req->sessionInfo->{ $self->notifObject->notifField };

    # ALL notifications are returned here => Need to check active ones only
    my ( $notifs, $forUser ) =
      eval { $self->notifObject->getNotifications($uid) };
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
        my $now    = strftime "%Y-%m-%d", localtime;
        foreach my $fileName ( keys %$notifs ) {
            my $file       = $notifs->{$fileName};
            my $fileResult = 1;
            my $json       = from_json( $file, { allow_nonref => 1 } );
            $json = [$json] unless ( ref $json eq 'ARRAY' );

            # Get pending notifications and verify that they have been accepted
          LOOP: foreach my $notif (@$json) {
                my $reference = $notif->{reference};

                # Check date
                my $date = $notif->{date};
                $self->logger->debug("Get date: $date");
                unless ( $date and $date =~ /\b\d{4}-\d{2}-\d{2}\b/ ) {
                    $self->logger->error('Malformed date');
                    next LOOP;
                }
                unless ( $date le $now ) {
                    $self->logger->debug('Notification date not reached');
                    $fileResult = 0;    # Do not delete notification
                    next LOOP;
                }

                # Check condition if any
                if ( my $condition = $notif->{condition} ) {
                    $self->logger->debug("Get condition $condition");
                    $condition = $self->p->HANDLER->substitute($condition);
                    unless ( $condition =
                        $self->p->HANDLER->buildSub($condition) )
                    {
                        $self->logger->error( 'Notification condition error: '
                              . $self->p->HANDLER->tsv->{jail}->error );
                        next LOOP;
                    }
                    unless ( $condition->( $req, $req->sessionInfo ) ) {
                        $self->logger->debug(
                            'Notification condition not authorized');
                        $fileResult = 0;    # Do not delete notification
                        next LOOP;
                    }
                }

                # Check if this pending notification has been seen
                if ( my $refId = $refs->{$reference} ) {

                    # Verity that checkboxes have been checked
                    if ( $notif->{check} ) {
                        $notif->{check} = [ $notif->{check} ]
                          unless ( ref( $notif->{check} ) eq 'ARRAY' );
                        if ( my $toCheckCount = @{ $notif->{check} } ) {
                            unless ($checks->{$refId}
                                and $toCheckCount == @{ $checks->{$refId} } )
                            {
                                $self->userLogger->notice(
"$uid has not accepted notification $reference"
                                );
                                $result = $fileResult = 0;
                                next LOOP;
                            }
                        }
                    }
                }
                else {
                    # Current pending notification has not been found in
                    # request
                    $self->logger->debug(
                        'Current pending notification has not been found');
                    $result = $fileResult = 0;
                    next LOOP;
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
        return $self->p->do( $req, [ 'controlUrl', @{ $self->p->endAuth } ] );
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
            $_->{check} = [ $_->{check} ]
              unless ( ref( $_->{check} ) eq 'ARRAY' );
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
    my ( $self, $req, @args ) = @_;
    $self->p->logger->debug("REST request for notifications");
    return $self->p->sendError( $req, 'Only JSON requests here', 400 )
      unless ( $req->wantJSON );
    $self->p->logger->debug( "JSON content: " . $req->content );
    my ( $res, $err );
    if ( $req->method =~ /^POST$/i ) {
        $self->p->logger->debug("POST request");
        ( $res, $err ) = eval {
            $self->notifObject->newNotification( $req->content,
                $self->conf->{notificationDefaultCond} );
        };
        return $self->p->sendError( $req, $@, 500 ) if ($@);
    }
    elsif ( $req->method =~ /^GET$/i ) {
        $self->p->logger->debug("GET request");
        my ( $uid, $ref ) = @args;
        my $notifs;
        ( $notifs, $err ) =
          eval { $self->notifObject->getNotifications($uid) };
        return $self->p->sendError( $req, $@, 500 ) if ($@);
        $res = [];
        foreach my $notif ( keys %$notifs ) {
            $self->p->logger->debug("Found notification $notif");
            my $json =
              eval { from_json( $notifs->{$notif}, { allow_nonref => 1 } ) };
            return $self->p->sendError( $req, "Unable to decode JSON file: $@",
                400 )
              if ($@);
            $self->p->logger->debug(
                "Notification $notif: " . $notifs->{$notif} );
            if ($ref) {
                push( @$res,
                    map { "$_" => $json->{$_} },
                    split /\s+/,
                    $self->conf->{notificationServerSentAttributes} )
                  if ( $json->{reference} =~ /^$ref$/ );
            }
            else {
                push @$res,
                  {
                    "uid"       => $json->{uid},
                    "reference" => ( $json->{reference} || $json->{ref} )
                  };
            }
        }
    }
    elsif ( $req->method =~ /^DELETE$/i ) {
        $self->p->logger->debug("DELETE request");
        my $uid = $req->params('uid');
        my $ref = $req->params('reference');
        return $self->p->sendError( $req,
            "Missing parameters -> uid: $uid / ref: $ref", 400 )
          unless ( $uid and $ref );
        ( $res, $err ) =
          eval { $self->notifObject->deleteNotification( $uid, $ref ); };
        return $self->p->sendError( $req, $@, 500 ) if ($@);
    }
    else {
        return $self->p->sendError( $req, "Unknown HTTP method: $req->method",
            400 );
    }
    return $self->p->sendError( $req, ( $err ? $err : 'Bad request' ), 400 )
      unless ($res);
    return $self->p->sendJSONresponse( $req, { result => $res } );
}

1;
