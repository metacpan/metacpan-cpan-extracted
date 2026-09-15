use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::SegmentReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        my $state = $stream->data;
        $state->{received} .= $bytes;
        $state->{loop}->stop if length($state->{received}) == $state->{expected_size};
    }
}

{
    package T::SegmentWriter;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($stream, $bytes) { }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
setsockopt($a, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
    or die "setsockopt SO_SNDBUF: $!";

my $loop = Linux::Event::Loop->new;
my $first = 'A' x (1024 * 1024);
my $second = 'B' x (64 * 1024);
my $third = 'C' x (64 * 1024);
my $expected = $first . $second . $third;
my $state = { loop => $loop, expected_size => length($expected), received => '' };

my $reader = T::SegmentReader->new(
    loop => $loop,
    fh   => $b,
    data => $state,
);

my $writer = T::SegmentWriter->new(
    loop => $loop,
    fh   => $a,
    data => $state,
);

ok(!$writer->write($first), 'first large write establishes queued output');
$writer->write($second);
$writer->write($third);

# Queued writes have value semantics: later mutation of caller scalars must not
# change bytes already accepted by Stream.
$second =~ tr/B/X/;
$third  =~ tr/C/Y/;

$loop->run;
is($state->{received}, $expected, 'segmented native queue preserves ordering and values');

my $stats = $writer->{xs_state}->stats;
ok($stats->{queued_segments} >= 3, 'multiple native segments were queued');
ok($stats->{writev_calls} >= 1, 'segmented queue drained with writev');
is($stats->{pending_bytes}, 0, 'all native segments were consumed');

$writer->close;
$reader->close;
done_testing;
