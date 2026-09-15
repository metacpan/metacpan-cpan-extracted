use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::Transition::Handshake;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        my $state = $stream->data;
        $state->{input} .= $bytes;
        return if $state->{input} !~ s/\AUPGRADE\n//;
        my $remaining = delete $state->{input};
        $stream->transition_to('T::Transition::Line', input => $remaining);
    }
}

{
    package T::Transition::Line;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{messages} }, $message;
        $state->{loop}->stop if @{ $state->{messages} } == 2;
    }
}

{
    package T::Transition::Control;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{control} }, $message;
        $stream->transition_to('T::Transition::Fixed') if $message eq 'BINARY';
    }
}

{
    package T::Transition::Fixed;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 3;
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{fixed} }, $message;
        $state->{loop}->stop if @{ $state->{fixed} } == 2;
    }
}

{
    package T::Transition::FramedToRaw;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', '|';
    sub on_message ($stream, $message) {
        $stream->data->{framed} = $message;
        $stream->transition_to('T::Transition::RawTail');
    }
}

{
    package T::Transition::RawTail;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->data->{raw} .= $bytes;
        $stream->data->{loop}->stop;
    }
}

{
    package T::Transition::OtherRaw;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
}

{
    package T::Transition::Small;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub stream_tuning ($class) { return max_buffer => 4 }
    sub on_message ($stream, $message) { return }
}

{
    package T::Transition::SourceBase;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_message ($stream, $message) {
        $stream->data->{framed} = $message;
        $stream->transition_to('T::Transition::RawTail');
    }
}

{
    package T::Transition::SourceFixed;
    use parent -norequire, 'T::Transition::SourceBase';
    use Linux::Event::Framer 'Fixed', size => 2;
}

{
    package T::Transition::SourceLength;
    use parent -norequire, 'T::Transition::SourceBase';
    use Linux::Event::Framer 'LengthPrefix', bytes => 1;
}

{
    package T::Transition::SourceNetstring;
    use parent -norequire, 'T::Transition::SourceBase';
    use Linux::Event::Framer 'Netstring';
}

{
    package T::Transition::SourceVarint;
    use parent -norequire, 'T::Transition::SourceBase';
    use Linux::Event::Framer 'Varint';
}

{
    package T::Transition::SourceDecimal;
    use parent -norequire, 'T::Transition::SourceBase';
    use Linux::Event::Framer 'DecimalLength', separator => ' ';
}

