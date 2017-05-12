use strict;
use FindBin;
use Test::More;
use Plack::Test;

use HTML::Mason::PSGIHandler::Streamy;

my $h = HTML::Mason::PSGIHandler::Streamy->new(
    comp_root => $FindBin::Bin,
);

my $handler = sub { $h->handle_psgi(@_) };

test_psgi app => $handler, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => "http://localhost/hello.mhtml?foo=bar"));
    is $res->code, 200, 'got 200 response';
    like $res->content, qr/Hello World Foo/;
    like $res->content, qr/foo,bar/;

    $res = $cb->(HTTP::Request->new(GET => "http://localhost/hello.mhtml?403=1"));
    is $res->code, 403, 'got 403 response';

};

done_testing;

