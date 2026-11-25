use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);
use lib 'lib';
use Developer::Dashboard::GoRoutine qw(go share wait_all);

my $channel_factory = Developer::Dashboard::GoRoutine->can('channel');
ok( $channel_factory, 'GoRoutine exposes the channel factory' );
ok(
    ( grep { $_ eq 'channel' } @Developer::Dashboard::GoRoutine::EXPORT ) > 0,
    'channel is exported by the existing GoRoutine module',
);

my $unbuffered = $channel_factory->();
isa_ok( $unbuffered, 'Developer::Dashboard::GoRoutine::Channel' );
is( $unbuffered->capacity, 0, 'channel() creates an unbuffered channel' );

share my $received = '';
my $receiver = go sub { $received = $unbuffered->receive };
$unbuffered->send('rendezvous');
wait_all();
is( $received, 'rendezvous', 'unbuffered send waits for a receiver' );
is( $receiver->status, 'done', 'receiver routine finishes after rendezvous' );

my $buffered = $channel_factory->(2);
is( $buffered->capacity, 2, 'channel(N) creates the requested buffer capacity' );
$buffered->send('first');
$buffered->send('second');
is( $buffered->size, 2, 'buffered sends do not wait until the buffer is full' );
my ( $first, $first_ok ) = $buffered->receive;
my ( $second, $second_ok ) = $buffered->receive;
is_deeply( [ $first, $first_ok, $second, $second_ok ],
    [ 'first', 1, 'second', 1 ], 'buffered receive preserves FIFO values and open status' );

$buffered->close;
my ( $closed_value, $closed_ok ) = $buffered->receive;
is_deeply( [ $closed_value, $closed_ok ], [ undef, 0 ],
    'receive from a closed drained channel reports closed state' );
my $closed_scalar = $buffered->receive;
is( $closed_scalar, undef,
    'scalar receive from a closed drained channel returns undef' );
my $send_error = eval { $buffered->send('after-close'); 1 } ? '' : $@;
like( $send_error, qr/closed channel/i, 'sending after close fails explicitly' );

# Values cross a channel by reference, not by copy: there is one
# interpreter and no marshalling boundary, so the receiver gets the same
# Perl value the sender sent.
my $shared_ref = $channel_factory->(1);
my $sent = [ 1, 2, 3 ];
$shared_ref->send($sent);
my ($got_ref) = $shared_ref->receive;
is( refaddr($got_ref), refaddr($sent),
    'channel passes a reference through unchanged' );
push @$got_ref, 4;
is_deeply( $sent, [ 1, 2, 3, 4 ],
    'receiver and sender see the same referenced value' );

# A routine waiting to receive is still pending until the engine dispatches
# it, so kill cancels it at once and it never receives.
my $pending_channel = $channel_factory->();
my $pending_received = 0;
my $pending_waiter = go sub { $pending_channel->receive; $pending_received = 1 };
ok( $pending_waiter->kill, 'a routine waiting to receive accepts cancellation' );
wait_all();
is( $pending_waiter->status, 'killed', 'a cancelled channel waiter terminates cleanly' );
is( $pending_received, 0, 'a cancelled channel waiter never receives' );

# A routine already blocked inside receive cannot be killed by a flag it
# never checks, because it runs on the main thread; instead, closing the
# channel wakes it, which is the documented way to release a waiter.
my $waiting = $channel_factory->();
my $woken_value = 'unset';
my $woken_ok = -1;
my $blocked = go sub {
    my ( $value, $ok ) = $waiting->receive;
    $woken_value = defined $value ? $value : 'closed';
    $woken_ok = $ok;
};
my $closer = go(sub { $waiting->close }, { after => 0.05 });
wait_all();
is( $blocked->status, 'done', 'a channel waiter woken by close finishes normally' );
is( $woken_value, 'closed', 'a waiter woken by close receives no value' );
is( $woken_ok, 0, 'a waiter woken by close reports closed state' );
is( $closer->status, 'done', 'the routine that closed the channel completes normally' );

