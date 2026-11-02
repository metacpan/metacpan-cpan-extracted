use v5.36;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

{
    package T::FileDrainProducer;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($self, $bytes) { }
    sub on_drain ($self) {
        my $state = $self->data;
        $state->{drains}++;
        return if $state->{drains} != 1;

        $self->write('BETWEEN');
        $self->sendfile($state->{next_file}, offset => 127,
            length => $state->{next_length});
        close($state->{next_file});
        $self->write('DONE');
        $self->end;
    }
    sub on_error ($self, $err) {
        $self->data->{writer_error} = "$err";
        $self->data->{loop}->stop;
    }
}

{
    package T::FileDrainReceiver;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_data ($self, $bytes) { $self->data->{received} .= $bytes }
    sub on_eof ($self) {
        $self->data->{eofs}++;
        $self->data->{loop}->stop;
    }
    sub on_error ($self, $err) {
        $self->data->{reader_error} = "$err";
        $self->data->{loop}->stop;
    }
}

sub file_of ($bytes) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $pos = 0;
    while ($pos < length($bytes)) {
        my $n = syswrite($fh, $bytes, length($bytes) - $pos, $pos);
        die "syswrite failed: $!" if !defined($n) || !$n;
        $pos += $n;
    }
    seek($fh, 0, 0) or die "seek failed: $!";
    return $fh;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    setsockopt($out, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt failed: $!";
    my $loop = Linux::Event::Loop->new;
    my $first = 'F' x (512 * 1024);
    my $second = 'S' x (256 * 1024);
    my $file1 = file_of($first);
    my $file2 = file_of($second);
    my $state = {
        loop => $loop, drains => 0, eofs => 0, received => '',
        next_file => $file2, next_length => length($second) - 127,
    };
    my $receiver = T::FileDrainReceiver->new(
        loop => $loop, fh => $peer, data => $state,
    );
    my $writer = T::FileDrainProducer->new(
        loop => $loop, fh => $out, data => $state,
    );
    $writer->write('START');
    $writer->sendfile($file1);
    close($file1);
    cmp_ok($writer->pending_bytes, '>', 4096,
        'first file is queued above the drain watermark');
    $loop->run_for(4);

    is($state->{received}, 'START' . $first . 'BETWEEN'
        . substr($second, 127) . 'DONE',
        'on_drain file submission preserves preceding bytes and final marker');
    cmp_ok($state->{drains}, '>=', 1,
        'on_drain submits the second file from inside a native callback');
    is($state->{eofs}, 1, 'graceful end follows reentrant file output');
    ok(!$state->{writer_error} && !$state->{reader_error},
        'reentrant file submission produces no transport error');
    is($writer->pending_bytes, 0, 'all reentrant output drains');
    $writer->close;
    $receiver->close;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    my $writer = T::FileDrainProducer->new(
        fh => $out, data => { drains => 0 },
    );
    my $empty = file_of('');
    is($writer->sendfile($empty), 1, 'empty source is an accepted no-op');
    is($writer->sendfile($empty, offset => 0, length => 0), 1,
        'explicit zero-length range is an accepted no-op');
    is($writer->pending_bytes, 0, 'empty source queues no output');
    is(tell($empty), 0, 'empty source offset remains unchanged');
    $writer->close;
    close($peer);
    close($empty);
}

done_testing;
