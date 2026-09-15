use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;

{
    package T::U32BEStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'U32BE';
    sub stream_tuning ($class) { return read_size => 3 }
    sub on_message ($stream, $message) {
        $stream->data->{got} = $message;
        $stream->data->{loop}->stop;
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $state = { loop => $loop };
my $stream = T::U32BEStream->new(loop => $loop, fh => $a, data => $state);

ok($stream->send('hello'), 'U32BE send succeeds');
my $wire = '';
is(sysread($b, $wire, 9), 9, 'peer reads U32BE frame');
is($wire, "\x00\x00\x00\x05hello", 'U32BE outbound wire format is correct');

syswrite($b, "\x00\x00\x00\x07payload");
$loop->run;
is($state->{got}, 'payload', 'native U32BE decodes payload');
$stream->close;
close $b;

done_testing;
