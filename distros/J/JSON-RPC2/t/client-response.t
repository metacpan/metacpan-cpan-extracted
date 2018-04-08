use warnings;
use strict;
use lib 't';
use share;

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

my ($failed, $result, $error, $call);
my ($json_request, $json_response);

my $client = JSON::RPC2::Client->new();

# - bad params
#   * no params
throws_ok { $client->response() } qr/param/,
    'no params';
#   * bad json in 1st param
($failed, $result, $error, $call) = $client->response(undef);
is $failed, 'Parse error',
    'bad json';
($failed, $result, $error, $call) = $client->response('bad json');
is $failed, 'Parse error';
($failed, $result, $error, $call) = $client->response({});
is $failed, 'expect {jsonrpc}="2.0"';
#   * two params
$json_request = $client->call('somefunc');
$json_response = fake_result($json_request, 42);
throws_ok { $client->response($json_response, 'extra param') } qr/param/,
    'two params';
lives_ok { $client->response($json_response) };

# - not HASH
#   * string
#   * number
#   * array
#   * true
#   * false
#   * null
($failed, $result, $error, $call) = $client->response('"string"');
is $failed, 'Parse error',
    'not HASH';
($failed, $result, $error, $call) = $client->response('3.14');
is $failed, 'Parse error';
($failed, $result, $error, $call) = $client->response('[]');
is $failed, 'expect Object';
($failed, $result, $error, $call) = $client->response('true');
like $failed, qr/expect Object|Parse error/ms;
($failed, $result, $error, $call) = $client->response('false');
like $failed, qr/expect Object|Parse error/ms;
($failed, $result, $error, $call) = $client->response('null');
is $failed, 'Parse error';


# - require "jsonrpc":"2.0"
#   * no "jsonrpc"
($failed, $result, $error, $call) = $client->response('{}');
is $failed, 'expect {jsonrpc}="2.0"',
    'no "jsonrpc"';
($failed, $result, $error, $call) = $client->response('{"key":0}');
is $failed, 'expect {jsonrpc}="2.0"';
#   * not "2.0"
($failed, $result, $error, $call) = $client->response('{"jsonrpc":0}');
is $failed, 'expect {jsonrpc}="2.0"',
    '"jsonrpc": not "2.0"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":2}');
is $failed, 'expect {jsonrpc}="2.0"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":2.0}');
is $failed, 'expect {jsonrpc}="2.0"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2"}');
is $failed, 'expect {jsonrpc}="2.0"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.00"}');
is $failed, 'expect {jsonrpc}="2.0"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0"}');
isnt $failed, 'expect {jsonrpc}="2.0"';

# - require known "id"
#   * no "id"
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0"}');
is $failed, 'expect {id} is scalar',
    'no "id"';
#   * "id" not a number
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":null}');
is $failed, 'expect {id} is scalar',
    '"id" not a number';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":true}');
is $failed, 'expect {id} is scalar';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":false}');
is $failed, 'expect {id} is scalar';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":[]}');
is $failed, 'expect {id} is scalar';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":{}}');
is $failed, 'expect {id} is scalar';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":"bad id"}');
#   * unknown "id"
is $failed, 'unknown {id}',
    'unknown "id"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"result":42}');
is $failed, 'unknown {id}';

# - require "result" or "error"
#   * no "result", no "error"
#   * "result"
#   * "error"
#   * "result" and "error"
$json_request = $client->call('somefunc');
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0}');
is $failed, 'expect {result} or {error}',
    'no "result", no "error"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"result":42}');
ok !$failed,
    '"result"';
$json_request = $client->call('somefunc');
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"result":42,"error":{"code":0,"message":""}}');
is $failed, 'expect {result} or {error}',
    '"result" and "error"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":""}}');
ok !$failed,
    '"error"';

# - "error" must be a HASH with keys "code", "message" and optional "data"
#   * not a hash
$json_request = $client->call('somefunc');
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":null}');
is $failed, 'expect {error} is Object',
    '… must be a HASH';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":true}');
is $failed, 'expect {error} is Object';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":false}');
is $failed, 'expect {error} is Object';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":3.14}');
is $failed, 'expect {error} is Object';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":"pi"}');
is $failed, 'expect {error} is Object';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":[]}');
is $failed, 'expect {error} is Object';
#   * empty
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{}}');
is $failed, 'expect {error}{code} is Integer',
    '… empty';
#   * no "code", with "message"
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"message":""}}');
is $failed, 'expect {error}{code} is Integer',
    '… no "code", with "message"';
#   * with "code", no "message"
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0}}');
is $failed, 'expect {error}{message} is String',
    '… with "code", no "message"';
#   * "code", "message"
#       - "code" not a number
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":null}}');
is $failed, 'expect {error}{code} is Integer',
    '… "code" not a number';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":true}}');
is $failed, 'expect {error}{code} is Integer';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":false}}');
is $failed, 'expect {error}{code} is Integer';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":""}}');
is $failed, 'expect {error}{code} is Integer';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":[]}}');
is $failed, 'expect {error}{code} is Integer';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":{}}}');
is $failed, 'expect {error}{code} is Integer';
#       - "message" not a string
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":null}}');
is $failed, 'expect {error}{message} is String',
    '… "message" not a string';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":true}}');
is $failed, 'expect {error}{message} is String';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":false}}');
is $failed, 'expect {error}{message} is String';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":[]}}');
is $failed, 'expect {error}{message} is String';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":{}}}');
is $failed, 'expect {error}{message} is String';
#   * "code", "message", "extra"
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":"","extra":null}}');
is $failed, 'only optional key must be {error}{data}',
    '… "code", "message", "extra"';
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":"","one":1,"two":2}}');
is $failed, 'only optional key must be {error}{data}';
#   * "code", "message", "data"
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"error":{"code":0,"message":"","data":null}}');
ok !$failed,
    '… "code", "message", "data"';

# 100%
($json_request, $call) = $client->call('somefunc');
$client->cancel($call);
$call = undef;
($failed, $result, $error, $call) = $client->response('{"jsonrpc":"2.0","id":0,"result":42}');
ok !$failed,
    'response on canceled call';

done_testing();
