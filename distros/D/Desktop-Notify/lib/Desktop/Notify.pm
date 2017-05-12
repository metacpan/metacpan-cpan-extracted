package Desktop::Notify;

use warnings;
use strict;

use Net::DBus;
use File::Basename;
use Data::Dumper;

use Desktop::Notify::Notification;

=head1 NAME

Desktop::Notify - Communicate with the Desktop Notifications framework

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Desktop::Notify;
    
    # Open a connection to the notification daemon
    my $notify = Desktop::Notify->new();
    
    # Create a notification to display
    my $notification = $notify->create(summary => 'Desktop::Notify',
                                       body => 'Hello, world!',
                                       timeout => 5000);
    
    # Display the notification
    $notification->show();
    
    # Close the notification later
    $notification->close();

=head1 DESCRIPTION

This module provides a Perl interface to the Desktop Notifications framework.

The framework allows applications to display pop-up notifications on an X
desktop.  This is implemented with two components: a daemon that displays the
notifications, and a client library used by applications to send notifications
to the daemon.  These components communicate through the DBus message bus
protocol.

More information is available from
L<http://trac.galago-project.org/wiki/DesktopNotifications>

This module serves the same purpose as C<libnotify>, in an object-oriented Perl
interface.  It is not, however, an interface to C<libnotify> itself, but a
separate implementation of the specification using L<Net::DBus>.

=head1 METHODS

=head2 new %opts

Connect to the notification daemon. %opts can include the following options:

=over

=item app_name

The application name to use for notifications. Default is C<basename($0)>

=item app_icon

Path to an image to use for notification icons.

=item bus

The Net::DBus mesage bus to use. Default is to call Net::DBus->session, which
is usually where notification-daemon can be reached.

=item service

The DBus service name of the daemon. Default is
I<org.freedesktop.Notifications>.

=item objpath

The path to the notifications DBus object. Default is
I</org/freedesktop/Notifications>.

=item objiface

The DBus interface to access the notifications object as. Default is
I<org.freedesktop.Notifications>.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = {};

    $self->{bus} = $opts{bus} || Net::DBus->session;
    $self->{service} = $self->{bus}
        ->get_service($opts{service} || 'org.freedesktop.Notifications');
    $self->{notify} = $self->{service}
        ->get_object($opts{objpath} || '/org/freedesktop/Notifications',
                     $opts{objiface} || 'org.freedesktop.Notifications');
    $self->{app_name} = $opts{app_name} || basename($0);
    $self->{app_icon} = $opts{app_icon} || '';
    $self->{notify}->connect_to_signal('NotificationClosed',
                                       sub {$self->_close_cb(@_)});
    $self->{notify}->connect_to_signal('ActionInvoked',
                                       sub {$self->_action_cb(@_)});

    bless $self, $class;
}

=head2 create %params

Creates a new notification object that can be displayed later. This will return
a L<Desktop::Notify::Notification> object; see that module for information
about using it.

=cut

sub create {
    my ($self, %params) = @_;

    return new Desktop::Notify::Notification($self, %params);
}

sub _register_notification {
    my ($self, $n) = @_;
    $self->{notes}->{$n->{id}} = $n;
}

sub _close_cb {
    my ($self, $nid) = @_;
    print __PACKAGE__, ": notification closed\n";
    if ($self->{close_callback})
    {
        print "invoking callback\n";
        $self->{close_callback}->($self->{notes}->{$nid});
    }
    delete $self->{notes}->{$nid};
}

sub _action_cb {
    my ($self, $nid, $action_key) = @_;
    print __PACKAGE__, ": action invoked\n";
    if ($self->{action_callback})
    {
        print "invoking callback\n";
        $self->{action_callback}->($self->{notes}->{$nid}, $action_key);
    }
    # delete $self->{notes}->{$nid};
}

=head2 close_callback $coderef

Sets a user-specified function to be called whenever a notification is closed.
It will be called with one argument, which is the Notification object that was
just closed.

=cut

sub close_callback {
    my ($self, $cb) = @_;

    print "close callback is $cb\n";
    $self->{close_callback} = $cb;
}

=head2 action_callback $coderef

Sets a user-specified function to be called whenever an action is invoked.
It will be called with two arguments, which are the Notification object on which
an action was invoked, and the key of the action invoked.

=cut

sub action_callback {
    my ($self, $cb) = @_;

    print "action callback is $cb\n";
    $self->{action_callback} = $cb;
}

=head1 AUTHOR

Stephen Cavilia, C<< <sac at atomicradi.us> >>

=head1 SEE ALSO

L<Net::DBus>

L<http://www.galago-project.org/specs/notification/index.php>

L<http://www.galago-project.org/downloads.php>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-desktop-notify at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Desktop-Notify>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Desktop::Notify

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Desktop-Notify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Desktop-Notify>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Desktop-Notify>

=item * Search CPAN

L<http://search.cpan.org/dist/Desktop-Notify>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Stephen Cavilia, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Desktop::Notify
