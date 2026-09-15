use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_INET pack_sockaddr_in inet_aton);
use Scalar::Util qw(blessed);

use Linux::Event::Address;
use Linux::Event::Error;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::ListenerProbeStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
    sub on_listener_error ($class, $listener, $error) {
        $main::STREAM_LISTENER_ERROR_CALLED++;
    }
}

{
    package T::RecoveringListener;
    use parent 'Linux::Event::IO::Sock::Listener';
    sub on_error ($listener, $error) {
        $main::LISTENER_ERROR = $error;
        return;
    }
}

our ($STREAM_LISTENER_ERROR_CALLED, $LISTENER_ERROR);

my $loop = Linux::Event::Loop->new;

ok(!T::ListenerProbeStream->can('listen'),
    'Stream does not expose Listener construction');
ok(!Linux::Event::IO::Sock::Listener->can('cancel'),
    'Listener has one close operation and no compatibility alias');

like(exception(sub { Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::ListenerProbeStream' }, loop => $loop,
) }),
    qr/exactly one socket source/, 'one socket source is required');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => '127.0.0.1', port => 0, unix => '/unused',
    );
}), qr/exactly one socket source/, 'mixed socket sources are rejected');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => '127.0.0.1',
    );
}), qr/port must be an integer/, 'TCP source requires a port');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => "127.0.0.1\0.invalid", port => 0,
    );
}), qr/without NUL bytes/, 'host containing a NUL byte is rejected');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, unix => "/tmp/linux-event\0.sock",
    );
}), qr/without NUL bytes/, 'Unix path containing a NUL byte is rejected');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => '127.0.0.1', port => 70_000,
    );
}), qr/port must be at most 65535/, 'out-of-range port is rejected');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => '127.0.0.1', port => 0,
        edge_triggered => 1, max_accept_per_tick => 1,
    );
}), qr/requires max_accept_per_tick => 0/,
    'bounded accept drain cannot be edge-triggered');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => '127.0.0.1', port => 0, surprise => 1,
    );
}), qr/unknown options: surprise/, 'unknown options are rejected');
like(exception(sub {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        loop => $loop, host => '127.0.0.1', port => 0, permissions => 0600,
    );
}), qr/options not valid.*permissions/,
    'source-specific options cannot silently affect another mode');

my $v6only_error = eval {
    Linux::Event::IO::Sock::Listener->new(
        stream => { class => 'T::ListenerProbeStream' },
        host         => '127.0.0.1',
        port         => 0,
        v6only       => 1,
    );
    undef;
} // $@;
ok(blessed($v6only_error) && $v6only_error->isa('Linux::Event::Error'),
    'IPv6-only policy mismatch throws a structured Error');
is($v6only_error->type, 'socket_configuration',
    'IPv6-only policy mismatch has socket configuration type');
is($v6only_error->option, 'v6only',
    'IPv6-only policy mismatch identifies v6only');

my $address = Linux::Event::Address->new(
    pack_sockaddr_in(4321, inet_aton('127.0.0.1')),
);
is($address->family, 'inet', 'Address parses IPv4 family lazily');
is($address->family_number, AF_INET, 'Address exposes numeric family');
is($address->host, '127.0.0.1', 'Address exposes host');
is($address->port, 4321, 'Address exposes port');

my $error = Linux::Event::Error->new(
    type => 'resource', operation => 'accept', errno => 24,
    message => 'Too many open files', fatal => 0,
);
is($error->type, 'resource', 'Error exposes type');
ok(!$error->fatal, 'Error exposes fatality');
is("$error", 'accept: Too many open files (errno=24)',
    'Error stringifies with operation and errno');

my $fatal_listener = Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::ListenerProbeStream' },
    host => '127.0.0.1', port => 0,
);
like(exception(sub { $fatal_listener->on_error($error) }),
    qr/^listener failed: accept: Too many open files/,
    'base Listener owns the fatal runtime-error policy');
is($STREAM_LISTENER_ERROR_CALLED, undef,
    'Listener errors are not delegated to the Stream class');
$fatal_listener->close;

my $recovering = T::RecoveringListener->new(
    stream => { class => 'T::ListenerProbeStream' },
    host => '127.0.0.1', port => 0,
);
$recovering->on_error($error);
is($LISTENER_ERROR, $error,
    'Listener subclass may replace runtime-error policy');
$recovering->close;

{
    package T::ListenerBrokenLoop;
    sub new ($class) { bless {}, $class }
    sub add ($self, $object) { $object->_attach_to_loop($self) }
    sub watch ($self, @option) { die "synthetic Listener watch failure\n" }
}

my $retry_listener = T::RecoveringListener->new(
    stream => { class => 'T::ListenerProbeStream' },
    host         => '127.0.0.1',
    port         => 0,
);
my $broken = T::ListenerBrokenLoop->new;
my $attach_error = eval { $broken->add($retry_listener); undef } // $@;
ok(blessed($attach_error) && $attach_error->isa('Linux::Event::Error'),
    'Listener registration failure throws a structured Error');
is($attach_error->operation, 'watch',
    'Listener registration failure identifies the watch operation');
is($retry_listener->state, 'unattached',
    'Listener registration failure leaves the Listener unattached');
ok(defined($retry_listener->fd),
    'Listener registration failure preserves its listening socket');
is($loop->add($retry_listener), $retry_listener,
    'Listener can attach after a registration failure');
$retry_listener->close;

done_testing;

sub exception ($code) {
    my $error = '';
    eval { $code->(); 1 } or $error = $@;
    return $error;
}
