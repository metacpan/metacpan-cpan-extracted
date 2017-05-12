## @file
# DBI storage methods for notifications

## @class
# DBI storage methods for notifications
package Lemonldap::NG::Common::Notification::DBI;

use strict;
use Time::Local;
use DBI;
use Encode;
use utf8;

our $VERSION = '1.9.1';

## @method boolean prereq()
# Check if DBI parameters are set.
# @return true if all is OK
sub prereq {
    my $self = shift;
    $self->{dbiTable} = $self->{table} if ( $self->{table} );
    unless ( $self->{dbiChain} ) {
        $Lemonldap::NG::Common::Notification::msg =
          '"dbiChain" is required in DBI notification type';
        return 0;
    }
    $self->lmLog( 'Warning: "dbiUser" parameter is not set', 'warn' )
      unless ( $self->{dbiUser} );
    1;
}

## @method hashref get(string uid,string ref)
# Returns notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
# @param $uid UID
# @param $ref Notification reference
# @return hashref where keys are internal reference and values are XML strings
sub get {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    _execute(
        $self,
        "SELECT * FROM $self->{dbiTable} WHERE done IS NULL AND uid=?"
          . ( $ref ? " AND ref=?" : '' )
          . "ORDER BY date",
        $uid,
        ( $ref ? $ref : () )
    ) or return ();
    my $result;
    while ( my $h = $self->{sth}->fetchrow_hashref() ) {

        # Get XML message
        my $xml = $h->{xml};

        # Decode it to get the correct uncoded string
        Encode::from_to( $xml, "utf8", "iso-8859-1", Encode::FB_CROAK );

        # Store message in result
        my $identifier =
          &getIdentifier( $self, $h->{uid}, $h->{ref}, $h->{date} );
        $result->{$identifier} = $xml;
    }
    $self->lmLog( $self->{sth}->err(), 'warn' ) if ( $self->{sth}->err() );
    return $result;
}

## @method hashref getAll()
# Return all messages not notified.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid and ref.
sub getAll {
    my $self = shift;
    _execute( $self,
        "SELECT * FROM $self->{dbiTable} WHERE done IS NULL ORDER BY date" );
    my $result;
    while ( my $h = $self->{sth}->fetchrow_hashref() ) {
        $result->{"$h->{date}#$h->{uid}#$h->{ref}"} = {
            date      => $h->{date},
            uid       => $h->{uid},
            ref       => $h->{ref},
            condition => $h->{condition}
        };
    }
    $self->lmLog( $self->{sth}->err(), 'warn' ) if ( $self->{sth}->err() );
    return $result;
}

## @method boolean delete(string myref)
# Mark a notification as done.
# @param $myref identifier returned by get() or getAll()
sub delete {
    my ( $self, $myref ) = @_;
    my ( $d, $u, $r );
    unless ( ( $d, $u, $r ) = ( $myref =~ /^([^#]+)#(.+?)#(.+)$/ ) ) {
        $Lemonldap::NG::Common::Notification::msg = "Bad reference $myref";
        $self->lmLog( "Bad reference $myref", 'warn' );
        return 0;
    }
    my @ts = localtime();
    $ts[5] += 1900;
    $ts[4]++;
    return _execute(
        $self,
        "UPDATE $self->{dbiTable} "
          . "SET done='$ts[5]-$ts[4]-$ts[3] $ts[2]:$ts[1]' "
          . "WHERE done IS NULL AND uid=? AND ref=? AND date=?",
        $u,
        $r,
        $d
    );
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
        $Lemonldap::NG::Common::Notification::msg = "Bad reference $myref";
        $self->lmLog( "Bad reference $myref", 'warn' );
        return 0;
    }

    my $clause;
    $clause = "done IS NOT NULL AND" unless ($force);

    return _execute(
        $self,
        "DELETE FROM $self->{dbiTable} "
          . "WHERE $clause uid=? AND ref=? AND date=?",
        $u,
        $r,
        $d
    );
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
    $xml = $xml->serialize();

    utf8::encode($xml);

    my $res =
      $condition =~ /.+/
      ? _execute(
        $self,
        "INSERT INTO $self->{dbiTable} (date,uid,ref,cond,xml) "
          . "VALUES(?,?,?,?,?)",
        $date,
        $uid,
        $ref,
        $condition,
        $xml
      )
      : _execute(
        $self,
        "INSERT INTO $self->{dbiTable} (date,uid,ref,xml) " . "VALUES(?,?,?,?)",
        $date,
        $uid,
        $ref,
        $xml
      );
    return $res;
}

## @method hashref getDone()
# Returns a list of notification that have been done
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    my ($self) = @_;
    _execute( $self,
        "SELECT * FROM $self->{dbiTable} WHERE done IS NOT NULL ORDER BY done"
    );
    my $result;
    while ( my $h = $self->{sth}->fetchrow_hashref() ) {
        my @t = split( /\D+/, $h->{date} );
        my $done = timelocal( $t[5], $t[4], $t[3], $t[2], $t[1], $t[0] );
        $result->{"$h->{date}#$h->{uid}#$h->{ref}"} =
          { notified => $done, uid => $h->{uid}, ref => $h->{ref}, };
    }
    $self->lmLog( $self->{sth}->err(), 'warn' ) if ( $self->{sth}->err() );
    return $result;
}

## @method private object _execute(string query, array args)
# Execute a query and catch errors
# @return number of lines touched or 1 if select succeed
sub _execute {
    my ( $self, $query, @args ) = @_;
    my $dbh = _dbh($self) or return 0;
    unless ( $self->{sth} = $dbh->prepare($query) ) {
        $self->lmLog( $dbh->errstr(), 'warn' );
        return 0;
    }
    my $tmp;
    unless ( $tmp = $self->{sth}->execute(@args) ) {
        $self->lmLog( $self->{sth}->errstr(), 'warn' );
        return 0;
    }
    return $tmp;
}

## @method object private _dbh()
# Return the DBI object (build it if needed).
# @return database handle object
sub _dbh {
    my $self = shift;
    $self->{dbiTable} ||= "notifications";
    return $self->{dbh} if ( $self->{dbh} and $self->{dbh}->ping );
    my $r = DBI->connect_cached(
        $self->{dbiChain}, $self->{dbiUser},
        $self->{dbiPassword}, { RaiseError => 0 }
    );
    $self->lmLog( $DBI::errstr, 'error' ) unless ($r);
    return $r;
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

