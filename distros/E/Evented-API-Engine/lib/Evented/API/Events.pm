# Copyright (c) 2017, Mitchell Cooper
# default event responders
package Evented::API::Events;

use warnings;
use strict;
use 5.010;

use Evented::Object;
use parent 'Evented::Object';

use Scalar::Util qw(blessed weaken);
use Evented::Object::Hax qw(set_symbol);

our $VERSION = '4.13';

sub add_events {
    my $mod = shift;

    # default initialize handler
    $mod->on(init => \&mod_default_init,
        name     => 'api.engine.initSubroutine',
        priority => 100,
        with_eo  => 1
    );

    # default void handler
    $mod->on(void => \&mod_default_void,
        name     => 'api.engine.voidSubroutine',
        priority => 100,
        with_eo  => 1
    );

    # default variable exports
    $mod->on(set_variables =>
        \&mod_default_set_variables, 'api.engine.setVariables');

    # make the module a class monitor of each package
    Evented::Object::add_class_monitor($_, $mod) for $mod->packages;

    # registered a callback
    $mod->on('monitor:register_callback' =>
        \&mod_event_registered, 'api.engine.eventTracker.register');

    # deleted all callbacks for an event
    $mod->on('monitor:delete_event' =>
        \&mod_event_deleted, 'api.engine.eventTracker.deleteEvent');

    # deleted a specific callback
    $mod->on('monitor:delete_callback' =>
        \&mod_callback_deleted, 'api.engine.eventTracker.deleteCallback');

    # module unloaded
    $mod->on(unload => \&mod_unloaded,
        'api.engine.eventTracker.unload');
}

# on init, call module's ->init()
sub mod_default_init {
    my $mod = shift;
    my $init = $mod->package->can('init') or return 1;
    return $init->(@_);
}

# on void, call module's ->void()
sub mod_default_void {
    my $mod = shift;
    my $void = $mod->package->can('void') or return 1;
    return $void->(@_);
}

# on variable set, export the API Engine, module, and module version
sub mod_default_set_variables {
    my $mod = shift;
    set_symbol($mod->package, {
        '$api'      => $mod->api,
        '$mod'      => $mod,
        '$VERSION'  => $mod->{version}
    });
}

# on event register, add to managed event list
sub mod_event_registered {
    my ($mod, $fire, $eo, $event_name, $cb) = @_;
    my $ref = ref $eo;

    # permanent (not managed)
    if ($cb->{permanent}) {
        $mod->Debug("Permanent event: $event_name ($$cb{name}) registered to $ref");
        return;
    }

    # store eo, event, and cb name
    # hold weak reference to eo
    my $e = [ $eo, $event_name, $cb->{name} ];
    weaken($e->[0]);

    $mod->list_store_add('managed_events', $e);
    $mod->Debug("Event: $event_name ($$cb{name}) registered to $ref");
}

# on event delete, remove from managed event list
sub mod_event_deleted {
    my ($mod, $fire, $eo, $event_name) = @_;
    my $ref = ref $eo;
    $mod->Debug("Event: $event_name (all callbacks) deleted from $ref");
    $mod->list_store_remove_matches('managed_events', sub {
        my $e = shift;
        return 1 if not defined $e->[0];        # disposed, delete
        return unless $eo         == $e->[0];   # wrong eo
        return unless $event_name eq $e->[1];   # wrong event
        return 1;                               # match, delete
    });
}

# on callback delete, remove from managed event list
sub mod_callback_deleted {
    my ($mod, $fire, $eo, $event_name, $cb_name) = @_;
    my $ref = ref $eo;
    $mod->Debug("Event: $event_name ($cb_name) deleted from $ref");
    $mod->list_store_remove_matches('managed_events', sub {
        my $e = shift;
        return 1 if !$e->[0];                   # disposed, delete
        return unless $eo         == $e->[0];   # wrong eo
        return unless $event_name eq $e->[1];   # wrong event
        return unless $cb_name    eq $e->[2];   # wrong cb name
        return 1;                               # match, delete
    }, 1);
}

# on module unload, delete managed events
sub mod_unloaded {
    my $mod = shift;
    my $indented;
    foreach my $e ($mod->list_store_items('managed_events')) {
        my ($eo, $event_name, $name) = @$e;
        my $ref = ref $eo;

        # this is a weak reference --
        # if undefined, it was disposed of
        return unless $eo;

        # first one
        if (!$indented) {
            $mod->Debug('Destroying managed event callbacks');
            $mod->api->{indent}++;
            $indented++;
        }

        # delete this callback
        $eo->delete_callback($event_name, $name);
        $mod->Debug("Event: $event_name ($name) deleted from $ref");

    }
    $mod->api->{indent}-- if $indented;
    return 1;
}

1
