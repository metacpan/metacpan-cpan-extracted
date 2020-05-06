## @file
# DBI storage methods for notifications

## @class
# DBI storage methods for notifications
package Lemonldap::NG::Common::Notifications::DBI;

use strict;
use Mouse;
use Time::Local;
use DBI;
use Encode;

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Common::Notifications';

sub import {
    shift;
    return Lemonldap::NG::Common::Notifications->import(@_);
}

has dbiTable => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->{table} || 'notifications' }
);

has dbiChain => (
    is       => 'ro',
    required => 1
);

has dbiUser => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->{p}->logger->warn('Warning: "dbiUser" parameter is not set');
        return '';
    }
);

has dbiPassword => ( is => 'ro', default => '' );

# Database handle object
has _dbh => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $r    = DBI->connect_cached(
            $self->{dbiChain}, $self->{dbiUser},
            $self->{dbiPassword}, { RaiseError => 1 }
        );
        $self->logger->error($DBI::errstr) unless ($r);
        return $r;
    }
);

# Current query
has sth => ( is => 'rw' );

# Returns notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
sub get {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    $self->_execute(
        "SELECT * FROM "
          . $self->dbiTable
          . " WHERE done IS NULL AND uid=?"
          . ( $ref ? " AND ref=?" : '' )
          . " ORDER BY date",
        $uid,
        ( $ref ? $ref : () )
    ) or return ();
    my $result;
    while ( my $h = $self->sth->fetchrow_hashref() ) {

        # Get XML message
        my $xml = $h->{xml};

        # Decode it to get the correct uncoded string
        Encode::from_to( $xml, "utf8", "iso-8859-1", Encode::FB_CROAK );

        # Store message in result
        my $identifier =
          &getIdentifier( $self, $h->{uid}, $h->{ref}, $h->{date} );
        $result->{$identifier} = $xml;
    }
    $self->logger->warn( $self->sth->err() ) if ( $self->sth->err() );
    return $result;
}

# Returns accepted notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
sub getAccepted {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    $self->_execute(
        "SELECT * FROM "
          . $self->dbiTable
          . " WHERE uid=? AND ref=? ORDER BY date",
        $uid,
        ( $ref ? $ref : () )
    ) or return ();
    my $result;
    while ( my $h = $self->sth->fetchrow_hashref() ) {

        # Get XML message
        my $xml = $h->{xml};

        # Decode it to get the correct uncoded string
        Encode::from_to( $xml, "utf8", "iso-8859-1", Encode::FB_CROAK );

        # Store message in result
        my $identifier =
          &getIdentifier( $self, $h->{uid}, $h->{ref}, $h->{date} );
        $result->{$identifier} = $xml;
    }
    $self->logger->warn( $self->sth->err() ) if ( $self->sth->err() );
    return $result;
}

## @method hashref getAll()
# Return all pending notifications.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid, ref and condition.
sub getAll {
    my $self = shift;
    $self->_execute( 'SELECT * FROM '
          . $self->dbiTable
          . ' WHERE done IS NULL ORDER BY date' );
    my $result;
    while ( my $h = $self->sth->fetchrow_hashref() ) {
        $result->{"$h->{date}#$h->{uid}#$h->{ref}"} = {
            date      => $h->{date},
            uid       => $h->{uid},
            ref       => $h->{ref},
            condition => $h->{condition}
        };
    }
    $self->logger->warn( $self->sth->err() ) if ( $self->sth->err() );
    return $result;
}

## @method hashref getExisting()
# Return all notifications.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid, ref and condition.
sub getExisting {
    my $self = shift;
    $self->_execute( 'SELECT * FROM ' . $self->dbiTable . ' ORDER BY date' );
    my $result;
    while ( my $h = $self->sth->fetchrow_hashref() ) {
        $result->{"$h->{date}#$h->{uid}#$h->{ref}"} = {
            date      => $h->{date},
            uid       => $h->{uid},
            ref       => $h->{ref},
            condition => $h->{condition}
        };
    }
    $self->logger->warn( $self->sth->err() ) if ( $self->sth->err() );
    return $result;
}

