package Deeme;
use strict;
use 5.008_005;
our $VERSION = '0.05';
use Deeme::Obj -base;
use Carp 'croak';
has 'backend';
use Scalar::Util qw(blessed);
use constant DEBUG => $ENV{DEEME_DEBUG} || 0;

sub new {
    my $self = shift;
    $self = $self->SUPER::new(@_);
    if ( !$self->backend ) {
        require Deeme::Backend::Memory;
        $self->backend( Deeme::Backend::Memory->new );
    }
    $self->backend->deeme($self);
    return $self;
}

sub catch { $_[0]->on( error => $_[1] ) and return $_[0] }

sub emit {
    my ( $self, $name ) = ( shift, shift );

    if ( my $s = $self->backend->events_get($name) ) {
        warn "-- Emit $name in @{[blessed $self]} (@{[scalar @$s]})\n"
            if DEBUG;
        my @onces = $self->backend->events_onces($name);
        my $i     = 0;
        for my $cb (@$s) {
            ( $onces[$i] == 1 )
                ? ( splice( @onces, $i, 1 )
                    and $self->_unsubscribe_index( $name => $i ) )
                : $i++;
            $self->$cb(@_);
        }
    }
    else {
        warn "-- Emit $name in @{[blessed $self]} (0)\n" if DEBUG;
        die "@{[blessed $self]}: $_[0]" if $name eq 'error';
    }

    return $self;
}

sub emit_safe {
    my ( $self, $name ) = ( shift, shift );

    if ( my $s = $self->backend->events_get($name) ) {
        warn "-- Emit $name in @{[blessed $self]} safely (@{[scalar @$s]})\n"
            if DEBUG;
        my @onces = $self->backend->events_onces($name);
        my $i     = 0;
        for my $cb (@$s) {
            $self->emit( error => qq{Event "$name" failed: $@} )
                unless eval {
                ( $onces[$i] == 1 )
                    ? ( splice( @onces, $i, 1 )
                        and $self->_unsubscribe_index( $name => $i ) )
                    : $i++;
                $self->$cb(@_);
                1;
                };
        }
    }
    else {
        warn "-- Emit $name in @{[blessed $self]} safely (0)\n" if DEBUG;
        die "@{[blessed $self]}: $_[0]" if $name eq 'error';
    }

    return $self;
}

sub has_subscribers { !!@{ shift->subscribers(shift) } }

sub on {
    my ( $self, $name, $cb ) = @_;
    warn "-- on $name in @{[blessed $self]}\n"
        if DEBUG;
    return $self->backend->event_add( $name, $cb ||= [], 0 );
}

sub once {
    my ( $self, $name, $cb ) = @_;
    warn "-- once $name in @{[blessed $self]}\n"
        if DEBUG;
    return $self->backend->event_add( $name, $cb ||= [], 1 );
}

sub subscribers { shift->backend->events_get( shift, 0 ) || [] }

sub unsubscribe {
    my ( $self, $name, $cb ) = @_;
    warn "-- unsubscribe $name in @{[blessed $self]}\n"
        if DEBUG;
    # One
    if ($cb) {
        my @events = @{ $self->backend->events_get( $name, 0 ) };
        my @onces = $self->backend->events_onces($name);

        my ($index) = grep { $cb eq $events[$_] } 0 .. $#events;
        if ( defined $index ) {

            splice @events, $index, 1;
            splice @onces,  $index, 1;
            $self->backend->event_delete($name) and return $self
                unless @events;
            $self->backend->event_update( $name, \@events, 0 );
            $self->backend->once_update( $name, \@onces );
        }
    }

    # All
    else { $self->backend->event_delete($name); }

    return $self;
}

sub reset {
    my $self = shift;
     warn "-- events reset called in @{[blessed $self]}\n"
        if DEBUG;
    $self->backend->events_reset;
    return $self;
}

sub _unsubscribe_index {
    my ( $self, $name, $index ) = @_;

    warn "-- unsubscribing $name (# $index) in @{[blessed $self]}\n"
        if DEBUG;
    my @events = @{ $self->backend->events_get( $name, 0 ) };
    my @onces = $self->backend->events_onces($name);

    splice @events, $index, 1;
    splice @onces,  $index, 1;
    $self->backend->event_delete($name) and return $self
        unless @events;
    $self->backend->event_update( $name, [@events], 0 );
    $self->backend->once_update( $name, \@onces );

    return $self;
}


1;
__END__

=encoding utf-8

=head1 NAME

Deeme - a Database-agnostic driven Event Emitter

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Deeme is a database-agnostic driven event emitter base-class.
Deeme allows you to define binding subs on different points in multiple applications, and execute them later, in another worker. It is handy if you have to attach subs to events that are delayed in time and must be fixed. It can act also like a jobqueue and It is strongly inspired by (and a rework of) L<Mojo::EventEmitter>.

Have a look at L<Deeme::Worker> for the jobqueue functionality.

=head1 EVENTS

L<Deeme> can emit the following events.

=head2 error

  $e->on(error => sub {
    my ($e, $err) = @_;
    ...
  });

Emitted for event errors, fatal if unhandled.

  $e->on(error => sub {
    my ($e, $err) = @_;
    say "This looks bad: $err";
  });

=head1 METHODS

L<Deeme> inherits all methods from L<Deeme::Obj> and
implements the following new ones.

=head2 catch

  $e = $e->catch(sub {...});

Subscribe to L</"error"> event.

  # Longer version
  $e->on(error => sub {...});

=head2 emit

  $e = $e->emit('foo');
  $e = $e->emit('foo', 123);

Emit event.

=head2 reset

  $e = $e->reset;

Delete all events on the backend.

=head2 emit_safe

  $e = $e->emit_safe('foo');
  $e = $e->emit_safe('foo', 123);

Emit event safely and emit L</"error"> event on failure.

=head2 has_subscribers

  my $bool = $e->has_subscribers('foo');

Check if event has subscribers.

=head2 on

  my $cb = $e->on(foo => sub {...});

Subscribe to event.

  $e->on(foo => sub {
    my ($e, @args) = @_;
    ...
  });

=head2 once

  my $cb = $e->once(foo => sub {...});

Subscribe to event and unsubscribe again after it has been emitted once.

  $e->once(foo => sub {
    my ($e, @args) = @_;
    ...
  });

=head2 subscribers

  my $subscribers = $e->subscribers('foo');

All subscribers for event.

  # Unsubscribe last subscriber
  $e->unsubscribe(foo => $e->subscribers('foo')->[-1]);

=head2 unsubscribe

  $e = $e->unsubscribe('foo');
  $e = $e->unsubscribe(foo => $cb);

Unsubscribe from event.

=head1 DEBUGGING

You can set the C<DEEME_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  DEEME_DEBUG=1

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Deeme::Worker>, L<Deeme::Backend::Memory>, L<Deeme::Backend::Mango>, L<Deeme::Backend::Meerkat>, L<Mojo::EventEmitter>, L<Mojolicious>

=cut
