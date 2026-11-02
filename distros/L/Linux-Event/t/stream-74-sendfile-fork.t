use v5.36;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use POSIX qw(_exit);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_SNDBUF);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;

{
    package T::ForkFileSender;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_data ($self, $bytes) { }
    sub on_error ($self, $error) {
        $self->data->{writer_error} = "$error";
        $self->data->{loop}->stop;
    }
}

{
    package T::ForkFileReceiver;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { $self->data->{received} .= $bytes }
    sub on_eof ($self) {
        $self->data->{eof}++;
        $self->data->{loop}->stop;
    }
    sub on_error ($self, $error) {
        $self->data->{reader_error} = "$error";
        $self->data->{loop}->stop;
    }
}

sub source_file ($body) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $written = 0;
    while ($written < length($body)) {
        my $count = syswrite($fh, $body,
            length($body) - $written, $written);
        die "source write failed: $!" if !defined($count) || !$count;
        $written += $count;
    }
    seek($fh, 0, 0) or die "seek source: $!";
    return $fh;
}

sub source_fd_count ($fh) {
    my @info = stat($fh);
    die "stat source failed" unless @info;
    opendir(my $dir, '/proc/self/fd') or die "opendir: $!";
    my $count = 0;
    for my $fd (grep { /^\d+$/ } readdir($dir)) {
        my @entry = stat("/proc/self/fd/$fd");
        $count++ if @entry
            && $entry[0] == $info[0] && $entry[1] == $info[1];
    }
    closedir($dir);
    return $count;
}

sub child_exit ($ok) { _exit($ok ? 0 : 1) }
sub child_ok ($pid, $name) {
    is(waitpid($pid, 0), $pid, "$name process reaped");
    is($? >> 8, 0, "$name process succeeded");
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop };
    my $writer = T::ForkFileSender->new(
        loop => $loop, fh => $out, data => $state,
    );
    my $fh = source_file('x' x (1024 * 1024));
    $writer->sendfile($fh);
    ok($writer->pending_bytes > 0, 'parent has queued file output before fork');
    is(source_fd_count($fh), 2, 'parent owns source and queued source duplicate');

    my $pid = $loop->fork;
    if ($pid == 0) {
        child_exit($writer->is_closed && !$loop->has($writer)
            && source_fd_count($fh) == 1);
    }
    child_ok($pid, 'unlisted Stream child drop');
    ok(!$writer->is_closed, 'unlisted queued Stream remains active in parent');
    is(source_fd_count($fh), 2, 'child drop does not disturb parent source fd');
    $writer->close;
    is(source_fd_count($fh), 1, 'parent close releases queued source fd');
    close $fh;
    close $peer;
}

{
    socketpair(my $out, my $peer, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    setsockopt($out, SOL_SOCKET, SO_SNDBUF, pack('i', 4096))
        or die "setsockopt: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = {
        loop => $loop, received => '', eof => 0,
    };
    my $receiver = T::ForkFileReceiver->new(
        loop => $loop, fh => $peer, data => $state,
    );
    my $writer = T::ForkFileSender->new(
        loop => $loop, fh => $out, data => $state,
    );
    my $body = ('abcdef0123456789' x 32768);
    my $fh = source_file($body);
    $writer->write('BEGIN');
    $writer->sendfile($fh);
    $writer->write('END');
    $writer->end;
    ok($writer->pending_bytes > 0,
        'file and trailer remain queued before managed move');

    my $pid = $loop->fork(move => [$writer]);
    if ($pid == 0) {
        my $valid = $writer->state eq 'active'
            && $loop->has($writer)
            && source_fd_count($fh) == 2;
        $loop->run_for(4);
        $valid &&= !$state->{writer_error} && $writer->pending_bytes == 0
            && source_fd_count($fh) == 1;
        child_exit($valid);
    }
    is($writer->state, 'moved', 'parent writer becomes moved after fork');
    is(source_fd_count($fh), 1,
        'moving Stream releases parent copy of queued source fd');
    $loop->run_for(4);
    is($state->{received}, 'BEGIN' . $body . 'END',
        'child drains inherited ordered file segment to parent receiver');
    is($state->{eof}, 1, 'child end sends EOF after the file and trailer');
    ok(!$state->{reader_error}, 'receiving the moved file reports no error');
    child_ok($pid, 'moved Stream file transfer');
    $receiver->close;
    close $fh;
}

done_testing;
