use v5.36;
use strict;
use warnings;

use Test::More;
use Fcntl qw(O_NONBLOCK O_RDONLY O_WRONLY);
use File::Temp qw(tempdir);
use POSIX qw(mkfifo);
use Socket qw(AF_UNIX SOCK_DGRAM);

use Linux::Event::Loop;
use Linux::Event::_ByteStream;
use Linux::Event::IO::Sock::Stream;

{
    package T::GenericReader;
    use parent 'Linux::Event::_ByteStream';
    sub on_data ($self, $bytes) { $self->data->{bytes} .= $bytes }
    sub on_eof ($self) {
        $self->data->{eof}++;
        $self->data->{loop}->stop;
    }
}

{
    package T::GenericWriter;
    use parent 'Linux::Event::_ByteStream';
}

{
    package T::QueuedWriter;
    use parent 'Linux::Event::_ByteStream';
    sub stream_tuning ($class) {
        return high_watermark => 4096, low_watermark => 1024;
    }
    sub on_drain ($self) { $self->data->{drains}++ }
    sub on_close ($self) { $self->data->{loop}->stop }
}

{
    package T::GenericDuplex;
    use parent 'Linux::Event::_ByteStream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($self, $line) {
        $self->write("reply:$line\n");
        $self->data->{messages}++;
    }
    sub on_eof ($self) {
        $self->data->{eof}++;
        $self->data->{loop}->stop;
    }
}

{
    package T::Console;
    use parent 'Linux::Event::_ByteStream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub on_message ($self, $line) { $self->write("You typed: $line\n") }
    sub on_eof ($self) { $self->end; $self->data->{loop}->stop }
}

{
    package T::SocketProbe;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { }
}

{
    package T::FakeWatcher;
    sub new ($class) { bless { cancelled => 0 }, $class }
    sub disable_read ($self) { }
    sub disable_write ($self) { }
    sub cancel ($self) { $self->{cancelled} = 1 }
}

{
    package T::PartialLoop;
    sub new ($class) { bless { calls => 0, watchers => [] }, $class }
    sub add ($self, $object) { $object->_attach_to_loop($self) }
    sub watch_fd ($self, @args) {
        die "synthetic second watcher failure\n" if ++$self->{calls} == 2;
        my $watcher = T::FakeWatcher->new;
        push @{ $self->{watchers} }, $watcher;
        return $watcher;
    }
}

{
    pipe(my $read, my $write) or die "pipe: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { loop => $loop, bytes => '', eof => 0 };
    my $stream = T::GenericReader->new(
        loop => $loop, read_fh => $read, data => $data,
    );
    ok($stream->has_read && !$stream->has_write,
        'read-only Stream exposes its capability');
    syswrite($write, 'generic input') == 13 or die "syswrite: $!";
    close $write;
    $loop->run;
    is($data->{bytes}, 'generic input', 'read-only Stream drains bytes');
    is($data->{eof}, 1, 'read-only Stream reports EOF once');
    ok($stream->is_closed, 'read-only Stream closes after EOF');
}

{
    pipe(my $input_read, my $input_write) or die "input pipe: $!";
    pipe(my $output_read, my $output_write) or die "output pipe: $!";
    my $stream = T::GenericDuplex->new(
        read_fh => $input_read, write_fh => $output_write,
    );
    my $handles = $stream->detach;
    is($stream->state, 'detached', 'generic detach is terminal');
    is_deeply([sort keys %$handles], [qw(read_fh write_fh)],
        'generic detach returns both directional handles');
    syswrite($input_write, "detached\n") == 9 or die "syswrite: $!";
    is(sysread($handles->{read_fh}, my $input, 9), 9,
        'detached read handle remains open');
    is($input, "detached\n", 'detached read handle retains byte ordering');
    syswrite($handles->{write_fh}, 'output') == 6 or die "syswrite: $!";
    is(sysread($output_read, my $output, 6), 6,
        'detached write handle remains open');
    is($output, 'output', 'detached write handle retains byte ordering');
    close $handles->{read_fh};
    close $handles->{write_fh};
    close $input_write;
    close $output_read;
}

