## @file
# File storage methods for notifications

## @class
# File storage methods for notifications
package Lemonldap::NG::Common::Notification::File;

use strict;
use MIME::Base64;

our $VERSION = '1.9.1';

## @method boolean prereq()
# Check if parameters are set and if storage directory exists.
# @return true if all is OK
sub prereq {
    my $self = shift;
    unless ( $self->{dirName} ) {
        $Lemonldap::NG::Common::Notification::msg =
          '"dirName" is required in "File" notification type !';
        return 0;
    }
    if ( $self->{table} ) {
        $self->{dirName} =~ s/\/conf\/?$//;
        $self->{dirName} .= "/$self->{table}";
    }
    unless ( -d $self->{dirName} ) {
        $Lemonldap::NG::Common::Notification::msg =
          "Directory \"$self->{dirName}\" does not exist !";
        return 0;
    }

    # Configure file name separator (_ by default)
    $self->{fileNameSeparator} ||= "_";

    1;
}

## @method hashref get(string uid,string ref)
# Returns notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
# @param $uid UID
# @param $ref Notification reference
# @return hashref where keys are filenames and values are XML strings
sub get {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    my $fns = $self->{fileNameSeparator};
    my $identifier = &getIdentifier( $self, $uid, $ref );

    opendir D, $self->{dirName};
    my @notif = grep /^\d{8}${fns}${identifier}\S*\.xml$/, readdir(D);
    closedir D;

    my $files;
    foreach my $file (@notif) {
        unless ( open F, $self->{dirName} . "/$file" ) {
            $self->lmLog( "Unable to read notification $self->{dirName}/$file",
                'error' );
            next;
        }
        $files->{$file} = join( '', <F> );
    }
    return $files;
}

## @method hashref getAll()
# Return all messages not notified.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid and ref.
sub getAll {
    my $self = shift;
    opendir D, $self->{dirName};
    my @notif;
    my $fns = $self->{fileNameSeparator};
    @notif = grep /^\S*\.xml$/, readdir(D);
    my %h = map {
/^(\d{8})${fns}([^\s${fns}]+)${fns}([^\s${fns}]+)(?:${fns}([^\s${fns}]+))?\.xml$/
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
    my $new = ( $myref =~ /(.*?)(?:\.xml)$/ )[0] . '.done';
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

## @method boolean newNotif(string date, string uid, string ref, string xml)
# Insert a new notification
# @param date Date
# @param uid UID
# @param ref Reference of the notification
# @param xml XML notification
# @return true if succeed
sub newNotif {
    my ( $self, $date, $uid, $ref, $condition, $xml ) = @_;
    my $fns = $self->{fileNameSeparator};
    $date =~ s/-//g;
    return ( 0, "Bad date" ) unless ( $date =~ /^\d{8}/ );
    my $filename =
        $self->{dirName}
      . "/${date}${fns}${uid}${fns}"
      . encode_base64( $ref, '' );
    $filename .= "${fns}" . encode_base64( $condition, '' ) if $condition;
    $filename .= ".xml";

    return ( 0, 'This notification still exists' ) if ( -e $filename );
    my $old = ( $filename =~ /(.*?)(?:\.xml)$/ )[0] . '.done';
    return ( 0, 'This notification has been done' ) if ( -e $old );
    open my $F, ">$filename" or return ( 0, "Unable to create $filename ($!)" );
    binmode($F);
    $xml->toFH($F);
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

