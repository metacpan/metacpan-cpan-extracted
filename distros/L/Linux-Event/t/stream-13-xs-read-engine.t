use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::SmallReadStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_size => 4 }
    sub on_data ($stream, $bytes) {
        my $state = $stream->data;
        $state->{got} .= $bytes;
        $state->{loop}->stop if length($state->{got}) >= 10;
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $loop = Linux::Event::Loop->new;
my $state = { loop => $loop, got => '' };

my $stream = T::SmallReadStream->new(
    loop => $loop,
    fh   => $a,
    data => $state,
);

isa_ok($stream->{xs_state}, 'Linux::Event::_ByteStream::State');
isa_ok($stream->{descriptor}{native}, 'Linux::Event::_ByteStream::Descriptor::Native');

is(syswrite($b, 'abcdefghij'), 10, 'peer wrote test bytes');
$loop->run;
is($state->{got}, 'abcdefghij', 'native read engine drains and delivers bytes');

my $stats = $stream->{xs_state}->stats;
my $snapshot = $stream->{xs_state}->_stats_snapshot;
is(ref($snapshot), 'ARRAY', 'native stats primitive returns a compact snapshot');
is(scalar($snapshot->@*), 49, 'native stats snapshot has one value per public key');
is_deeply(
    [sort keys $stats->%*],
    [sort qw(
        activity_clock_calls activity_tracking bytes_read bytes_written
        consumer_event_calls consumer_flush_calls consumer_flush_pending
        consumer_message_calls consumer_pause_count consumer_paused
        consumer_resume_count delimiter_searches delivery_calls drain_calls
        empty_calls eof_count frames_emitted framing_error_count input_appends
        input_buffered_bytes input_compactions input_peak_bytes
        message_batch_calls message_batch_peak_bytes
        message_batch_peak_messages message_batch_size message_callback_calls
        output_limit_count pending_bytes queue_peak_bytes queued_segments
        read_batch_bytes read_batch_flushes read_batch_peak_bytes
        read_budget_bytes read_calls read_eagain_count read_eintr_count
        read_error_count read_ready_calls transition_count write_blocked
        write_calls write_eagain_count write_eintr_count write_error_count
        write_ready_calls write_submit_calls writev_calls
    )],
    'native stats preserve the complete public key set',
);
ok($stats->{read_ready_calls} >= 1, 'native readiness handler ran');
ok($stats->{read_calls} >= 3, 'native engine performed multiple small read calls');
is($stats->{bytes_read}, 10, 'native byte count is exact');
ok($stats->{delivery_calls} >= 3, 'delivery callback follows successful reads');
$stats->{bytes_read} = 0;
is($stream->{xs_state}->stats->{bytes_read}, 10,
    'stats presentation returns an independent hash snapshot');

$stream->close;
close $b;

done_testing;
