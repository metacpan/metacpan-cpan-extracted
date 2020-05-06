# Copyright (c) 2011-17, Mitchell Cooper
#
# Evented::Object: a simple yet featureful base class event framework.
# https://github.com/cooper/evented-object
#
package Evented::Object::Collection; # leave this package name the same FOREVER.

use warnings;
use strict;
use utf8;
use 5.010;

use Scalar::Util qw(weaken blessed);
use List::Util qw(min max);
use Carp qw(carp);

our $VERSION = '5.68';
our $events  = $Evented::Object::events;
our $props   = $Evented::Object::props;

my $dummy;
my %boolopts = map { $_ => 1 } qw(safe return_check fail_continue);

sub new {
    return bless {
        pending         => {},
        default_names   => {},
        names           => {}
    }, shift;
}

sub push_callbacks {
    my ($collection, $callbacks, $names) = @_;
    my $pending  = $collection->{pending};
    my $my_names = $collection->{names};

    # add to pending callbacks and callback name-to-ID mapping.
    @$pending { keys %$callbacks } = values %$callbacks;
    @$my_names{ keys %$names     } = values %$names;

    # set default names for any callback names which were not found
    $collection->{default_names}{ $_->[2]{name} } ||= $_->[2]{id}
        for values %$callbacks;
}

#
#   Available fire options
#   ----------------------
#
#   safe            calls all callbacks within eval blocks.
#                   consumes no parameter.
#
#   return_check    causes the event to ->stop if any callback returns false
#                   BUT IT WAITS until all have been fired. so if one returns false,
#                   the rest will be called, but $fire->stopper will be true afterward.
#                   consumes no parameter.
#
#   caller          specify an alternate [caller 1] value, mostly for internal use.
#                   parameter = caller(1) info wrapped in an array reference.
#
#   fail_continue   if 'safe' is enabled and a callback raises an exception, it will
#                   by default ->stop the fire. this option tells it to continue instead.
#                   consumes no parameter.
#
#   data            some data to fire with the event. esp. good for things that might be
#                   useful at times but not accessed frequently enough to be an argument.
#                   parameter = the data.
#
sub fire {
    my ($collection, @options) = @_;

    # handle options.
    my ($caller, $data) = $collection->{caller};
    while (@options) {
        my $opt = shift @options;

        if ($opt eq 'caller')   { $caller = shift @options } # custom caller
        if ($opt eq 'data')     { $data   = shift @options } # fire data

        # boolean option.
        $collection->{$opt} = 1 if $boolopts{$opt};

    }

    # create fire object.
    my $fire = Evented::Object::EventFire->new(
        caller     => $caller ||= [caller 1], # $fire->caller
        data       => $data,                  # $fire->data
        collection => $collection
    );

    # if it hasn't been sorted, do so now.
    $collection->sort if not $collection->{sorted};
    my $callbacks = $collection->{sorted} or return $fire;

    # if return_check is enabled, add a callback to be fired last that will
    # check the return values. this is basically hackery using a dummy object.
    if ($collection->{return_check}) {
        my $cb = {
            name   => 'eventedObject.returnCheck',
            caller => $caller,
            code   => \&_return_check
        };
        my $group = [
            $dummy ||= Evented::Object->new,
            'returnCheck',
            [],
            "$dummy/returnCheck"
        ];
        push @$callbacks, [
            -inf,           # [0] $priority
            $group,         # [1] $group
            $cb             # [2] $cb
        ];
        $cb->{id} = "$$group[3]/$$cb{name}";
        $collection->{pending}{ $cb->{id} } = $cb;
    }

    # call them.
    return $collection->_call_callbacks($fire);

}

