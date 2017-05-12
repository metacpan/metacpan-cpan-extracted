##@file
# Notification system for Lemonldap::NG

##@class
# Notification system for Lemonldap::NG
package Lemonldap::NG::Common::Notification;

use strict;
use utf8;
use XML::LibXML;
use XML::LibXSLT;
use CGI::Cookie;
use Scalar::Util 'weaken';

#inherits Lemonldap::NG::Common::Notification::DBI
#inherits Lemonldap::NG::Common::Notification::File

our $VERSION = '1.9.1';
our ( $msg, $parser );

## @cmethod Lemonldap::NG::Common::Notification new(hashref storage)
# Constructor.
# @param $storage same syntax as Lemonldap::NG::Common::Conf object
# @return Lemonldap::NG::Common::Notification object
sub new {
    my ( $class, $storage ) = @_;
    my $self = bless {}, $class;
    (%$self) = (%$storage);
    unless ( $self->{p} ) {
        $msg = "p=>portal is required";
        return 0;
    }
    weaken $self->{p};
    my $type = $self->{type};
    $self->{type} = "Lemonldap::NG::Common::Notification::$self->{type}"
      unless ( $self->{type} =~ /::/ );
    eval "require $self->{type}";
    if ($@) {
        $msg = "Error: unknown storage type $type ($@)";
        return 0;
    }
    unless ( $self->_prereq ) {
        return 0;
    }

    # Initiate XML parser
    $parser = XML::LibXML->new();

    return $self;
}

## @method protected void lmLog(string mess, string level)
# Log subroutine. Call Lemonldap::NG::Portal::lmLog().
# @param $mess Text to log
# @param $level Level (debug|info|notice|error)
sub lmLog {
    my ( $self, $mess, $level ) = @_;
    $self->{p}->lmLog( "[Notification] $mess", $level );
}

