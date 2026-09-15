use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::Framer::LengthPrefix ();

sub legacy_length_frame ($bytes, $little, $payload) {
    my @octets;
    my $value = length($payload);
    for (1 .. $bytes) {
        unshift @octets, $value & 0xff;
        $value >>= 8;
    }
    @octets = reverse @octets if $little;
    return pack('C*', @octets) . $payload;
}

for my $bytes (1, 2, 4) {
    for my $endian (qw(big little)) {
        my $definition = Linux::Event::Framer::LengthPrefix->_build_definition(
            bytes => $bytes, endian => $endian,
        );
        my $max = $bytes == 1 ? 255 : $bytes == 2 ? 65_535 : 0xffff_ffff;
        for my $length (grep { $_ <= $max }
            0, 1, 2, 127, 128, 255, 256, 65_535, 65_536, 200_000) {
            my $payload = 'x' x $length;
            is($definition->{frame}->($definition->{native}, $payload),
                legacy_length_frame($bytes, $endian eq 'little', $payload),
                "$bytes-byte $endian prefix is byte-equivalent at $length");
        }
    }
}

{
    package T::LengthBEStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'LengthPrefix', bytes => 2, endian => 'big';
    sub stream_tuning ($class) { return read_size => 2 }
    sub on_message ($stream, $message) {
        my $state = $stream->data;
        push @{ $state->{got} }, $message;
        $state->{loop}->stop if @{ $state->{got} } == $state->{target};
    }
}

{
    package T::LengthLEStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'LengthPrefix', bytes => 2, endian => 'little';
    sub on_message ($stream, $message) { }
}

{
    package T::LengthLimitedStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'LengthPrefix', bytes => 2, max_frame => 3;
    sub on_message ($stream, $message) {
        Test::More::fail('oversized length frame must not emit');
    }
    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
        $stream->data->{loop}->stop;
    }
}

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $state = { loop => $loop, got => [], target => 2 };
my $stream = T::LengthBEStream->new(loop => $loop, fh => $a, data => $state);
ok($stream->send('abc'), 'big-endian send succeeds');
my $outbound = '';
is(sysread($b, $outbound, 5), 5, 'peer reads big-endian frame');
is($outbound, "\x00\x03abc", 'big-endian outbound prefix is correct');

my $wire = "\x00\x05alpha\x00\x04betaZ";
is(syswrite($b, $wire), length($wire), 'peer wrote two prefixed frames plus tail');
$loop->run;
is_deeply($state->{got}, [qw(alpha beta)], 'native LengthPrefix decodes split input');
is($stream->{xs_state}->stats->{input_buffered_bytes}, 1,
    'length framer leaves tail buffered');
$stream->close;
close $b;

socketpair(my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $little = T::LengthLEStream->new(loop => $loop, fh => $c);
ok($little->send('abc'), 'little-endian send succeeds');
my $little_wire = '';
is(sysread($d, $little_wire, 5), 5, 'peer reads little-endian frame');
is($little_wire, "\x03\x00abc", 'little-endian outbound prefix is correct');
$little->close;
close $d;

socketpair(my $e, my $f, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop2 = Linux::Event::Loop->new;
my $limited_state = { loop => $loop2 };
my $limited = T::LengthLimitedStream->new(
    loop => $loop2, fh => $e, data => $limited_state,
);
syswrite($f, "\x00\x04test");
$loop2->run;
like($limited_state->{error}, qr/frame exceeds max_frame=3/,
    'native length prefix enforces max_frame');
close $f;

done_testing;