# sorts the callbacks, trying its best to listen to before and after.
sub sort : method {
    my $collection = shift;
    return unless $collection->{pending};
    my %callbacks = %{ $collection->{pending} };
    my (@sorted, %done, %waited);

    # iterate over the callback sets,
    # which are array refs of [ priority, group, cb ]
    my @callbacks = values %callbacks;
    while (my $set = shift @callbacks) {
        my ($priority, $group, $cb) = @$set;
        my $cb_id    = $cb->{id};
        my $group_id = $group->[3];

        next if $done{$cb_id};

        # a real priority exists already.
        if (defined $priority && $priority ne 'nan') {
            push @sorted, $set;
            $done{$cb_id} = 1;
            next;
        }


        # TODO: if before and afters cannot be resolved, the callback dependencies
        # are currently skipped. maybe there should be a way to specify that a callback
        # dependency is REQUIRED, meaning to skip the callback entirely if it cannot
        # be done. or maybe something more sophisticated that can prioritize the
        # befores and afters in this way. for now though, we will just try to not
        # specify impossible befores and afters.



        # callback priority determination can be postponed until another's
        # priority is determined. the maxmium number of times one particular
        # callback can be postponed is the number of total callbacks.
        my $wait_max = keys %callbacks;

        my $name_to_id = $collection->_group_names($group_id);
        my $get_befores_afters = sub {
            my ($key, @results) = shift;
            my $list = $cb->{$key} or return;
            $list = [ $list ] if ref $list ne 'ARRAY';

            # for each callback name, find its priority.
            foreach my $their_name (@$list) {

                # map callback name to id, id to cbref, and cbref to priority.
                my $their_id = $name_to_id->{$their_name} or next;
                my $their_cb = $callbacks{$their_id}      or next;
                my $their_p  = $their_cb->[0];

                # if their priority is nan,
                # we have to wait until it is determined.
                if ($their_p eq 'nan') {
                    my $wait_key = "$cb_id $their_id";
                    push @callbacks, $set
                        unless $waited{$key}++ > $wait_max;
                    return 1;
                }

                push @results, $their_p;
            }

            return (undef, @results);
        };

        my ($next, @befores) = $get_befores_afters->('before'); next if $next;
        ($next, my @afters ) = $get_befores_afters->('after');  next if $next;

        # figure the ideal priority.
        if (@befores && @afters) {
            my $a_refpoint = min @afters;
            my $b_refpoint = max @befores;
            $priority      = ($a_refpoint + $b_refpoint) / 2;
        }

        # only before. just have 1 higher priority.
        elsif (@befores) {
            my $refpoint = max @befores;
            $priority    = ++$refpoint;
        }

        # only after.
        elsif (@afters) {
            my $refpoint = min @afters;
            $priority    = --$refpoint;
        }

        $priority = 0 if $priority eq 'nan';

        # done with this callback.
        $set->[0] = $priority;
        push @sorted, $set;
        $done{$cb_id} = 1;

    }

    # the final sort by numerical priority.
    $collection->{sorted} = [ sort { $b->[0] <=> $a->[0] } @sorted ];

}

# Nov. 22, 2013 revision
# ----------------------
#
#   collection      a set of callbacks about to be fired. they might belong to multiple
#                   objects or maybe even multiple events. they can each have their own
#                   arguments, and they all have their own options, code references, etc.
#
#        group      represents the group to which a callback belongs. a group consists of
#                   the associated evented object, event name, and arguments.
#
# This revision eliminates all of these nested structures by reworking the way
# a callback collection works. A collection should be an array of callbacks.
# This array, unlike before, will contain an additional element: an array
# reference representing the "group."
#
#   @collection = (
#       [ $priority, $group, $cb ],
#       [ $priority, $group, $cb ],
#       ...
#   )
#
#   $group =                                $cb =
#   [ $eo, $event_name, $args, $id ]        { code, caller, %opts }
#
# This format has several major advantages over the former one. Specifically,
# it makes it very simple to determine which callbacks will be called in the
# future, which ones have been called already, how many are left, etc.
#