{
    pipe(my $input_read, my $input_write) or die "input pipe: $!";
    pipe(my $output_read, my $output_write) or die "output pipe: $!";
    my $stream = T::GenericDuplex->new(
        read_fh => $input_read, write_fh => $output_write,
    );
    my $broken = T::PartialLoop->new;
    my $error = eval { $broken->add($stream); 1 } ? '' : "$@";
    like($error, qr/synthetic second watcher failure/,
        'split registration reports a second-watcher failure');
    ok($broken->{watchers}[0]{cancelled},
        'split registration rolls back the first watcher');
    is($stream->state, 'unattached',
        'split Stream remains attachable after partial registration failure');
    my $loop = Linux::Event::Loop->new;
    is($loop->add($stream), $stream,
        'split Stream attaches after registration rollback');
    $stream->close;
    close $input_write;
    close $output_read;
}

{
    socketpair(my $stream_fh, my $peer_fh, AF_UNIX, Socket::SOCK_STREAM(), 0)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { bytes => '' };
    my $stream = T::GenericReader->new(
        loop => $loop, fh => $stream_fh, data => $data,
    );
    $stream->close_read;
    ok($stream->is_read_closed && !$stream->is_closed,
        'close_read leaves a shared generic write direction alive');
    syswrite($peer_fh, 'ignored') == 7 or die "syswrite: $!";
    $loop->run_for(0.01);
    is($data->{bytes}, '', 'close_read disables shared-descriptor reads');
    ok($stream->write('still-writable'),
        'shared generic handle remains writable after close_read');
    is(sysread($peer_fh, my $output, 14), 14,
        'peer receives bytes after generic close_read');
    is($output, 'still-writable', 'post-close_read bytes are intact');
    $stream->close_write;
    ok($stream->is_closed, 'closing the last shared direction closes Stream');
    close $peer_fh;
}

SKIP: {
    my $directory = tempdir(CLEANUP => 1);
    my $path = "$directory/input.fifo";
    skip "mkfifo unavailable: $!", 3 if !mkfifo($path, 0600);
    sysopen(my $read, $path, O_RDONLY | O_NONBLOCK)
        or skip "FIFO read open unavailable: $!", 3;
    sysopen(my $write, $path, O_WRONLY | O_NONBLOCK)
        or skip "FIFO write open unavailable: $!", 3;
    my $loop = Linux::Event::Loop->new;
    my $data = { loop => $loop, bytes => '', eof => 0 };
    my $stream = T::GenericReader->new(
        loop => $loop, read_fh => $read, data => $data,
    );
    syswrite($write, 'fifo') == 4 or die "FIFO syswrite: $!";
    close $write;
    $loop->run;
    is($data->{bytes}, 'fifo', 'generic Stream reads a FIFO');
    is($data->{eof}, 1, 'generic FIFO read reports EOF');
    ok($stream->is_closed, 'read-only FIFO Stream closes after EOF');
}

{
    pipe(my $read, my $write) or die "pipe: $!";
    my $stream = T::GenericWriter->new(write_fh => $write);
    ok(!$stream->has_read && $stream->has_write,
        'write-only Stream exposes its capability');
    ok($stream->write('generic output'), 'write-only Stream writes bytes');
    $stream->end;
    is(do { local $/; <$read> }, 'generic output',
        'write-only end drains and closes its handle');
    ok($stream->is_closed, 'write-only Stream closes after end');
    close $read;
}

{
    pipe(my $input_read, my $input_write) or die "input pipe: $!";
    pipe(my $output_read, my $output_write) or die "output pipe: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { loop => $loop, messages => 0, eof => 0 };
    my $stream = T::GenericDuplex->new(
        loop => $loop,
        read_fh => $input_read,
        write_fh => $output_write,
        data => $data,
    );
    ok(!defined($stream->fh), 'split Stream has no ambiguous shared fh');
    isnt($stream->read_fd, $stream->write_fd,
        'split Stream registers independent descriptors');
    syswrite($input_write, "hello\n") == 6 or die "syswrite: $!";
    close $input_write;
    $loop->run;
    is($data->{messages}, 1, 'split Stream uses native framing on read side');
    is($data->{eof}, 1, 'split Stream observes read EOF');
    ok(!$stream->is_closed, 'read EOF leaves independent write side open');
    ok($stream->write('after-eof'), 'write remains legal after read EOF');
    $stream->end;
    is(do { local $/; <$output_read> }, "reply:hello\nafter-eof",
        'split output drains in order before write end');
    ok($stream->is_closed, 'split Stream closes after both directions end');
    close $output_read;
}

