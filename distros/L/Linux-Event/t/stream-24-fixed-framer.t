use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;

{
    package T::FixedFourStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 4;
    sub stream_tuning ($class) { return read_size => 3 }
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{got} }, $message;
        $state->{loop}->stop if @{ $state->{got} } == 2;
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $state = { loop => $loop, got => [] };
my $stream = T::FixedFourStream->new(loop => $loop, fh => $a, data => $state);

is(syswrite($b, 'abcdefghij'), 10, 'peer wrote fixed frames plus tail');
$loop->run;
is_deeply($state->{got}, [qw(abcd efgh)], 'native Fixed emits complete frames');
is($stream->{xs_state}->stats->{input_buffered_bytes}, 2,
    'Fixed leaves incomplete tail buffered');

is($stream->send('WXYZ'), 1, 'send accepts exact fixed payload');
my $wire = '';
is(sysread($b, $wire, 4), 4, 'peer reads outbound fixed payload');
is($wire, 'WXYZ', 'Fixed outbound framing is payload itself');

my $ok = eval { $stream->send('bad'); 1 };
ok(!$ok, 'send rejects wrong fixed payload length');
like($@, qr/does not equal fixed size 4/, 'fixed-size send error is descriptive');

$stream->close;
close $b;
done_testing;
