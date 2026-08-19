#!/usr/bin/env perl
# Talk to a JSON API: POST a JSON body, decode the JSON reply, and carry the
# session cookie into a follow-up request started from the completion callback.
# The server is a few lines of IO::Socket::INET at the bottom of this file.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';
use IO::Socket::INET;
use JSON::PP ();
use POSIX ();

my $json = JSON::PP->new->utf8->canonical;

# Fork the server before the client exists: a client does not survive a fork.
my ($server, $base) = start_server();

my $client = EV::YACurl->new({});
my $payload = $json->encode({ user => 'camel', password => 'hunter2' });
my ($login, $profile) = ('', '');
my ($session, $done, $failed);

$client->request(sub {
    my ($response, $error) = @_;
    if ($error) { $done = 1; return $failed = "login: $error" }

    my $account = eval { $json->decode($login) };
    if (!$account) { $done = 1; return $failed = "login: unparseable reply: $login" }

    printf "logged in as %s (status %d), session cookie %s\n",
        $account->{user}, $response->getinfo(CURLINFO_RESPONSE_CODE), $session // 'missing';

    $client->request(sub {
        my ($response, $error) = @_;
        $done = 1;
        return $failed = "profile: $error" if $error;

        my $data = eval { $json->decode($profile) };
        return $failed = "profile: unparseable reply: $profile" unless $data;

        printf "profile: %s, plan %s, %d request(s) on this session\n",
            $data->{user}, $data->{plan}, $data->{requests};
    }, {
        CURLOPT_URL => "$base/profile",
        # Every request is its own easy handle, so libcurl's cookie engine does
        # not carry a session between them: hold on to it and send it back.
        CURLOPT_COOKIE => $session,
        CURLOPT_HTTPHEADER => ['Accept: application/json'],
        CURLOPT_WRITEFUNCTION => sub { $profile .= $_[0] },
    });
}, {
    CURLOPT_URL => "$base/login",
    # Selects POST and copies the body, so $payload need not outlive this call.
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
    CURLOPT_HEADERFUNCTION => sub {
        $session = $1 if $_[0] =~ /^set-cookie:\s*(session=[^;]+)/i;
    },
    CURLOPT_WRITEFUNCTION => sub { $login .= $_[0] },
});

EV::run until $done;

kill 'TERM', $server;
waitpid $server, 0;
die "$failed\n" if $failed;

sub start_server {
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 8, ReuseAddr => 1)
        or die "listen failed: $!\n";
    my $url = 'http://127.0.0.1:' . $listener->sockport;

    defined(my $pid = fork) or die "fork failed: $!\n";
    return ($pid, $url) if $pid;

    $SIG{PIPE} = 'IGNORE';
    my %sessions;

    while (my $conn = $listener->accept) {
        my $request = read_request($conn) or next;
        my ($status, $headers, $body);

        if ($request->{path} eq '/login') {
            my $sent = eval { $json->decode($request->{body}) } || {};
            my $token = sprintf 'session=%08x', rand 0xffffffff;
            $sessions{$token} = 0;
            ($status, $headers) = (200, ["Set-Cookie: $token; Path=/"]);
            $body = $json->encode({ ok => JSON::PP::true, user => $sent->{user} });
        } elsif (exists $sessions{ $request->{headers}{cookie} // '' }) {
            $status = 200;
            $body = $json->encode({
                user     => 'camel',
                plan     => 'hacker',
                requests => ++$sessions{ $request->{headers}{cookie} },
            });
        } else {
            $status = 401;
            $body = $json->encode({ error => 'not logged in' });
        }

        print { $conn } "HTTP/1.1 $status Status\r\n",
            map("$_\r\n", @{ $headers || [] }),
            "Content-Type: application/json\r\n",
            "Content-Length: ", length $body, "\r\n",
            "Connection: close\r\n\r\n", $body;
        close $conn;
    }

    POSIX::_exit(0);
}

sub read_request {
    my ($conn) = @_;
    my ($buffer, $chunk) = ('');

    $buffer .= $chunk while index($buffer, "\r\n\r\n") < 0 && sysread $conn, $chunk, 65536;
    my ($head, $body) = split /\r\n\r\n/, $buffer, 2;
    return undef unless defined $head && $head =~ m{\A\S+ (\S+)};

    my $target = $1;
    my %headers = map { /\A([^:]+):\s*(.*)\z/ ? (lc $1, $2) : () } split /\r\n/, $head;
    $body = '' unless defined $body;

    my $length = $headers{'content-length'} || 0;
    while (length($body) < $length) {
        sysread $conn, $chunk, 65536 or last;
        $body .= $chunk;
    }

    return { path => (split /\?/, $target)[0], headers => \%headers, body => $body };
}
