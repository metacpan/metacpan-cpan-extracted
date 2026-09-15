use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::EndDrainReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->data->{received} += length($bytes);
    }
    sub on_eof ($stream) {
        my $state = $stream->data;
        Test::More::is($state->{received}, $state->{payload_size},
            'reader sees all bytes before EOF');
        $stream->end;
    }
    sub on_close ($stream) {
        my $state = $stream->data;
        $state->{closed}++;
        $state->{loop}->stop if $state->{closed} == 2;
    }
}

{
    package T::EndDrainWriter;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($stream, $bytes) { }
    sub on_eof ($stream) { }
    sub on_close ($stream) {
        my $state = $stream->data;
        $state->{closed}++;
        $state->{loop}->stop if $state->{closed} == 2;
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
setsockopt($a, SOL_SOCKET, SO_SNDBUF, pack('i', 4096)) or die "setsockopt SO_SNDBUF: $!";

my $loop = Linux::Event::Loop->new;
my $payload = 'q' x (1024 * 1024);
my $state = {
    loop => $loop, payload_size => length($payload), received => 0, closed => 0,
};

my ($writer, $reader);
$reader = T::EndDrainReader->new(
    loop => $loop,
    fh   => $b,
    data => $state,
);

$writer = T::EndDrainWriter->new(
    loop => $loop,
    fh   => $a,
    data => $state,
);

ok(!$writer->write($payload), 'payload is queued and backpressured');
$writer->end;
$loop->run;

is($state->{received}, length($payload), 'end drains queued output rather than dropping it');
is($state->{closed}, 2, 'both streams close after both half-closes complete');
ok($writer->is_closed, 'writer closed');
ok($reader->is_closed, 'reader closed');

done_testing;
