# Copyright (c) 2011-17, Mitchell Cooper
#
# Evented::Object: a simple yet featureful base class event framework.
#
# Evented::Object is based on the libuic UIC::Evented::Object:
# ... which is based on Evented::Object from foxy-java IRC Bot,
# ... which is based on Evented::Object from Arinity IRC Services,
# ... which is based on Evented::Object from ntirc IRC Client,
# ... which is based on IRC::Evented::Object from libirc IRC Library.
#
# Evented::Object and its very detailed documentation can be found
# in their latest versions at https://github.com/cooper/evented-object.
#
package Evented::Object;

use warnings;
use strict;
use utf8;
use 5.010;

# these must be set before loading EventFire.
our ($events, $props, %monitors);
BEGIN {
    $events = 'eventedObject.events';
    $props  = 'eventedObject.props';
}

use Scalar::Util qw(weaken blessed);
use Evented::Object::EventFire;
use Evented::Object::Collection;

our $VERSION = '5.67';

# creates a new evented object.
sub new {
    my ($class, %opts) = @_;
    bless \%opts, $class;
}

#############################
### REGISTERING CALLBACKS ###
#############################

# ->register_callback()
#
# aliases: ->register_event(), ->on()
# attaches an event callback.
#
# $eo->register_callback(myEvent => sub {
#     ...
# }, 'some.callback.name', priority => 200);
#
sub register_callback {
    my ($eo, $event_name, $code, @opts_) = @_;

    # if there is an odd number of options, the first is the callback name.
    # this also implies with_eo.
    my %opts;
    if (@opts_ % 2) {
        %opts = (
            name    => shift @opts_,
            with_eo => 1,
            @opts_
        );
    }
    else {
        %opts = @opts_;
    }

    # no name was provided, so we shall construct one using pure hackery.
    # this is one of the most criminal things I've ever done.
    my @caller = caller;
    if (!defined $opts{name}) {
        state $c    = -1; $c++;
        $opts{name} = "$event_name:$caller[0]($caller[2],$c)";
    }

    # determine the event store.
    my $event_store = _event_store($eo);

    # before/after a callback.
    my $priority = delete $opts{priority} || 0;
    if (defined $opts{before} or defined $opts{after}) {
        $priority = 'nan';
        # nan priority indicates it should be determined at a later time.
    }

    # add the callback.
    my $callbacks = $event_store->{$event_name}{$priority} ||= [];
    push @$callbacks, my $cb = {
        %opts,
        code   => $code,
        caller => \@caller
    };

    # tell class monitor.
    _monitor_fire(
        $opts{_caller} // $caller[0],
        register_callback => $eo, $event_name, $cb
    );

    return $cb;
}

# ->register_callbacks()
#
# attaches several event callbacks at once.
#
sub register_callbacks {
    my $eo = shift;
    return map { $eo->register_callback(%$_, _caller => caller) } @_;
}

##########################
### DELETING CALLBACKS ###
##########################

# ->delete_callback(event_name => 'callback.name')
# ->delete_event('event_name')
#
# deletes an event callback or all callbacks of an event.
# returns a true value if any events were deleted, false otherwise.
# more specifically, it returns the number of callbacks deleted.
#
sub delete_callback {
    my ($eo, $event_name, $name, $caller) = @_;
    my @caller      = $caller && ref $caller eq 'ARRAY' ? @$caller : caller;
    my $amount      = 0;
    my $event_store = _event_store($eo);

    # event does not have any callbacks.
    return 0 unless $event_store->{$event_name};

     # if no callback is specified, delete all events of this type.
    if (!$name) {
        $amount = scalar keys %{ $event_store->{$event_name} };
        delete $event_store->{$event_name};
        _monitor_fire($caller[0], delete_event => $eo, $event_name);
        return $amount;
    }

    # iterate through callbacks and delete matches.
    PRIORITY: foreach my $priority (keys %{ $event_store->{$event_name} }) {
        my $callbacks = $event_store->{$event_name}{$priority};
        my @goodbacks;

        CALLBACK: foreach my $cb (@$callbacks) {

            # don't want this one.
            if (ref $cb ne 'HASH' || $cb->{name} eq $name) {
                $amount++;
                next CALLBACK;
            }

            push @goodbacks, $cb;
        }

        # no callbacks left in this priority.
        if (!scalar @goodbacks) {
            delete $event_store->{$event_name}{$priority};
            next PRIORITY;
        }

        # keep these callbacks.
        @$callbacks = @goodbacks;

    }

    return $amount;
}

