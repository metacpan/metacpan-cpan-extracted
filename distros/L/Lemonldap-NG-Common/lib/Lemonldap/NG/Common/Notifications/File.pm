## @file
# File storage methods for notifications

## @class
# File storage methods for notifications
package Lemonldap::NG::Common::Notifications::File;

use strict;
use Mouse;
use Time::Local;
use MIME::Base64;

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Common::Notifications';

sub import {
    shift;
    return Lemonldap::NG::Common::Notifications->import(@_);
}

has dirName => ( is => 'ro', required => 1 );

has table => (
    is      => 'rw',
    trigger => sub {
        $_[0]->{dirName} =~ s/\/conf\/?$//;
        $_[0]->{dirName} .= "/$_[0]->{table}";
    }
);

has fileNameSeparator => ( is => 'rw', default => '_' );

# Returns notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
sub get {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    my $ext        = $self->extension;
    my $fns        = $self->{fileNameSeparator};
    my $identifier = &getIdentifier( $self, $uid, $ref );

    opendir D, $self->{dirName};
    my @notif = grep /^\d{8}${fns}${identifier}\S*\.$ext$/, readdir(D);
    closedir D;

    my $files;
    foreach my $file (@notif) {
        unless ( open F, '<', $self->{dirName} . "/$file" ) {
            $self->logger->error(
                "Unable to read notification $self->{dirName}/$file");
            next;
        }
        $files->{$file} = join( '', <F> );
    }
    return $files;
}

# Returns accepted notification corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
sub getAccepted {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    my $ext        = $self->extension;
    my $fns        = $self->{fileNameSeparator};
    my $identifier = &getIdentifier( $self, $uid, $ref );

    opendir D, $self->{dirName};
    my @notif = grep /^\d{8}${fns}${identifier}\S*\.(?:done|$ext)$/, readdir(D);
    closedir D;

    my $files;
    foreach my $file (@notif) {
        unless ( open F, '<', $self->{dirName} . "/$file" ) {
            $self->logger->error(
                "Unable to read notification $self->{dirName}/$file");
            next;
        }
        $files->{$file} = join( '', <F> );
    }
    return $files;
}

## @method hashref getAll()
# Return all pending notifications.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid, ref and condition.
sub getAll {
    my $self = shift;
    my $ext  = $self->extension;
    opendir D, $self->{dirName};
    my @notif;
    my $fns = $self->{fileNameSeparator};
    @notif = grep /^\S*\.$ext$/, readdir(D);
    my %h = map {
/^(\d{8})${fns}([^\s${fns}]+)${fns}([^\s${fns}]+)(?:${fns}([^\s${fns}]+))?\.$ext$/
          ? (
            $_ => {
                date      => $1,
                uid       => $2,
                ref       => decode_base64($3),
                condition => decode_base64( $4 // '' )
            }
          )
          : ()
    } @notif;
    return \%h;
}

## @method hashref getExisting()
# Return all notifications.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid, ref and condition.
sub getExisting {
    my $self = shift;
    my $ext  = $self->extension;
    opendir D, $self->{dirName};
    my @notif;
    my $fns = $self->{fileNameSeparator};
    @notif = grep /^\S*\.$ext$/, readdir(D);
    my %h = map {
/^(\d{8})${fns}([^\s${fns}]+)${fns}([^\s${fns}]+)(?:${fns}([^\s${fns}]+))?\.(?:$ext|done)$/
          ? (
            $_ => {
                date      => $1,
                uid       => $2,
                ref       => decode_base64($3),
                condition => decode_base64( $4 // '' )
            }
          )
          : ()
    } @notif;
    return \%h;
}

## @method boolean delete(string myref)
# Mark a notification as done.
# @param $myref identifier returned by get() or getAll()
sub delete {
    my ( $self, $myref ) = @_;
    my $ext = $self->extension;
    my $new = ( $myref =~ /(.*?)(?:\.$ext)$/ )[0] . '.done';
    return rename( $self->{dirName} . "/$myref", $self->{dirName} . "/$new" );
}

## @method boolean purge(string myref)
# Purge notification (really delete record)
# @param $myref identifier returned by get() or getAll()
# @return true if something was deleted
sub purge {
    my ( $self, $myref ) = @_;
    return unlink( $self->{dirName} . "/$myref" );
}

# Insert a new notification
sub newNotif {
    my ( $self, $date, $uid, $ref, $condition, $content ) = @_;
    my $ext = $self->extension;
    my $fns = $self->{fileNameSeparator};
    $fns ||= '_';
    my @t = split( /\D+/, $date );
    $t[1]--;
    eval {
        timelocal( $t[5] || 0, $t[4] || 0, $t[3] || 0, $t[2], $t[1], $t[0] );
    };
    return ( 0, "Bad date" ) if ($@);
    $date =~ s/-//g;
    return ( 0, "Bad date" ) unless ( $date =~ /^\d{8}/ );
    my $filename =
        $self->{dirName}
      . "/${date}${fns}${uid}${fns}"
      . encode_base64( $ref, '' );
    $filename .= "${fns}" . encode_base64( $condition, '' ) if $condition;
    $filename .= ".$ext";

    return ( 0, 'This notification still exists' ) if ( -e $filename );
    my $old = ( $filename =~ /(.*?)(?:\.$ext)$/ )[0] . '.done';
    return ( 0, 'This notification has been done' ) if ( -e $old );
    open my $F, '>', $filename
      or return ( 0, "Unable to create $filename ($!)" );
    binmode($F);
    print $F $content;
    return ( 0, "Unable to close $filename ($!)" ) unless ( close $F );
    return 1;
}

## @method hashref getDone()
# Returns a list of notification that have been done
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    my ($self) = @_;
    opendir D, $self->{dirName};
    my @notif;
    my $fns = $self->{fileNameSeparator};
    @notif = grep /^\d{8}${fns}\S*\.done$/, readdir(D);
    my $res;
    foreach my $file (@notif) {
        my ( $u, $r ) =
          ( $file =~
/^\d+${fns}([^${fns}]+)${fns}([^${fns}]+)${fns}?([^${fns}]+)\.done$/
          );
        die unless ( -f "$self->{dirName}/$file" );
        my $time = ( stat("$self->{dirName}/$file") )[10];
        $res->{$file} = {
            'uid'      => $u,
            'ref'      => decode_base64($r),
            'notified' => $time,
        };
    }
    return $res;
}

## @method string getIdentifier(string uid, string ref, string date)
# Get notification identifier
# @param $uid uid
# @param $ref ref
# @param $date date
# @return the notification identifier
sub getIdentifier {
    my ( $self, $uid, $ref, $date ) = @_;
    my $result;

    # Special fix to manage purge from notification explorer
    return $date if $date;

    my $fns = $self->{fileNameSeparator};
    if ($date) {
        $result .= $date . $fns;
    }
    $result .= $uid;
    if ($ref) {
        my $tmp = encode_base64( $ref, '' );
        $result .= $fns . $tmp;
    }
    return $result;
}

1;