# call the passed callback priority sets.
sub _call_callbacks {
    my ($collection, $fire) = @_;
    my $ef_props = $fire->{$props};

    # store the collection.
    my $remaining = $collection->{sorted} or return;
    $ef_props->{collection} = $collection;

    # call each callback.
    while (my $entry = shift @$remaining) {
        my ($priority, $group, $cb) = @$entry;
        my ($eo, $event_name, $args, $group_id) = @$group;

        # sanity check!
        blessed $eo && $eo->isa('Evented::Object') or return;

        # callback name-to-ID mapping is specific to each group.
        $ef_props->{callback_ids} = $collection->_group_names($group_id);

        # increment the callback counter.
        $ef_props->{callback_i}++;

        # set the evented object of this callback.
        # set the event name of this callback.
        $ef_props->{object}             = $eo; weaken($ef_props->{object});     # $fire->object
        $ef_props->{name}               = $event_name;                          # $fire->event_name

        # store identifiers.
        $ef_props->{callback_id}        = my $cb_id = $cb->{id};
        $ef_props->{group_id}           = $group_id;

        # create info about the call.
        $ef_props->{callback_name}      = $cb->{name};                          # $fire->callback_name
        $ef_props->{callback_priority}  = $priority;                            # $fire->callback_priority
        $ef_props->{callback_data}      = $cb->{data} if defined $cb->{data};   # $fire->callback_data

        # this callback has been called already.
        next if $ef_props->{called}{$cb_id};

        # this callback has probably been cancelled.
        next unless $collection->{pending}{$cb_id};


        # determine arguments.
        #
        # no compat <3.0: used to always have obj unless specified with no_obj or later no_fire_obj.
        # no compat <2.9: with_obj -> eo_obj
        # compat: all later version had a variety of with_obj-like-options below.
        #
        my @cb_args = @$args;
        my $include_obj = grep $cb->{$_}, qw(with_eo with_obj with_evented_obj eo_obj);
        unshift @cb_args, $fire unless $cb->{no_fire_obj};
        unshift @cb_args, $eo   if $include_obj;

        # set return values.
        $ef_props->{last_return}            =   # set last return value.
        $ef_props->{return}{$cb_id}         =   # set this callback's return value.

            # call the callback with proper arguments.
            $collection->{safe} ? eval { $cb->{code}(@cb_args) }
                                :        $cb->{code}(@cb_args);

        # set $fire->called($cb) true, and set $fire->last to the callback's name.
        $ef_props->{called}{$cb_id} = 1;
        $ef_props->{last_callback}  = $cb->{name};

        # no longer pending.
        delete $collection->{pending}{$cb_id};

        # stop if eval failed.
        if ($collection->{safe} and my $err = $@) {
            chomp $err;
            $ef_props->{error}{$cb_id} = # not used for anything
            $ef_props->{exception}     = $err;
            $fire->stop($err) unless $collection->{fail_continue};
        }

        # if stop is true, $fire->stop was called. stop the iteration.
        if ($ef_props->{stop}) {
            $ef_props->{stopper} = $cb->{name}; # set $fire->stopper.
            last;
        }

    }

    # dispose of things that are no longer needed.
    delete @$ef_props{ qw(
        callback_name callback_priority
        callback_data callback_i object
        collection
    ) };

    # return the event object.
    $ef_props->{complete} = 1;
    return $fire;

}

sub _group_names {
    my ($collection, $group_id) = @_;
    return $collection->{group_names}{$group_id} ||= do {
        my $names_from_group = $collection->{names}{$group_id} || {};
        my $default_names    = $collection->{default_names};
        my %names = (%$default_names, %$names_from_group);
        \%names
    }
}

sub _return_check {
    my $fire    = shift;
    my %returns = %{ $fire->{$props}{return} || {} };
    foreach my $cb_id (keys %returns) {
        next if $returns{$cb_id};
        return $fire->stop("$cb_id returned false with return_check enabled");
    }
    return 1;
}

1;

=head1 NAME

B<Evented::Object::Collection> - represents a group of pending
L<Evented::Object> callbacks.

=head1 DESCRIPTION

L</Collections> are returned by the evented object 'prepare' methods. They
represent a group of callbacks that are about to be fired. Using collections
allows you to prepare a fire ahead of time before executing it. You can also
fire events with special options this way.

=head1 METHODS


=head2 $col->fire(@options)

Fires the pending callbacks with the specified options, if any. If the callbacks
have not yet been sorted, they are sorted before the event is fired.

 $eo->prepare(some_event => @arguments)->fire('safe');

B<Parameters>

=over

=item *

B<@options> - I<optional>, a mixture of boolean and key:value options for the
event fire.

=back

B<@options> - fire options

=over

=item *

B<caller> - I<requires value>, use an alternate C<[caller 1]> value for the event
fire. This is typically only used internally.

=item *

B<return_check> - I<boolean>, if true, the event will yield that it was stopped
if any of the callbacks return a false value. Note however that if one callbacks
returns false, the rest will still be called. The fire object will only yield
stopped status after all callbacks have been called and any number of them
returned false.

=item *

B<safe> - I<boolean>, wrap all callback calls in C<eval> for safety. if any of
them fail, the event will be stopped at that point with the error.

=item *

B<fail_continue> - I<boolean>, if C<safe> above is enabled, this tells the fire
to continue even if one of the callbacks fails. This could be dangerous if any
of the callbacks expected a previous callback to be done when it actually
failed.

=item *

B<data> - I<requires value>, a scalar value that can be fetched by
C<< $fire->data >> from within the callbacks. Good for data that might be useful
sometimes but not frequently enough to deserve a spot in the argument list. If
C<data> is a hash reference, its values can be fetched conveniently with
C<< $fire->data('key') >>.

=back

=head2 $col->sort

Sorts the callbacks according to C<priority>, C<before>, and C<after> options.

=head1 AUTHOR

L<Mitchell Cooper|https://github.com/cooper> <cooper@cpan.org>

Copyright E<copy> 2011-2017. Released under New BSD license.

Comments, complaints, and recommendations are accepted. Bugs may be reported on
L<GitHub|https://github.com/cooper/evented-object/issues>.
