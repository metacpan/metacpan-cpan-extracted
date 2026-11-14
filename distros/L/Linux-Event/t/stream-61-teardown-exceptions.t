use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::_ByteStream;

{
    package T::EventCroakBase;
    use parent 'Linux::Event::_ByteStream';
    BEGIN {
        Linux::Event::_ByteStream->_declare_consumer(
            __PACKAGE__,
            Linux::Event::_ByteStream::TestSupport->_test_consumer_definition('event-croak'),
        );
    }
    sub on_close ($stream) { $stream->data->{close_calls}++ }
}

{
    package T::EventCroakLine;
    use parent -norequire, 'T::EventCroakBase';
    use Linux::Event::Framer 'Delimiter', "\n";
}

{
    package T::FlushErrorBase;
    use parent 'Linux::Event::_ByteStream';
    BEGIN {
        Linux::Event::_ByteStream->_declare_consumer(
            __PACKAGE__,
            Linux::Event::_ByteStream::TestSupport->_test_consumer_definition('flush-error'),
        );
    }
    sub on_close ($stream) { $stream->data->{close_calls}++ }
}

{
    package T::FlushErrorLine;
    use parent -norequire, 'T::FlushErrorBase';
    use Linux::Event::Framer 'Delimiter', "\n";
}

{
    package T::CloseCroak;
    use parent 'Linux::Event::_ByteStream';
    sub on_data ($stream, $bytes) { return }
    sub on_close ($stream) {
        $stream->data->{close_calls}++;
        die "synthetic on_close exception\n";
    }
}

{
    package T::UnwindMessageBase;
    use parent 'Linux::Event::_ByteStream';
    BEGIN {
        Linux::Event::_ByteStream->_declare_consumer(
            __PACKAGE__,
            Linux::Event::_ByteStream::TestSupport->_test_consumer_definition,
        );
    }
    sub on_close ($stream) { $stream->data->{close_calls}++ }
}

{
    package T::UnwindMessageLine;
    use parent -norequire, 'T::UnwindMessageBase';
    use Linux::Event::Framer 'Delimiter', "\n";
}

{
    package T::UnwindRaw;
    use parent 'Linux::Event::_ByteStream';
    BEGIN {
        Linux::Event::_ByteStream->_declare_consumer(
            __PACKAGE__,
            Linux::Event::_ByteStream::TestSupport->_test_consumer_definition('raw-input'),
        );
    }
    sub on_close ($stream) { $stream->data->{close_calls}++ }
}

