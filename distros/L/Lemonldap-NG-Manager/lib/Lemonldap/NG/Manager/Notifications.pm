package Lemonldap::NG::Manager::Notifications;

use strict;
use utf8;
use Mouse;
use JSON qw(from_json to_json);
use POSIX qw(strftime);
use MIME::Base64 qw(decode_base64);

use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Common::Conf::ReConstants;
require Lemonldap::NG::Common::Notifications;

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::PSGI::Router
  Lemonldap::NG::Common::Conf::AccessLib
);

our $VERSION = '2.0.10';

has notifAccess => ( is => 'rw' );
has notifFormat => ( is => 'rw' );

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'notifications.html';

sub init {
    my ( $self, $conf ) = @_;

    if ( $conf->{oldNotifFormat} ) {
        Lemonldap::NG::Common::Notifications->import('XML');
        $self->notifFormat('XML');
    }
    else {
        Lemonldap::NG::Common::Notifications->import('JSON');
        $self->notifFormat('JSON');
    }

    unless ( $self->setNotifAccess($conf) ) {
        $self->addRoute( 'notifications.html', 'notEnabled', ['GET'] );
        $self->addRoute( notifications => 'notEnabled', ['GET'] );
        return ( $self->error ? 0 : 1 );
    }
    $self->{multiValuesSeparator} ||= '; ';

    # HTML template
    $self->addRoute( 'notifications.html', undef, ['GET'] )

      # READ
      ->addRoute(
        'notifications' =>
          { actives => 'activeNotifications', done => 'doneNotifications' },
        ['GET']
      )

      # Create new notification
      ->addRoute(
        'notifications' => { actives => 'newNotification' },
        ['POST']
      )

      # Update a notification (mark as done)
      ->addRoute(
        notifications =>
          { actives => { ':notificationId' => 'updateNotification' } },
        ['PUT']
      )

      # Delete a notification
      ->addRoute(
        notifications =>
          { done => { ':notificationId' => 'deleteDoneNotification' } },
        ['DELETE']
      );
    return 1;
}

sub setNotifAccess {
    my ( $self, $conf ) = @_;

    # TODO: refresh system
    $self->{$_} //= $conf->{$_}
      foreach (
        qw/portal notification notificationStorage notificationStorageOptions/);

    unless ( $self->{notification} ) {
        return 0;
    }

    # TODO: old parameters (with table)
    unless ( $self->{notificationStorage} ) {
        $self->handlerAbort( notifications =>
              'notificationStorage is not defined in configuration' );
        return 0;
    }
    my $type =
      "Lemonldap::NG::Common::Notifications::$self->{notificationStorage}";
    $type =~ s/(?:C|R)DBI$/DBI/;
    eval "require $type";
    if ($@) {
        $self->handlerAbort( notifications => "Unable to load $type: $@" );
        return 0;
    }

    # Force table name
    unless (
        eval {
            $self->notifAccess(
                $type->new( {
                        %{ $self->{notificationStorageOptions} },
                        p    => $self,
                        conf => $self
                    }
                )
            );
        }
      )
    {
        $self->handlerAbort( notifications => $@ );
        return 0;
    }
    return $self->notifAccess();
}

#######################
# II. DISPLAY METHODS #
#######################

sub notEnabled {
    my ( $self, $req ) = @_;
    return $self->sendError( $req,
        'Notifications are not enabled in your configuration', 400 );
}

sub activeNotifications {
    my ( $self, $req, $notif ) = @_;
    return $self->notifications( $req, $notif, 'actives' );
}

sub doneNotifications {
    my ( $self, $req, $notif ) = @_;
    return $self->notifications( $req, $notif, 'done' );
}

