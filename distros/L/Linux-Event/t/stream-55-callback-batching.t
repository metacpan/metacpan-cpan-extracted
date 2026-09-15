use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::Batch::Raw;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return read_size => 4, read_batch_bytes => 10;
    }
    sub on_data ($stream, $bytes) {
        push @{ $stream->data->{chunks} }, $bytes;
        push @{ $stream->data->{order} }, 'data:' . $bytes
            if $stream->data->{order};
    }
    sub on_eof ($stream) { push @{ $stream->data->{order} }, 'eof' }
}

{
    package T::Batch::RawPause;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return read_size => 4, read_batch_bytes => 8;
    }
    sub on_data ($stream, $bytes) {
        push @{ $stream->data->{chunks} }, $bytes;
        $stream->pause_read if @{ $stream->data->{chunks} } == 1;
    }
}

{
    package T::Batch::Messages;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 3 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
        $stream->data->{retained} = $messages if $stream->data->{retain};
    }
    sub on_eof ($stream) { push @{ $stream->data->{order} }, 'eof' }
}

{
    package T::Batch::MessagesByteGuard;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) {
        return message_batch_size => 10, max_buffer => 5;
    }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}

{
    package T::Batch::MessagesOne;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 1 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
    }
}

{
    package T::Batch::MessagesPause;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
        $stream->pause_read if @{ $stream->data->{batches} } == 1;
    }
}

{
    package T::Batch::MessagesClose;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{batches} }, [@$messages];
        $stream->close;
    }
}

{
    package T::Batch::MessagesError;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|', max_frame => 4;
    sub stream_tuning ($class) { return message_batch_size => 8 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{order} }, 'batch:' . join(',', @$messages);
    }
    sub on_error ($stream, $error) {
        push @{ $stream->data->{order} }, 'error:' . $error->type;
    }
}

{
    package T::Batch::MessagesDie;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
    sub on_messages ($stream, $messages) { die "batch callback failed\n" }
}

{
    package T::Batch::TransitionSource;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
    sub on_messages ($stream, $messages) {
        push @{ $stream->data->{source} }, @$messages;
        $stream->transition_to('T::Batch::TransitionTarget')
            if $messages->[0] eq 'SWITCH';
    }
}

{
    package T::Batch::TransitionTarget;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 3;
    sub on_message ($stream, $message) {
        push @{ $stream->data->{target} }, $message;
    }
}

{
    package T::Batch::TransitionRawSource;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
}

{
    package T::Batch::TransitionRawTarget;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_batch_bytes => 4 }
    sub on_data ($stream, $bytes) {
        push @{ $stream->data->{chunks} }, $bytes;
    }
}

