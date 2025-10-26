package MikroTik::Client::Reactor::AE;
use Mojo::Base 'Mojo::Reactor::Poll';

use AnyEvent 5.0;
use Carp         qw(croak);
use Mojo::Util   qw(steady_time);
use Scalar::Util qw(weaken);

my $AE;

sub DESTROY { undef $AE }

sub again {
    my ($self, $id, $after) = @_;
    croak 'Timer not active' unless my $t = $self->{timers}{$id};
    $t->{after}   = $after if defined $after;
    $t->{time}    = steady_time + $t->{after};
    $t->{watcher} = AE::timer($t->{after}, $t->{after}, $t->{cb});
}

sub is_running { !!(shift->{running} || $AnyEvent::CondVar::Base::WAITING) }

sub new { $AE++ ? Mojo::Reactor::Poll->new : shift->SUPER::new }

sub one_tick {
    my $self = shift;
    local $self->{running} = 1 unless $self->{running};
    state $tick
        = ($AnyEvent::MODEL || '') eq 'AnyEvent::Impl::EV'
        ? sub { EV::run(EV::RUN_ONCE()); }
        : \&Mojo::Reactor::Poll::one_tick;
    $self->$tick();
}

sub recurring { shift->_timer(1, @_) }

sub start {
    my $self = shift;
    local $self->{running} = 1 unless $self->{running};
    weaken $self;
    $self->{idle} = AE::timer 1, 2,
        sub { $self->stop unless keys %{$self->{timers}} || keys %{$self->{io}} };
    ($self->{cv} = AE::cv)->recv;
}

sub stop {
    my $self = shift;
    delete @{$self}{qw(idle running)};
    if (my $cv = $self->{cv}) { $cv->send }
}

sub timer { shift->_timer(0, @_) }

sub watch {
    my $self = shift->SUPER::watch(@_);
    my ($handle, $read, $write) = @_;

    my $fd = fileno $handle;
    croak 'I/O watcher not active' unless my $io = $self->{io}{$fd};

    weaken $self;

    if ($read) {
        $io->{watcher_r}
            ||= AE::io($fd, 0, sub { $self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0) });
    }
    else { delete $io->{watcher_r} }

    if ($write) {
        $io->{watcher_w}
            ||= AE::io($fd, 1, sub { $self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1) });
    }
    else { delete $io->{watcher_w} }

    return $self;
}

sub _timer {
    my ($self, $recurring, $after, $cb) = @_;
    $after ||= 0.0001 if $recurring;
    my $id = $self->SUPER::_timer($recurring, $after);
    my $t  = $self->{timers}{$id};
    weaken $t;
    $t->{cb} = my $wrapper = sub {
        $recurring
            ? do { $t->{time} = steady_time + $t->{after} }
            : do { delete $self->{timers}{$id}; };
        $self->_try('Timer', $cb);
    };
    $t->{watcher} = AE::timer($after, $after, $wrapper);
    return $id;
}

1;

=encoding utf8

=head1 NAME

Mojo::Reactor::AE - Low-level event reactor adaptor for AnyEvent

=head1 SYNOPSIS

    use MikroTik::Client::Reactor::AE;

    # Watch if handle becomes readable or writable
    my $reactor = MikroTik::Client::Reactor::AE->new;
    $reactor->io($first => sub ($reactor, $writable) {
        say $writable ? 'First handle is writable' : 'First handle is readable';
    });

    # Change to watching only if handle becomes writable
    $reactor->watch($first, 0, 1);

    # Turn file descriptor into handle and watch if it becomes readable
    my $second = IO::Handle->new_from_fd($fd, 'r');
    $reactor->io($second => sub ($reactor, $writable) {
        say $writable ? 'Second handle is writable' : 'Second handle is readable';
    })->watch($second, 1, 0);

    # Add a timer
    $reactor->timer(15 => sub ($reactor) {
        $reactor->remove($first);
        $reactor->remove($second);
        say 'Timeout!';
    });

    # Start reactor if necessary
    $reactor->start unless $reactor->is_running;

=head1 DESCRIPTION

L<MikroTik::Client::Reactor::AE> is a low-level event reactor adaptor for L<AnyEvent>.

=head1 EVENTS

L<MikroTik::Client::Reactor::AE> inherits all events from L<Mojo::Reactor::Poll>.

=head1 METHODS

L<MikroTik::Client::Reactor::AE> inherits all methods from L<Mojo::Reactor::Poll>
and implements the following new ones.

=head2 again

    $reactor->again($id);
    $reactor->again($id, 0.5);

Restart timer and optionally change the invocation time. Note that this method
requiresan active timer.

=head2 is_running

    my $bool = $reactor->is_running;

Check if reactor is running.

=head2 new

    my $reactor = MikroTik::Client::Reactor::AE->new;

Construct a new L<MikroTik::Client::Reactor::AE> object.

=head2 one_tick

    $reactor->one_tick;

Run reactor until an event occurs or no events are being watched anymore.

    # Don't block longer than 0.5 seconds
    my $id = $reactor->timer(0.5 => sub {});
    $reactor->one_tick;
    $reactor->remove($id);

=head2 recurring

    my $id = $reactor->recurring(0.25 => sub {...});

Create a new recurring timer, invoking the callback repeatedly after a given
amount of time in seconds.

=head2 start

    $reactor->start;

Start watching for I/O and timer events, this will block until L</"stop"> is called
or no events are being watched anymore.

    # Start reactor only if it is not running already
    $reactor->start unless $reactor->is_running;

=head2 stop

    $reactor->stop;

Stop watching for I/O and timer events.

=head2 timer

    my $id = $reactor->timer(0.5 => sub {...});

Create a new timer, invoking the callback after a given amount of time in seconds.

=head2 watch

    $reactor = $reactor->watch($handle, $readable, $writable);

Change I/O events to watch handle for with true and false values. Note that this method
requires an active I/O watcher.

    # Watch only for readable events
    $reactor->watch($handle, 1, 0);

    # Watch only for writable events
    $reactor->watch($handle, 0, 1);

    # Watch for readable and writable events
    $reactor->watch($handle, 1, 1);

    # Pause watching for events
    $reactor->watch($handle, 0, 0);

=head1 SEE ALSO

L<MikroTik::Client>

=cut
