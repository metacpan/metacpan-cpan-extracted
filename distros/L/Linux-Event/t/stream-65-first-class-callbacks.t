use v5.36;
use strict;
use warnings;

use Scalar::Util qw(weaken);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);
use Test::More;

use Linux::Event::Loop;
use Linux::Event::IO::Pipe;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::_ByteStream ();

{
    package T::Callbacks::RawMethod;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_size => 4 }
    sub on_data ($stream, $bytes) { $stream->data->{method} .= $bytes }
}

{
    package T::Callbacks::RawOther;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_size => 4 }
    sub on_data ($stream, $bytes) { $stream->data->{other} .= $bytes }
}

{
    package T::Callbacks::RawMissing;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_size => 4 }
}

{
    package T::Callbacks::LineMethod;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($stream, $message) {
        push @{ $stream->data->{method} }, $message;
    }
}

{
    package T::Callbacks::LineOther;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 3;
    sub on_message ($stream, $message) {
        push @{ $stream->data->{other} }, $message;
    }
}

{
    package T::Callbacks::LineMissing;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
}

{
    package T::Callbacks::BatchMissing;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
}

{
    package T::Callbacks::Limited;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 32, low_watermark => 16,
            max_pending_bytes => 64;
    }
}

{
    package T::Callbacks::Drain;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
}

{
    package T::Callbacks::ConsumerBase;
    use parent 'Linux::Event::IO::Sock::Stream';
    BEGIN {
        Linux::Event::_ByteStream->_declare_consumer(
            __PACKAGE__,
            Linux::Event::_ByteStream::TestSupport->_test_consumer_definition,
        );
    }
}

{
    package T::Callbacks::ConsumerLine;
    use parent -norequire, 'T::Callbacks::ConsumerBase';
    use Linux::Event::Framer 'Delimiter', "\n";
}

