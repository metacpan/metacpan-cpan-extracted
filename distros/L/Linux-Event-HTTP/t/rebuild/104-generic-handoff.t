use v5.36;
use Test::More;
use IO::Socket::INET;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;

{
    package Local::RawEcho;
    sub new ($class, %arg) { bless { %arg, seen => '', failed => '' }, $class }
    sub input ($self, $bytes) {
        $self->{seen} .= $bytes;
        $self->{host}->unblock_send("ACK:$bytes");
        $self->{loop}->stop;
        return length($bytes);
    }
    sub input_eof ($self) { $self->{eof}++; return }
    sub transport_error ($self, $err) { $self->{failed} .= "$err"; return }
    sub resume_output ($self) { $self->{drains}++; return }
}

for my $kind ('upgrade', 'connect') {
    subtest "generic HTTP1 $kind handoff and same-read raw tail" => sub {
        my $loop = Linux::Event::Loop->new;
        my (@order, @successors, @errors);
        my $accepted = 0;
        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop, host => '127.0.0.1', port => 0,
            native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1),
            on_error => sub { push @errors, "@_" },
            on_request => sub ($tx, $req) {
                ++$accepted;
                push @order, 'request';
                if ($kind eq 'connect') {
                    $tx->respond(status => 200);
                } else {
                    $tx->respond(status => 101,
                        headers => [[Connection => 'Upgrade'],
                                    [Upgrade => 'raw-echo']]);
                }
            },
            on_handoff => sub ($tx, $req, $response, $host) {
                push @order, 'handoff';
                isa_ok($tx, 'Unblock::HTTP1::Transaction');
                is($req->method, $kind eq 'connect' ? 'CONNECT' : 'GET',
                    'original request delivered to handoff callback');
                is($response->status, $kind eq 'connect' ? 200 : 101,
                    'switch response delivered');
                my $consumer = Local::RawEcho->new(
                    host => $host, loop => $loop,
                );
                push @successors, $consumer;
                return $consumer;
            },
        );
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $server->port,
            Proto => 'tcp',
        ) or die "connect: $!";
        my $request = $kind eq 'connect'
            ? "CONNECT example.test:443 HTTP/1.1\r\nHost: example.test:443\r\n\r\n"
            : "GET /raw HTTP/1.1\r\nHost: example.test\r\n"
                . "Connection: Upgrade\r\nUpgrade: raw-echo\r\n\r\n";
        my $wire = $request . 'FIRST';
        is(syswrite($sock, $wire), length($wire),
            'request and raw protocol tail sent in one write');
        my $guard = Linux::Event::Kernel::Timer->new(
            loop => $loop, after => 4,
            on_timer => sub { push @errors, 'handoff timed out'; $loop->stop },
        );
        $loop->run;
        $guard->cancel;
        is($accepted, 1, 'request admitted once');
        is(scalar @successors, 1, 'one successor installed');
        is($successors[0]{seen}, 'FIRST', 'same-read tail delivered once');
        is_deeply(\@order, ['request', 'handoff'],
            'protocol owner selected only after successful HTTP response');
        is_deeply(\@errors, [], 'no parser or application failures');
        $loop->run_for(0.04);
        $sock->blocking(0);
        my $reply = '';
        for (1..6) {
            my $count = sysread($sock, my $part, 8192);
            $reply .= $part if defined($count) && $count > 0;
            last if index($reply, 'ACK:FIRST') >= 0;
            $loop->run_for(0.02);
        }
        like($reply, $kind eq 'connect'
            ? qr{\AHTTP/1\.1 200\b} : qr{\AHTTP/1\.1 101\b},
            'HTTP response serialized before raw protocol bytes');
        like($reply, qr{\r\n\r\nACK:FIRST\z}s,
            'same live socket retains ordered output after handoff');
        close $sock;
        $loop->run_for(0.04);
        my $done = 0;
        $server->shutdown(grace => 0, on_complete => sub {
            ++$done; $loop->stop;
        });
        if (!$done) {
            my $timeout = Linux::Event::Kernel::Timer->new(
                loop => $loop, after => 3,
                on_timer => sub { push @errors, 'shutdown timeout'; $loop->stop },
            );
            $loop->run;
            $timeout->cancel;
        }
        is($done, 1, 'clean server shutdown once');
        is($server->connection_count, 0, 'successor socket released');
        is($loop->count, 0, 'no orphaned watchers');
    };
}
done_testing;
