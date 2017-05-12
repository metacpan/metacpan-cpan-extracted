#!perl
use strict;
use utf8;
use warnings qw(all);

use File::Temp qw(:seekable);
use LWP::Protocol::Net::Curl encoding => '';
use LWP::UserAgent;
use Test::HTTP::Server;
use Test::More;

my $server = Test::HTTP::Server->new;
local $ENV{no_proxy} = '*';

my $ua = LWP::UserAgent->new;

my $file = File::Temp->new;

my $res = $ua->request(
    HTTP::Request->new(
        GET => $server->uri . q(echo/head)
    ), $file->filename
);
my $len = $res->headers->header(q(content-length));

ok($res->is_success, q(success));
is($res->content, '', q(empty content));
ok($len > 0, q(non-empty content-length));

$file->seek(0, SEEK_SET);
$file->read(my $buf, $len);

is(length $buf, $len, q(data size match));
like($buf, qr{^GET\s+/echo/head\s+HTTP/1\.[01]}isx, q(looks like HTTP response));

done_testing(5);
