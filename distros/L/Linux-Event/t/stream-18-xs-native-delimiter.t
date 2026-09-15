use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::NativeDelimiterStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\x02END\x03";
    sub stream_tuning ($class) { return read_size => 4 }
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{messages} }, $message;
        $state->{loop}->stop if @{ $state->{messages} } == 2;
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";

my $loop = Linux::Event::Loop->new;
my $delimiter = "\x02END\x03";
my $state = { loop => $loop, messages => [] };

my $stream = T::NativeDelimiterStream->new(
    loop => $loop,
    fh   => $a,
    data => $state,
);

my $wire = "alpha${delimiter}beta${delimiter}tail";
is(syswrite($b, $wire), length($wire), 'peer wrote framed bytes');
$loop->run;

is_deeply($state->{messages}, [qw(alpha beta)], 'native delimiter emits complete messages');

my $stats = $stream->{xs_state}->stats;
ok($stats->{input_appends} >= 2, 'small read_size appended multiple chunks directly to native input');
is($stats->{delivery_calls}, 0, 'native framed reads do not create/deliver Perl read chunks');
is($stats->{frames_emitted}, 2, 'native framer counted semantic frames');
ok($stats->{delimiter_searches} >= 2, 'delimiter search executed natively');
is($stats->{input_buffered_bytes}, 4, 'incomplete tail remains in native storage');

$stream->close;
close $b;
done_testing;
