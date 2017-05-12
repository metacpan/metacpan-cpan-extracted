package Mesos::Dispatcher;
use Mesos::XS;
use AnyEvent;
use Mesos::Channel;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;

=head1 NAME

Mesos::Dispatcher - base class for Mesos dispatchers

=head1 DESCRIPTION

A parent class for event dispatchers to inherit from.

=head1 ATTRIBUTES

=head2 channel

A Mesos::Channel, used for sending event data from Mesos C++ callbacks to perl.

=head2 cb

A code ref to be invoked when an event is ready to be processed from the channel.

Normally this will be set by Mesos::Role::HasDispatcher.

=head1 METHODS

=head2 new

    my $dispatcher = Mesos::Dispatcher->new(%args)

        OPTIONAL %args
            cb
            channel

=head2 call

A shortcut for invoking the cb attribute.

=head2 notify

=head2 recv

Receive event data from the channel. Returns undef if no event data is available.

=head2 send

=head2 wait

Wait for an event to be sent to the channel, invoke the cb attribute, and return the event arguments.

=cut

has channel => (
    is      => 'ro',
    handles => [qw(recv send)],
    default => sub { Mesos::Channel->new },
);

has cb => (
    is      => 'ro',
    writer  => 'set_cb',
    default => sub { sub{} },
);

sub call { shift->cb->() }

sub xs_init {
    my ($self) = @_;
    $self->_xs_init($self->channel);
}

after send => sub { shift->notify };

sub wait {
    my ($self, $time) = @_;

    my $cv = AnyEvent->condvar;
    my $w  = $time && do {
        AnyEvent->timer(after => $time, cb => sub { $cv->send })
    };

    my $old_cb = $self->cb;
    my $guard  = guard { $self->set_cb($old_cb) };
    $self->set_cb(sub {
        my @return = $old_cb->();
        $cv->send(@return);
    });
    my @return = $cv->recv;

    weaken($self);
    return @return;
}

sub BUILD { shift->xs_init }

1;
