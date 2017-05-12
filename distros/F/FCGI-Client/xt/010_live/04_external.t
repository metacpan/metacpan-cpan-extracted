use strict;
use warnings;
use Test::More;
use Test::TCP;
use FCGI;
use FCGI::Client::Connection;

test_tcp(
    client => sub {
        my $port = shift;
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
        ) or die $!;
        my $client = FCGI::Client::Connection->new(sock => $sock);
        my ( $stdout, $stderr ) = $client->request(
            +{
                REQUEST_METHOD => 'GET',
                QUERY_STRING   => 'foo=bar',
            },
            ''
        );
        is $stdout, "Content−type: text/html\r\n\r\nhello external world";
        done_testing;
    },
    server => sub {
        my $port = shift;
        my %env;
        my $sock = FCGI::OpenSocket(':'.$port, 100) or die;
        my $request = FCGI::Request(
            \*STDIN,
            \*STDOUT,
            \*STDOUT,
            \%env,
            $sock,
            &FCGI::FAIL_ACCEPT_ON_INTR,
        );
        while ($request->Accept >= 0) {
            print("Content−type: text/html\r\n\r\nhello external world");
        }
    },
);

