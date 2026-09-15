use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(
    AF_INET AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF
    inet_aton pack_sockaddr_in
);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;

{
    package T::RecipeTuneStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub stream_tuning ($class) {
        return (
            read_size         => 64,
            read_budget_bytes => 111,
            idle_timeout      => 7,
        );
    }

    sub on_data ($stream, $bytes) { return }
}

{
    package T::LiveRawStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_data ($stream, $bytes) {
        $stream->data->{bytes} .= $bytes;
        return;
    }

    sub on_error ($stream, $error) {
        $stream->data->{error} = $error;
        return;
    }

    sub on_drain ($stream) {
        $stream->data->{drains}++;
        return;
    }
}

{
    package T::LiveFramedStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub on_message ($stream, $message) {
        push @{ $stream->data->{messages} }, $message;
        return;
    }

    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
        return;
    }

    sub on_error ($stream, $error) {
        $stream->data->{error} = $error;
        return;
    }
}

sub socket_pair () {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    return ($left, $right);
}

sub constrained_pair () {
    my ($left, $right) = socket_pair();
    setsockopt($left, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt SO_SNDBUF: $!";
    return ($left, $right);
}

subtest 'class, Listener, and live tuning precedence' => sub {
    my $loop = Linux::Event::Loop->new;
    my $accepted;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            class => 'T::RecipeTuneStream',
            tuning => {
                read_budget_bytes => 222,
                idle_timeout      => 3,
            },
        },
        on_accept => sub ($listener, $stream) {
            $accepted = $stream;
            $loop->stop;
        },
    );

    socket(my $client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
    connect($client,
        pack_sockaddr_in($listener->port, inet_aton('127.0.0.1')))
        or die "connect: $!";
    $loop->run;

    isa_ok($accepted, 'T::RecipeTuneStream');
    is($accepted->{xs_state}->stats->{read_budget_bytes}, 222,
        'Listener recipe overrides class read budget before accept');
    is($accepted->idle_timeout, 3,
        'Listener recipe overrides class timeout before accept');

    is($accepted->tune(read_budget_bytes => 333, idle_timeout => 1),
        $accepted, 'tune returns the Stream');
    is($accepted->{xs_state}->stats->{read_budget_bytes}, 333,
        'live tuning replaces Listener read budget in native state');
    is($accepted->idle_timeout, 1,
        'live tuning replaces Listener timeout');

    $accepted->close;
    $listener->close;
    close $client;
};

subtest 'ordinary live tuning preserves raw input callback' => sub {
    my ($left, $right) = socket_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { bytes => '', drains => 0 };
    my $stream = T::LiveRawStream->new(
        loop => $loop, fh => $left, data => $state,
    );

    $stream->tune(
        read_size         => 2,
        read_budget_bytes => 7,
        read_batch_bytes  => 0,
    );
    is($stream->{xs_state}->stats->{read_budget_bytes}, 7,
        'native read budget changes without callback replacement');

    is(syswrite($right, 'abcdef'), 6, 'peer writes raw tuning payload');
    $loop->run_once(100);
    is($state->{bytes}, 'abcdef',
        'existing on_data callback remains active after tuning');
    cmp_ok($stream->{xs_state}->stats->{read_calls}, '>=', 3,
        'new read_size is used by the native read engine');

    $stream->close;
    close $right;
};

subtest 'message batching can change callback mode live' => sub {
    my ($left, $right) = socket_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { messages => [], batches => [] };
    my $stream = T::LiveFramedStream->new(
        loop => $loop, fh => $left, data => $state,
    );

    syswrite($right, "one\n") == 4 or die "syswrite: $!";
    $loop->run_once(100);
    is_deeply($state->{messages}, ['one'],
        'unbatched mode uses on_message');

    $stream->tune(message_batch_size => 2);
    is($stream->{xs_state}->stats->{message_batch_size}, 2,
        'native message batch size changes live');
    syswrite($right, "two\nthree\n") == 10 or die "syswrite: $!";
    $loop->run_once(100);
    is_deeply($state->{batches}, [[qw(two three)]],
        'batched mode switches to on_messages');

    $stream->tune(message_batch_size => 0);
    syswrite($right, "four\n") == 5 or die "syswrite: $!";
    $loop->run_once(100);
    is_deeply($state->{messages}, [qw(one four)],
        'disabling batching restores on_message');

    $stream->close;
    close $right;
};

