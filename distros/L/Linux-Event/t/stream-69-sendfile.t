use v5.36;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

{
    package T::SendfileReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) {
        my $state = $self->data;
        $state->{received} .= $bytes;
        $state->{loop}->stop
            if length($state->{received}) >= $state->{expected_size};
    }
    sub on_error ($self, $error) {
        $self->data->{reader_error} = $error;
        $self->data->{loop}->stop;
    }
}

{
    package T::SendfileWriter;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($self, $bytes) { }
    sub on_drain ($self) { $self->data->{drains}++ }
    sub on_error ($self, $error) {
        $self->data->{writer_error} = $error;
        $self->data->{loop}->stop;
    }
}

{
    package T::SendfileLimited;
    use parent -norequire, 'T::SendfileWriter';
    sub stream_tuning ($class) {
        return high_watermark => 2048, low_watermark => 1024,
            max_pending_bytes => 4096;
    }
}

sub source_file ($data) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $written = syswrite($fh, $data);
    die "source_file: syswrite failed: $!" if !defined($written)
        || $written != length($data);
    seek($fh, 0, 0) or die "seek: $!";
    return $fh;
}

sub pair ($writer_class = 'T::SendfileWriter') {
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    setsockopt($left, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop, received => '', drains => 0 };
    my $reader = T::SendfileReader->new(
        loop => $loop, fh => $right, data => $state,
    );
    my $writer = $writer_class->new(
        loop => $loop, fh => $left, data => $state,
    );
    return ($loop, $state, $writer, $reader);
}

my $body = ('0123456789abcdef' x 65536);
{
    my ($loop, $state, $writer, $reader) = pair();
    my $fh = source_file($body);
    seek($fh, 37, 0);
    my $expected = 'HEADER' . $body . 'TRAILER';
    $state->{expected_size} = length($expected);

    ok($writer->write('HEADER'), 'header accepted');
    ok(!$writer->sendfile($fh), 'large file is accepted with backpressure');
    is(tell($fh), 37, 'sendfile does not change source file position');
    ok($writer->pending_bytes > 0, 'unsent file range counts as pending output');
    close($fh);
    ok($writer->write('TRAILER') == 0 || $writer->pending_bytes > 0,
        'trailer accepted behind the file');
    $writer->end;
    $loop->run_for(4);

    is($state->{received}, $expected, 'header, file and trailer arrive in order');
    ok(!$state->{writer_error}, 'no file transfer error');
    ok(!$state->{reader_error}, 'no receiver error');
    is($writer->pending_bytes, 0, 'file range and trailer drain completely');
    ok($state->{drains} >= 1, 'file transfer participates in on_drain');
    $writer->close;
    $reader->close;
}

{
    my ($loop, $state, $writer, $reader) = pair();
    my $fh = source_file('abcdefghij' x 10000);
    my $expected = '[' . substr('abcdefghij' x 10000, 312, 2000)
        . ']';
    $state->{expected_size} = length($expected);
    $writer->write('[');
    ok($writer->sendfile($fh, offset => 312, length => 2000),
        'small explicit source range accepted');
    $writer->write(']');
    $writer->end;
    $loop->run_for(4);
    is($state->{received}, $expected, 'explicit range preserves exact bytes');
    is(tell($fh), 0, 'range send leaves the original file position untouched');
    $writer->close;
    $reader->close;
    close($fh);
}

{
    my ($loop, $state, $writer, $reader) = pair('T::SendfileLimited');
    my $fh = source_file('Z' x 131072);
    my $accepted = $writer->sendfile($fh);
    ok(!$accepted, 'hard output cap rejects an oversized source range');
    ok($writer->is_closed, 'output limit fails and closes the Stream');
    isa_ok($state->{writer_error}, 'Linux::Event::Error');
    is($state->{writer_error}->type, 'output_limit',
        'file range uses existing output limit error type');
    $reader->close;
    close($fh);
}

{
    my ($loop, $state, $writer, $reader) = pair();
    my $fh = source_file('0123456789');
    for my $invalid (
        [ offset => -1 ],
        [ offset => 11 ],
        [ offset => 4, length => 7 ],
        [ length => 2.5 ],
        [ mystery => 1 ],
    ) {
        my $ok = eval { $writer->sendfile($fh, @$invalid); 1 };
        ok(!$ok, 'invalid range or option is rejected');
        like($@, qr/sendfile\(\)/, 'invalid argument has sendfile diagnostic');
    }
    $writer->close;
    $reader->close;
    close($fh);
}

{
    my ($loop, $state, $writer, $reader) = pair();
    my $source = source_file('A' x (1024 * 1024));
    $state->{expected_size} = 1024 * 1024;
    ok(!$writer->sendfile($source), 'large range queued before truncation');
    truncate($source, 0) or die "truncate: $!";
    $loop->run_for(4);
    ok($writer->is_closed, 'truncating a pending source produces terminal error');
    isa_ok($state->{writer_error}, 'Linux::Event::Error');
    $reader->close;
    close($source);
}

done_testing;