sub stream_pair ($class, $state) {
    socketpair(my $stream_fh, my $peer_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    $state->{loop} = $loop;
    my $stream = $class->new(loop => $loop, fh => $stream_fh, data => $state);
    return ($loop, $stream, $peer_fh);
}

# A raw handshake can hand the unconsumed suffix directly to a native framer.
{
    my $state = { input => '', messages => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Transition::Handshake', $state);
    my $watcher_id = refaddr($stream->{watcher});
    my $xs_state_id = refaddr($stream->{xs_state});
    my $data_id = refaddr($stream->data);

    syswrite($peer, "UPGRADE\none\ntwo\n");
    $loop->run;

    isa_ok($stream, 'T::Transition::Line');
    is_deeply($state->{messages}, [qw(one two)],
        'raw handshake suffix is parsed by the new native framer');
    is(refaddr($stream->{watcher}), $watcher_id, 'transition retains watcher');
    is(refaddr($stream->{xs_state}), $xs_state_id, 'transition retains native state');
    is(refaddr($stream->data), $data_id, 'transition retains application data');
    is($stream->{xs_state}->stats->{transition_count}, 1,
        'native instrumentation counts the transition');
    ok($stream->send('reply'), 'send uses the target class framer');
    my $wire = '';
    is(sysread($peer, $wire, 1024), 6, 'peer receives target-framed output');
    is($wire, "reply\n", 'transition changes outbound framing for later sends');
    $stream->close;
    close $peer;
}

# Bytes read after the last old-protocol frame stay native and are reinterpreted
# under the new descriptor without a second read readiness event.
{
    my $state = { control => [], fixed => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Transition::Control', $state);
    syswrite($peer, "BINARY\nabcDEF");
    $loop->run;

    isa_ok($stream, 'T::Transition::Fixed');
    is_deeply($state->{control}, ['BINARY'], 'old parser stops at transition');
    is_deeply($state->{fixed}, [qw(abc DEF)],
        'unread framed input is preserved across framed transition');
    $stream->close;
    close $peer;
}

# A framed parser may transition to raw delivery without losing its suffix.
{
    my $state = { raw => '' };
    my ($loop, $stream, $peer) = stream_pair(
        'T::Transition::FramedToRaw', $state
    );
    syswrite($peer, 'RAW|trailing-bytes');
    $loop->run;

    isa_ok($stream, 'T::Transition::RawTail');
    is($state->{framed}, 'RAW', 'final old-protocol message is delivered');
    is($state->{raw}, 'trailing-bytes',
        'framed native suffix becomes one raw input chunk');
    $stream->close;
    close $peer;
}

# Every native parser loop must stop using its old constants after a callback
# changes descriptors. These cases guard each distinct parser implementation.
for my $case (
    ['T::Transition::SourceFixed',     'GOtail'],
    ['T::Transition::SourceLength',    "\x02GOtail"],
    ['T::Transition::SourceNetstring', '2:GO,tail'],
    ['T::Transition::SourceVarint',    "\x02GOtail"],
    ['T::Transition::SourceDecimal',   '2 GOtail'],
) {
    my ($class, $wire) = @$case;
    my $state = { raw => '' };
    my ($loop, $stream, $peer) = stream_pair($class, $state);
    syswrite($peer, $wire);
    $loop->run;

    isa_ok($stream, 'T::Transition::RawTail', "$class transitioned to raw");
    is($state->{framed}, 'GO', "$class delivered its final old frame");
    is($state->{raw}, 'tail', "$class preserved its unread suffix");
    $stream->close;
    close $peer;
}

# Pause state survives transition and gates explicitly supplied input.
{
    my $state = { messages => [] };
    my ($loop, $stream, $peer) = stream_pair('T::Transition::Handshake', $state);
    $stream->pause_read;
    $stream->transition_to('T::Transition::Line', input => "held\n");
    is_deeply($state->{messages}, [], 'paused transition does not dispatch input');
    ok($stream->is_read_paused, 'read pause survives transition');
    $stream->resume_read;
    is_deeply($state->{messages}, ['held'],
        'resume dispatches input buffered during transition');
    $stream->close;
    close $peer;
}

{
    package T::Transition::NoMessageSink;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
}

{
    package T::Transition::NoDataSink;
    use parent 'Linux::Event::IO::Sock::Stream';
}

{
    my $state = { input => '' };
    my ($loop, $stream, $peer) = stream_pair(
        'T::Transition::Handshake', $state,
    );
    my $ok = eval {
        $stream->transition_to('T::Transition::NoMessageSink');
        1;
    };
    ok(!$ok, 'transition without a message sink is rejected');
    like($@, qr/target readable framed Stream has no message sink/,
        'transition rejects a readable framed target without delivery');
    isa_ok($stream, 'T::Transition::Handshake',
        'failed callback validation leaves source class active');
    $stream->close;
    close $peer;
}

{
    my $state = { input => '' };
    my ($loop, $stream, $peer) = stream_pair(
        'T::Transition::Handshake', $state,
    );
    my $ok = eval {
        $stream->transition_to('T::Transition::NoDataSink');
        1;
    };
    ok(!$ok, 'transition without a raw data sink is rejected');
    like($@, qr/target readable raw Stream has no on_data callback/,
        'transition rejects a readable raw target without delivery');
    isa_ok($stream, 'T::Transition::Handshake',
        'failed raw callback validation leaves source class active');
    $stream->close;
    close $peer;
}

# Output queue identity and accounting are connection state, not descriptor state.
{
    my $state = {};
    my ($loop, $stream, $peer) = stream_pair('T::Transition::Handshake', $state);
    $stream->write('x' x (4 * 1024 * 1024));
    my $pending = $stream->pending_bytes;
    ok($pending > 0, 'test establishes queued output');
    my $xs_state_id = refaddr($stream->{xs_state});
    $stream->transition_to('T::Transition::OtherRaw');
    is(refaddr($stream->{xs_state}), $xs_state_id,
        'queued-output transition retains native state');
    is($stream->pending_bytes, $pending,
        'queued bytes and ordering survive transition');
    $stream->close;
    close $peer;
}

# Failed transitions are atomic and leave the original type active.
{
    my $state = {};
    my ($loop, $stream, $peer) = stream_pair('T::Transition::Handshake', $state);
    my $descriptor_id = refaddr($stream->{descriptor});

    my $ok = eval {
        $stream->transition_to('T::Transition::Small', input => '12345');
        1;
    };
    ok(!$ok, 'target max_buffer rejects oversized preserved input');
    like($@, qr/preserved input exceeds target max_buffer/,
        'transition buffer error identifies target policy');
    isa_ok($stream, 'T::Transition::Handshake');
    is(refaddr($stream->{descriptor}), $descriptor_id,
        'failed transition preserves Perl descriptor');
    is($stream->{xs_state}->stats->{transition_count}, 0,
        'failed transition does not mutate native descriptor');

    $ok = eval { $stream->transition_to('T::Transition::Handshake'); 1 };
    ok(!$ok, 'transition to active class is rejected');
    like($@, qr/already active/, 'same-type transition error is clear');

    $ok = eval {
        $stream->transition_to('T::Transition::OtherRaw', imaginary => 1);
        1;
    };
    ok(!$ok, 'unknown transition option is rejected');
    like($@, qr/unknown options: imaginary/, 'unknown option is named');

    $stream->close;
    $ok = eval { $stream->transition_to('T::Transition::OtherRaw'); 1 };
    ok(!$ok, 'closed Stream cannot transition');
    like($@, qr/stream is closed/, 'closed transition error is clear');
    close $peer;
}

done_testing;
