use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;

{
    package T::DecimalStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength';
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
    package T::DecimalPipeStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength', separator => '|';
    sub on_message ($stream, $message) { }
}

{
    package T::DecimalPrefixStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength',
        separator => '|', include_prefix => 1;
    sub on_message ($stream, $message) {
        $stream->data->{got} = $message;
        $stream->data->{loop}->stop;
    }
}

{
    package T::DecimalLimitedStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength', max_frame => 3;
    sub on_message ($stream, $message) {
        Test::More::fail('oversized DecimalLength frame must not emit');
    }
    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
        $stream->data->{loop}->stop;
    }
}

sub decimal_frame ($payload, $separator = ' ') {
    return length($payload) . $separator . $payload;
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

eval q{
    package T::BadDecimalSeparatorWidth;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength', separator => '12';
    sub on_message { }
    1;
};
like($@, qr/exactly one byte/, 'multi-byte decimal separator is rejected');

eval q{
    package T::BadDecimalDigitSeparator;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'DecimalLength', separator => '7';
    sub on_message { }
    1;
};
like($@, qr/must not be an ASCII digit/, 'digit decimal separator is rejected');

socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $state = { loop => $loop, got => [], target => 3 };
my $stream = T::DecimalStream->new(loop => $loop, fh => $a, data => $state);

ok($stream->send('HELLO'), 'default DecimalLength send succeeds');
is(read_exact($b, 7), '5 HELLO',
    'default outbound wire form is decimal length, space, payload');
ok($stream->send(''), 'empty DecimalLength send succeeds');
is(read_exact($b, 2), '0 ', 'empty payload has canonical zero length');

my $wire = decimal_frame('') . decimal_frame('x' x 128)
    . decimal_frame('done') . '12';
is(syswrite($b, $wire), length($wire),
    'peer wrote complete decimal frames and partial prefix');
$loop->run;
is_deeply($state->{got}, ['', 'x' x 128, 'done'],
    'native DecimalLength handles split prefixes and multiple messages');
is($stream->{xs_state}->stats->{input_buffered_bytes}, 2,
    'partial decimal prefix remains buffered');
$stream->close;
close $b;

socketpair(my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $pipe = T::DecimalPipeStream->new(loop => $loop, fh => $c);
ok($pipe->send('abc'), 'custom-separator send succeeds');
is(read_exact($d, 5), '3|abc', 'custom one-byte separator is used outbound');
$pipe->close;
close $d;

socketpair(my $e, my $f, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop2 = Linux::Event::Loop->new;
my $prefix_state = { loop => $loop2 };
my $prefixed = T::DecimalPrefixStream->new(
    loop => $loop2, fh => $e, data => $prefix_state,
);
syswrite($f, '5|hello');
$loop2->run;
is($prefix_state->{got}, '5|hello',
    'include_prefix preserves decimal length and separator');
$prefixed->close;
close $f;

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

like(native_error('05 hello', 'T::DecimalStream'), qr/leading zero/,
    'native DecimalLength rejects a non-canonical leading zero');
like(native_error('x bad', 'T::DecimalStream'), qr/invalid decimal length/,
    'native DecimalLength rejects a non-digit length');
like(native_error(' hello', 'T::DecimalStream'), qr/invalid decimal length/,
    'native DecimalLength requires at least one length digit');
like(native_error(('1' x 21), 'T::DecimalStream'),
    qr/decimal length field too long/,
    'native DecimalLength bounds an unterminated length field');
like(native_error('4 four', 'T::DecimalLimitedStream'),
    qr/frame exceeds max_frame=3/, 'native DecimalLength enforces max_frame');

socketpair(my $g, my $h, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $limited = T::DecimalLimitedStream->new(
    loop => $loop, fh => $g, data => { loop => $loop },
);
eval { $limited->send('four') };
like($@, qr/exceeds max_frame=3/, 'outbound DecimalLength enforces max_frame');
$limited->close;
close $h;

done_testing;
