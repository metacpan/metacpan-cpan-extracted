package Lemonldap::NG::Common::Notifications::JSON;

use strict;
use Mouse;
use JSON qw(from_json to_json);

our $VERSION = '2.0.0';

sub newNotification {
    my ( $self, $jsonString ) = @_;
    my $json;
    eval { $json = from_json( $jsonString, { allow_nonref => 1 } ) };
    if ( my $err = $@ ) {
        eval { $self->logger->error("Unable to decode JSON file: $err") };
        return 0;
    }
    my @notifs;
    $json = [$json] unless ( ref($json) eq 'ARRAY' );
    foreach my $notif (@$json) {
        my @data;

        # Mandatory information
        foreach (qw(date uid reference)) {
            my $tmp;
            unless ( $tmp = $notif->{$_} ) {
                $self->logger->error("Attribute $_ is missing");
                return 0;
            }
            push @data, $tmp;
        }
        push @data, ( $notif->{condition} // '' );
        push @notifs, [ @data, $jsonString ];
    }
    my $count;
    foreach (@notifs) {
        $count++;
        my ( $r, $err ) = $self->newNotif(@$_);
        die "$err" unless ($r);
    }
    return $count;
}

sub deleteNotification {
    my ( $self, $uid, $myref ) = @_;
    my @data;

    # Check input parameters
    unless ( $uid and $myref ) {
        $self->userLogger->error(
            'REST service "delete notification" called without all parameters');
        return 0;
    }

    $self->logger->debug(
"REST service deleteNotification called for uid $uid and reference $myref"
    );

    # Get notifications
    my $user = $self->get($uid);

    # Return 0 if no files were found
    return 0 unless ($user);

    # Counting
    my $count = 0;

    foreach my $ref ( keys %$user ) {
        my $json = from_json( $user->{$ref}, { allow_nonref => 1 } );

        # Browse notification in file
        foreach my $notif (@$json) {

            # Get notification's data
            if ( $notif->{reference} eq $myref ) {
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
