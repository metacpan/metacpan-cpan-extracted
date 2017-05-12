# $Id: /mirror/perl/Event-Notify/trunk/lib/Event/Notify.pm 31297 2007-11-29T11:30:40.898880Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Event::Notify;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.00005';
use Carp ();

sub new
{
    my $class = shift;
    return bless { observers => {} }, $class;
}

sub register
{
    my ($self, $observer) = @_;
    $observer->register($self) if $observer->can('register');
}

sub register_event
{
    my($self, $event, $observer, $opts) = @_;

    $opts ||= {};

    if (! $event) {
        Carp::croak( "No event was specified" );
    }

    my $ref = ref($observer || '');
    if (! $ref) {
        Carp::croak( "Non-ref observer passed. Expected an object or a CODE ref");
    }

    my $slot;
    if ($ref eq 'CODE') {
        # You're not passing me a method name, are you? if so,
        # I won't croak, but I *will* complain
        if ($opts->{method}) {
            carp( "Useless use of method name for a CODE observer in Event::Notify->register_event()" );
        }
        $slot = [ $observer, undef ]
    } else {
        my $method = $opts->{method} || 'notify';

        if (! $observer->can($method)) {
            Carp::croak("$observer does not implement a $method() method");
        }
        $slot = [ $observer, $method ]
    }

    $self->{observers}{$event} ||= [];
    push @{ $self->{observers}{$event} }, $slot;
}

sub unregister_event
{
    my($self, $event, $observer) = @_;

    my $observers = $self->{observers}{$event};
    return () unless $observers;

    for my $i (0 .. $#{$observers}) {
        next unless $observers->[$i]->[0] == $observer;
        return splice(@$observers, $i, 1);
    }
    return ();
}

sub notify
{
    my ($self, $event, @args) = @_;

    my $observers = $self->{observers}{$event} || [];
    foreach my $data (@$observers) {
        my($o, $method) = @$data;
        ref $o eq 'CODE' ?
            $o->($event, @args) :
            $o->$method($event, @args) 
        ;
    }
}

sub clear_observers
{
    my $self = shift;
    $self->{observers} = {};
}

1;

__END__

=head1 NAME

Event::Notify - Simple Observer/Notifier

=head1 SYNOPSIS

  use Event::Notify;

  my $notify = Event::Notify->new;
  $notify->register( $observer );
  $notify->register_event( $event, $observer );
  $notify->notify( $event, @args );

=head1 DESCRIPTION

Event::Notify implements a simple Observer pattern. It's not really intended
to be subclassed, or a fancy system. It just registers observers, and
broadcasts events, that's it. The simplicity is that it can be embedded
in a class that doesn't necessarily want to be a subclass of a notifier.

Simply create a slot for it, and delegate methods to it:

  package MyClass;
  use Event::Notify;

  sub new {
    my $class = shift;
    my $self = shift;
    $self->{notify} = Event::Notify->new;
  }

  # This interface doesn't have to be this way. Here, we're just making
  # a simple delegation mechanism 
  sub register_event { shift->{notify}->register_event(@_) }
  sub unregister_event { shift->{notify}->unregister_event(@_) }
  sub notify { shift->{notify}->notify(@_) }

Voila, you got yourself a observable module without inheritance!

=head1 METHODS

=head2 new

Creates a new instance

=head2 register($observer)

Registers a new observer. The observer must implement a notify() method.

When called, the observer's register() method is invoked, so each observer
can register itself to whatever event the observer wants to subscribe to.

So your observer's register() method could do something like this:

  package MyObserver;
  sub register {
    my ($observer, $notify) = @_;
    $notify->register_event( 'event_name1', $observer );
    $notify->register_event( 'event_name2', $observer );
    $notify->register_event( 'event_name3', $observer );
    $notify->register_event( 'event_name4', $observer );
  }

Think of it as sort of an automatic initializer.

=head2 register_event($event,$observer[,\%opts])

Registers an observer $observer as observing a particular event $event
The $observer can be either an object or a subroutine reference.

In case C<$observer> is an object, the object must implement a method
named C<notify()>, or the method name specified the C<method> parameter
in the optional third parameter C<%opts>

Calling

  $notify->register_event($event, $observer);

is the same as saying

  $notify->register_event($event, $observer, { method => 'notify' });

If the object does not implement the named method (or C<notify()>, if you
don't specify one), then it will croak

=head2 unregister_event($event,$observer)

Unregisters an observer.

=head2 notify($event,@args)

Notifies all of the observers about a particular event. @args is passed
directly to the observers' notify() event

=head2 clear_observers()

Clears all observers from this object.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut