package Mesos::Role::Dispatcher;
use Moo::Role;

=head1 NAME

Mesos::Role::Dispatcher

=head1 DESCRIPTION

A role for handling Mesos driver events

=head1 METHODS

=cut

requires 'channel';
requires 'process';

=head2 dispatch_event()

Handle a single event, if any are pending.

=cut

sub dispatch_event {
    my ($self) = @_;
    my ($event, @args) = $self->channel->recv;
    $self->process->$event($self, @args);
}

=head2 dispatch_events()

Handle all pending events.

=cut

sub dispatch_events {
    my ($self) = @_;
    my $channel = $self->channel;
    $self->dispatch_event while $channel->size;
}


1;
