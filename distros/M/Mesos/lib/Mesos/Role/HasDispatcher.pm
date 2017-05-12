package Mesos::Role::HasDispatcher;
use Mesos::Types qw(Dispatcher);
use Module::Runtime qw(require_module);
use Scalar::Util qw(weaken);
use Moo::Role;
use namespace::autoclean;
requires qw(
    event_handler
    status
    start
    stop
    abort
);

=head1 NAME

=head1 DESCRIPTION

Handles constructing and dispatching events from a Mesos::Dispatcher.

=head1 ATTRIBUTES

=head2 dispatcher

=head2 running

=head1 METHODS

=head2 dispatch_event

=head2 run

=head2 run_once

=head1 REQUIRES

=head2 event_handler

=head2 status

=head2 start

=head2 stop

=head2 abort

=cut

has dispatcher => (
    is      => 'ro',
    isa     => Dispatcher,
    coerce  => 1,
    default => sub { 'AnyEvent' },
);

has running => (
    is      => 'rw',
    default => sub { 0 },
);

after  start => sub { shift->running(1) };
after  $_    => sub { shift->running(0) } for qw(stop abort);
before $_    => sub {
    my ($self) = @_;
    $self->start unless $self->running;
} for qw(run run_once);

sub run {
    my ($self) = @_;
    $self->dispatcher->wait while $self->running;
    return $self->status;
}

sub run_once {
    my ($self) = @_;
    $self->dispatcher->wait;
    return $self->status;
}

sub dispatch_event {
    my ($self) = @_;
    my $dispatcher = $self->dispatcher;
    my $handler    = $self->event_handler;

    my ($event, @args) = $dispatcher->recv;
    if ($handler->can($event)) {
        $handler->$event($self, @args);
    } else {
        warn "Event handler can't process event type $event";
    }
    return ($event, @args);
}

after BUILD => sub {
    weaken(my $self = shift);
    my $dispatcher = $self->dispatcher;
    $dispatcher->set_cb(sub { $self->dispatch_event });
};

1;
