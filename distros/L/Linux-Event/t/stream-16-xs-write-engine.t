use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::WriteEngineReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        my $state = $stream->data;
        $state->{received} .= $bytes;
        $state->{loop}->stop
            if length($state->{received}) == $state->{payload_size} && $state->{drains};
    }
}

{
    package T::WriteEngineWriter;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($stream, $bytes) { }
    sub on_drain ($stream) {
        my $state = $stream->data;
        $state->{drains}++;
        $state->{loop}->stop if length($state->{received}) == $state->{payload_size};
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
setsockopt($a, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
    or die "setsockopt SO_SNDBUF: $!";

my $loop = Linux::Event::Loop->new;
my $payload = ('abcdefgh' x (256 * 1024)); # 2 MiB, deterministic byte pattern
my $state = {
    loop => $loop, payload_size => length($payload), received => '', drains => 0,
};

my $reader = T::WriteEngineReader->new(
    loop => $loop,
    fh   => $b,
    data => $state,
);

my $writer = T::WriteEngineWriter->new(
    loop => $loop,
    fh   => $a,
    data => $state,
);

isa_ok($writer->{xs_state}, 'Linux::Event::_ByteStream::State');
ok(!$writer->write($payload), 'large write enters native backpressure');
ok($writer->pending_bytes > 0, 'native queue reports pending bytes');
ok($writer->is_write_blocked, 'native blocked state is visible');

$loop->run;

is($state->{received}, $payload, 'native queued writer preserves exact byte content');
is($writer->pending_bytes, 0, 'native write queue drains completely');
ok(!$writer->is_write_blocked, 'blocked state clears after drain');
is($state->{drains}, 1, 'native backpressure interval emits one drain callback');

my $stats = $writer->{xs_state}->stats;
ok($stats->{write_submit_calls} >= 1, 'native write submission ran');
ok($stats->{write_calls} >= 1, 'native immediate write syscall ran');
ok($stats->{writev_calls} >= 1, 'native queued path used writev');
is($stats->{bytes_written}, length($payload), 'native write byte accounting is exact');
ok($stats->{queued_segments} >= 1, 'native queue stored at least one segment');
is($stats->{pending_bytes}, 0, 'native stats report empty queue');

$writer->close;
$reader->close;
done_testing;
