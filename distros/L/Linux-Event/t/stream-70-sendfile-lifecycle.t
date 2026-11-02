use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use File::Temp ();
use FindBin qw($Bin);
use POSIX qw(_exit);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::TLS;

{
    package T::FileLifecycle;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($self, $bytes) {
        my $state = $self->data;
        $state->{received} .= $bytes;
        $state->{loop}->stop
            if $state->{loop} && length($state->{received})
                >= ($state->{expected_size} // 1_000_000_000);
    }
    sub on_error ($self, $err) {
        $self->data->{error} = $err;
        $self->data->{loop}->stop if $self->data->{loop};
    }
}

{
    package T::FramedFileLifecycle;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Fixed', size => 4;
    sub on_message ($self, $msg) { }
}

sub file_of ($data) {
    my $fh = File::Temp->new(UNLINK => 1);
    binmode($fh);
    my $offset = 0;
    while ($offset < length($data)) {
        my $count = syswrite($fh, $data, length($data) - $offset, $offset);
        die "syswrite: $!" if !defined($count) || $count == 0;
        $offset += $count;
    }
    seek($fh, 0, 0) or die "seek: $!";
    return $fh;
}

sub fd_count () {
    opendir(my $dir, '/proc/self/fd') or die "opendir /proc/self/fd: $!";
    my $count = scalar(grep { /^\d+$/ } readdir($dir));
    closedir($dir);
    return $count;
}

{
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $state = { received => '' };
    my $writer = T::FileLifecycle->new(fh => $left, data => $state);
    my $fh = file_of('D' x (1024 * 1024));
    my $before = fd_count();
    ok($writer->sendfile($fh), 'large sendfile accepts the fixed source range');
    is(fd_count(), $before + 1, 'queued range owns a duplicated fd');
    $writer->close;
    is(fd_count(), $before - 1,
        'close drops queued file duplicate and owning socket');
    close $right;
    close $fh;
}

{
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $writer = T::FileLifecycle->new(
        fh => $left, data => { received => '' },
    );
    my $fh = file_of('E' x (1024 * 1024));
    my $before = fd_count();
    $writer->sendfile($fh);
    is(fd_count(), $before + 1, 'close_write setup holds one duplicate');
    $writer->close_write;
    is($writer->pending_bytes, 0, 'close_write discards queued range');
    is(fd_count(), $before, 'close_write closes the source duplicate');
    $writer->close;
    close $right;
    close $fh;
}

{
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $writer = T::FileLifecycle->new(
        fh => $left, data => { received => '' },
    );
    my $fh = file_of('hello');
    ok($writer->sendfile($fh, length => 0), 'zero-length range is a no-op');
    is($writer->pending_bytes, 0, 'zero range adds no pending bytes');
    my $ok = eval { $writer->sendfile($right); 1 };
    ok(!$ok, 'socket source is rejected as a non-regular file');
    like($@, qr/source must be a regular file/,
        'nonregular source has a clear diagnostic');
    my $temporary = File::Temp->new(UNLINK => 1);
    my $path = $temporary->filename;
    open(my $writeonly, '>', $path) or die "open writeonly: $!";
    my $readable_ok = eval { $writer->sendfile($writeonly); 1 };
    ok(!$readable_ok, 'write-only regular file is rejected');
    like($@, qr/source file is not readable/,
        'unreadable source is explained without closing the Stream');
    ok(!$writer->is_closed, 'bad source arguments do not close output socket');
    close $writeonly;
    close $temporary;
    $writer->close;
    close $right;
    close $fh;
}

{
    socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $state = { loop => $loop, received => '', expected_size => 8 };
    my $reader = T::FileLifecycle->new(
        loop => $loop, fh => $right, data => $state,
    );
    my $writer = T::FramedFileLifecycle->new(
        loop => $loop, fh => $left,
    );
    my $fh = file_of('abcdef');
    $writer->write('H');
    ok($writer->sendfile($fh), 'framed subclass permits explicit raw file bytes');
    $writer->write('T');
    $writer->end;
    $loop->run_for(2);
    is($state->{received}, 'HabcdefT',
        'sendfile on framed subclass does not add message framing');
    $writer->close;
    $reader->close;
    close $fh;
}

{
    socketpair(my $client_fh, my $server_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    my $loop = Linux::Event::Loop->new;
    my $cert = "$Bin/tls-certs/server-cert.pem";
    my $key = "$Bin/tls-certs/server-key.pem";
    my $state = { loop => $loop, received => '' };
    my $server = T::FileLifecycle->new(
        loop => $loop, fh => $server_fh, data => $state,
        transport => Linux::Event::TLS->server(
            cert_file => $cert, key_file => $key,
        ),
    );
    my $client = T::FileLifecycle->new(
        loop => $loop, fh => $client_fh, data => $state,
        transport => Linux::Event::TLS->client(
            server_name => 'localhost', ca_file => $cert,
        ),
    );
    my $fh = file_of('SECRET');
    my $early = eval { $client->sendfile($fh); 1 };
    ok(!$early, 'TLS sendfile is rejected before handshake');
    like($@, qr/requires a plain transport/, 'TLS rejection names transport');
    $loop->run_for(1);
    ok($client->is_transport_ready, 'TLS handshake completed');
    my $late = eval { $client->sendfile($fh); 1 };
    ok(!$late, 'TLS sendfile is rejected after handshake');
    is($state->{received}, '', 'raw file bytes never bypass TLS');
    $client->close;
    $server->close;
    close $fh;
}

{
    my $child = fork();
    die "fork: $!" unless defined $child;
    if ($child == 0) {
        $SIG{PIPE} = 'DEFAULT';
        socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
            or _exit(10);
        my $state = { received => '' };
        my $writer = T::FileLifecycle->new(fh => $left, data => $state);
        my $fh = file_of('S' x (1024 * 1024));
        close $right;
        eval { $writer->sendfile($fh); 1 };
        _exit($state->{error} ? 0 : 11);
    }
    waitpid($child, 0);
    is($?, 0, 'sendfile peer disconnect reports an error without SIGPIPE death');
}

done_testing;
