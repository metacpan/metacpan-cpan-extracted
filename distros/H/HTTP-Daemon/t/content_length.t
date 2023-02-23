use strict;
use warnings;

use HTTP::Response ();
use IO::Socket::IP ();
use Socket         qw( $CRLF );
use IO::Select     ();
use Test::More 0.98;

use lib 't/lib';
use TestServer::Reflect ();

my @TESTS = (
    {
        title   => "Positive Content Length",
        raw => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: +1

END_RAW

        status  => 400,
        like    => qr/value must be an unsigned integer/,
    },
    {
        title   => "Negative Content Length",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: -1

END_RAW
        status  => 400,
        like    => qr/value must be an unsigned integer/,
    },
    {
        title   => "Non Integer Content Length",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: 3.14

END_RAW
        status  => 400,
        like    => qr/value must be an unsigned integer/,
    },
    {
        title   => "Explicit Content Length ... with exact length",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: 8

ABCDEFGH
END_RAW
        status  => 200,
        like    => qr/^ABCDEFGH$/,
    },
    {
        title   => "No Content Length with body ... will be ignored",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1

ABCDEFGH
END_RAW
        status  => 200,
        like    => qr/^$/,
    },
    {
        title   => "Shorter Content Length ... gets truncated",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: 4

ABCDEFGH
END_RAW
        status  => 200,
        like    => qr/^ABCD$/,
    },
    {
        title   => "Different Content Length ... must fail",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: 8
Content-Length: 4

ABCDEFGH
END_RAW
        status  => 400,
        like    => qr/values are not the same/,
    },
    {
        title   => "Longer Content Length ... gets timeout",
        raw     => <<'END_RAW',
POST /echo HTTP/1.1
Content-Length: 9

ABCDEFGH
END_RAW
        timeout => 1,
    },
);

my $daemon = TestServer::Reflect->new;
my $url = $daemon->start;

my $addr = $url->host;
my $port = $url->port;

for my $test (@TESTS) {
    my $raw = $test->{raw} or next;
    $raw =~ s/(?<!\n)\r?\n\z//;
    $raw =~ s/\r?\n/$CRLF/g;

    my $sock = IO::Socket::IP->new(
        PeerAddr => $addr,
        PeerPort => $port,
        Timeout  => 2,
    ) or die;

    print $sock $raw;

    my $select = IO::Select->new;
    $select->add($sock);
    my @ready = $select->can_read(2);
    if (!@ready) {
        ok $test->{timeout}, $test->{title};
        next;
    }

    my $raw_res = do { local $/; <$sock> };
    close $sock;

    my $res = HTTP::Response->parse($raw_res);

    ok $raw_res, $test->{title};

    is $res->code, $test->{status},
        "... and has expected status";

    like $res->content, $test->{like},
        "... and body does match"
        if $test->{like};
}

done_testing;