sub stream_pair ($class, $state = {}) {
    socketpair(my $stream_fh, my $peer_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $stream = $class->new(
        loop => $loop, fh => $stream_fh, data => $state,
    );
    return ($loop, $stream, $peer_fh);
}

subtest 'raw reads coalesce to byte limit and EAGAIN' => sub {
    my $state = { chunks => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::Raw', $state);
    is(syswrite($peer, 'abcdefghijklmnopqrstuvwxyz'), 26,
        'peer writes raw burst');
    $loop->run_once(100);
    is_deeply([map length, @{ $state->{chunks} }], [10, 10, 6],
        'raw batching flushes at byte limit and final EAGAIN');
    is(join('', @{ $state->{chunks} }), 'abcdefghijklmnopqrstuvwxyz',
        'raw batching preserves every byte in order');
    my $stats = $stream->{xs_state}->stats;
    is($stats->{read_batch_bytes}, 10, 'stats expose raw byte limit');
    is($stats->{read_batch_flushes}, 3, 'stats count raw batch callbacks');
    is($stats->{read_batch_peak_bytes}, 10, 'stats expose largest raw batch');
    is($stats->{delivery_calls}, 3, 'three Perl on_data entries replace seven reads');
    cmp_ok($stats->{read_calls}, '>=', 8,
        'native engine performed data reads plus final EAGAIN');
    $stream->close;
    close $peer;
};

subtest 'raw batch callback can pause and resume safely' => sub {
    my $state = { chunks => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::RawPause', $state);
    syswrite($peer, 'abcdefghijklmnop');
    $loop->run_once(100);
    is_deeply($state->{chunks}, ['abcdefgh'],
        'pause takes effect after the current explicit raw batch');
    $stream->resume_read;
    $loop->run_once(100);
    is_deeply($state->{chunks}, ['abcdefgh', 'ijklmnop'],
        'resume delivers the next raw batch without loss');
    $stream->close;
    close $peer;
};

subtest 'raw remainder is delivered before EOF' => sub {
    my $state = { chunks => [], order => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::Raw', $state);
    syswrite($peer, 'final!');
    close $peer;
    $loop->run_once(100);
    is_deeply($state->{order}, ['data:final!', 'eof'],
        'raw remainder arrived before EOF callback');
    $stream->close;
};

subtest 'framed messages use bounded array callbacks' => sub {
    my $state = { batches => [], retain => 1 };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::Messages', $state);
    syswrite($peer, 'one|two|three|four|five|six|seven|');
    $loop->run_once(100);
    is_deeply($state->{batches}, [
        [qw(one two three)], [qw(four five six)], ['seven'],
    ], 'complete frames are delivered in bounded ordered batches');
    my $stats = $stream->{xs_state}->stats;
    is($stats->{frames_emitted}, 7, 'frame count remains semantic-message count');
    is($stats->{message_batch_size}, 3, 'stats expose configured batch size');
    is($stats->{message_callback_calls}, 0,
        'ordinary one-message callback was not entered');
    is($stats->{message_batch_calls}, 3, 'three batch callbacks were entered');
    is($stats->{message_batch_peak_messages}, 3,
        'stats expose largest delivered message batch');
    is_deeply($state->{retained}, ['seven'],
        'application may retain the detached callback array');
    $stream->close;
    close $peer;
};

subtest 'max_buffer also bounds aggregate message batch payload' => sub {
    my $state = { batches => [] };
    my ($loop, $stream, $peer) = stream_pair(
        'T::Batch::MessagesByteGuard', $state,
    );
    syswrite($peer, 'abc|def|');
    $loop->run_once(100);
    is_deeply($state->{batches}, [[qw(abc def)]],
        'payload budget flushes below the configured message count');
    my $stats = $stream->{xs_state}->stats;
    is($stats->{message_batch_peak_bytes}, 6,
        'stats expose bounded one-message overshoot at payload boundary');
    is($stats->{message_batch_calls}, 1,
        'payload budget caused one callback without waiting for more input');
    $stream->close;
    close $peer;
};

subtest 'batch size one retains explicit array contract' => sub {
    my $state = { batches => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::MessagesOne', $state);
    syswrite($peer, 'one|two|');
    $loop->run_once(100);
    is_deeply($state->{batches}, [['one'], ['two']],
        'batch mode always passes an array reference');
    $stream->close;
    close $peer;
};

subtest 'framed batch callback can pause and resume buffered frames' => sub {
    my $state = { batches => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::MessagesPause', $state);
    syswrite($peer, 'one|two|three|four|');
    $loop->run_once(100);
    is_deeply($state->{batches}, [[qw(one two)]],
        'pause stops parsing after the current message batch');
    $stream->resume_read;
    is_deeply($state->{batches}, [[qw(one two)], [qw(three four)]],
        'resume synchronously dispatches complete native frames');
    $stream->close;
    close $peer;
};

subtest 'close after one batch suppresses remaining frames' => sub {
    my $state = { batches => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::MessagesClose', $state);
    syswrite($peer, 'one|two|three|four|');
    $loop->run_once(100);
    is_deeply($state->{batches}, [[qw(one two)]],
        'close takes effect at the explicit message-batch boundary');
    ok($stream->is_closed, 'Stream is closed by batch callback');
    close $peer;
};

subtest 'partial message batch is delivered before EOF' => sub {
    my $state = { batches => [], order => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::Messages', $state);
    syswrite($peer, 'last|');
    close $peer;
    $loop->run_once(100);
    unshift @{ $state->{order} },
        map { 'batch:' . join(',', @$_) } @{ $state->{batches} };
    is_deeply($state->{order}, ['batch:last', 'eof'],
        'message batch precedes EOF lifecycle callback');
    $stream->close;
};

subtest 'complete messages precede a later framing error' => sub {
    my $state = { order => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Batch::MessagesError', $state);
    syswrite($peer, 'ok|oversized');
    $loop->run_once(100);
    is_deeply($state->{order}, ['batch:ok', 'error:framing'],
        'pending valid batch is flushed before framing error');
    ok($stream->is_closed, 'framing error still closes Stream');
    close $peer;
};

subtest 'batch callback exception propagates with native state cleaned' => sub {
    my ($loop, $stream, $peer) = stream_pair('T::Batch::MessagesDie');
    syswrite($peer, 'one|two|');
    my $ok = eval { $loop->run_once(100); 1 };
    ok(!$ok, 'batch callback exception leaves Loop dispatch');
    like($@, qr/batch callback failed/, 'original batch exception is preserved');
    is($stream->{xs_state}->stats->{message_batch_calls}, 1,
        'failed callback still counts one detached batch');
    $stream->close;
    close $peer;
};

subtest 'protocol transition occurs after the complete explicit batch' => sub {
    my $state = { source => [], target => [] };
    my ($loop, $stream, $peer) = stream_pair(
        'T::Batch::TransitionSource', $state,
    );
    syswrite($peer, 'SWITCH|LASTOLD|abcDEF');
    $loop->run_once(100);
    isa_ok($stream, 'T::Batch::TransitionTarget');
    is_deeply($state->{source}, [qw(SWITCH LASTOLD)],
        'all messages in source batch retain old protocol semantics');
    is_deeply($state->{target}, [qw(abc DEF)],
        'unread suffix is reinterpreted by target parser');
    $stream->close;
    close $peer;
};

subtest 'raw transition input observes the explicit byte boundary' => sub {
    my $state = { chunks => [] };
    my ($loop, $stream, $peer) = stream_pair(
        'T::Batch::TransitionRawSource', $state,
    );
    $stream->transition_to(
        'T::Batch::TransitionRawTarget', input => 'abcdefghij',
    );
    is_deeply($state->{chunks}, [qw(abcd efgh ij)],
        'already-buffered transition bytes use bounded raw callbacks');
    is($stream->{xs_state}->stats->{read_batch_flushes}, 3,
        'transition input contributes to raw batch instrumentation');
    $stream->close;
    close $peer;
};

sub descriptor_error ($class) {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    eval { $class->new(loop => $loop, fh => $left) };
    my $error = $@;
    close $left if defined fileno($left);
    close $right;
    return $error;
}

{
    package T::Batch::InvalidRawMessageBatch;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return message_batch_size => 2 }
    sub on_data ($stream, $bytes) { return }
}
{
    package T::Batch::InvalidRawMessages;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    sub on_messages ($stream, $messages) { return }
}
{
    package T::Batch::InvalidFramedReadBatch;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return read_batch_bytes => 64 }
    sub on_message ($stream, $message) { return }
}
{
    package T::Batch::InvalidMissingMessages;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
}
{
    package T::Batch::InvalidBothMessageCallbacks;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => 2 }
    sub on_message ($stream, $message) { return }
    sub on_messages ($stream, $messages) { return }
}
{
    package T::Batch::InvalidUnconfiguredMessages;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub on_messages ($stream, $messages) { return }
}
{
    package T::Batch::InvalidNegativeReadBatch;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_batch_bytes => -1 }
    sub on_data ($stream, $bytes) { return }
}
{
    package T::Batch::InvalidNegativeMessageBatch;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub stream_tuning ($class) { return message_batch_size => -1 }
    sub on_message ($stream, $message) { return }
}

subtest 'batching policies validate class contracts' => sub {
    like(descriptor_error('T::Batch::InvalidRawMessageBatch'),
        qr/message_batch_size is available only to framed ordered-byte classes/,
        'raw ordered-byte class rejects framed batching policy');
    like(descriptor_error('T::Batch::InvalidRawMessages'),
        qr/on_messages.*does not declare a framer/,
        'raw ordered-byte class rejects on_messages');
    like(descriptor_error('T::Batch::InvalidFramedReadBatch'),
        qr/read_batch_bytes is available only to raw ordered-byte classes/,
        'framed ordered-byte class rejects raw batching policy');
    like(descriptor_error('T::Batch::InvalidMissingMessages'),
        qr/requires on_message or a native consumer/,
        'batch policy requires a class or constructor batch callback');
    is(descriptor_error('T::Batch::InvalidBothMessageCallbacks'), '',
        'a framed class may provide both callbacks for live batch switching');
    like(descriptor_error('T::Batch::InvalidUnconfiguredMessages'),
        qr/readable framed Stream requires on_message or a native consumer/,
        'initial unbatched policy still requires an effective on_message sink');
    like(descriptor_error('T::Batch::InvalidNegativeReadBatch'),
        qr/read_batch_bytes must be a non-negative integer/,
        'raw batch byte limit rejects negative values');
    like(descriptor_error('T::Batch::InvalidNegativeMessageBatch'),
        qr/message_batch_size must be a non-negative integer/,
        'message batch size rejects negative values');
};

done_testing;
