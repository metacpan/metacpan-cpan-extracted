# Copyright (c) 2011-16, Mitchell Cooper
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

our $VERSION = '5.63';
our $events  = $Evented::Object::events;
our $props   = $Evented::Object::props;

# create a new event object.
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
