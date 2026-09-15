use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::Framer::Varint ();

{
    package T::VarintStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Varint';
    sub stream_tuning ($class) { return read_size => 1 }
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

{
    package T::VarintPrefixStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Varint', include_prefix => 1;
    sub on_message ($stream, $message) {
        $stream->data->{got} = $message;
        $stream->data->{loop}->stop;
    }
}

{
    package T::VarintLimitedStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Varint', max_frame => 3;
    sub on_message ($stream, $message) {
        Test::More::fail('oversized Varint frame must not emit');
    }
    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
        $stream->data->{loop}->stop;
    }
}

sub varint_frame ($payload) {
    my $value = length($payload);
    my @bytes;
    do {
        my $byte = $value % 128;
        $value = int($value / 128);
        $byte |= 0x80 if $value;
        push @bytes, $byte;
    } while ($value);
    return pack('C*', @bytes) . $payload;
}

{
    my $definition = Linux::Event::Framer::Varint->_build_definition;
    for my $length (
        0, 1, 2, 126, 127, 128, 255, 256, 16_383, 16_384,
        65_535, 65_536, 200_000,
    ) {
        my $payload = 'x' x $length;
        is($definition->{frame}->($definition->{native}, $payload),
            varint_frame($payload),
            "Varint prefix is byte-equivalent at $length");
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
my $stream = T::VarintStream->new(loop => $loop, fh => $a, data => $state);

ok($stream->send(''), 'zero-length Varint send succeeds');
is(read_exact($b, 1), "\x00", 'zero-length payload has one-byte prefix');
ok($stream->send('x' x 128), 'multi-byte Varint send succeeds');
my $outbound = read_exact($b, 130);
is(substr($outbound, 0, 2), "\x80\x01", '128 uses canonical LEB128 prefix');

my $wire = varint_frame('') . varint_frame('x' x 128)
    . varint_frame('done') . "\x80";
is(syswrite($b, $wire), length($wire),
    'peer wrote complete Varint frames and partial prefix');
$loop->run;
is_deeply($state->{got}, ['', 'x' x 128, 'done'],
    'native Varint handles split prefixes and multiple messages');
is($stream->{xs_state}->stats->{input_buffered_bytes}, 1,
    'partial trailing Varint prefix remains buffered');
$stream->close;
close $b;

socketpair(my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop2 = Linux::Event::Loop->new;
my $prefix_state = { loop => $loop2 };
my $prefixed = T::VarintPrefixStream->new(
    loop => $loop2, fh => $c, data => $prefix_state,
);
syswrite($d, varint_frame('x' x 128));
$loop2->run;
is(substr($prefix_state->{got}, 0, 2), "\x80\x01",
    'include_prefix preserves the variable-width prefix');
is(length($prefix_state->{got}), 130,
    'include_prefix message contains prefix plus payload');
$prefixed->close;
close $d;

sub native_error ($wire, $class) {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $error_loop = Linux::Event::Loop->new;
    my $error_state = { loop => $error_loop, got => [] };
    my $bad = $class->new(loop => $error_loop, fh => $left, data => $error_state);
    syswrite($right, $wire);
    $error_loop->run;
    $bad->close;
    close $right;
    return $error_state->{error};
}

like(native_error("\x80\x00", 'T::VarintStream'),
    qr/non-canonical varint length/, 'native Varint rejects an overlong zero');
like(native_error(("\x80" x 10), 'T::VarintStream'),
    qr/(?:prefix too long|overflow)/, 'native Varint rejects an overlong prefix');
like(native_error(("\xff" x 9) . "\x02", 'T::VarintStream'),
    qr/varint length overflow/, 'native Varint rejects unsigned overflow');
like(native_error("\x04four", 'T::VarintLimitedStream'),
    qr/frame exceeds max_frame=3/, 'native Varint enforces max_frame');

socketpair(my $e, my $f, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $limited = T::VarintLimitedStream->new(
    loop => $loop, fh => $e, data => { loop => $loop },
);
eval { $limited->send('four') };
like($@, qr/exceeds max_frame=3/, 'outbound Varint enforces max_frame');
$limited->close;
close $f;

done_testing;