## @method boolean delete(string myref)
# Mark a notification as done.
# @param $myref identifier returned by get() or getAll()
sub delete {
    my ( $self, $myref ) = @_;
    my ( $d, $u, $r );
    unless ( ( $d, $u, $r ) = ( $myref =~ /^([^#]+)#(.+?)#(.+)$/ ) ) {
        $self->logger->warn("Bad reference $myref");
        return 0;
    }
    my @ts = localtime();
    $ts[5] += 1900;
    $ts[4]++;
    return $self->_execute( 'UPDATE '
          . $self->dbiTable
          . " SET done='$ts[5]-$ts[4]-$ts[3] $ts[2]:$ts[1]' "
          . 'WHERE done IS NULL AND uid=? AND ref=? AND date=?',
        $u, $r, $d );
}

## @method boolean purge(string myref, boolean force)
# Purge notification (really delete record)
# @param $myref identifier returned by get or getAll
# @param $force force purge for not deleted session
# @return true if something was deleted
sub purge {
    my ( $self, $myref, $force ) = @_;
    my ( $d, $u, $r );
    unless ( ( $d, $u, $r ) = ( $myref =~ /^([^#]+)#(.+?)#(.+)$/ ) ) {
        $self->logger->warn("Bad reference $myref");
        return 0;
    }
    unless ( $d =~ s/^(\d{4})(\d{2})(\d{2}).*$/$1-$2-$3/
        or $d =~ s/^(\d{4}-\d{2}-\d{2}).*$/$1/ )
    {
        $self->logger->warn("Bad date $d");
        return 0;
    }

    my $clause;
    $clause = "done IS NOT NULL AND" unless ($force);

    return $self->_execute( 'DELETE FROM '
          . $self->dbiTable
          . " WHERE $clause uid=? AND ref=? AND date=?",
        $u, $r, $d );
}

## @method boolean newNotif(string date, string uid, string ref, string condition, string xml)
# Insert a new notification
# @param date Date
# @param uid UID
# @param ref Reference of the notification
# @param condition Condition for the notification
# @param xml XML notification
# @return true if succeed
sub newNotif {
    my ( $self, $date, $uid, $ref, $condition, $xml ) = @_;
    my @t = split( /\D+/, $date );
    $t[1]--;
    eval {
        timelocal( $t[5] || 0, $t[4] || 0, $t[3] || 0, $t[2], $t[1], $t[0] );
    };
    return ( 0, "Bad date" ) if ($@);
    my $res =
      $condition =~ /.+/
      ? $self->_execute( 'INSERT INTO '
          . $self->dbiTable
          . ' (date,uid,ref,cond,xml) VALUES(?,?,?,?,?)',
        $date, $uid, $ref, $condition, $xml )
      : $self->_execute( 'INSERT INTO '
          . $self->dbiTable
          . ' (date,uid,ref,xml) VALUES(?,?,?,?)',
        $date, $uid, $ref, $xml );
    return $res;
}

## @method hashref getDone()
# Returns a list of notification that have been done
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    my ($self) = @_;
    $self->_execute( 'SELECT * FROM '
          . $self->dbiTable
          . ' WHERE done IS NOT NULL ORDER BY done' );
    my $result;
    while ( my $h = $self->sth->fetchrow_hashref() ) {
        my @t = split( /\D+/, $h->{date} );
        $t[1]--;
        my $done = eval {
            timelocal( $t[5] || 0, $t[4] || 0, $t[3] || 0, $t[2], $t[1],
                $t[0] );
        };
        if ($@) {
            $self->logger->warn("Bad date: $h->{date}");
            return {};
        }
        $result->{"$h->{date}#$h->{uid}#$h->{ref}"} =
          { notified => $done, uid => $h->{uid}, ref => $h->{ref}, };
    }
    $self->logger->warn( $self->sth->err() ) if ( $self->sth->err() );
    return $result;
}

## @method private object _execute(string query, array args)
# Execute a query and catch errors
# @return number of lines touched or 1 if select succeed
sub _execute {
    my ( $self, $query, @args ) = @_;
    my $dbh = $self->_dbh or die "DB connection unavailable";
    unless ( $self->sth( $dbh->prepare($query) ) ) {
        $self->logger->warn( $dbh->errstr() );
        return 0;
    }
    my $tmp;
    unless ( $tmp = $self->sth->execute(@args) ) {
        $self->logger->warn( $self->sth->errstr() );
        return 0;
    }
    return $tmp;
}

## @method string getIdentifier(string uid, string ref, string date)
# Get notification identifier
# @param $uid uid
# @param $ref ref
# @param $date date
# @return the notification identifier
sub getIdentifier {
    my ( $self, $uid, $ref, $date ) = @_;
    return $date . "#" . $uid . "#" . $ref;
}

1;