# Two routines sending on the same unbuffered channel before any
# receiver runs must both deliver, in order: the second send must not
# overwrite the first sender's value. (Q review 5953551354 on PR #82.)
my $two_channel = $channel_factory->();
share my @received_two;
my $first_sender = go sub { $two_channel->send('first') };
my $second_sender = go sub { $two_channel->send('second') };
my $two_receiver = go sub {
    push @received_two, scalar $two_channel->receive for 1 .. 2;
};
wait_all();
is_deeply( \@received_two, [ 'first', 'second' ],
    'two concurrent unbuffered sends both arrive, in order' );
is( $first_sender->status, 'done', 'first sender finishes after delivery' );
is( $second_sender->status, 'done', 'second sender finishes after delivery' );
is( $two_receiver->status, 'done', 'receiver finishes after both values' );

# size() counts values already offered by blocked senders: an
# unbuffered send with no receiver waiting parks its value in
# sender_queue, and receive() takes it from there, so size() must
# report it before the receiver runs. (Q review 5979186129 on PR #82:
# size() counted only queue and returned 0 while a value was available.)
my $sized_channel = $channel_factory->();
share my $observed_size = -1;
share my $sized_value = 'unset';
share my $sized_ok = -1;
my $sized_sender = go sub { $sized_channel->send('pending') };
my $sized_checker = go( sub { $observed_size = $sized_channel->size },
    { after => 0.1 } );
my $sized_receiver = go(
    sub {
        my ( $value, $ok ) = $sized_channel->receive;
        $sized_value = defined $value ? $value : 'undef';
        $sized_ok = $ok;
    },
    { after => 0.2 } );
wait_all();
is( $observed_size, 1,
    'size counts a value waiting in the sender queue' );
is( $sized_value, 'pending', 'receiver takes the pending sender value' );
is( $sized_ok, 1, 'receive of a pending sender value reports open state' );
is( $sized_channel->size, 0,
    'size is zero after the pending value is received' );
is( $sized_sender->status, 'done', 'pending sender finishes after delivery' );
is( $sized_checker->status, 'done', 'size checker routine completes normally' );
is( $sized_receiver->status, 'done', 'size receiver routine completes normally' );

done_testing;

__END__

=head1 NAME

t/244-goroutine-channels.t - GoRoutine 0.12 channel contract tests

=head1 PURPOSE

Verifies the GoRoutine channel API: unbuffered rendezvous, buffered FIFO
transport, close behavior, explicit errors for sends after close, values
passed by reference, cancellation of a channel waiter before it runs, and
waking a blocked receiver by closing the channel.

=head1 WHY IT EXISTS

The GoRoutine 0.12 package adds process-wide channels as a first-class API.
Dashboard currently exposes GoRoutine controls and shared object graphs, so
this test prevents an incomplete integration that omits channels or changes
their Go-style blocking and close semantics.

=head1 WHEN TO USE

Run when changing the Dashboard GoRoutine XS, shared transport, channel
implementation, or module exports. The test should fail against a build that
does not expose the channel API and pass only when the channel lifecycle is
implemented.

=head1 HOW TO USE

Build the XS bundle and run this test in the dev Docker service:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/244-goroutine-channels.t

=head1 WHAT USES IT

Dashboard asynchronous code may use channels for cancellation-aware
communication between GoRoutine workers. The test exercises only the public
Developer::Dashboard::GoRoutine API and does not depend on a separate module
name or extension object.

=head1 EXAMPLES

Run this contract alone:

  prove -Iblib/lib -Iblib/arch -Ilib -lv t/244-goroutine-channels.t

Run it together with the shared-object and routine-control contracts:

  prove -Iblib/lib -Iblib/arch -Ilib -lv t/237-goroutine-shared-objects.t t/238-goroutine-routine-controls.t t/244-goroutine-channels.t

=cut
