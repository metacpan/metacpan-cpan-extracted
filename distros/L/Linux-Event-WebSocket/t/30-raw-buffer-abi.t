use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Framer ();
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::WebSocket::_BQ ();
use Linux::Event::WebSocket::_Engine ();
use Linux::Event::WebSocket::_Frame;
use Linux::Event::WebSocket::_Parser;
use Scalar::Util qw(refaddr);

{
    package Linux::Event::WebSocket::_RawABITestConnection;
    use v5.36;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub _websocket_raw_config ($self) {
        return [ 'server', 1024 * 1024 ];
    }

    sub _websocket_raw_native_ready ($self, $native) {
        my $state = $self->data;
        $state->{provider_native} = $native;
        $self->{raw_engine} = Linux::Event::WebSocket::_Engine->new(
            connection       => $self,
            endpoint_type    => 'server',
            max_message_size => 1024 * 1024,
            native           => $native,
            message_handler  => sub ($connection, $payload, $type) {
                push @{$state->{events}}, [ $type, $payload ];
                $connection->loop->stop
                    if @{$state->{events}} >= $state->{expected};
            },
        );
        $state->{engine_native} = $self->{raw_engine}{native};
        return $self->{raw_engine};
    }

    sub _websocket_engine_error ($self, $error) {
        push @{$self->data->{errors}}, "$error";
        return;
    }

    sub _websocket_engine_closing ($self) {
        $self->data->{closing} = 1;
        return;
    }

    sub _websocket_engine_close ($self, $code, $reason) {
        $self->data->{close} = [ $code, $reason ];
        return;
    }

}

Linux::Event::Framer->declare_native_consumer(
    'Linux::Event::WebSocket::_RawABITestConnection',
    Linux::Event::WebSocket::_BQ->raw_consumer_definition,
);

socketpair(my $socket, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $loop = Linux::Event::Loop->new;
my $state = {
    events   => [],
    errors   => [],
    expected => 2,
};

my $stream = Linux::Event::WebSocket::_RawABITestConnection->new(
    loop => $loop,
    fh   => $socket,
    data => $state,
);

my $text = Linux::Event::WebSocket::_Frame->encode(
    text => 'hello raw ABI',
    masked   => 1,
    mask_key => "\x01\x02\x03\x04",
);
my $binary = Linux::Event::WebSocket::_Frame->encode(
    binary => "\x00\x01\xff\x7f",
    masked   => 1,
    mask_key => "\x05\x06\x07\x08",
);

my $split = int(length($text) / 2);
syswrite($peer, substr($text, 0, $split))
    == $split or die "first syswrite: $!";

my $finish = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 0,
    on_timer => sub ($timer) {
        my $tail = substr($text, $split) . $binary;
        syswrite($peer, $tail) == length($tail)
            or die "second syswrite: $!";
        return;
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "raw-buffer ABI test timed out\n";
    },
);

$loop->run;
$guard->cancel;
$finish->cancel;

is_deeply(
    $state->{errors},
    [],
    'raw native consumer reports no bq errors',
);
is_deeply(
    $state->{events},
    [
        [ text   => 'hello raw ABI' ],
        [ binary => "\x00\x01\xff\x7f" ],
    ],
    'raw native consumer enters the normal Engine message path',
);

is(
    refaddr($state->{provider_native}),
    refaddr($state->{engine_native}),
    'raw consumer and Engine share one bq native state object',
);

ok(
    !$stream->can('on_data'),
    'raw ABI fixture has no Perl on_data receive callback',
);

$stream->close if !$stream->is_closed;
close $peer;

socketpair(my $control_socket, my $control_peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "control socketpair: $!";

my $control_loop = Linux::Event::Loop->new;
my $control_state = {
    events   => [],
    errors   => [],
    expected => 0,
};

my $control_stream = Linux::Event::WebSocket::_RawABITestConnection->new(
    loop => $control_loop,
    fh   => $control_socket,
    data => $control_state,
);

my $server_output = Linux::Event::WebSocket::_Parser->new(
    endpoint_type  => 'client',
    max_frame_size => 1024,
);
my @control_frame;
my $close_sent = 0;

my $control_guard = Linux::Event::Kernel::Timer->new(
    loop => $control_loop,
    after => 2,
    on_timer => sub ($timer) {
        die "raw control-frame ABI test timed out\n";
    },
);

my $peer_reader;
$peer_reader = $control_loop->watch_fd(
    fileno($control_peer),
    fh => $control_peer,
    read => sub ($watcher) {
        my $read = sysread($control_peer, my $bytes, 4096);
        die "control peer read: $!" if !defined $read;
        return if !$read;

        $server_output->feed($bytes);
        while (my $frame = $server_output->next_frame) {
            push @control_frame, $frame;

            if ($frame->{type} eq 'pong' && !$close_sent) {
                $close_sent = 1;
                my $payload =
                    Linux::Event::WebSocket::_Frame->close_payload(1000, 'done');
                my $close = Linux::Event::WebSocket::_Frame->encode(
                    close => $payload,
                    masked   => 1,
                    mask_key => "\x11\x12\x13\x14",
                );
                syswrite($control_peer, $close) == length($close)
                    or die "control close write: $!";
            }

            if ($frame->{type} eq 'close') {
                $control_guard->cancel;
                $control_loop->stop;
            }
        }
        return;
    },
);

my $ping = Linux::Event::WebSocket::_Frame->encode(
    ping => 'probe',
    masked   => 1,
    mask_key => "\x21\x22\x23\x24",
);
syswrite($control_peer, $ping) == length($ping)
    or die "control ping write: $!";

$control_loop->run;

is_deeply(
    $control_state->{errors},
    [],
    'raw control path reports no errors',
);

my ($pong) = grep { $_->{type} eq 'pong' } @control_frame;
ok($pong, 'raw control path writes Pong');
is($pong->{payload}, 'probe', 'raw Pong preserves Ping payload');

my ($close_frame) = grep { $_->{type} eq 'close' } @control_frame;
ok($close_frame, 'raw control path writes Close response');
my ($close_code, $close_reason) =
    Linux::Event::WebSocket::_Frame->parse_close_payload($close_frame->{payload});
is($close_code, 1000, 'raw Close response preserves status code');
is($close_reason, 'done', 'raw Close response preserves reason');

ok($control_state->{closing}, 'raw Close enters WebSocket closing state');
is_deeply(
    $control_state->{close},
    [ 1000, 'done' ],
    'raw Close reaches normal Engine close lifecycle',
);

$peer_reader->cancel;
$control_stream->close if !$control_stream->is_closed;
close $control_peer;

done_testing;
