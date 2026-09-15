use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::IO::Pipe;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::TTY;

{
    package T::ResourceKind::PipeA;
    use parent 'Linux::Event::IO::Pipe';
    sub on_data ($self, $bytes) { return }
}

{
    package T::ResourceKind::PipeB;
    use parent 'Linux::Event::IO::Pipe';
    sub on_data ($self, $bytes) { return }
}

{
    package T::ResourceKind::TTYA;
    use parent 'Linux::Event::IO::TTY';
    sub on_data ($self, $bytes) { return }
}

{
    package T::ResourceKind::TTYB;
    use parent 'Linux::Event::IO::TTY';
    sub on_data ($self, $bytes) { return }
}

{
    package T::ResourceKind::SockA;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { return }
}

{
    package T::ResourceKind::SockB;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) { return }
}

sub rejects_kind_change ($object, $target, $from, $to) {
    my $class = ref $object;
    my $descriptor = refaddr($object->{descriptor});
    my $xs_state = refaddr($object->{xs_state});

    my $ok = eval {
        $object->transition_to($target);
        1;
    };
    ok(!$ok, "$from -> $to transition is rejected");
    like(
        $@,
        qr/cannot change ordered-byte resource kind \($from -> $to\)/,
        'resource-kind error identifies both sides',
    );
    is(ref($object), $class, 'failed transition preserves source class');
    is(refaddr($object->{descriptor}), $descriptor,
        'failed transition preserves descriptor');
    is(refaddr($object->{xs_state}), $xs_state,
        'failed transition preserves native state');
}

subtest 'Pipe transitions remain Pipe transitions' => sub {
    pipe(my $read_fh, my $write_fh) or die "pipe: $!";
    my $pipe = T::ResourceKind::PipeA->new(read_fh => $read_fh);

    rejects_kind_change($pipe, 'T::ResourceKind::TTYA', 'pipe', 'tty');
    rejects_kind_change(
        $pipe, 'T::ResourceKind::SockA', 'pipe', 'stream-socket',
    );

    $pipe->transition_to('T::ResourceKind::PipeB');
    isa_ok($pipe, 'T::ResourceKind::PipeB',
        'same-kind Pipe protocol transition succeeds');

    $pipe->close;
    close $write_fh;
};

subtest 'stream-socket transitions remain stream-socket transitions' => sub {
    socketpair(my $socket_fh, my $peer_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $stream = T::ResourceKind::SockA->new(fh => $socket_fh);

    rejects_kind_change(
        $stream, 'T::ResourceKind::PipeA', 'stream-socket', 'pipe',
    );
    rejects_kind_change(
        $stream, 'T::ResourceKind::TTYA', 'stream-socket', 'tty',
    );

    $stream->transition_to('T::ResourceKind::SockB');
    isa_ok($stream, 'T::ResourceKind::SockB',
        'same-kind stream-socket protocol transition succeeds');

    $stream->close;
    close $peer_fh;
};

subtest 'TTY transitions remain TTY transitions' => sub {
    my $opened = open(my $pty_fh, '+<', '/dev/ptmx');
    if (!$opened || !-t $pty_fh) {
        close $pty_fh if $opened;
        plan skip_all => '/dev/ptmx is unavailable as a TTY on this system';
    }

    my $tty = T::ResourceKind::TTYA->new(fh => $pty_fh);

    rejects_kind_change($tty, 'T::ResourceKind::PipeA', 'tty', 'pipe');
    rejects_kind_change(
        $tty, 'T::ResourceKind::SockA', 'tty', 'stream-socket',
    );

    $tty->transition_to('T::ResourceKind::TTYB');
    isa_ok($tty, 'T::ResourceKind::TTYB',
        'same-kind TTY protocol transition succeeds');

    $tty->close;
};

done_testing;
