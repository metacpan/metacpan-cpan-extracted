[![Build Status](https://travis-ci.org/mudler/p5-Deeme.png?branch=master)](https://travis-ci.org/mudler/p5-Deeme)
# NAME

Deeme - a Database-agnostic driven Event Emitter

# SYNOPSIS

    package Cat;
    use Deeme::Obj 'Deeme';
    use Deeme::Backend::Meerkat;

    # app1.pl
    package main;
    # Subscribe to events in an application (thread, fork, whatever)
    my $tiger = Cat->new(backend=> Deeme::Backend::Meerkat->new(...) ); #or you can just do Deeme->new
    $tiger->on(roar => sub {
      my ($tiger, $times) = @_;
      say 'RAWR!' for 1 .. $times;
    });

     ...

    #then, later in another application
    # app2.pl
    my $tiger = Cat->new(backend=> Deeme::Backend::Meerkat->new(...));
    $tiger->emit(roar => 3);

# DESCRIPTION

Deeme is a database-agnostic driven event emitter base-class.
Deeme allows you to define binding subs on different points in multiple applications, and execute them later, in another worker. It is handy if you have to attach subs to events that are delayed in time and must be fixed. It can act also like a jobqueue and It is strongly inspired by (and a rework of) [Mojo::EventEmitter](https://metacpan.org/pod/Mojo::EventEmitter).

Have a look at [Deeme::Worker](https://metacpan.org/pod/Deeme::Worker) for the jobqueue functionality.

# EVENTS

[Deeme](https://metacpan.org/pod/Deeme) can emit the following events.

## error

    $e->on(error => sub {
      my ($e, $err) = @_;
      ...
    });

Emitted for event errors, fatal if unhandled.

    $e->on(error => sub {
      my ($e, $err) = @_;
      say "This looks bad: $err";
    });

# METHODS

[Deeme](https://metacpan.org/pod/Deeme) inherits all methods from [Deeme::Obj](https://metacpan.org/pod/Deeme::Obj) and
implements the following new ones.

## catch

    $e = $e->catch(sub {...});

Subscribe to ["error"](#error) event.

    # Longer version
    $e->on(error => sub {...});

## emit

    $e = $e->emit('foo');
    $e = $e->emit('foo', 123);

Emit event.

## reset

    $e = $e->reset;

Delete all events on the backend.

## emit\_safe

    $e = $e->emit_safe('foo');
    $e = $e->emit_safe('foo', 123);

Emit event safely and emit ["error"](#error) event on failure.

## has\_subscribers

    my $bool = $e->has_subscribers('foo');

Check if event has subscribers.

## on

    my $cb = $e->on(foo => sub {...});

Subscribe to event.

    $e->on(foo => sub {
      my ($e, @args) = @_;
      ...
    });

## once

    my $cb = $e->once(foo => sub {...});

Subscribe to event and unsubscribe again after it has been emitted once.

    $e->once(foo => sub {
      my ($e, @args) = @_;
      ...
    });

## subscribers

    my $subscribers = $e->subscribers('foo');

All subscribers for event.

    # Unsubscribe last subscriber
    $e->unsubscribe(foo => $e->subscribers('foo')->[-1]);

## unsubscribe

    $e = $e->unsubscribe('foo');
    $e = $e->unsubscribe(foo => $cb);

Unsubscribe from event.

# DEBUGGING

You can set the `DEEME_DEBUG` environment variable to get some
advanced diagnostics information printed to `STDERR`.

    DEEME_DEBUG=1

# AUTHOR

mudler <mudler@dark-lab.net>

# COPYRIGHT

Copyright 2014- mudler

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Deeme::Worker](https://metacpan.org/pod/Deeme::Worker), [Deeme::Backend::Memory](https://metacpan.org/pod/Deeme::Backend::Memory), [Deeme::Backend::Mango](https://metacpan.org/pod/Deeme::Backend::Mango), [Deeme::Backend::Meerkat](https://metacpan.org/pod/Deeme::Backend::Meerkat), [Mojo::EventEmitter](https://metacpan.org/pod/Mojo::EventEmitter), [Mojolicious](https://metacpan.org/pod/Mojolicious)