# ->delete_all_events()
#
# deletes all the callbacks of EVERY event.
# useful when you're done with an object to ensure any possible self-referencing
# callbacks are properly destroyed for garbage collection to work.
#
sub delete_all_events {
    my ($eo, $amount) = (shift, 0);
    my $event_store   = _event_store($eo) or return;
    ref $event_store eq 'HASH'            or return;

    # delete one-by-one.
    # we can't simply set an empty list because monitor events must be fired.
    foreach my $event_name (keys %$event_store) {
        $eo->delete_event($event_name);
        $amount++;
    }

    # just clear it to be safe.
    %$event_store = ();
    delete $eo->{$events};
    delete $eo->{$props};

    return $amount;
}

########################
### PREPARING EVENTS ###
########################

# ->prepare()
#
# automatically guesses whether to use
# ->prepare_event() or ->prepare_together().
#
sub prepare {
    my ($eo_maybe, $eo) = $_[0];
    $eo = shift if blessed $eo_maybe && $eo_maybe->isa(__PACKAGE__);
    if (ref $_[0] && ref $_[0] eq 'ARRAY') {
        return $eo->prepare_together(@_);
    }
    return $eo->prepare_event(@_);
}

# ->prepare_event()
#
# prepares a single event fire by creating a callback collection.
# returns the collection.
#
sub prepare_event {
    my ($eo, $event_name, @args) = @_;
    return $eo->prepare_together([ $event_name, @args ]);
}

# ->prepare_together()
#
# prepares several events fire by creating a callback collection.
# returns the collection.
#
sub prepare_together {
    my $obj;
    my $collection = Evented::Object::Collection->new;
    foreach my $set (@_) {
        my $eo;

        # called with evented object.
        if (blessed $set) {
            $set->isa(__PACKAGE__) or return;
            $obj = $set;
            next;
        }

        # okay, it's an array ref of
        # [ $eo (optional), $event_name => @args ]
        ref $set eq 'ARRAY' or next;
        my ($eo_maybe, $event_name, @args);

        # was an object specified?
        $eo_maybe = shift @$set;
        if (blessed $eo_maybe && $eo_maybe->isa(__PACKAGE__)) {
            $eo = $eo_maybe;
            ($event_name, @args) = @$set;
        }

        # no object; fall back to $obj.
        else {
            $eo = $obj or return;
            ($event_name, @args) = ($eo_maybe, @$set);
        }

        # add to the collection.
        my ($callbacks, $names) =
            _get_callbacks($eo, $event_name, @args);
        $collection->push_callbacks($callbacks, $names);

    }

    return $collection;
}

#####################
### FIRING EVENTS ###
#####################

# ->fire_event()
#
# prepares an event and then fires it.
#
sub fire_event {
    shift->prepare_event(shift, @_)->fire(caller => [caller 1]);
}

# ->fire_events_together()
# fire_events_together()
#
# prepares several events and then fires them together.
#
sub fire_events_together {
    prepare_together(@_)->fire(caller => [caller 1]);
}

# ->fire_once()
#
# prepares an event, fires it, and deletes all callbacks afterward.
#
sub fire_once {
    my ($eo, $event_name, @args) = @_;

    # fire with this caller.
    my $fire = $eo->prepare_event($event_name, @args)->fire(
        caller => [caller 1]
    );

    # delete the event.
    $eo->delete_event($event_name);
    return $fire;

}

########################
### LISTENER OBJECTS ###
########################