{
    pipe(my $read, my $write) or die "pipe: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { loop => $loop, bytes => 0, drains => 0 };
    my $stream = T::QueuedWriter->new(
        write_fh => $write, data => $data,
    );
    my $reader = $loop->watch(
        fh => $read,
        data => $data,
        read => sub ($watcher) {
            my $n = sysread($read, my $bytes, 65_536);
            if (defined $n) {
                if ($n == 0) { $watcher->cancel; return }
                $data->{bytes} += $n;
                return;
            }
            return if $!{EINTR};
            die "sysread: $!";
        },
    );
    my $payload = 'x' x (1024 * 1024);
    ok(!$stream->write($payload),
        'detached generic write side applies native queue backpressure');
    cmp_ok($stream->pending_bytes, '>', 0, 'generic output is queued natively');
    $loop->add($stream);
    $stream->end;
    $loop->run;
    while (1) {
        my $n = sysread($read, my $bytes, 65_536);
        last if defined($n) && $n == 0;
        if (defined $n) { $data->{bytes} += $n; next }
        next if $!{EINTR};
        die "final sysread: $!";
    }
    is($data->{bytes}, length($payload), 'generic end drains the full queue');
    is($data->{drains}, 1, 'generic queue reports one drain transition');
    close $read;
}

{
    pipe(my $input_read, my $input_write) or die "input pipe: $!";
    pipe(my $output_read, my $output_write) or die "output pipe: $!";
    local *STDIN;
    local *STDOUT;
    open STDIN, '<&', $input_read or die "dup STDIN: $!";
    open STDOUT, '>&', $output_write or die "dup STDOUT: $!";
    close $input_read;
    close $output_write;
    my $loop = Linux::Event::Loop->new;
    my @warning;
    local $SIG{__WARN__} = sub { push @warning, @_ };
    my $console = T::Console->new(
        loop => $loop, read_fh => \*STDIN, write_fh => \*STDOUT,
        data => { loop => $loop },
    );
    syswrite($input_write, "console\n") == 8 or die "syswrite: $!";
    close $input_write;
    $loop->run;
    is(do { local $/; <$output_read> }, "You typed: console\n",
        'STDIN/STDOUT Stream behaves as a framed console');
    is_deeply(\@warning, [], 'generic Stream performs no socket address lookup');
    close $output_read;
}

{
    pipe(my $read, my $write) or die "pipe: $!";
    my $error = eval { T::SocketProbe->new(fh => $read); 1 } ? '' : "$@";
    like($error, qr/not a socket/, 'Socket rejects a non-socket descriptor');
    close $read if defined fileno($read);
    close $write;
}

{
    pipe(my $read, my $write) or die "pipe: $!";
    my $loop = Linux::Event::Loop->new;
    my $data = { loop => $loop, bytes => '', eof => 0 };
    my $stream = T::GenericReader->new(read_fh => $read, data => $data);
    $stream->pause_read;
    $loop->add($stream);
    syswrite($write, 'paused') == 6 or die "syswrite: $!";
    $loop->run_for(0.01);
    is($data->{bytes}, '',
        'pause_read before attachment suppresses generic input');
    $stream->resume_read;
    close $write;
    $loop->run;
    is($data->{bytes}, 'paused',
        'resume_read enables a previously detached read side');
}

{
    pipe(my $read, my $write) or die "pipe: $!";
    my $error = eval {
        T::GenericWriter->new(fh => $write, write_fh => $write);
        1;
    } ? '' : "$@";
    like($error, qr/fh cannot be combined/,
        'shared and directional constructor forms are exclusive');
    $error = eval { T::GenericWriter->new; 1 } ? '' : "$@";
    like($error, qr/at least one of fh, read_fh, or write_fh/,
        'generic Stream requires at least one direction');
    $error = eval { T::GenericWriter->connect(host => '127.0.0.1'); 1 }
        ? '' : "$@";
    like($error, qr/only on Linux::Event::IO::Sock::Stream subclasses/,
        'generic Stream does not expose socket connection acquisition');
    close $read;
    close $write;
}

SKIP: {
    skip "datagram socket unavailable: $!", 1
        if !socket(my $datagram, AF_UNIX, SOCK_DGRAM, 0);
    my $error = eval { T::SocketProbe->new(fh => $datagram); 1 } ? '' : "$@";
    like($error, qr/not a SOCK_STREAM socket/,
        'Socket rejects a datagram socket');
    close $datagram;
}

done_testing;
