use v5.36;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

{
    package T::MultiFileReceiver;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { $self->data->{received} .= $bytes }
    sub on_eof ($self) {
        $self->data->{eof}++;
        $self->data->{loop}->stop;
    }
    sub on_error ($self, $err) {
        $self->data->{reader_error} = $err;
        $self->data->{loop}->stop;
    }
}

{
    package T::MultiFileSender;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($self, $bytes) { }
    sub on_drain ($self) { $self->data->{drains}++ }
    sub on_error ($self, $err) {
        $self->data->{writer_error} = $err;
        $self->data->{loop}->stop;
    }
}

sub file_of ($bytes) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $count = syswrite($fh, $bytes, length($bytes) - $offset, $offset);
        die "syswrite: $!" if !defined($count) || !$count;
        $offset += $count;
    }
    seek($fh, 0, 0) or die "seek: $!";
    return $fh;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    setsockopt($out, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop, received => '', eof => 0, drains => 0 };
    my $receiver = T::MultiFileReceiver->new(
        loop => $loop, fh => $peer, data => $state,
    );
    my $sender = T::MultiFileSender->new(
        loop => $loop, fh => $out, data => $state,
    );

    my $a = ('abcdefgh01234567' x 8192);
    my $b = ('ZYXWVUTS98765432' x 8192);
    my $file_a = file_of($a);
    my $file_b = file_of($b);
    seek($file_a, 23, 0) or die "seek file_a: $!";
    seek($file_b, 47, 0) or die "seek file_b: $!";

    my $expected = '<A>'
        . substr($a, 20, 95_000) . '<B>'
        . substr($b, 11, 100_000) . '<A2>'
        . substr($a, length($a) - 31, 31) . '</>';
    $sender->write('<A>');
    $sender->sendfile($file_a, offset => 20, length => 95_000);
    $sender->write('<B>');
    $sender->sendfile($file_b, offset => 11, length => 100_000);
    $sender->write('<A2>');
    $sender->sendfile($file_a, offset => length($a) - 31, length => 31);
    $sender->write('</>');
    ok($sender->pending_bytes > 0, 'alternating ranges enter ordered queue');
    is(tell($file_a), 23, 'first source file position remains untouched');
    is(tell($file_b), 47, 'second source file position remains untouched');
    close $file_a;
    close $file_b;
    $sender->end;
    $loop->run_for(4);

    is($state->{received}, $expected,
        'multiple files, repeated ranges and ordinary bytes remain in order');
    is($state->{eof}, 1, 'end finishes queued file ranges before peer EOF');
    is($sender->pending_bytes, 0, 'all queued file bytes and markers are drained');
    ok(!$state->{writer_error} && !$state->{reader_error},
        'alternating range transfer has no transport errors');
    ok($state->{drains} >= 1, 'file ranges use ordinary low-watermark event');
    $sender->close;
    $receiver->close;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $writer = T::MultiFileSender->new(fh => $out, data => { drains => 0 });
    my $file = file_of('x' x (1024 * 1024));
    $writer->sendfile($file);
    ok($writer->pending_bytes > 0, 'large range remains queued for detach test');
    my $detached = eval { $writer->detach; 1 };
    ok(!$detached, 'cannot detach socket while file output is pending');
    like($@, qr/pending output must drain/, 'detach explains blocked file queue');
    ok(!$writer->is_closed, 'rejected detach leaves socket and transfer intact');
    $writer->close;
    close $peer;
    close $file;
}

done_testing;
