# NAME

Event::Notify - Simple Observer/Notifier

# SYNOPSIS

    use Event::Notify;

    my $notify = Event::Notify->new;
    $notify->register( $observer );
    $notify->register_event( $event, $observer );
    $notify->notify( $event, @args );

# DESCRIPTION

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

# METHODS

## new

Creates a new instance

## register($observer)

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

## register\_event($event,$observer\[,\\%opts\])

Registers an observer $observer as observing a particular event $event
The $observer can be either an object or a subroutine reference.

In case `$observer` is an object, the object must implement a method
named `notify()`, or the method name specified the `method` parameter
in the optional third parameter `%opts`

Calling

    $notify->register_event($event, $observer);

is the same as saying

    $notify->register_event($event, $observer, { method => 'notify' });

If the object does not implement the named method (or `notify()`, if you
don't specify one), then it will croak

## unregister\_event($event,$observer)

Unregisters an observer.

## notify($event,@args)

Notifies all of the observers about a particular event. @args is passed
directly to the observers' notify() event

## clear\_observers()

Clears all observers from this object.

# AUTHOR

Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
