use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;

{
    package T::NetstringStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Netstring';
    sub stream_tuning ($class) { return read_size => 2 }
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{got} }, $message;
        $state->{loop}->stop if @{ $state->{got} } == ($state->{target} // 1);
    }
    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
        $stream->data->{loop}->stop;
    }
}

sub read_exact ($fh, $wanted) {
    my $bytes = '';
    while (length($bytes) < $wanted) {
        my $count = sysread($fh, $bytes, $wanted - length($bytes), length($bytes));
        die "sysread: $!" if !defined $count;
        die 'unexpected EOF' if $count == 0;
    }
    return $bytes;
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $state = { loop => $loop, got => [], target => 3 };
my $stream = T::NetstringStream->new(loop => $loop, fh => $a, data => $state);
ok($stream->send('hello'), 'non-empty netstring send succeeds');
ok($stream->send(''), 'empty netstring send succeeds');
is(read_exact($b, 11), '5:hello,0:,', 'outbound netstrings are canonical');

my $wire = '5:alpha,0:,4:beta,2:ta';
is(syswrite($b, $wire), length($wire), 'peer wrote netstrings plus tail');
$loop->run;
is_deeply($state->{got}, ['alpha', '', 'beta'],
    'native Netstring emits multiple messages');
is($stream->{xs_state}->stats->{input_buffered_bytes}, 4,
    'netstring tail remains buffered');
$stream->close;
close $b;

socketpair(my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop2 = Linux::Event::Loop->new;
my $bad_state = { loop => $loop2, got => [] };
my $bad = T::NetstringStream->new(loop => $loop2, fh => $c, data => $bad_state);
syswrite($d, '03:abc,');
$loop2->run;
like($bad_state->{error}, qr/invalid netstring leading zero/,
    'native Netstring rejects noncanonical leading zero');
close $d;

done_testing;