sub socket_stream ($class) {
    socketpair(my $stream_fh, my $peer_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { close_calls => 0 };
    my $stream = $class->new(
        loop => $loop, fh => $stream_fh, data => $data,
    );
    return ($loop, $stream, $peer_fh, $stream_fh, $data);
}

sub split_stream ($class) {
    pipe(my $read_fh, my $read_peer) or die "read pipe: $!";
    pipe(my $write_peer, my $write_fh) or die "write pipe: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { close_calls => 0 };
    my $stream = $class->new(
        loop => $loop,
        read_fh => $read_fh,
        write_fh => $write_fh,
        data => $data,
    );
    return ($loop, $stream, $read_peer, $write_peer,
        $read_fh, $write_fh, $data);
}

sub assert_full_cleanup ($loop, $stream, $stream_fh, $data, $label) {
    ok($stream->is_closed, "$label leaves Stream terminal");
    is($stream->state, 'closed', "$label leaves the closed state visible");
    ok(!defined($stream->{xs_state}), "$label releases native state");
    ok(!defined(fileno($stream_fh)), "$label closes the owned descriptor");
    is($loop->resources->{registered_fds}, 0,
        "$label removes the epoll registration");
    is($data->{close_calls}, 1, "$label still invokes on_close exactly once");
}

subtest 'terminal event exception cannot interrupt full close teardown' => sub {
    my ($loop, $stream, $peer, $stream_fh, $data)
        = socket_stream('T::EventCroakLine');
    my $ok = eval { $stream->close; 1 };
    ok(!$ok, 'close propagates the terminal provider exception');
    like($@, qr/synthetic consumer event exception/,
        'close preserves the provider diagnostic');
    assert_full_cleanup($loop, $stream, $stream_fh, $data, 'close');
    close $peer;
};

subtest 'terminal flush error cannot interrupt full close teardown' => sub {
    my ($loop, $stream, $peer, $stream_fh, $data)
        = socket_stream('T::FlushErrorLine');
    $stream->{xs_state}->_test_consumer_arm(sub { $stream->close });
    syswrite($peer, "message\n") == 8 or die "syswrite: $!";
    my $ok = eval { $loop->run_for(0.05); 1 };
    ok(!$ok, 'reentrant close propagates terminal flush ERROR');
    like($@, qr/reported an error from terminal flush/,
        'terminal flush error preserves its diagnostic');
    assert_full_cleanup($loop, $stream, $stream_fh, $data,
        'terminal flush failure');
    close $peer;
};

subtest 'close_read completes directional cleanup after event exception' => sub {
    my ($loop, $stream, $read_peer, $write_peer,
        $read_fh, $write_fh, $data) = split_stream('T::EventCroakLine');
    my $ok = eval { $stream->close_read; 1 };
    ok(!$ok, 'close_read propagates the terminal provider exception');
    like($@, qr/synthetic consumer event exception/,
        'close_read preserves the provider diagnostic');
    ok($stream->is_read_closed, 'read direction reaches terminal state');
    ok(!$stream->is_closed, 'write direction remains active');
    ok(!defined($stream->{read_watcher}), 'read watcher is released');
    ok(!defined(fileno($read_fh)), 'owned read descriptor is closed');
    ok(defined(fileno($write_fh)), 'owned write descriptor remains open');
    is($loop->resources->{registered_fds}, 1,
        'only the write registration remains');
    is($data->{close_calls}, 0, 'directional close does not invoke on_close');
    $stream->close;
    close $read_peer;
    close $write_peer;
};

subtest 'close_read completes directional cleanup after flush error' => sub {
    my ($loop, $stream, $read_peer, $write_peer,
        $read_fh, $write_fh, $data) = split_stream('T::FlushErrorLine');
    $stream->{xs_state}->_test_consumer_arm(sub { $stream->close_read });
    syswrite($read_peer, "message\n") == 8 or die "syswrite: $!";
    my $ok = eval { $loop->run_for(0.05); 1 };
    ok(!$ok, 'close_read propagates terminal flush ERROR');
    like($@, qr/reported an error from terminal flush/,
        'close_read preserves the flush diagnostic');
    ok($stream->is_read_closed, 'read direction reaches terminal state');
    ok(!defined($stream->{read_watcher}), 'read watcher is released');
    ok(!defined(fileno($read_fh)), 'owned read descriptor is closed');
    ok(defined(fileno($write_fh)), 'write descriptor remains open');
    is($loop->resources->{registered_fds}, 1,
        'only the write registration remains after flush failure');
    $stream->close;
    close $read_peer;
    close $write_peer;
};

subtest 'failed detach closes unreturned handles deterministically' => sub {
    my ($loop, $stream, $peer, $stream_fh, $data)
        = socket_stream('T::EventCroakLine');
    my $ok = eval { $stream->detach; 1 };
    ok(!$ok, 'detach propagates the terminal provider exception');
    like($@, qr/synthetic consumer event exception/,
        'detach preserves the provider diagnostic');
    ok($stream->is_closed, 'failed detach leaves Stream terminal');
    is($stream->state, 'detached', 'failed detach records detached state');
    ok(!defined($stream->{xs_state}), 'failed detach releases native state');
    ok(!defined(fileno($stream_fh)),
        'failed detach closes the handle that could not be returned');
    is($loop->resources->{registered_fds}, 0,
        'failed detach removes the epoll registration');
    is($data->{close_calls}, 0, 'detach does not invoke on_close');
    close $peer;
};

subtest 'close_write transitive full close is exception-safe' => sub {
    my ($loop, $stream, $peer, $stream_fh, $data)
        = socket_stream('T::EventCroakLine');
    $stream->{read_closed} = 1;
    my $ok = eval { $stream->close_write; 1 };
    ok(!$ok, 'close_write propagates failure from transitive full close');
    like($@, qr/synthetic consumer event exception/,
        'close_write preserves the provider diagnostic');
    assert_full_cleanup($loop, $stream, $stream_fh, $data,
        'close_write transitive close');
    close $peer;
};

subtest 'on_close exception occurs after ownership teardown' => sub {
    my ($loop, $stream, $peer, $stream_fh, $data)
        = socket_stream('T::CloseCroak');
    my $ok = eval { $stream->close; 1 };
    ok(!$ok, 'on_close exception propagates');
    like($@, qr/synthetic on_close exception/,
        'on_close diagnostic is preserved');
    assert_full_cleanup($loop, $stream, $stream_fh, $data,
        'on_close failure');
    close $peer;
};

for my $case (
    ['framed message', 'T::UnwindMessageLine', "message\n"],
    ['raw input',      'T::UnwindRaw',         "message\n"],
) {
    my ($kind, $class, $payload) = @$case;

    subtest "$kind callback exception clears pending flush while Stream lives" => sub {
        my ($loop, $stream, $peer, $fh, $data) = socket_stream($class);
        $stream->{xs_state}->_test_consumer_arm(sub {
            die "synthetic $kind callback exception\n";
        });
        is(syswrite($peer, $payload), length($payload),
            "$kind input submitted");
        my $ok = eval { $loop->run_for(0.05); 1 };
        ok(!$ok, "$kind exception propagates");
        like($@, qr/synthetic .* callback exception/,
            "$kind original diagnostic is preserved");
        is($stream->{xs_state}->stats->{consumer_flush_pending}, 0,
            "$kind incomplete flush marker is cleared");
        $stream->close;
        close $peer;
    };

    subtest "$kind close and exception release final Stream ownership" => sub {
        my ($loop, $stream, $peer, $fh, $data) = socket_stream($class);
        my $weak = $stream;
        Scalar::Util::weaken($weak);
        my $before =
            Linux::Event::_ByteStream::TestSupport->_test_consumer_destroy_count;
        $stream->{xs_state}->_test_consumer_arm(sub {
            my $closing = $stream;
            undef $stream;
            $closing->close;
            die "synthetic $kind close exception\n";
        });
        is(syswrite($peer, $payload), length($payload),
            "$kind input submitted");
        my $ok = eval { $loop->run_for(0.05); 1 };
        ok(!$ok, "$kind close exception propagates");
        like($@, qr/synthetic .* close exception/,
            "$kind original close diagnostic is preserved");
        is($loop->resources->{registered_fds}, 0,
            "$kind releases the Loop registration");
        ok(!defined(fileno($fh)), "$kind closes the owned descriptor");
        is($data->{close_calls}, 1, "$kind invokes on_close once");
        ok(!defined($weak), "$kind drops the final Stream reference");
        cmp_ok(
            Linux::Event::_ByteStream::TestSupport->_test_consumer_destroy_count,
            '>', $before, "$kind destroys the native consumer"
        );
        close $peer;
    };
}

done_testing;