## @method string getNotification(Lemonldap::NG::Portal portal)
# Check if notification(s) are available for the connected user.
# If it is, encrypt cookies and generate HTML form content.
# @param $portal Lemonldap::NG::Portal object that call
# @return HTML fragment containing form content
sub getNotification {
    my ( $self, $portal ) = @_;
    my ( @files, $form );

    # Get user datas,
    my $uid = $portal->{notificationField} || $portal->{whatToTrace} || 'uid';
    $uid =~ s/\$//g;
    $uid = $portal->{sessionInfo}->{$uid};

    # Check if some notifications have to be done
    # 1. For the user
    my $user = $self->_get($uid);

    # 2. For all users
    my $all = $self->_get( $portal->{notificationWildcard} );

    # 3. Join results
    my $n = {};
    if ( $user and $all ) { $n = { %$user, %$all }; }
    else                  { $n = $user ? $user : $all; }

    # Return 0 if no files were found
    return 0 unless ($n);

    # Create XSLT object
    my $xslt       = XML::LibXSLT->new();
    my $style_file = (
        -e $portal->{notificationXSLTfile}
        ? $portal->{notificationXSLTfile}
        : $portal->getApacheHtdocsPath() . "/skins/common/notification.xsl"
    );
    my $style_doc  = $parser->parse_file($style_file);
    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    # Prepare HTML code
    @files = map { $n->{$_} } sort keys %$n;
    my $i = 0;    # Files count
    foreach my $file (@files) {
        eval {
            my $xml = $parser->parse_string($file);
            my $j   = 0;                              # Notifications count

            # Browse notifications in file
            foreach my $notif (
                $xml->documentElement->getElementsByTagName('notification') )
            {

                # Get the reference
                my $reference = $notif->getAttribute('reference');

                $self->lmLog( "Get reference $reference", 'debug' );

                # Check it in session
                if (
                    exists $portal->{sessionInfo}
                    ->{ "notification_" . $reference } )
                {

                    # The notification was already accepted
                    $self->lmLog(
                        "Notification $reference was already accepted",
                        'debug' );

                    # Remove it from XML
                    $notif->unbindNode();
                    next;
                }

                # Check condition if any
                my $condition = $notif->getAttribute('condition');

                if ($condition) {

                    $self->lmLog( "Get condition $condition", 'debug' );

                    unless ( $portal->safe->reval($condition) ) {
                        $self->lmLog( "Notification condition not accepted",
                            'debug' );

                        # Remove it from XML
                        $notif->unbindNode();
                        next;

                    }
                }

                $j++;
            }

            # Go to next file if no notification found
            next unless $j;
            $i++;

            # Transform XML into HTML
            my $results = $stylesheet->transform( $xml, start => $i );
            $form .= $stylesheet->output_string($results);
        };
        if ($@) {
            $self->lmLog(
                "Bad XML file: a notification for $uid was not done ($@)",
                'warn' );
            return 0;
        }
    }

    # Stop here if nothing to display
    return 0 unless $i;

    # Now a notification has to be done. Replace cookies by hidden fields
    $i = 0;
    while ( my $tmp = shift @{ $portal->{cookie} } ) {
        $i++;
        my $t = $portal->{cipher}->encrypt( $tmp->value );
        unless ( defined($t) ) {
            $self->lmLog(
"Notification for $uid was not done : $Lemonldap::NG::Common::Crypto::msg",
                'warn'
            );
            return 0;
        }
        $tmp->value($t);
        $form .= qq{<input type="hidden" id="cookie$i" name="cookie$i" value="}
          . $tmp->as_string . '" />';
    }
    $form .= '<input type="hidden" name="type" value="notification"/>';
    return $form;
}

## @method boolean checkNotification(Lemonldap::NG::Portal portal)
# Check if notifications have been displayed and accepted.
# @param $portal Lemonldap::NG::Portal object that call
# @return true if all checkboxes have been checked
sub checkNotification {
    my ( $self, $portal ) = ( @_, 0, 2 );
    my ( $refs, $checks );

    # First, rebuild environment (cookies,...)
    foreach ( $portal->param() ) {
        if (/^cookie/) {
            my @tmp   = split /(?:=|;\s+)/, $portal->param($_);
            my %tmp   = @tmp;
            my $value = $portal->{cipher}->decrypt( $tmp[1] );
            unless ( defined($value) ) {
                $self->lmLog( "Unable to decrypt cookie", 'warn' );
                return 0;
            }
            push @{ $portal->{cookie} },
              $portal->cookie(
                -name   => $tmp[0],
                -value  => $value,
                -domain => $tmp{domain},
                -path   => "/",
                -secure => ( grep( /^secure$/, @tmp ) ? 1 : 0 ),
                @_,
              );
            if ( $tmp[0] eq $portal->{cookieName} ) {
                my $tmp = $portal->{existingSession};
                $portal->{existingSession} = sub { 0 };
                $portal->controlExistingSession($value);
                $portal->{existingSession} = $tmp;
            }
        }
        elsif (s/^reference//) {
            $refs->{$_} = $portal->param("reference$_");
        }
        elsif ( s/^check// and /^(\d+x\d+)x(\d+)$/ ) {
            push @{ $checks->{$1} }, $2;
        }
    }
    $portal->controlExistingSession() unless ( $portal->{sessionInfo} );
    unless ( $portal->{sessionInfo} ) {
        $self->lmLog( "Invalid session", 'warn' );
        return 0;
    }
    my $result = 1;
    foreach my $ref ( keys %$refs ) {
        my $uid =
             $portal->{notificationField}
          || $portal->{whatToTrace}
          || 'uid';
        $uid =~ s/\$//g;
        $uid = $portal->{sessionInfo}->{$uid};

        # Get notifications by references
        # 1. For the user
        my $user = $self->_get( $uid, $refs->{$ref} );

        # 2. For all users
        my $all = $self->_get( $portal->{notificationWildcard}, $refs->{$ref} );

        # 3. Join results
        my $files = {};
        if ( $user and $all ) { $files = { %$user, %$all }; }
        else                  { $files = $user ? $user : $all; }

        unless ($files) {
            $self->lmLog( "Can't find notification $refs->{$ref} for $uid",
                'error' );
            next;
        }

        # Browse found files
        foreach my $file ( keys %$files ) {
            my $xml;
            eval { $xml = $parser->parse_string( $files->{$file} ) };
            if ($@) {
                $self->lmLog( "Bad XML notification for $uid", 'error' );
                next;
            }

            # Browse notifications in file
            foreach my $notif (
                $xml->documentElement->getElementsByTagName('notification') )
            {
                my $reference  = $notif->getAttribute('reference');
                my @tmp        = $notif->getElementsByTagName('check');
                my $checkCount = @tmp;
                if ( $checkCount == 0
                    or
                    ( $checks->{$ref} and $checkCount == @{ $checks->{$ref} } )
                  )
                {

                    # Notification is accepted

                    $self->lmLog(
                        "$uid has accepted notification $refs->{$ref}",
                        'notice' );

                    # 1. Register acceptation in persistent session
                    my $time     = time();
                    my $notifkey = "notification_" . $refs->{$ref};
                    $portal->updatePersistentSession(
                        { $notifkey => $time },

                    );

                    $self->lmLog(
                        "Notification "
                          . $refs->{$ref}
                          . " registered in persistent session",
                        'debug'
                    );

                    # 2. Delete it if not a wildcard notification
                    if ( exists $user->{$file} ) {

                        if ( $self->_delete($file) ) {
                            $self->lmLog(
                                "Notification " . $refs->{$ref} . " deleted",
                                'debug' );
                        }
                        else {
                            $self->lmLog(
"Unable to delete notification $refs->{$ref} for $uid",
                                'error'
                            );
                        }
                    }
                }
                else {
                    $self->lmLog(
                        "$uid has not accepted notification $refs->{$ref}",
                        'notice' );
                    $result = 0;
                }
            }
        }
    }
    return $result;
}

## @method int newNotification(string xml)
# Check XML datas and insert new notifications.
# @param $xml XML string containing notification
# @return number of notifications done
sub newNotification {
    my ( $self, $xml ) = @_;
    eval { $xml = $parser->parse_string($xml); };
    if ($@) {
        $self->lmLog( "Unable to read XML file : $@", 'error' );
        return 0;
    }
    my @notifs;
    my ( $version, $encoding ) = ( $xml->version(), $xml->encoding() );
    foreach
      my $notif ( $xml->documentElement->getElementsByTagName('notification') )
    {
        my @datas = ();

        # Mandatory information
        foreach (qw(date uid reference)) {
            my $tmp;
            unless ( $tmp = $notif->getAttribute($_) ) {
                $self->lmLog( "Attribute $_ is missing", 'error' );
                return 0;
            }
            push @datas, $tmp;
        }

        # Other information
        foreach (qw(condition)) {
            my $tmp;
            if ( $tmp = $notif->getAttribute($_) ) {
                push @datas, $tmp;
            }
            else { push @datas, ""; }
        }

        my $result = XML::LibXML::Document->new( $version, $encoding );
        my $root = XML::LibXML::Element->new('root');
        $root->appendChild($notif);
        $result->setDocumentElement($root);
        push @notifs, [ @datas, $result ];
    }
    my $tmp = $self->{type};
    my $count;
    foreach (@notifs) {
        $count++;
        my ( $r, $err ) = $self->_newNotif(@$_);
        die "$err" unless ($r);
    }
    return $count;
}

## @method int deleteNotification(string $uid, string $myref)
## Delete notifications for the connected user
## @param $uid of the user
## @param $myref notification's reference
## @return number of deleted notifications
sub deleteNotification {
    my ( $self, $uid, $myref ) = @_;
    my @data;

    # Check input parameters
    unless ( $uid and $myref ) {
        $self->lmLog(
            "SOAP service deleteNotification called without all parameters",
            'error' );
        return 0;
    }

    $self->lmLog(
"SOAP service deleteNotification called for uid $uid and reference $myref",
        'debug'
    );

    # Get notifications
    my $user = $self->_get($uid);

    # Return 0 if no files were found
    return 0 unless ($user);

    # Counting
    my $count = 0;

    foreach my $ref ( keys %$user ) {
        my $xml = $parser->parse_string( $user->{$ref} );

        # Browse notification in file
        foreach my $notif (
            $xml->documentElement->getElementsByTagName('notification') )
        {

            # Get notification's data
            if ( $notif->getAttribute('reference') eq $myref ) {
                push @data, $ref;
            }

            # Delete the notification (really)
            foreach (@data) {
                if ( $self->purge( $_, 1 ) ) {
                    $self->lmLog( "Notification $_ was removed.", 'debug' );
                    $count++;
                }
            }
        }
    }
    return $count;
}

## @method hashref getAll()
# Return all messages not notified. Wrapper for storage module getAll()
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid and ref.
sub getAll {
    no strict 'refs';
    return &{ $_[0]->{type} . '::getAll' }(@_);
}

## @method hashref getDone()
# Returns a list of notification that have been done. Wrapper for storage module
# getDone().
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    no strict 'refs';
    return &{ $_[0]->{type} . '::getDone' }(@_);
}

