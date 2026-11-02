use v5.36;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

{
    package T::FileFairnessWriter;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($self, $bytes) { }
    sub on_error ($self, $error) {
        $self->data->{error} = $error;
        $self->data->{loop}->stop;
    }
}

{
    package T::FileFairnessNext;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { }
}

{
    package T::FileFairnessReader;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) {
        $self->data->{received} .= $bytes;
        $self->data->{loop}->stop
            if length($self->data->{received})
                >= $self->data->{expected_size};
    }
}

{
    package T::FileFairnessClose;
    use parent -norequire, 'T::FileFairnessWriter';
    sub on_drain ($self) {
        $self->data->{drains}++;
        $self->close;
        $self->data->{loop}->stop;
    }
}

sub source ($size) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $block = '0123456789abcdef' x 4096;
    my $left = $size;
    while ($left) {
        my $amount = $left > length($block) ? length($block) : $left;
        my $n = syswrite($fh, $block, $amount);
        die "syswrite failed: $!" if !defined $n || !$n;
        $left -= $n;
    }
    seek($fh, 0, 0) or die "seek: $!";
    return $fh;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    setsockopt($out, SOL_SOCKET, SO_SNDBUF, pack('i', 1024 * 1024))
        or die "setsockopt: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop };
    my $writer = T::FileFairnessWriter->new(
        loop => $loop, fh => $out, data => $state,
    );
    my $fh = source(1024 * 1024);
    ok(!$writer->sendfile($fh), 'file range enters bounded output queue');
    my $before = $writer->{xs_state}->stats->{bytes_written};
    $loop->run_once(100);
    my $after = $writer->{xs_state}->stats->{bytes_written};
    ok($after > $before, 'first writable readiness makes file progress');
    ok($after - $before <= 65536,
        'first readiness moves no more than file fairness budget');
    $before = $after;
    $loop->run_once(100);
    $after = $writer->{xs_state}->stats->{bytes_written};
    ok($after - $before <= 65536,
        'second readiness also respects per-turn budget');
    ok($writer->pending_bytes > 0, 'large transfer has remaining queued bytes');
    $writer->close;
    close $peer;
    close $fh;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $fh = source(256 * 1024);
    my $body = ('0123456789abcdef' x 16384);
    my $expected = '<' . $body . '>';
    my $state = { loop => $loop, received => '', expected_size => length($expected) };
    my $reader = T::FileFairnessReader->new(
        loop => $loop, fh => $peer, data => $state,
    );
    my $writer = T::FileFairnessWriter->new(
        loop => $loop, fh => $out, data => $state,
    );
    $writer->write('<');
    $writer->sendfile($fh);
    $writer->transition_to('T::FileFairnessNext');
    $writer->write('>');
    $writer->end;
    $loop->run_for(4);
    is($state->{received}, $expected,
        'protocol transition preserves queued file ordering and bytes');
    ok(!$state->{error}, 'transitioned file transfer has no write error');
    $writer->close;
    $reader->close;
    close $fh;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop, drains => 0 };
    my $fh = source(1024 * 1024);
    my $reader = T::FileFairnessReader->new(
        loop => $loop, fh => $peer,
        data => { loop => $loop, received => '', expected_size => 1024 * 1024 },
    );
    my $writer = T::FileFairnessClose->new(
        loop => $loop, fh => $out, data => $state,
    );
    $writer->sendfile($fh);
    $loop->run_for(4);
    is($state->{drains}, 1, 'on_drain fires exactly once');
    ok($writer->is_closed, 'closing inside on_drain safely tears down queue');
    ok(!$state->{error}, 'reentrant close causes no write error');
    $writer->close;
    $reader->close;
    close $fh;
}

done_testing;
