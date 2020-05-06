# Copyright (c) 2011-17, Mitchell Cooper
#
# Evented::Object: a simple yet featureful base class event framework.
# https://github.com/cooper/evented-object
#
package Evented::Object::EventFire; # leave this package name the same FOREVER.

use warnings;
use strict;
use utf8;
use 5.010;

##########################
### EVENT FIRE OBJECTS ###
##########################

our $VERSION = '5.68';
our $events  = $Evented::Object::events;
our $props   = $Evented::Object::props;

# create a new fire object.
sub new {
    my ($class, %opts) = @_;
    $opts{callback_i} ||= 0;
    return bless { $props => \%opts }, $class;
}

# cancel all future callbacks once.
# if stopped already, returns the reason.
sub stop {
    my ($fire, $reason) = @_;
    $fire->{$props}{stop} ||= $reason || 'unspecified';
}

# returns a true value if the given callback has been called.
# with no argument, returns number of callbacks called so far.
sub called {
    my ($fire, $cb_name) = @_;

    # return the number of callbacks called.
    # this includes the current callback.
    if (!length $cb_name) {
        my $called = scalar keys %{ $fire->{$props}{called} };
        $called++ unless $fire->{$props}{complete};
        return $called;
    }

    # return whether the specified callback was called.
    my $cb_id = $fire->_cb_id($cb_name) or return;
    return $fire->{$props}{called}{$cb_id};
}

# returns a true value if the given callback will be called soon.
# with no argument, returns number of callbacks pending.
sub pending {
    my ($fire, $cb_name) = @_;
    my $pending = $fire->{$props}{collection}{pending};

    # return number of callbacks remaining.
    if (!length $cb_name) {
        return scalar keys %$pending;
    }

    # return whether the specified callback is pending.
    my $cb_id = $fire->_cb_id($cb_name) or return;
    return $pending->{$cb_id};
}

# cancels a future callback once.
sub cancel {
    my ($fire, $cb_name) = @_;

    # if there is no argument given, we will just
    # treat this like a ->stop on the event.
    length $cb_name or return $fire->stop;

    # cancel the callback.
    my $cb_id = $fire->_cb_id($cb_name) or return;
    delete $fire->{$props}{collection}{pending}{$cb_id};

    return 1;
}

# returns the return value of the given callback.
# if it has not yet been called, this will return undef.
# if the return value has a possibility of being undef,
# the only way to be sure is to first test ->callback_called.
sub return_of {
    my ($fire, $cb_name) = @_;
    my $cb_id = $fire->_cb_id($cb_name) or return;
    return $fire->{$props}{return}{$cb_id};
}

# returns the callback that was last called.
sub last {
    shift->{$props}{last_callback};
}

# returns the return value of the last-called callback.
sub last_return {
    shift->{$props}{last_return};
}

# returns the callback that stopped the event.
sub stopper {
    shift->{$props}{stopper};
}

# returns the name of the event being fired.
# this isn't reliable afterward because it can differ within one fire.
sub event_name {
    shift->{$props}{name};
}

# returns the name of the callback being called.
sub callback_name {
    shift->{$props}{callback_name};
}

# returns the caller(1) value of ->fire_event().
sub caller {
    @{ shift->{$props}{caller} };
}

# returns the priority of the callback being called.
sub callback_priority {
    shift->{$props}{callback_priority};
}

# returns the value of the 'data' option when the callback was registered.
# if an argument is provided, it is used as the key to the data hash.
sub callback_data {
    my $data = shift->{$props}{callback_data};
    my $key_maybe = shift;
    if (ref $data eq 'HASH') {
        return $data->{$key_maybe} if defined $key_maybe;
        return $data->{data} // $data;
    }
    return $data;
}

# returns the value of the 'data' option on the ->fire().
# if an argument is provided, it is used as the key to the data hash.
sub data {
    my $data = shift->{$props}{data};
    my $key_maybe = shift;
    if (ref $data eq 'HASH') {
        return $data->{$key_maybe} if defined $key_maybe;
        return $data->{data} // $data;
    }
    return $data;
}

# returns the evented object.
sub object {
    shift->{$props}{object};
}

# returns the exception from 'safe' option, if any.
sub exception {
    shift->{$props}{exception};
}

# find a callback ID from a callback name.
sub _cb_id {
    my ($fire, $cb_name) = @_;
    return $fire->{$props}{callback_ids}{$cb_name};
}

###############
### ALIASES ###
###############

sub object;

BEGIN {
    *eo = *object;
}

1;

=head1 NAME

B<Evented::Object::EventFire> - represents an L<Evented::Object> event fire.

=head1 DESCRIPTION

The fire object provides methods for fetching information related to the current
event fire. It also provides an interface for modifying the behavior of the
remaining callbacks.