## @method boolean purge(string myref, boolean force)
# Purge notification (really delete record). Wrapper for storage module purge()
# @param $myref identifier returned by get or getAll
# @param $force force purge for not deleted session
# @return true if something was deleted
sub purge {
    no strict 'refs';
    return &{ $_[0]->{type} . '::purge' }(@_);
}

## @method private hashref _get(string uid,string ref)
# Returns notifications corresponding to the user $uid. Wrapper for storage
# module get().
# If $ref is set, returns only notification corresponding to this reference.
# @param $uid UID
# @param $ref Notification reference
# @return hashref where keys are internal reference and values are XML strings
sub _get {
    no strict 'refs';
    my $self = $_[0];

    # Debug lines. Must be removed ?
    die ref($self)
      unless ( ref($self) eq 'Lemonldap::NG::Common::Notification' );
    return &{ $_[0]->{type} . '::get' }(@_);
}

## @method private boolean _delete(string myref)
# Mark a notification as done. Wrapper for storage module delete()
# @param $myref identifier returned by get() or getAll()
sub _delete {
    no strict 'refs';
    return &{ $_[0]->{type} . '::delete' }(@_);
}

## @method private boolean _prereq()
# Check if storage module parameters are set. Wrapper for storage module
# prereq()
# @return true if all is OK
sub _prereq {
    no strict 'refs';
    return &{ $_[0]->{type} . '::prereq' }(@_);
}

## @method private boolean _newNotif(string date, string uid, string ref, string xml)
# Insert a new notification. Wrapper for storage module newNotif()
# @param date Date
# @param uid UID
# @param ref Reference of the notification
# @param xml XML notification
# @return true if succeed
sub _newNotif {
    no strict 'refs';
    return &{ $_[0]->{type} . '::newNotif' }(@_);
}

## @method private string _getIdentifier(string uid, string ref, string date)
# Get notification identifier
# @param $uid uid
# @param $ref ref
# @param $date date
# @return the notification identifier
sub _getIdentifier {
    no strict 'refs';
    return &{ $_[0]->{type} . '::getIdentifier' }(@_);
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::Notification - Provides notification messages system.

=head1 SYNOPSIS

    use Lemonldap::NG::Portal;

=head1 DESCRIPTION

Lemonldap::NG::Common::Notification.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>,

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2009-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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


