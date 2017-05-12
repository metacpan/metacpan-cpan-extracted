package Mesos::Dispatcher::POE;
use POE;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'Mesos::Dispatcher::Pipe';

=head1 NAME

Mesos::Dispatcher::POE

=head1 DESCRIPTION

A Mesos::Dispatcher implementation, and subclass of Mesos::Dispatcher::Pipe.

Creates a POE::Session to handle reading from the pipe.

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

has session => (
    is      => 'ro',
    writer  => 'set_session',
    clearer => 'clear_session',
);

sub wait {
    my ($self, $time) = @_;
    require POE::Future;

    my $future  = POE::Future->new;
    my $timeout = $time && do {
        POE::Future->new_delay($time)
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

sub run {
    my ($self) = @_;
    POE::Kernel->run;
    return $self->status;
}

sub BUILD {
    my ($self) = @_;
    weaken($self);

    my %states = (
        _start => sub {
            $_[KERNEL]->select_read($self->fh, 'dispatch');
        },
        dispatch => sub {
            $self->call;
        },
        shutdown => sub {
            $_[KERNEL]->select_read($self->fh);
        }
    );

    my $session = POE::Session->create(inline_states => \%states);
    $self->set_session($session);
}

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;

    POE::Kernel->call($self->session, 'shutdown');
    $self->clear_session;
}

1;
