package Mesos::Dispatcher::Mojo;
use Future::Mojo;
use Mojo::IOLoop;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'Mesos::Dispatcher::Pipe';

=head1 NAME

Mesos::Dispatcher::Mojo

=head1 DESCRIPTION

A Mesos::Dispatcher implementation, and subclass of Mesos::Dispatcher::Pipe.

Creates a Mojo::Reactor I/O watcher to handle reading from the pipe.

=cut

has fh => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_fh',
);
sub _build_fh {
    my ($self) = @_;
    open my($fh), '<&=', $self->fd;
    return $fh;
}

=head1 ATTRIBUTES

=head2 loop

The Mojo::IOLoop to use for event handling.
Defaults to Mojo::IOLoop->singleton.

=cut

has loop => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { Mojo::IOLoop->singleton },
);

sub wait {
    my ($self, $time) = @_;
    my $loop   = $self->loop;
    my $future = Future::Mojo->new($loop);

    my $timeout = $time && do {
        Future::Mojo->new_timer($loop, $time)
                    ->then(sub { $future->done })
    };

    my $old_cb = $self->cb;
    my $guard  = guard {
        $future->cancel;
        $timeout->cancel if $timeout;
        $self->set_cb($old_cb);
    };
    $self->set_cb(sub {
        my @return = $old_cb->();
        $future->done(@return);
    });
    my @return = $future->get;

    weaken($self);
    return @return;
}

sub BUILD {
    my ($self) = @_;
    weaken($self);

    my $handle  = $self->fh;
    my $reactor = $self->loop->reactor;
    $reactor->io($handle, sub { $self->call() });
    $reactor->watch($handle, 1, 0);
}

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;

    my $handle  = $self->fh;
    my $reactor = $self->loop->reactor;
    $reactor->remove($handle);
}

1;