sub notifications {
    my ( $self, $req, $notif, $type ) = @_;
    my $sub = { actives => 'getAll', done => 'getDone' }->{$type}
      or die "Unknown type $type";

    # Case 1: a notification is required
    if ($notif) {
        my $params = $req->parameters();
        return $self->notification( $req, $notif, $type, $params->{uid},
            $params->{reference} );
    }

    # Case 2: list
    my $params = $req->parameters();
    my ( $notifs, $res );

    $notifs = $self->notifAccess->$sub();
    my $total = ( keys %$notifs );

    # Restrict to wanted values
    if (
        my %filters =
        map { /^(?:(?:group|order)By)$/ ? () : ( $_ => $params->{$_} ); }
        keys %$params
      )
    {
        while ( my ( $field, $value ) = each %filters ) {
            $value =~ s/\*/\.\*/g;
            $value = qr/^$value$/;
            foreach my $k ( keys %$notifs ) {
                delete $notifs->{$k}
                  unless ( $notifs->{$k}->{$field}
                    && $notifs->{$k}->{$field} =~ $value );
            }
        }
    }

    if ( my $groupBy = $req->params('groupBy') ) {
        my ( $length, $start, $r ) = ( 0, 0 );
        if ( $groupBy =~ /^substr\((\w+)(?:,(\d+)(?:,(\d+))?)?\)$/ ) {
            ( $groupBy, $length, $start ) = ( $1, $2, $3 );
            $start ||= 0;
            $length = 1 if ( $length < 1 );
        }
        foreach my $k ( keys %$notifs ) {
            my $s =
              $length
              ? substr( $notifs->{$k}->{$groupBy}, $start, $length )
              : $notifs->{$k}->{$groupBy};
            $r->{$s}++;
        }
        my $count = 0;
        $res = [
            map { $count += $r->{$_}; { value => $_, count => $r->{$_} } }
            sort keys %$r
        ];
        return $self->sendJSONresponse(
            $req,
            {
                result => 1,
                count  => $count,
                values => $res,
                total  => $total
            }
        );
    }
    else {
        my @r = map {
            my $r = { notification => $_ };
            foreach my $k (qw(uid date condition)) {
                $r->{$k} = $notifs->{$_}->{$k};
            }
            $r->{reference} = $notifs->{$_}->{ref};
            $r;
        } keys %$notifs;

        if ( my $orderBy = $req->params('orderBy') ) {
            my @fields = split /,/, $orderBy;
            while ( my $f = pop @fields ) {
                @r = sort { $a->{$f} cmp $b->{$f} } @r;
            }
        }
        return $self->sendJSONresponse(
            $req,
            {
                result => 1,
                count  => scalar(@r),
                values => \@r,
                total  => $total
            }
        );
    }
}

sub notification {
    my ( $self, $req, $id, $type ) = @_;
    my $backend = $self->{notificationStorage};
    $self->logger->debug("Notification storage backend: $backend");
    $self->logger->debug("Notification id: $id");

    if ( $type eq 'actives' ) {
        my ( $uid, $ref ) = ( $id =~ /([^_]+?)_(.+)/ );
        my $n = $self->notifAccess->get( $uid, $ref );
        unless ($n) {
            $self->userLogger->notice(
                "Active notification $ref not found for user $uid");
            return $self->sendJSONresponse(
                $req,
                {
                    result => 0,
                    error  => "Active notification $ref not found for user $uid"
                }
            );
        }
        $self->logger->debug("Active notification $ref found for user $uid");
        return $self->sendJSONresponse( $req,
            { result => 1, count => 1, notifications => [ values %$n ] } );
    }
    else {
        my ( $date, $uid, $ref ) =
          $backend eq 'File'
          ? ( $id =~ /([^_]+?)_(.+?)_(.+?)\.done/ )
          : ( $id =~ /([^_]+?)_(.+?)_(.+)/ );
        $ref = decode_base64($ref) if ( $backend eq 'File' );
        my $n = $self->notifAccess->getAccepted( $uid, $ref );
        unless ($n) {
            my $msg =
              $ref && $uid
              ? "Done notification $ref not found for user $uid"
              : 'Done notification not found';
            $self->userLogger->notice($msg);
            return $self->sendJSONresponse(
                $req,
                {
                    result => 0,
                    error  => $msg
                }
            );
        }
        $self->logger->debug("Done notification $ref found for user $uid");
        return $self->sendJSONresponse(
            $req,
            {
                result        => 1,
                count         => 1,
                done          => $id,
                notifications => [ values %$n ]
            }
        );
    }
}

