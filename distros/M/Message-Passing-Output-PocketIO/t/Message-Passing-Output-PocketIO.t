# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Message-Passing-Filter-Regexp.t'
use lib 'lib';
use strict;
use warnings;
use AnyEvent;
use Data::Dumper;
use PocketIO::Client::IO;
use Test::More;
BEGIN { use_ok('Message::Passing::Output::PocketIO') };

my $input = {
    '@tags' => [],
    '@message' => '127.0.0.1 - - [19/Jan/2012:21:08:54 +0800] "POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1" 200 11435',
    '@timestamp' => '2012-06-19T21:08:54+0800',
    '@fields' => {},
};

my $exp_proto = [
    'websocket',
    'flashsocket',
    'htmlfile',
    'xhr-polling',
    'jsonp-polling'
];

my $cv = AnyEvent->condvar;

my $in = Message::Passing::Output::PocketIO->new(
    port => 8080,
);
isa_ok( $in, "Message::Passing::Output::PocketIO" );

my $socket = PocketIO::Client::IO->connect("http://localhost:8080/");
isa_ok( $socket, "PocketIO::Socket::ForClient" );

my $w = AnyEvent->timer(
    after => 1,
    cb => sub {
        $in->consume($input);
        $cv->send;
    }
);

$socket->on( 'connect', sub {
    is_deeply( $_[0]->{_client}->{acceptable_transports}, $exp_proto, "acceptable protocol");
});

$cv->recv;

done_testing;