Fire objects are specific to the particular event fire, not the event itself.
If you fire the same event twice in a row, the fire object used the first time
will not be the same as the second time. Therefore, all modifications made by
the fire object's methods apply only to the callbacks remaining in this
particular fire. For example, C<< $fire->cancel($callback) >> will only cancel
the supplied callback once.

=head1 METHODS

=head2 $fire->object

Returns the evented object.

 $fire->object->delete_event('myEvent');

=head2 $fire->caller

Returns the value of C<caller(1)> from within the C<< ->fire() >> method.
This allows you to determine from where the event was fired.

 my $name   = $fire->event_name;
 my @caller = $fire->caller;
 say "Package $caller[0] line $caller[2] called event $name";

=head2 $fire->stop($reason)

Cancels all remaining callbacks. This stops the rest of the event firing. After
a callback calls $fire->stop, the name of that callback is stored as
C<< $fire->stopper >>.

If the event has already been stopped, this method returns the reason for which
the fire was stopped or "unspecified" if no reason was given.

 # ignore messages from trolls
 if ($user eq 'noah') {
     # user is a troll.
     # stop further callbacks.
     return $fire->stop;
 }

=over

=item *

B<$reason> - I<optional>, the reason for stopping the event fire.

=back

=head2 $fire->stopper

Returns the callback which called C<< $fire->stop >>.

 if ($fire->stopper) {
     say 'Fire was stopped by '.$fire->stopper;
 }

=head2 $fire->exception

If the event was fired with the C<< safe >> option, it is possible that an
exception occurred in one (or more if C<< fail_continue >> enabled) callbacks.
This method returns the last exception that occurred or C<< undef >> if none
did.

 if (my $e = $fire->exception) {
    say "Exception! $e";
 }

=head2 $fire->called($callback)

If no argument is supplied, returns the number of callbacks called so far,
including the current one. If a callback argument is supplied, returns whether
that particular callback has been called.

 say $fire->called, 'callbacks have been called so far.';

 if ($fire->called('some.callback')) {
     say 'some.callback has been called already.';
 }

B<Parameters>

=over

=item *

B<$callback> - I<optional>, the callback being checked.

=back

=head2 $fire->pending($callback)

If no argument is supplied, returns the number of callbacks pending to be
called, excluding the current one. If a callback  argument is supplied, returns
whether that particular callback is pending for being called.

 say $fire->pending, ' callbacks are left.';

 if ($fire->pending('some.callback')) {
     say 'some.callback will be called soon (unless it gets canceled)';
 }

B<Parameters>

=over

=item *

B<$callback> - I<optional>, the callback being checked.

=back

=head2 $fire->cancel($callback)

Cancels the supplied callback once.

 if ($user eq 'noah') {
     # we don't love noah!
     $fire->cancel('send.hearts');
 }

B<Parameters>

=over

=item *

B<$callback> - callback to be cancelled.

=back

=head2 $fire->return_of($callback)

Returns the return value of the supplied callback.

 if ($fire->return_of('my.callback')) {
     say 'my.callback returned a true value';
 }

B<Parameters>

=over

=item *

B<$callback> - desired callback.

=back

=head2 $fire->last

Returns the most recent previous callback called.
This is also useful for determining which callback was the last to be called.

 say $fire->last, ' was called before this one.';

 my $fire = $eo->fire_event('myEvent');
 say $fire->last, ' was the last callback called.';

=head2 $fire->last_return

Returns the last callback's return value.

 if ($fire->last_return) {
     say 'the callback before this one returned a true value.';
 }
 else {
     die 'the last callback returned a false value.';
 }

=head2 $fire->event_name

Returns the name of the event.

 say 'the event being fired is ', $fire->event_name;

=head2 $fire->callback_name

Returns the name of the current callback.

 say 'the current callback being called is ', $fire->callback_name;

=head2 $fire->callback_priority

Returns the priority of the current callback.

 say 'the priority of the current callback is ', $fire->callback_priority;

=head2 $fire->callback_data($key)

Returns the data supplied to the callback when it was registered, if any. If the
data is a hash reference, an optional key parameter can specify a which value to
fetch.

 say 'my data is ', $fire->callback_data;
 say 'my name is ', $fire->callback_data('name');

B<Parameters>

=over

=item *

B<$key> - I<optional>, a key to fetch a value if the data registered was a hash.

=back

=head2 $fire->data($key)

Returns the data supplied to the collection when it was fired, if any. If the
data is a hash reference, an optional key parameter can specify a which value to
fetch.

 say 'fire data is ', $fire->data;
 say 'fire time was ', $fire->data('time');

B<Parameters>

=over

=item *

B<$key> - I<optional>, a key to fetch a value if the data registered was a hash.

=back

=head1 AUTHOR

L<Mitchell Cooper|https://github.com/cooper> <cooper@cpan.org>

Copyright E<copy> 2011-2017. Released under New BSD license.

Comments, complaints, and recommendations are accepted. Bugs may be reported on
L<GitHub|https://github.com/cooper/evented-object/issues>.
