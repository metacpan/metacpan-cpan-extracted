#!perl
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Socket ();
use Fetch;

# A pooled keep-alive connection can be closed by the server at the very
# moment it is reused: the FIN is still in flight when the pool peeks at the
# socket, so it looks healthy, and the request goes out onto a socket that is
# already gone. That is a lost race rather than a failed request, and a client
# over a pool has to survive it - so Fetch redials and sends the request
# again. It must only do that when replaying the request is safe.

# The losing side of that race, deterministically: connection 1 answers its
# first request and then hangs up on the second without answering it.
# Connection 2 onwards answers everything.
sub start_server {
    my $srv;
    socket($srv, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or return;
    setsockopt($srv, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($srv, Socket::pack_sockaddr_in(0, Socket::inet_aton('127.0.0.1')))
        or return;
    listen($srv, 20) or return;
    my $port = (Socket::unpack_sockaddr_in(getsockname $srv))[0];

    my $pid = fork;
    return unless defined $pid;
    if (!$pid) {
        # Never hold the harness's pipe open, and never outlive the run.
        open STDOUT, '>', File::Spec->devnull();
        open STDERR, '>', File::Spec->devnull();
        alarm 60;
        my $conn = 0;
        while (accept(my $cl, $srv)) {
            $conn++;
            my $seq = 0;
            while (1) {
                my $req = '';
                while (sysread($cl, my $b, 4096)) {
                    $req .= $b;
                    last if $req =~ /\r\n\r\n/;
                }
                last if $req eq '';
                $seq++;
                last if $conn == 1 && $seq == 2;   # hang up on the reuse
                my $body = "conn$conn-req$seq";
                syswrite($cl, "HTTP/1.1 200 OK\r\nContent-Length: "
                            . length($body) . "\r\n\r\n$body");
            }
            close $cl;
        }
        exit 0;
    }
    close $srv;
    return ($pid, $port);
}

# ---- an idempotent request rides out the stale connection ------------------
SKIP: {
    my ($pid, $port) = start_server();
    skip 'cannot start a test server', 3 unless $pid;
    my $url = "http://127.0.0.1:$port/";
    my $ua  = Fetch->new;

    is($ua->get($url)->get->content, 'conn1-req1',
       'the first request opens a connection');
    is($ua->get($url)->get->content, 'conn2-req1',
       'a reused connection the server closed is redialled, not failed');
    is($ua->get($url)->get->content, 'conn2-req2',
       'and the redialled connection is pooled like any other');

    kill 'KILL', $pid; waitpid $pid, 0;
}

# ---- a non-idempotent one is not replayed ----------------------------------
SKIP: {
    my ($pid, $port) = start_server();
    skip 'cannot start a test server', 3 unless $pid;
    my $url = "http://127.0.0.1:$port/";
    my $ua  = Fetch->new;

    is($ua->get($url)->get->content, 'conn1-req1', 'connection is pooled');

    # Sending this POST twice would mean the server acting on it twice, so it
    # fails instead - cleanly, and without hanging.
    my $f = $ua->post($url, body => 'charge=1');
    eval { $f->get };
    ok($f->is_failed, 'a POST onto a stale pooled connection fails');
    like($f->failure, qr/closed|reset|broken pipe/i,
         'and says why rather than being replayed');

    kill 'KILL', $pid; waitpid $pid, 0;
}

done_testing;
