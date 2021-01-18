package Lemonldap::NG::Common::Notifications::XML;

use strict;
use Mouse;
use XML::LibXML;

our $VERSION = '2.0.10';

# XML parser
has parser => (
    is      => 'rw',
    builder => sub {
        return XML::LibXML->new( load_ext_dtd => 0, expand_entities => 0 );
    }
);

# Check XML data and insert new notifications.
# @param $xml XML string containing notification
# @return number of notifications done
sub newNotification {
    my ( $self, $xml, $defaultCond ) = @_;
    $defaultCond ||= '';
    eval { $xml = $self->parser->parse_string($xml) };
    if ( my $err = $@ ) {
        eval { $self->logger->error("Unable to read XML file : $err") };
        return 0;
    }

    my @notifs;
    my ( $version, $encoding ) = ( $xml->version(), $xml->encoding() );

    foreach
      my $notif ( $xml->documentElement->getElementsByTagName('notification') )
    {
        my @data = ();
        $notif->{reference} =~ s/_/-/g;    # Remove underscores (#2135)

        # Mandatory information
        foreach (qw(date uid reference)) {
            my $tmp;
            unless ( $tmp = $notif->getAttribute($_) ) {
                $self->logger->error("Attribute $_ is missing");
                return 0;
            }
            if ( $self->get( $notif->{uid}, $notif->{reference} ) ) {
                my $err = "A notification already exists with reference "
                  . $notif->{reference};
                $self->logger->error("$err");
                return 0;
            }

            # Prevent to store time. Keep date only
            $tmp =~ s/^(\d{4}-\d{2}-\d{2}).*$/$1/;
            push @data, $tmp;
        }

        # Other information
        foreach (qw(condition)) {
            my $tmp;
            if ( $tmp = $notif->getAttribute($_) ) {
                push @data, $tmp;
            }
            else {
                $self->userLogger->info(
                    "Set defaultCondition ($defaultCond) for notification "
                      . $notif->{reference} );
                push @data, $defaultCond;
            }
        }

        my $result = XML::LibXML::Document->new( $version, $encoding );
        my $root   = XML::LibXML::Element->new('root');
        $root->appendChild($notif);
        $result->setDocumentElement($root);
        $result = $result->serialize;
        utf8::encode($result);
        push @notifs, [ @data, $result ];
    }
    my $count;
    foreach (@notifs) {
        $count++;
        my ( $r, $err ) = $self->newNotif(@$_);
        die "$err" unless ($r);
    }
    return $count;
}

## Delete notifications for the connected user
## @param $uid of the user
## @param $myref notification's reference
## @return number of deleted notifications
sub deleteNotification {
    my ( $self, $uid, $myref ) = @_;
    my @data;

    # Check input parameters
    unless ( $uid and $myref ) {
        $self->userLogger->error(
            "SOAP service deleteNotification called without all parameters");
        return 0;
    }

    $self->logger->debug(
"SOAP service deleteNotification called for uid $uid and reference $myref"
    );

    # Get notifications
    my $user = $self->get($uid);

    # Return 0 if no files were found
    return 0 unless ($user);

    # Counting
    my $count = 0;

    foreach my $ref ( keys %$user ) {
        my $xml = $self->parser->parse_string( $user->{$ref} );

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
                    $self->logger->debug("Notification $_ was removed.");
                    $count++;
                }
            }
        }
    }
    return $count;
}

1;