subtest 'watermarks reconcile immediately' => sub {
    my ($left, $right) = constrained_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { bytes => '', drains => 0 };
    my $stream = T::LiveRawStream->new(
        loop => $loop, fh => $left, data => $state,
    );
    $stream->tune(high_watermark => 4096, low_watermark => 1024);

    ok(!$stream->write('x' x (2 * 1024 * 1024)),
        'large write establishes native backpressure');
    ok($stream->is_write_blocked, 'Stream is blocked before retuning');
    my $pending = $stream->pending_bytes;
    ok($pending > 4096, 'test has queued output');

    $stream->tune(
        high_watermark => $pending + 1024,
        low_watermark  => $pending + 512,
    );
    ok(!$stream->is_write_blocked,
        'new watermarks immediately clear the blocked state');
    is($state->{drains}, 1,
        'watermark reconciliation emits one drain transition');

    $stream->close;
    close $right;
};

subtest 'lower max_pending_bytes preserves existing queue' => sub {
    my ($left, $right) = constrained_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { bytes => '', drains => 0 };
    my $stream = T::LiveRawStream->new(
        loop => $loop, fh => $left, data => $state,
    );

    ok(!$stream->write('y' x (2 * 1024 * 1024)),
        'test establishes queued output');
    my $pending = $stream->pending_bytes;
    ok($pending > 1, 'queued output is large enough to lower the limit below it');

    $stream->tune(max_pending_bytes => $pending - 1);
    is($stream->pending_bytes, $pending,
        'lowering hard output limit does not discard existing bytes');
    ok(!$stream->is_closed,
        'Stream remains open while grandfathered output is queued');

    $stream->write('z');
    isa_ok($state->{error}, 'Linux::Event::Error');
    is($state->{error}->type, 'output_limit',
        'future queue growth is rejected against the lower limit');

    close $right;
};

subtest 'lower max_buffer preserves incomplete frame until future growth' => sub {
    my ($left, $right) = socket_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { messages => [], batches => [] };
    my $stream = T::LiveFramedStream->new(
        loop => $loop, fh => $left, data => $state,
    );

    is(syswrite($right, 'abcdefghijklmnop'), 16,
        'peer writes an incomplete framed payload');
    $loop->run_once(100);
    is($stream->{xs_state}->_input_buffered_bytes, 16,
        'incomplete frame is retained in native input state');

    $stream->tune(max_buffer => 8);
    is($stream->{xs_state}->_input_buffered_bytes, 16,
        'lowering max_buffer does not discard already buffered input');
    ok(!$stream->is_closed,
        'grandfathered incomplete frame remains valid immediately after tuning');

    is(syswrite($right, 'q'), 1, 'peer attempts future input growth');
    $loop->run_once(100);
    ok($stream->is_closed,
        'future input growth against the lower cap closes the Stream');
    isa_ok($state->{error}, 'Linux::Event::Error');
    is($state->{error}->type, 'framing',
        'future growth failure uses the normal framing error lifecycle');
    like("$state->{error}", qr/max_buffer=8/,
        'framing error reports the lowered input cap');

    close $right;
};

subtest 'enabling idle timeout live arms deadline tracking' => sub {
    my ($left, $right) = socket_pair();
    my $loop = Linux::Event::Loop->new;
    my $state = { bytes => '', drains => 0 };
    my $stream = T::LiveRawStream->new(
        loop => $loop, fh => $left, data => $state,
    );

    my $timeout = 0.20;
    $stream->tune(idle_timeout => $timeout);
    is($stream->idle_timeout, $timeout,
        'live timeout is visible immediately');
    $loop->run_for(0.60);
    ok($stream->is_closed, 'new idle timeout expires without reconstruction');
    isa_ok($state->{error}, 'Linux::Event::Error');
    is($state->{error}->operation, 'idle',
        'live timeout arms the idle deadline');

    close $right;
};

subtest 'invalid and closed tuning calls are rejected' => sub {
    my ($left, $right) = socket_pair();
    my $stream = T::LiveRawStream->new(
        fh => $left, data => { bytes => '', drains => 0 },
    );

    my $ok = eval { $stream->tune(unknown_tuning => 1); 1 };
    ok(!$ok, 'unknown live tuning option is rejected');
    like($@, qr/unknown options: unknown_tuning/,
        'unknown option is named');

    $stream->close;
    $ok = eval { $stream->tune(read_size => 1024); 1 };
    ok(!$ok, 'closed Stream cannot be tuned');
    like($@, qr/stream is closed/, 'closed tuning error is explicit');
    close $right;
};

done_testing;
