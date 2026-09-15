use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::BackpressureReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        my $state = $stream->data;
        $state->{received} += length($bytes);
        $state->{loop}->stop
            if $state->{received} == $state->{payload_size} && $state->{drain_calls};
    }
}

{
    package T::BackpressureWriter;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($stream, $bytes) { }
    sub on_drain ($stream) {
        my $state = $stream->data;
        $state->{drain_calls}++;
        $state->{loop}->stop if $state->{received} == $state->{payload_size};
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
setsockopt($a, SOL_SOCKET, SO_SNDBUF, pack('i', 4096)) or die "setsockopt SO_SNDBUF: $!";

my $loop = Linux::Event::Loop->new;
my $payload = 'x' x (2 * 1024 * 1024);
my $state = {
    loop => $loop, payload_size => length($payload),
    received => 0, drain_calls => 0,
};

my $reader = T::BackpressureReader->new(
    loop => $loop,
    fh   => $b,
    data => $state,
);

my $writer = T::BackpressureWriter->new(
    loop => $loop,
    fh   => $a,
    data => $state,
);

ok(!$writer->write($payload), 'large write crosses high watermark');
ok($writer->is_write_blocked, 'blocked state is visible');
ok($writer->pending_bytes > 4096, 'bytes are queued in user space');

$loop->run;

is($state->{received}, length($payload), 'all queued bytes are delivered');
is($state->{drain_calls}, 1, 'on_drain fires exactly once for blocked transition');
ok(!$writer->is_write_blocked, 'blocked state clears below low watermark');
is($writer->pending_bytes, 0, 'write queue is empty');

$writer->close;
$reader->close;
done_testing;
