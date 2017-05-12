package Lemonldap::NG::Manager::Notifications;

use 5.10.0;
use utf8;
use Mouse;

use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Manager::Constants;
use Lemonldap::NG::Common::Notification;

use feature 'state';

extends 'Lemonldap::NG::Manager::Lib';

our $VERSION = '1.9.1';

has _notifAccess => ( is => 'rw' );

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'notifications.html';

sub addRoutes {
    my $self = shift;

    unless ( $self->notifAccess ) {
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

}

sub notifAccess {
    my $self = shift;
    return $self->_notifAccess if ( $self->_notifAccess );

    # 1. Get notificationStorage or build it using globalStorage
    my $conf = $self->_confAcc->getConf();
    unless ($conf) {
        $self->error($Lemonldap::NG::Common::Conf::msg);
        return 0;
    }
    my $args;

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
    $args->{type} = $self->{notificationStorage};
    foreach ( keys %{ $self->{notificationStorageOptions} } ) {
        $args->{$_} = $self->{notificationStorageOptions}->{$_};
    }

    # Get the type
    $args->{type} =~ s/.*:://;
    $args->{type} =~ s/(CBDI|RDBI)/DBI/;    # CDBI/RDBI are DBI

    # If type not File or DBI, abort
    unless ( $args->{type} =~ /^(File|DBI|LDAP)$/ ) {
        $self->handlerAbort( notifications =>
              "Only File, DBI or LDAP supported for Notifications" );
        return 0;
    }

    # Force table name
    $args->{p} = $self;
    unless (
        $self->_notifAccess( Lemonldap::NG::Common::Notification->new($args) ) )
    {
        $self->handlerAbort(
            notifications => $Lemonldap::NG::Common::Notification::msg );
        return 0;
    }
    return $self->_notifAccess();
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
    return $self->notification( $req, $notif, $type ) if ($notif);

    # Case 2: list
    my $params = $req->params();
    my ( $notifs, $res );

    $notifs = $self->notifAccess->$sub();

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
                  unless ( $notifs->{$k}->{$field} =~ $value );
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
        return $self->sendJSONresponse( $req,
            { result => 1, count => scalar(@r), values => \@r } );
    }
}

sub notification {
    my ( $self, $req, $id, $type ) = @_;

    if ( $type eq 'actives' ) {
        my ( $uid, $ref ) = ( $id =~ /([^_]+?)_(.+)/ );
        my $n = $self->notifAccess->_get( $uid, $ref );
        unless ($n) {
            $self->lmLog( "Notification $ref not found for user $uid",
                'notice' );
            return $self->sendJSONresponse(
                $req,
                {
                    result => 0,
                    error  => "Notification $ref not found for user $uid"
                }
            );
        }
        return $self->sendJSONresponse( $req,
            { result => 1, count => 1, notifications => [ values %$n ] } );
    }
    else {
        return $self->sendJSONresponse( $req,
            { result => 1, count => 1, done => $id } );
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

    foreach my $r (qw(uid date reference xml)) {
        return $self->sendError( $req, "Missing $r", 200 )
          unless ( $json->{$r} );
    }

    unless ( $json->{date} =~ /^\d{4}-\d{2}-\d{2}$/ ) {
        return $self->sendError( $req, "Malformed date", 200 );
    }

    utf8::decode( $json->{xml} );

    my $newNotif = qq#<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<root><notification #
      . join(
        ' ',
        map {
            if ( my $t = $json->{$_} ) { $t =~ s/"/'/g; qq#$_="$t"# }
            else                       { () }
        } (qw(uid date reference condition))
      ) . ">$json->{xml}</notification></root>";

    unless ( eval { $self->notifAccess->newNotification($newNotif) } ) {
        $self->lmLog(
"Notification not created: $@$Lemonldap::NG::Common::Notification::msg",
            'error'
        );
        return $self->sendError(
            $req,
"Notification not created: $@$Lemonldap::NG::Common::Notification::msg",
            200
        );
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
    unless ( $n = $self->notifAccess->_get( $uid, $ref ) ) {
        $self->lmLog( "Notification $ref not found for user $uid", 'notice' );
        return $self->sendError( $req,
            "Notification $ref not found for user $uid" );
    }

    # Delete notifications
    my $status = 1;
    foreach ( keys %$n ) {
        $status = 0 unless ( $self->notifAccess->_delete($_) );
    }

    unless ($status) {
        $self->lmLog( "Notification $ref for user $uid not deleted", 'error' );
        return $self->sendError( $req,
            "Notification $ref for user $uid not deleted" );
    }

    else {
        $self->lmLog( "Notification $ref deleted for user $uid", 'info' );
        return $self->sendJSONresponse( $req, { result => 1 } );
    }
}

sub deleteDoneNotification {
    my ( $self, $req ) = @_;
    my $res;

    # Purge notification
    my $id = $req->params('notificationId') or die;
    my ( $uid, $ref, $date ) = ( $id =~ /([^_]+?)_([^_]+?)_(.+)/ );
    my $identifier = $self->notifAccess->_getIdentifier( $uid, $ref, $date );
    unless ( $self->notifAccess->purge($identifier) ) {
        $self->lmLog(
"Notification $identifier not purged ($Lemonldap::NG::Common::Notification::msg)",
            'warn'
        );
        return $self->sendError(
            $req,
"Notification $identifier not purged ($Lemonldap::NG::Common::Notification::msg)",
            400
        );
    }

    $self->lmLog( "Notification $identifier purged", 'info' );
    return $self->sendJSONresponse( $req, { result => 1 } );
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Notifications - Notifications explorer component of
L<Lemonldap::NG::Manager>.

=head1 SYNOPSIS

See L<Lemonldap::NG::Manager>.

=head1 DESCRIPTION

Lemonldap::NG::Manager provides a web interface to manage Lemonldap::NG Web-SSO
system.

The Perl part of Lemonldap::NG::Manager is the REST server. Web interface is
written in Javascript, using AngularJS framework and can be found in `site`
directory. The REST API is described in REST-API.md file given in source tree.

Lemonldap::NG Manager::Notifications provides the notifications explorer part.

=head1 ORGANIZATION

Lemonldap::NG Manager::Notifications is the only one module used to explore
notifications.  The javascript part is in `site/static/js/notifications.js`
file.

=head1 SEE ALSO

L<Lemonldap::NG::Manager>, L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
