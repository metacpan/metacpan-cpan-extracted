use warnings;
use strict;
use t::share;

# REQUEST:
# {
#   "jsonrpc": "2.0",
#   "id": 123,                          # except notify()
#   "method": "remote_func",
#   "params": [1,'a',123],              # remote_func(1,'a',123)
#   or
#   "params": {name=>'Alex',…},         # remote_func(name => 'Alex', …)
# }
# RESPONSE:
# {
#   "jsonrpc": "2.0",
#   "id": 123,
#   "result": …,
#   or
#   "error": {
#       "code": -32000,
#       "message": "some error",
#       "data": …,                      # optional
#   },
# }

my (@res, $failed, $result, $error, $call);
my ($json_request, $json_response);

my $client = JSON::RPC2::Client->new();

sub one_res (@) {
    is 0+@_, 1;
    return @{ $_[0] };
}

# - bad params
#   * no params
throws_ok { $client->batch_response() } qr/param/,
    'no params';
#   * bad json in 1st param
($failed, $result, $error, $call) = one_res $client->batch_response(undef);
is $failed, 'Parse error',
    'bad json';
($failed, $result, $error, $call) = one_res $client->batch_response('bad json');
is $failed, 'Parse error';
($failed, $result, $error, $call) = one_res $client->batch_response({});
is $failed, 'expect {jsonrpc}="2.0"';
#   * two params
$json_request = $client->call('somefunc');
$json_response = fake_result($json_request, 42);
throws_ok { $client->batch_response($json_response, 'extra param') } qr/param/,
    'two params';
lives_ok { $client->batch_response($json_response) };

# - not HASH or non-empty ARRAY
#   * string
#   * number
#   * array
#   * true
#   * false
#   * null
($failed, $result, $error, $call) = one_res $client->batch_response('"string"');
is $failed, 'Parse error',
    'not HASH';
($failed, $result, $error, $call) = one_res $client->batch_response('3.14');
is $failed, 'Parse error';
($failed, $result, $error, $call) = one_res $client->batch_response('[]');
is $failed, 'empty Array';
($failed, $result, $error, $call) = one_res $client->batch_response('true');
like $failed, qr/expect Array or Object|Parse error/ms;
($failed, $result, $error, $call) = one_res $client->batch_response('false');
like $failed, qr/expect Array or Object|Parse error/ms;
($failed, $result, $error, $call) = one_res $client->batch_response('null');
is $failed, 'Parse error';

# - require "jsonrpc":"2.0"
#   * no "jsonrpc"
($failed, $result, $error, $call) = one_res $client->batch_response('{}');
is $failed, 'expect {jsonrpc}="2.0"',
    'no "jsonrpc"';
($failed, $result, $error, $call) = one_res $client->batch_response('[{}]');
is $failed, 'expect {jsonrpc}="2.0"',
    'no "jsonrpc"';
($failed, $result, $error, $call) = one_res $client->batch_response('{"jsonrpc":"2.0"}');
isnt $failed, 'expect {jsonrpc}="2.0"';
($failed, $result, $error, $call) = one_res $client->batch_response('[{"jsonrpc":"2.0"}]');
isnt $failed, 'expect {jsonrpc}="2.0"';

# - batch response
my @call;
($json_request, @call) = $client->batch(
    $client->call('func1'),
    $client->call('func2'),
);
@res = $client->batch_response('[{"jsonrpc":"2.0","id":1,"result":2},{"jsonrpc":"2.0","id":0,"result":1}]');
is 0+@res, 2,
    'got 2 replies';
is "$res[0][1]", 2;
is "$res[0][3]", "$call[1]";
is "$res[1][1]", 1;
is "$res[1][3]", "$call[0]";

# 100%
($json_request, $call) = $client->batch($client->call('somefunc'));
$client->cancel($call);
$call = undef;
($failed, $result, $error, $call) = one_res $client->batch_response('[{"jsonrpc":"2.0","id":0,"result":42}]');
ok !$failed,
    'response on canceled call';


done_testing();
