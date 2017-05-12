package Desktop::Notify::Notification;

use strict;
use warnings;

use base qw/Class::Accessor/;

Desktop::Notify::Notification->mk_accessors(qw/summary body timeout/);

=head1 NAME

Desktop::Notify::Notification - a notification object for the desktop
notifications framework

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    # $notify is an existing Desktop::Notify object
    my $note = $notify->create(summary => 'Rebuilding FooBar',
                               body => 'Progress: 10%');
    $note->show;
    
    ...
    
    # Update the notification later
    $note->body('Progress: 20%');
    $note->show;
    
    ...
    # Take it off the screen
    $note->close;


=head1 DESCRIPTION

Desktop notification objects are represented as objects of this class.  They
are created by a L<Desktop::Notify> object.  Displaying, closing, and modifying
the notification is done by using methods in this class.

=head1 METHODS

=head2 new $notify, %params

This is called internally by L<Desktop::Notify> to create a new notification
object.

=cut

sub new {
    my ($class, $server, %params) = @_;

    my $self = \%params;
    $self->{server} = $server;
    $self->{id} = undef;
    $self->{actions} ||= {};
    $self->{hints}   ||= {};
    bless $self, $class;
}

=head2 show

Display the notification on the screen. If this notification had previously
been shown and not closed yet, it will replace the existing notification.

Show can be called multiple times on the same notification, probably with
attribute changes between calls, and later show calls will cause the server to seamlessly replace the existing notification.

=cut

sub show {
    my $self = shift;

    $self->{id} = $self->{server}->{notify}
        ->Notify($self->{server}->{app_name},
                 $self->{id} || 0,
                 $self->{server}->{app_icon},
                 $self->{summary},
                 $self->{body},
                 [%{$self->{actions}}],
                 $self->{hints},
                 $self->{timeout} || 0,
                );
    $self->{server}->_register_notification($self);
    return $self;
}

=head2 close

Close the notification if it is already being displayed.

=cut

sub close {
    my $self = shift;

    if (defined $self->{id})
    {
        $self->{server}->{notify}->CloseNotification($self->{id});
        delete $self->{id};
    } else
    {
        warn "Trying to close notification that has not been shown.";
    }
    return $self;
}

=head1 ATTRIBUTES

The following parameters can be set when creating the object or later modified
using accessors (descriptions are from the specification at
L<http://www.galago-project.org/specs/notification/0.9/x408.html>)

=over

=item summary

The summary text briefly describing the notification.

=item body

The optional detailed body text. Can be empty.

=item actions

Actions are sent over as a list of pairs. Each even element in the list
(starting at index 0) represents the identifier for the action. Each odd
element in the list is the localized string that will be displayed to the user.

A user-specified function to be called whenever an action is invoked can be
specified with L<Desktop::Notify>'s L<action_callback> method.

=item hints

Optional hints that can be passed to the server from the client program.

=back

=over

=item timeout

The timeout time in milliseconds since the display of the notification at which
the notification should automatically close.

If -1, the notification's expiration time is dependent on the notification
server's settings, and may vary for the type of notification. If 0, never
expire.

=back

The following extra parameters are included in the specification but not
supported by L<Desktop::Notify> at this time

=over

=item app_icon

The optional program icon of the calling application.

=back

=cut

1;  # End of Desktop::Notify::Notification
