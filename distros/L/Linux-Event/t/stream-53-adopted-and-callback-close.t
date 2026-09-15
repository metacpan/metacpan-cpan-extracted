use v5.36;
use strict;
use warnings;
use Test::More;
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Framer ();

{
    package T::CloseOnData;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->data->{data}++;
        $stream->close;
    }
    sub on_close ($stream) { $stream->data->{close}++ }
}

{
    package T::CloseOnReady;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    sub on_ready ($stream) {
        $stream->data->{ready}++;
        $stream->close;
    }
    sub on_close ($stream) { $stream->data->{close}++ }
}

{
    package T::ReadySink;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
}

{
    package T::CloseOnMessage;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($stream, $message) {
        push @{ $stream->data->{messages} }, $message;
        $stream->close;
    }
    sub on_close ($stream) { $stream->data->{close}++ }
}

{
    package T::CloseOnEof;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    sub on_eof ($stream) {
        $stream->data->{eof}++;
        $stream->close;
    }
    sub on_close ($stream) { $stream->data->{close}++ }
}

{
    package T::CloseOnDrain;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($stream, $bytes) { return }
    sub on_drain ($stream) {
        $stream->data->{drain}++;
        $stream->close;
    }
    sub on_close ($stream) {
        $stream->data->{close}++;
        $stream->data->{loop}->stop;
    }
}

{
    package T::CloseOnError;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n", max_frame => 4;
    sub on_message ($stream, $message) { return }
    sub on_error ($stream, $error) {
        $stream->data->{error}++;
        $stream->close;
    }
    sub on_close ($stream) { $stream->data->{close}++ }
}

{
    package T::DrainReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->data->{received} += length($bytes);
    }
}

sub stream_pair ($class, $state) {
    socketpair(my $stream_fh, my $peer_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $stream = $class->new(
        loop => $loop, fh => $stream_fh, data => $state,
    );
    return ($loop, $stream, $peer_fh);
}

subtest 'adopted descriptor is close-on-exec' => sub {
    socketpair(my $stream_fh, my $peer_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    my $flags = fcntl($stream_fh, F_GETFD, 0);
    fcntl($stream_fh, F_SETFD, $flags & ~FD_CLOEXEC)
        or die "clear FD_CLOEXEC: $!";

    my $loop = Linux::Event::Loop->new;
    my $stream = T::CloseOnData->new(
        loop => $loop, fh => $stream_fh, data => { data => 0, close => 0 },
    );
    my $prepared = fcntl($stream->fh, F_GETFD, 0);
    ok($prepared & FD_CLOEXEC,
        'Stream prepares adopted descriptor with FD_CLOEXEC');
    $stream->close;
    close $peer_fh;
};

subtest 'close inside raw data callback stops dispatch safely' => sub {
    my $state = { data => 0, close => 0 };
    my ($loop, $stream, $peer) = stream_pair('T::CloseOnData', $state);
    syswrite($peer, 'payload');
    $loop->run_once(100);
    is($state->{data}, 1, 'raw callback runs once');
    is($state->{close}, 1, 'raw callback closes exactly once');
    close $peer;
};

subtest 'close inside ready callback is safe' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { ready => 0, close => 0 };
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop, stream => { class => 'T::ReadySink' },
        host => '127.0.0.1', port => 0,
    );
    my $stream = T::CloseOnReady->connect(
        loop => $loop, host => '127.0.0.1', port => $listener->port,
        timeout => 1, data => $state,
    );
    $loop->run_for(0.25);
    is($state->{ready}, 1, 'ready callback runs once');
    is($state->{close}, 1, 'ready callback closes exactly once');
    ok($stream->is_closed, 'Stream is terminal after ready callback');
    $listener->close;
};

subtest 'close inside framed callback stops remaining messages' => sub {
    my $state = { messages => [], close => 0 };
    my ($loop, $stream, $peer) = stream_pair('T::CloseOnMessage', $state);
    syswrite($peer, "first\nsecond\n");
    $loop->run_once(100);
    is_deeply($state->{messages}, ['first'],
        'no later frame is dispatched after callback closes Stream');
    is($state->{close}, 1, 'framed callback closes exactly once');
    close $peer;
};

subtest 'close inside EOF callback is idempotent' => sub {
    my $state = { eof => 0, close => 0 };
    my ($loop, $stream, $peer) = stream_pair('T::CloseOnEof', $state);
    close $peer;
    $loop->run_once(100);
    is($state->{eof}, 1, 'EOF callback runs once');
    is($state->{close}, 1, 'EOF callback closes exactly once');
};

subtest 'close inside error callback is idempotent' => sub {
    my $state = { error => 0, close => 0 };
    my ($loop, $stream, $peer) = stream_pair('T::CloseOnError', $state);
    syswrite($peer, 'oversized');
    $loop->run_once(100);
    is($state->{error}, 1, 'error callback runs once');
    is($state->{close}, 1, 'error callback closes exactly once');
    ok($stream->is_closed, 'Stream remains terminal after error cleanup');
    close $peer;
};

subtest 'close inside drain callback is safe' => sub {
    socketpair(my $writer_fh, my $reader_fh,
        AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    setsockopt($writer_fh, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt SO_SNDBUF: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop, drain => 0, close => 0, received => 0 };
    my $reader = T::DrainReader->new(
        loop => $loop, fh => $reader_fh, data => $state,
    );
    my $writer = T::CloseOnDrain->new(
        loop => $loop, fh => $writer_fh, data => $state,
    );
    ok(!$writer->write('x' x (2 * 1024 * 1024)),
        'test establishes a blocked writer');
    $loop->run_for(1);
    is($state->{drain}, 1, 'drain callback runs once');
    is($state->{close}, 1, 'drain callback closes exactly once');
    $reader->close;
};

done_testing;
