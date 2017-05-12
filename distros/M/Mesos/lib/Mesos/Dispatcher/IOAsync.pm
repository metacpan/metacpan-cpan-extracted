package Mesos::Dispatcher::IOAsync;
use IO::Async::Handle;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'Mesos::Dispatcher::Pipe';

=head1 NAME

Mesos::Dispatcher::IOAsync

=head1 DESCRIPTION

A Mesos::Dispatcher implementation, and subclass of Mesos::Dispatcher::Pipe.

Creates an IO::Async::Handle to handle reading from the pipe.

=head1 ATTRIBUTES

=head2 loop

The IO::Async::Loop to use for event handling.

=cut

has loop => (
    is       => 'ro',
    required => 1,
);

has notifier => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_notifier',
);
sub _build_notifier {
    my ($self) = @_;
    weaken($self);

    return IO::Async::Handle->new(
        read_fileno    => $self->fd,
        on_read_ready  => sub { $self->call },
        want_readready => 1,
    );
}

sub wait {
    my ($self, $time) = @_;
    my $loop   = $self->loop;
    my $future = $loop->new_future;

    my $time_id = $time && do {
        $loop->watch_time(
            after => $time,
            code  => sub { $future->done unless $future->is_done },
        )
    };

    my $old_cb = $self->cb;
    my $guard  = guard {
        $future->cancel;
        $loop->unwatch_time($time_id) if defined $time_id;
        $self->set_cb($old_cb);
    };
    $self->set_cb(sub {
        my @return = $old_cb->();
        $future->done(@return) unless $future->is_done;
    });
    my @return = $future->get;

    weaken($self);
    return @return;
}

sub run {
    my ($self) = @_;
    $self->loop->run;
    return $self->status;
}

sub BUILD {
    my ($self) = @_;
    $self->loop->add($self->notifier);
}

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;

    $self->loop->remove($self->notifier);
}

1;
