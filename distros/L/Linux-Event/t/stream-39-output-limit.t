use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::OutputLimit;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024,
            max_pending_bytes => 16_384;
    }
    sub on_data ($stream, $bytes) { }
    sub on_error ($stream, $error) {
        my $state = $stream->data;
        $state->{error} = $error;
        $state->{stats_at_error} = $stream->{xs_state}->stats;
    }
    sub on_close ($stream) { $stream->data->{close_calls}++ }
}

{
    package T::UnlimitedOutput;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
}

{
    package T::SmallTarget;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return max_pending_bytes => 4096 }
    sub on_data ($stream, $bytes) { }
}

{
    package T::NegativeOutputLimit;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return max_pending_bytes => -1 }
    sub on_data ($stream, $bytes) { }
}

sub constrained_pair () {
    socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    setsockopt($a, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt SO_SNDBUF: $!";
    return ($a, $b);
}

my $loop = Linux::Event::Loop->new;
my ($limited_fh, $limited_peer) = constrained_pair();
my $state = { close_calls => 0 };
my $limited = T::OutputLimit->new(
    loop => $loop, fh => $limited_fh, data => $state,
);

my $accepted_calls = 0;
while (!$limited->is_closed) {
    $limited->write('x' x 4096);
    $accepted_calls++ if !$limited->is_closed;
}

ok($accepted_calls > 0, 'writes are accepted before the hard limit is reached');
ok($limited->is_closed, 'hard output limit closes the Stream');
isa_ok($state->{error}, 'Linux::Event::Error');
is($state->{error}->type, 'output_limit', 'overflow has a distinct error type');
is($state->{error}->operation, 'write', 'overflow identifies the write operation');
is($state->{error}->limit, 16_384, 'error exposes the configured limit');
ok($state->{error}->pending_bytes > $state->{error}->limit,
    'error exposes the attempted pending byte count');
like("$state->{error}", qr/pending output would exceed 16384 bytes/,
    'overflow error string explains the limit');
is($state->{close_calls}, 1, 'overflow closes exactly once');
ok($state->{stats_at_error}{queue_peak_bytes} <= 16_384,
    'native queue never grows beyond the hard limit');
is($state->{stats_at_error}{output_limit_count}, 1,
    'native instrumentation records one output-limit failure');
close $limited_peer;

my ($source_fh, $source_peer) = constrained_pair();
my $source = T::UnlimitedOutput->new(loop => $loop, fh => $source_fh);
ok(!$source->write('y' x (2 * 1024 * 1024)),
    'unlimited source preserves accepted-false backpressure behavior');
ok($source->pending_bytes > 4096, 'source has more queued output than target cap');

my $transition_ok = eval {
    $source->transition_to('T::SmallTarget');
    1;
};
ok(!$transition_ok, 'transition to a smaller hard limit is rejected');
like($@, qr/queued output exceeds target max_pending_bytes/,
    'transition rejection identifies the target policy');
isa_ok($source, 'T::UnlimitedOutput', 'failed transition retains old type');
ok(!$source->is_closed, 'failed transition leaves connection open');
$source->close;
close $source_peer;

my ($bad_fh, $bad_peer) = constrained_pair();
my $bad_ok = eval {
    T::NegativeOutputLimit->new(loop => $loop, fh => $bad_fh);
    1;
};
ok(!$bad_ok, 'negative max_pending_bytes is rejected');
like($@, qr/max_pending_bytes must be a non-negative integer/,
    'invalid option reports a specific diagnostic');
close $bad_fh;
close $bad_peer;

done_testing;
