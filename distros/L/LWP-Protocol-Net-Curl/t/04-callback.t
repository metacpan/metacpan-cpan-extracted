#!perl
use strict;
use utf8;
use warnings qw(all);

use LWP::Protocol::Net::Curl;
$LWP::Protocol::Net::Curl::use_select = 1;

use LWP::UserAgent;
use Test::HTTP::Server;
use Test::More;

my $server = Test::HTTP::Server->new;
local $ENV{no_proxy} = '*';

my $ua = LWP::UserAgent->new;

my ($count, $length) = (0, 0);

my $res = $ua->get(
    $server->uri . q(repeat/1000/qwertasdfg),
    q(:content_cb) => sub {
        my ($chunk, $response, $protocol) = @_;
        ++$count;
        $length += length $chunk;
    },
    q(:read_size_hint) => 1000,
);

ok($res->is_success, q(success));
ok($count > 1, qq(received $count chunks));
is($length, $res->headers->header(q(content-length)), q(chunk length sum));

done_testing(3);
