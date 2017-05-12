use strict;
use Test::More 0.98;
use Plack::Test;
use HTTP::Request::Common;

use JSON::RPC::Lite;

my $method = method('echo', sub { $_[0] });
is ref $method, 'JSON::RPC::Spec', 'instance of `JSON::RPC::Spec`';

my $psgi_app = as_psgi_app;
is ref $psgi_app, 'CODE', 'CODE refs';

my $test = Plack::Test->create($psgi_app);
ok ref $test, 'create app';

sub json_req {
    POST '/',
      'Content-Type' => 'application/json',
      Content        => shift;
}

subtest 'valid request' => sub {
    my $res = $test->request(
        json_req('{"jsonrpc":"2.0","method":"echo","params":"Hello","id":1}')
    );
    is $res->code, 200, 'request';
    like $res->decoded_content, qr/"result":"Hello"/, 'result';
};

subtest 'notification request' => sub {
    my $res = $test->request(
        json_req('{"jsonrpc":"2.0","method":"echo","params":"Hello"}')
    );
    is $res->code, 204, 'no content';
};

subtest 'invalid request' => sub {
    my $res = $test->request(
        json_req('{}')
    );
    is $res->code, 200, 'request';
    like $res->decoded_content, qr/"Invalid Request"/, 'invalid request';
};

done_testing;
