#!perl
use strict;
use utf8;
use warnings qw(all);

use LWP::Protocol::Net::Curl;
use LWP::UserAgent;
use Test::HTTP::Server;
use Test::More;

my $server = Test::HTTP::Server->new;
local $ENV{no_proxy} = '*';

my $ua = LWP::UserAgent->new;

# test curlopt passing via special HTTP headers
my $res = $ua->get(
    $server->uri . q(echo/head),
    X_CurlOpt_Encoding => '',   # tricky edge case: empty string is meaningful!
);

isa_ok($res, q(HTTP::Response));
ok($res->is_success, q(is_success));

like($res->content, qr{\bAccept-Encoding\s*:}isx, q(CURLOPT set via X-headers));

done_testing(3);