sub newNotification {
    my ( $self, $req, @other ) = @_;
    return $self->sendError( $req,
        'There is no subkey for "newNotification"', 200 )
      if (@other);

    my $json = $req->jsonBodyToObj;
    unless ( defined($json) ) {
        return $self->sendError( $req, undef, 200 );
    }

    $json->{reference} =~ s/_/-/g;    # Remove underscores (#2135)

    foreach my $r (qw(uid reference xml)) {
        return $self->sendError( $req, "Missing $r", 200 )
          unless ( $json->{$r} );
    }

    # Set default date value
    my $dDate = strftime( "%Y-%m-%d", localtime() );
    if ( $json->{date} ) {
        $self->logger->debug(
"Posted data : uid = $json->{uid} - Ref = $json->{reference} - Date = $json->{date}"
        );
    }
    else {
        $self->logger->debug(
"Posted data : uid = $json->{uid} - Ref = $json->{reference} - Date = ???"
        );
        $json->{date} = $dDate;
    }

    # Check if posted date > today
    unless ( $json->{date} ge $dDate ) {
        $self->logger->debug("Posted Date < today");
        $json->{date} = $dDate;
    }
    $self->logger->debug("Notification Date = $json->{date}");

    unless ( $json->{date} =~ /^\d{4}-\d{2}-\d{2}$/ ) {
        $self->logger->error("Malformed date");
        return $self->sendError( $req, "Malformed date", 200 );
    }

    my $newNotif;
    if ( $self->notifFormat eq 'XML' ) {
        utf8::decode( $json->{xml} );
        $newNotif = qq#<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<root><notification #
          . join(
            ' ',
            map {
                if ( my $t = $json->{$_} ) { $t =~ s/"/'/g; qq#$_="$t"# }
                else                       { () }
            } (qw(uid date reference condition))
          ) . ">$json->{xml}</notification></root>";
    }
    else {
        eval {
            my $tmp = from_json( $json->{xml}, { allow_nonref => 1 } );
            $json->{$_} = $tmp->{$_} foreach ( keys %$tmp );
            delete $json->{xml};
        };
        if ($@) {
            $self->logger->error("Malformed notification $@");
            return $self->sendError( $req, "Malformed notification: $@", 200 );
        }
        $newNotif = to_json($json);
    }

    unless ( eval { $self->notifAccess->newNotification($newNotif) } ) {
        $self->logger->error("Notification not created: $@");
        return $self->sendError( $req, "Notification not created: $@", 200 );
    }
    else {
        return $self->sendJSONresponse( $req, { result => 1 } );
    }
}

sub updateNotification {
    my ( $self, $req ) = @_;

    my $json = $req->jsonBodyToObj;
    unless ( defined($json) ) {
        return $self->sendError( $req, undef, 200 );
    }

    # For now, only "mark as done" is proposed
    unless ( $json->{done} ) {
        return $self->sendError( $req, 'Only "done=1" is accepted for now',
            200 );
    }
    my $id = $req->params('notificationId') or die;
    my ( $uid, $ref ) = ( $id =~ /([^_]+?)_(.+)/ );
    my ( $n, $res );
    unless ( $n = $self->notifAccess->get( $uid, $ref ) ) {
        $self->logger->notice("Notification $ref not found for user $uid");
        return $self->sendError( $req,
            "Notification $ref not found for user $uid" );
    }

    # Delete notifications
    my $status = 1;
    foreach ( keys %$n ) {
        $status = 0 unless ( $self->notifAccess->delete($_) );
    }

    unless ($status) {
        $self->logger->error("Notification $ref for user $uid not deleted");
        return $self->sendError( $req,
            "Notification $ref for user $uid not deleted" );
    }

    else {
        $self->logger->info("Notification $ref deleted for user $uid");
        return $self->sendJSONresponse( $req, { result => 1 } );
    }
}

sub deleteDoneNotification {
    my ( $self, $req ) = @_;
    my $res;

    # Purge notification
    my $id = $req->params('notificationId') or die;
    my ( $uid, $ref, $date ) = ( $id =~ /([^_]+?)_([^_]+?)_(.+)/ );
    my $identifier = $self->notifAccess->getIdentifier( $uid, $ref, $date );
    unless ( eval { $self->notifAccess->purge($identifier) } ) {
        $self->logger->warn("Notification $identifier not purged ($@)");
        return $self->sendError( $req,
            "Notification $identifier not purged ($@)", 400 );
    }

    $self->logger->info("Notification $identifier purged");
    return $self->sendJSONresponse( $req, { result => 1 } );
}

1;