sub socket_pair () {
    socketpair(my $stream_fh, my $peer_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    return ($stream_fh, $peer_fh);
}

sub pump_until ($loop, $condition) {
    for (1 .. 40) {
        return 1 if $condition->();
        $loop->run_once(0.05);
    }
    return $condition->() ? 1 : 0;
}

sub construction_error ($class, @option) {
    my ($stream_fh, $peer_fh) = socket_pair();
    my $made = eval { $class->new(fh => $stream_fh, @option); 1 };
    my $error = $@;
    close $stream_fh if defined fileno($stream_fh);
    close $peer_fh;
    return ($made, $error);
}

subtest 'raw constructor callback is the effective native CV' => sub {
    my ($stream_fh, $peer_fh) = socket_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { method => '', closure => '', captures => [] };
    my $scope = 'lexical';
    my $callback = sub ($stream, $bytes) {
        $stream->data->{closure} .= $bytes;
        push @{ $stream->data->{captures} }, $scope;
    };
    my $weak = $callback;
    weaken($weak);
    my $stream = T::Callbacks::RawMethod->new(
        loop => $loop, fh => $stream_fh, data => $state,
        on_data => $callback,
    );
    undef $callback;
    ok(defined($weak), 'native state retains the closure');
    is(syswrite($peer_fh, 'abcdefgh'), 8, 'peer writes raw bytes');
    ok(pump_until($loop, sub { length($state->{closure}) == 8 }),
        'constructor callback receives raw native delivery');
    is($state->{closure}, 'abcdefgh', 'constructor callback receives all bytes');
    is($state->{method}, '', 'constructor callback overrides class method');
    is_deeply($state->{captures}, ['lexical', 'lexical'],
        'captured lexical remains available for every read');

    $stream->transition_to('T::Callbacks::RawOther', input => 'ijkl');
    is($state->{closure}, 'abcdefghijkl',
        'raw instance callback survives descriptor transition');
    is($state->{other} // '', '', 'target class method remains overridden');
    $stream->close;
    undef $stream;
    ok(!defined($weak), 'close releases the native callback CV');
    close $peer_fh;
};

subtest 'methodless raw and framed classes accept closures' => sub {
    my ($raw_fh, $raw_peer) = socket_pair();
    my $raw_loop = Linux::Event::Loop->new;
    my $raw_bytes = '';
    my $raw = T::Callbacks::RawMissing->new(
        loop => $raw_loop, fh => $raw_fh,
        on_data => sub ($stream, $bytes) { $raw_bytes .= $bytes },
    );
    syswrite($raw_peer, 'raw!');
    ok(pump_until($raw_loop, sub { length($raw_bytes) == 4 }),
        'methodless raw class uses constructor callback');
    is($raw_bytes, 'raw!', 'raw closure receives payload');
    $raw->close;
    close $raw_peer;

    my ($line_fh, $line_peer) = socket_pair();
    my $line_loop = Linux::Event::Loop->new;
    my @message;
    my $line = T::Callbacks::LineMissing->new(
        loop => $line_loop, fh => $line_fh,
        on_message => sub ($stream, $value) { push @message, $value },
    );
    syswrite($line_peer, "one\ntwo\n");
    ok(pump_until($line_loop, sub { @message == 2 }),
        'methodless framed class uses constructor callback');
    is_deeply(\@message, [qw(one two)], 'framed closure receives messages');
    $line->close;
    close $line_peer;
};

subtest 'framed and batched callbacks retain native semantics' => sub {
    my ($line_fh, $line_peer) = socket_pair();
    my $line_loop = Linux::Event::Loop->new;
    my $state = { method => [], closure => [], other => [] };
    my $line = T::Callbacks::LineMethod->new(
        loop => $line_loop, fh => $line_fh, data => $state,
        on_message => sub ($stream, $message) {
            push @{ $stream->data->{closure} }, $message;
        },
    );
    syswrite($line_peer, "one\n");
    ok(pump_until($line_loop, sub { @{ $state->{closure} } }),
        'framed constructor callback runs');
    is_deeply($state->{method}, [], 'framed class method is overridden');
    $line->transition_to('T::Callbacks::LineOther', input => 'abc');
    is_deeply($state->{closure}, [qw(one abc)],
        'framed callback survives compatible transition');
    is_deeply($state->{other}, [], 'transition target remains overridden');
    $line->close;
    close $line_peer;

    my ($batch_fh, $batch_peer) = socket_pair();
    my $batch_loop = Linux::Event::Loop->new;
    my @batch;
    my $batched = T::Callbacks::BatchMissing->new(
        loop => $batch_loop, fh => $batch_fh,
        on_messages => sub ($stream, $messages) { push @batch, [@$messages] },
    );
    syswrite($batch_peer, 'a|b|');
    ok(pump_until($batch_loop, sub { @batch }),
        'methodless batch class uses constructor callback');
    is_deeply(\@batch, [[qw(a b)]], 'on_messages retains batch signature');
    $batched->close;
    close $batch_peer;
};

subtest 'lifecycle constructor callbacks override class policy and release' => sub {
    my ($stream_fh, $peer_fh) = socket_pair();
    my $loop = Linux::Event::Loop->new;
    my @event;
    my $token = 'scope';
    my $close = sub ($stream) { push @event, "close:$token" };
    my $weak_close = $close;
    weaken($weak_close);
    my $stream = T::Callbacks::RawMissing->new(
        loop => $loop, fh => $stream_fh,
        on_data => sub { },
        on_ready => sub ($object) { push @event, 'ready' },
        on_transport_ready => sub ($object) { push @event, 'transport' },
        on_eof => sub ($object) { push @event, 'eof' },
        on_close => $close,
    );
    undef $close;
    $stream->_xs_transport_event(0, 'read', '');
    is_deeply(\@event, [qw(transport ready)],
        'transport and application readiness use effective callbacks');
    close $peer_fh;
    ok(pump_until($loop, sub { grep { $_ eq 'eof' } @event }),
        'EOF uses constructor callback');
    $stream->close;
    is_deeply(\@event, [qw(transport ready eof), 'close:scope'],
        'close uses constructor callback exactly once');
    ok(!defined($weak_close), 'close releases lifecycle callback closure');
};

subtest 'constructor on_drain is wired only when requested' => sub {
    my ($writer_fh, $reader_fh) = socket_pair();
    setsockopt($writer_fh, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt SO_SNDBUF: $!";
    my $loop = Linux::Event::Loop->new;
    my $received = 0;
    my $drained = 0;
    my $payload = 'x' x (512 * 1024);
    my $reader = Linux::Event::IO::Sock::Stream->new(
        loop => $loop, fh => $reader_fh,
        on_data => sub ($stream, $bytes) {
            $received += length($bytes);
            $loop->stop if $received == length($payload) && $drained;
        },
    );
    my $writer = T::Callbacks::Drain->new(
        loop => $loop, fh => $writer_fh,
        on_data => sub { },
        on_drain => sub ($stream) {
            $drained++;
            $loop->stop if $received == length($payload);
        },
    );
    ok(!$writer->write($payload), 'large write enters backpressure');
    $loop->run;
    is($received, length($payload), 'reader receives queued output');
    is($drained, 1, 'constructor on_drain fires once');
    $writer->close;
    $reader->close;
};

subtest 'constructor on_error participates in terminal cleanup' => sub {
    my ($stream_fh, $peer_fh) = socket_pair();
    setsockopt($stream_fh, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt SO_SNDBUF: $!";
    my ($reported, $closed);
    my $stream = T::Callbacks::Limited->new(
        fh => $stream_fh,
        on_data => sub { },
        on_error => sub ($object, $error) { $reported = $error },
        on_close => sub ($object) { $closed++ },
    );
    ok(!$stream->write('x' x (2 * 1024 * 1024)),
        'output limit rejects oversized write');
    isa_ok($reported, 'Linux::Event::Error');
    is($reported && $reported->type, 'output_limit',
        'constructor on_error receives error');
    is($closed, 1, 'constructor on_close follows error exactly once');
    ok($stream->is_closed, 'error leaves Stream closed');
    close $peer_fh;
};

subtest 'Pipe shares the ordered-byte constructor surface' => sub {
    pipe(my $read_fh, my $write_fh) or die "pipe: $!";
    my $loop = Linux::Event::Loop->new;
    my $bytes = '';
    my $pipe = Linux::Event::IO::Pipe->new(
        loop => $loop, read_fh => $read_fh,
        on_data => sub ($stream, $chunk) { $bytes .= $chunk },
    );
    syswrite($write_fh, 'pipe');
    ok(pump_until($loop, sub { length($bytes) == 4 }),
        'generic Pipe receives constructor on_data');
    is($bytes, 'pipe', 'Pipe callback receives bytes');
    $pipe->close;
    close $write_fh;
};

subtest 'pending connect failure releases constructor callbacks' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($reported, $closed);
    my $scope = 'pending';
    my $callback = sub ($stream, $bytes) { return "$scope:$bytes" };
    my $weak = $callback;
    weaken($weak);
    my $stream = Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        sockaddr => '', family => 9999, timeout => 1,
        on_data => $callback,
        on_error => sub ($object, $error) {
            $reported = $error;
            $loop->stop;
        },
        on_close => sub ($object) { $closed++ },
    );
    undef $callback;
    ok(defined($weak), 'pending Stream retains callback before native state');
    $loop->run;
    isa_ok($reported, 'Linux::Event::Error');
    is($closed, 1, 'connect failure performs constructor close callback');
    ok($stream->is_closed, 'failed connection is terminal');
    ok(!defined($weak), 'connect failure releases pending input callback');
};

subtest 'detach releases callbacks without firing on_close' => sub {
    my ($stream_fh, $peer_fh) = socket_pair();
    my $closed = 0;
    my $scope = 'detach';
    my $callback = sub ($stream, $bytes) { return "$scope:$bytes" };
    my $weak = $callback;
    weaken($weak);
    my $stream = T::Callbacks::RawMissing->new(
        fh => $stream_fh,
        on_data => $callback,
        on_close => sub ($object) { $closed++ },
    );
    undef $callback;
    my $detached = $stream->detach;
    ok(!defined($weak), 'detach releases native callback CV');
    is($closed, 0, 'detach suppresses on_close');
    close $detached;
    close $peer_fh;
};

subtest 'failed pre-state construction does not retain callbacks' => sub {
    pipe(my $read_fh, my $write_fh) or die "pipe: $!";
    my $scope = 'failed';
    my $callback = sub ($stream, $bytes) { return "$scope:$bytes" };
    my $weak = $callback;
    weaken($weak);
    my $made = eval {
        T::Callbacks::RawMissing->new(fh => $read_fh, on_data => $callback);
        1;
    };
    my $error = $@;
    undef $callback;
    ok(!$made, 'non-socket handle fails Socket construction');
    like($error, qr/not a socket/, 'failure occurs before native Stream state');
    ok(!defined($weak), 'failed construction releases callback');
    close $read_fh if defined fileno($read_fh);
    close $write_fh;
};

subtest 'invalid and incompatible callbacks fail during setup' => sub {
    my ($made, $error) = construction_error(
        'T::Callbacks::RawMissing', on_data => undef,
    );
    ok(!$made, 'undef callback is rejected');
    like($error, qr/on_data must be a coderef/, 'undef diagnostic names callback');

    ($made, $error) = construction_error(
        'T::Callbacks::RawMissing', on_message => sub { },
    );
    ok(!$made, 'raw class rejects on_message');
    like($error, qr/on_message requires a framed/, 'raw mismatch is clear');

    ($made, $error) = construction_error(
        'T::Callbacks::LineMissing', on_data => sub { },
    );
    ok(!$made, 'framed class rejects on_data');
    like($error, qr/on_data requires a raw/, 'framed mismatch is clear');

    ($made, $error) = construction_error(
        'T::Callbacks::BatchMissing', on_message => sub { },
    );
    ok(!$made, 'batching class rejects on_message');
    like($error, qr/on_message cannot be combined with message_batch_size/,
        'batch mismatch is clear');

    ($made, $error) = construction_error(
        'T::Callbacks::LineMissing', on_messages => sub { },
    );
    ok(!$made, 'ordinary framing rejects on_messages');
    like($error, qr/on_messages requires message_batch_size/,
        'unbatched mismatch is clear');

    ($made, $error) = construction_error(
        'T::Callbacks::ConsumerLine', on_message => sub { },
    );
    ok(!$made, 'native consumer rejects message closure');
    like($error, qr/on_message cannot be combined with a native consumer/,
        'native consumer mismatch is clear');
};

done_testing;