# ->add_listener()
#
# adds an object as a listener of another object's events.
# see "listeners" in the documentation.
#
sub add_listener {
    my ($eo, $obj, $prefix) = @_;

    # find listeners list.
    my $listeners = $eo->{$props}{listeners} ||= [];

    # store this listener.
    push @$listeners, [$prefix, $obj];

    # weaken the reference to the listener.
    weaken($listeners->[$#$listeners][1]);

    return 1;
}

# ->delete_listener()
#
# removes an object which was listening to another object's events.
# see "listeners" in the documentation.
#
sub delete_listener {
    my ($eo, $obj) = @_;
    return 1 unless my $listeners = $eo->{$props}{listeners};
    @$listeners = grep {
        ref $_->[1] eq 'ARRAY' and $_->[1] != $obj
    } @$listeners;
    return 1;
}

######################
### CLASS MONITORS ###
######################

# for objective use $eo->monitor_events($pkg)
sub monitor_events  {    add_class_monitor(reverse @_) }
sub stop_monitoring { delete_class_monitor(reverse @_) }

# add_class_monitor()
#
# set the monitor object of a class.
#
# TODO: honestly class monitors need to track individual callbacks so that the
# monitor is notified of all deletes of callbacks added by the class being
# monitored even if the delete action was not committed by that package.
#
sub add_class_monitor {
    my ($pkg, $obj) = @_;

    # ensure it's an evented object.
    return unless $obj->isa(__PACKAGE__);

    # it's already in the list.
    my $m = $monitors{$pkg} ||= [];
    return if grep { $_ == $obj } @$m = grep { defined } @$m;

    # hold a weak reference to the monitor.
    push @$m, $obj;
    weaken($monitors{$pkg}[$#$m]);

    return 1;
}

# delete_class_monitor()
#
# remove a class monitor object from a class.
#
sub delete_class_monitor {
    my ($pkg, $obj) = @_;
    my $m = $monitors{$pkg} or return;
    @$m   = grep { defined && $_ != $obj } @$m;
}

#######################
### CLASS FUNCTIONS ###
#######################

# safe_fire($obj, event => ...)
#
# checks that an object is blessed and that it is an evented object.
# if so, prepares and fires an event with optional arguments.
#
sub safe_fire {
    my $obj = shift;
    return if !blessed $obj || !$obj->isa(__PACKAGE__);
    return $obj->fire_event(@_);
}

#########################
### INTERNAL ROUTINES ###
#########################

# access package storage.
sub _package_store {
    my $package = shift;
    no strict 'refs';
    my $ref = "${package}::__EO__";
    if (!keys %$ref) {
        %$ref = ();
    }
    return *$ref{HASH};
}

# fetch the event store of object or package.
sub _event_store {
    my $eo    = shift;
    return $eo->{$events}   ||= {} if blessed $eo;
    my $store = _package_store($eo);
    return $store->{events} ||= {} if not blessed $eo;
}

# fetch the property store of object or package.
sub _prop_store {
    my $eo    = shift;
    return $eo->{$props}   ||= {} if blessed $eo;
    my $store = _package_store($eo);
    return $store->{props} ||= {} if not blessed $eo;
}

# fetch a callback from its name.
sub _get_callback_named {
    my ($eo, $event_name, $callback_name) = @_;
    foreach my $callback (@{ _get_callbacks($eo, $event_name) }) {
        return $callback if $callback->[2]{name} eq $callback_name
    }
    return;
}

# fetches callbacks of an event.
# internal use only.
sub _get_callbacks {
    my ($eo, $event_name, @args) = @_;
    my (%callbacks, %callback_names);

    # start out with two stores: the object and the package.
    my @stores = (
        [ $event_name => $eo->{$events}             ],
        [ $event_name => _event_store(blessed $eo)  ]
    );


    # if there are any listening objects, add those stores.
    if (my $listeners = $eo->{$props}{listeners}) {
        my @delete;

        LISTENER: foreach my $i (0 .. $#$listeners) {
            my $l = $listeners->[$i] or next;
            my ($prefix, $lis) = @$l;
            my $listener_event_name = $prefix.q(.).$event_name;

            # object has been deallocated by garbage disposal,
            # so we can delete this listener.
            if (!$lis) {
                push @delete, $i;
                next LISTENER;
            }


            push @stores, [ $listener_event_name => $lis->{$events} ];

        }

        # delete listeners if necessary.
        splice @$listeners, $_, 1 foreach @delete;

    }

    # add callbacks from each store.
    foreach my $st (@stores) {
        my ($event_name, $event_store) = @$st;
        my $store = $event_store->{$event_name} or next;
        foreach my $priority (keys %$store) {

            # create a group reference.
            my $group_id = "$eo/$event_name";
            my $group    = [ $eo, $event_name, \@args, $group_id ];
            weaken($group->[0]);

            # add each callback set. inject callback name.
            foreach my $cb_ref (@{ $store->{$priority} }) {
                my %cb = %$cb_ref; # make a copy
                $cb{id} = "$group_id/$cb{name}";
                $callbacks{ $cb{id} } = [ $priority, $group, \%cb ];
                $callback_names{$group_id}{ $cb{name} } = $cb{id};
            }

        }
    }

    return wantarray ? (\%callbacks, \%callback_names) : \%callbacks;
}

# fire a class monitor event.
sub _monitor_fire {
    my ($pkg, $event_name, @args) = @_;
    my $m = $monitors{$pkg} or return;
    safe_fire($_, "monitor:$event_name" => @args) foreach @$m;
}

sub DESTROY { shift->delete_all_events }

###############
### ALIASES ###
###############

sub register_event;
sub register_events;
sub delete_event;

sub on;
sub del;
sub fire;

BEGIN {
    *register_event     = *register_callback;
    *register_events    = *register_callbacks;
    *delete_event       = *delete_callback;
    *on                 = *register_callback;
    *del                = *delete_callback;
    *fire               = *fire_event;
}

1;

=head1 NAME

B<Evented::Object> - base class which allows you to attach callbacks to
objects and then fire events on them.

=head1 SYNOPSIS

 package Person;
 
 use warnings;
 use strict;
 use 5.010;
 use parent 'Evented::Object';
 
 use Evented::Object;
 
 # Creates a new person object. This is nothing special.
 # Evented::Object does not require any specific constructor to be called.
 sub new {
     my ($class, %opts) = @_;
     bless \%opts, $class;
 }
 
 # Fires birthday event and increments age.
 sub have_birthday {
     my $person = shift;
     $person->fire(birthday => ++$person->{age});
 }

In some other package...

 package main;
 
 # Create a person named Jake at age 19.
 my $jake = Person->new(name => 'Jake', age => 19);
 
 # Add an event callback that assumes Jake is under 21.
 $jake->on(birthday => sub {
     my ($fire, $new_age) = @_;
     say 'not quite 21 yet...';
 }, name => '21-soon');
 
 # Add an event callback that checks if Jake is 21
 # and cancels the above callback if so.
 $jake->on(birthday => sub {
  my ($fire, $new_age) =  @_;
     if ($new_age == 21) {
          say 'time to get drunk!';
          $fire->cancel('21-soon');
     }
 }, name => 'finally-21', priority => 1);
 
 # Jake has two birthdays.
 
 # Jake's 20th birthday.
 $jake->have_birthday;
 
 # Jake's 21st birthday.
 $jake->have_birthday;
 
 # Because 21-soon has a lower priority than finally-21,
 # finally-21 will cancel 21-soon if Jake is 21.
 
 # The result:
 #
 #   not quite 21 yet...
 #   time to get drunk!

=head1 DESCRIPTION

B<I doubt your objects have ever been this evented in your entire life.>

Evented::Object supplies an (obviously objective) interface to store and manage
callbacks for events, fire events upon objects, and more.

Evented::Object allows you to attach event callbacks to an object
(i.e., a blessed hash reference) and then fire events on that object. Event
fires are much like method calls, except that there can be many responders.

Whereas many event systems involve globally unique event names, Evented::Object
allows you to attach events on specific objects. The event callbacks,
priority options, and other data are stored within the object itself.

=head1 MANAGING CALLBACKS

The Evented::Object package provides several convenient methods for managing an
event-driven object.

=head2 Evented::Object->new()

Creates a new Evented::Object.

Typically, this method is overriden by a child class of Evented::Object.

 my $eo = Evented::Object->new();

=head2 $eo->register_callback($event_name => \&callback, %options)

Attaches an event callback the object.

When the specified event is fired, each
of the callbacks registered using this method will be called by descending
priority order (numerically higher priority numbers are called first.)

 $eo->register_callback(myEvent => sub {
     ...
 }, name => 'some.callback', priority => 200);

B<Parameters>

=over

=item *

B<$event_name> - name of the event.

=item *

B<\&callback> - CODE reference to be called when the event is fired.

=item *

B<%options> - I<optional>, a hash (NOT a hash reference) of any of the below
options.

=back

B<%options> - event handler options

All of these options are I<optional>, but the use of a callback name is
B<highly recommended>.

=over

=item *

B<name> - name of the callback being registered. must be unique to this
particular event.

=item *

B<priority> - numerical priority of the callback.

=item *

B<before> - name of a callback or an array reference of callback names to
precede.

=item *

B<after> - name of a callback or an array reference of callback names to
succeed.

=item *

B<data> - data that will be stored as C<< $fire->callback_data >> as the
callback is fired. If C<data> is a hash reference, its values can be fetched
conveniently with C<< $fire->callback_data('key') >>.

=item *

B<with_eo> - if true, the evented object will prepended to the argument list
(which is not the default behavior). note that this is enabled automatically
when using the odd-argument version.

=item *

B<no_fire_obj> - if true, the L<fire object|Evented::Object::EventFire> will not
be prepended to the argument list (which is the default behavior).

=back

Note: the order of objects will always be C<$eo>, C<$fire>, C<@args>, regardless
of omissions. By default, the argument list is C<$fire>, C<@args>.

You may have any number of C<before> and any
number of C<after> options for any given callback. For instance, one callback
may specify to be before 'b' and 'c' but after 'a'. Evented::Object will resolve
these priorities to its best ability.

In the case that the priorities can not be resolved (for instance, if a callback
asks to be before 'a' and after 'b' while 'b' has already asked to be before
'a'), the behavior of Evented::Object is not guaranteed to be consistent. In
other words, please do your best to not request impossible priorities.

In any case, C<before> and C<after> options are completely ignored when a
C<priority> is explicitly specified.

=head2 $eo->register_callback($event_name => \&callback, $cb_name, %options)

If the list of options is odd, it is assumed that the first element is the
callback name. In this case, the C<with_eo> option is also automatically
enabled.

 $eo->register_callback(myEvent => sub {
     ...
 }, 'some.callback, priority => 200);

See the above method specification for parameters and supported options.

=head2 $eo->register_callbacks(@events)

Registers several event callbacks at once.

The arguments should be a list of hash
references. These references take the same options as
C<< ->register_callback() >>. Returns a list of return values in the order that
the events were specified.

 $eo->register_callbacks(
     { myEvent => \&my_event_1, name => 'cb.1', priority => 200 },
     { myEvent => \&my_event_2, name => 'cb.2', priority => 100 }
 );

B<Parameters>

=over

=item *

B<@events> - array of hash references to pass to C<< ->register_callback() >>.

=back

=head2 $eo->delete_event($event_name)

Deletes all callbacks registered for the supplied event.

Returns number of callbacks deleted, false if none.

 $eo->delete_event('myEvent');

B<Parameters>

=over

=item *

B<$event_name> - name of the event.

=back

=head2 $eo->delete_callback($event_name, $callback_name)

Deletes an event callback from the object with the given callback name.

Returns true if a callback was deleted.

 $eo->delete_callback(myEvent => 'my.callback');

B<Parameters>

=over

=item *

B<$event_name> - name of the event.

=item *

B<$callback_name> - name of the callback being removed.

=back

=head2 $eo->delete_all_events()

Deletes all events and all callbacks from the object.

If you know that an
evented object will no longer be used in your program, by calling this method
you can be sure that no cyclical references from within callbacks will cause the
object to be leaked.

=head1 FIRING EVENTS

=head2 $eo->fire_event($event_name => @arguments)

Fires the specified event, calling each callback that was registered with
C<< ->register_callback() >> in descending order of their priorities.

Returns the L<fire object|Evented::Object::EventFire>.

 $eo->fire_event('some_event');

 $eo->fire_event(some_event => $some_argument, $some_other_argument);

B<Parameters>

=over

=item *

B<$event_name> - name of the event being fired.

=item *

B<@arguments> - I<optional>, list of arguments to pass to event callbacks.

=back

=head2 $eo->fire_once($event_name => @arguments)

Fires the specified event, calling each callback that was registered with
C<< ->register_callback() >> in descending order of their priorities.

Then, all callbacks for the event are deleted. This method is useful for
situations where an event will never be fired more than once.

Returns the L<fire object|Evented::Object::EventFire>.

 $eo->fire_once('some_event');
 $eo->fire_event(some_event => $some_argument, $some_other_argument);
 # the second does nothing because the first deleted the callbacks

B<Parameters>

=over

=item *

B<$event_name> - name of the event being fired.

=item *

B<@arguments> - I<optional>, list of arguments to pass to event callbacks.

=back

=head2 $eo->fire_events_together(@events)

The C<fire_events_together()> function can be used as a method on evented
objects. See the documentation for the function in L</"PROCEDURAL FUNCTIONS">.

=head2 $eo->prepare_event(event_name => @arguments)

Prepares a single event for firing.

Returns an L<Evented::Object::Collection> representing the pending callbacks.

 # an example using the fire option return_check.
 $eo->prepare_event(some_event => @arguments)->fire('return_check');

=head2 $eo->prepare_together(@events)

The preparatory method equivalent to C<< ->fire_events_together >>.

Returns an L<Evented::Object::Collection> representing the pending callbacks.

=head2 $eo->prepare(...)

A smart method that uses the best guess between C<< ->prepare_event >> and
C<< ->prepare_together >>.

 # uses ->prepare_event()
 $eo->prepare(some_event => @arguments);

 # uses ->prepare_together()
 $eo->prepare(
    [ some_event => @arguments ],
    [ some_other => @other_arg ]
 );
 
=head1 LISTENERS

An evented object can I<listen> for event notifications from another evented
object using the method L</"$eo-E<gt>add_listener($other_eo, $prefix)">.

Consider a scenario where you have a class whose objects represent a farm. You
have another class which represents a cow. You would like to use the same
callback for all of the moos that occur on the farm, regardless of which cow
initiated it.

Rather than attaching an event callback to every cow, you can instead make the
farm a listener of the cow. Then, you can attach a single callback to your farm.
If your cow's event for mooing is C<moo>, your farm's event for any mooing is
C<cow.moo>.

When an event is fired on an object, the same fire object is used for callbacks
belonging to both the evented object and its listening objects. Therefore,
callback names should be unique not only to the listener object but to the
object being listened on as well.

You should also note the values of the
L<fire object|Evented::Object::EventFire>:

=over

=item *

B<< $fire->event_name >> - name of the event from the perspective of the
listener; i.e. C<cow.moo> (NOT C<moo>)

=item *

B<< $fire->object >> - object being listened to; i.e. C<$cow> (NOT C<$farm>)

=back

This also means that stopping the event from a listener object will cancel
I<all> remaining callbacks.

=head2 $eo->add_listener($other_eo, $prefix)

Makes the passed evented object a listener of this evented object.

See L</"LISTENERS">.

 $cow->add_listener($farm, 'cow');

B<Parameters>

=over

=item *

B<$other_eo> - evented object that will listen.

=item *

B<$prefix> - string that event names will be prefixed with on the listener.

=back

=head2 $eo->delete_listener($other_eo)

Removes a listener of this evented object.

See L</"LISTENERS">.

 $cow->delete_listener($farm);

B<Parameters>

=over

=item *

B<$other_eo> - evented object that will listen.

=back

=head1 CLASS MONITORS

An evented object can be registered as a "monitor" of a specific class/package.

I<All> event callbacks that are added from that class to I<any> evented object
of I<any> type will trigger an event on the monitor object.

An example scenario of when this might be useful is an evented object for
debugging all events being registered by a certain package. It would log all of
them, making it easier to find a problem.

=head2 $eo->monitor_events($pkg)

Registers an evented object as the class monitor for a specific package.

See L</"CLASS MONITORS">.

 my $some_eo  = Evented::Object->new;
 my $other_eo = Evented::Object->new;

 $some_eo->on('monitor:register_callback', sub {
     my ($event, $eo, $event_name, $cb) = @_;
     # $eo         == $other_eo
     # $event_name == "blah"
     # $cb         == callback hash from ->register_callback()
     say "Registered $$cb{name} to $eo for $event_name";
 });

 $some_eo->monitor_events('Some::Class');

 package Some::Class;
 $other_eo->on(blah => sub{}); # will trigger the callback above

=over

=item *

B<$pkg> - package whose event activity you wish to monitor.

=back

=head2 $eo->stop_monitoring($pkg)

Removes an evented object from its current position as a monitor for a specific
package.

See L</"CLASS MONITORS">.

 $some_eo->stop_monitoring('Some::Class');

=over

=item *

B<$pkg> - package whose event activity you're monitoring.

=back

=head1 PROCEDURAL FUNCTIONS

The Evented::Object package provides some functions for use. These functions
typically are associated with more than one evented object or none at all.

=head2 fire_events_together(@events)

Fires multiple events at the same time.

This allows you to fire multiple similar
events on several evented objects at the same time. It essentially pretends that
the callbacks are all for the same event and all on the same object.

It follows priorities throughout all of the events and all of the objects, so it
is ideal for firing similar or identical events on multiple objects.

The same L<fire object|Evented::Object::EventFire> is used throughout.
This means that callback names must unique among all of these
objects and events. It also means that stopping an event from any callback will
cancel all remaining callbacks, regardless to which event or which object they
belong.

The function takes a list of array references in the form of:
C<< [ $evented_object, event_name => @arguments ] >>

 Evented::Object::fire_events_together(
     [ $server,  user_joined_channel => $user, $channel ],
     [ $channel, user_joined         => $user           ],
     [ $user,    joined_channel      => $channel        ]
 );

C<< ->fire_events_together >> can also be used as a method
on any evented object.

 $eo->fire_events_together(
     [ some_event => @arguments ],
     [ some_other => @other_arg ]
 );

The above example would formerly be achieved as:

 Evented::Object::fire_events_together(
     [ $eo, some_event => @arguments ],
     [ $eo, some_other => @other_arg ]
 );

However, other evented objects may be specified even when this is used as a
method. Basically, anywhere that an object is missing will fall back to the
object on which the method was called.

 $eo->fire_events_together(
     [ $other_eo, some_event => @arguments ],
     [            some_other => @other_arg ] # no object, falls back to $eo
 );
 
Returns the L<fire object|Evented::Object::EventFire>.

B<Parameters>

=over

=item *

B<@events> - array of events in the form of
C<< [$eo, event_name => @arguments] >>.

=back

=head2 safe_fire($eo, $event_name, @args)

Safely fires an event. In other words, if the C<$eo> is not an evented
object or is not blessed at all, the call will be ignored. This eliminates the
need to use C<blessed()> and C<< ->isa() >> on a value for testing whether it is
an evented object.

 Evented::Object::safe_fire($eo, myEvent => 'my argument');

B<Parameters>

=over

=item *

B<$eo> - evented object.

=item *

B<$event_name> - name of the event.

=item *

B<@args> - arguments for the event fire.

=back

=head1 ALIASES

A number of aliases exist for convenience, but please only use them if you're
certain that other subclassing will not interfere.

=head2 $eo->on(...)

Alias for C<< $eo->register_callback() >>.

=head2 $eo->del(...)

If one argument provided, alias for C<< $eo->delete_event >>.

If two arguments provided, alias for C<< $eo->delete_callback >>.

=head2 $eo->fire(...)

Alias for C<< $eo->fire_event() >>.

=head2 $eo->register_event(...)

Alias for C<< $eo->register_callback() >>.

=head2 $eo->register_events(...)

Alias for C<< $eo->register_callbacks() >>.

=head2 $fire->eo

Alias for C<< $fire->object >>.

=head1 AUTHOR

L<Mitchell Cooper|https://github.com/cooper> <cooper@cpan.org>

Copyright E<copy> 2011-2020. Released under New BSD license.

Comments, complaints, and recommendations are accepted. Bugs may be reported on
L<GitHub|https://github.com/cooper/evented-object/issues>.
