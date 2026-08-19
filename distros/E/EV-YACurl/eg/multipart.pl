#!/usr/bin/env perl
# Post a multipart/form-data body with CURLOPT_MIMEPOST: an array of parts,
# each with a name and either an inline value or a file to stream. The local
# server at the bottom parses what arrives and reports it back.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';
use IO::Socket::INET;
use POSIX ();

my $path = shift || $0;
-r $path or die "$path: not readable\n";

my ($server, $base) = start_server();

my $client = EV::YACurl->new({});
my ($reply, $done, $failed) = ('', 0);

$client->request(sub {
    my ($response, $error) = @_;
    $done = 1;
    return $failed = $error if $error;

    printf "%d, uploaded %d bytes in %.3fs\n%s",
        $response->getinfo(CURLINFO_RESPONSE_CODE),
        $response->getinfo(CURLINFO_SIZE_UPLOAD_T),
        $response->getinfo(CURLINFO_TOTAL_TIME_T) / 1_000_000,
        $reply;
}, {
    CURLOPT_URL => "$base/upload",
    CURLOPT_MIMEPOST => [
        { name => 'title',   value => 'an example upload' },
        { name => 'tags',    value => 'perl,ev,curl' },
        { name => 'payload', file  => $path },
    ],
    CURLOPT_WRITEFUNCTION => sub { $reply .= $_[0] },
});

EV::run until $done;

kill 'TERM', $server;
waitpid $server, 0;
die "$base/upload: $failed\n" if $failed;

sub start_server {
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 8, ReuseAddr => 1)
        or die "listen failed: $!\n";
    my $url = 'http://127.0.0.1:' . $listener->sockport;

    defined(my $pid = fork) or die "fork failed: $!\n";
    return ($pid, $url) if $pid;

    $SIG{PIPE} = 'IGNORE';

    while (my $conn = $listener->accept) {
        my $request = read_request($conn) or next;
        my $body = '';

        my ($boundary) = ($request->{headers}{'content-type'} // '') =~ /boundary=(\S+)/;
        if ($boundary) {
            for my $part (split /--\Q$boundary\E/, $request->{body}) {
                my ($head, $data) = split /\r\n\r\n/, $part, 2;
                next unless defined $data && $head =~ /name="([^"]+)"/;
                my $name = $1;
                $data =~ s/\r\n\z//;
                $body .= sprintf "%-8s %-20s %d bytes\n", $name,
                    $head =~ /filename="([^"]+)"/ ? $1 : '(inline)', length $data;
            }
        }

        print { $conn } "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n",
            "Content-Length: ", length $body, "\r\nConnection: close\r\n\r\n", $body;
        close $conn;
    }

    POSIX::_exit(0);
}

sub read_request {
    my ($conn) = @_;
    my ($buffer, $chunk) = ('');

    $buffer .= $chunk while index($buffer, "\r\n\r\n") < 0 && sysread $conn, $chunk, 65536;
    my ($head, $body) = split /\r\n\r\n/, $buffer, 2;
    return undef unless defined $head;

    my %headers = map { /\A([^:]+):\s*(.*)\z/ ? (lc $1, $2) : () } split /\r\n/, $head;
    $body = '' unless defined $body;

    # curl holds back bodies over a megabyte until the server says go, and
    # sends them a second later anyway when nobody answers.
    print { $conn } "HTTP/1.1 100 Continue\r\n\r\n"
        if lc($headers{expect} // '') eq '100-continue';

    my $length = $headers{'content-length'} || 0;
    while (length($body) < $length) {
        sysread $conn, $chunk, 65536 or last;
        $body .= $chunk;
    }

    return { headers => \%headers, body => $body };
}
