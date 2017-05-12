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

my ($json_request, $call);

my $client = JSON::RPC2::Client->new();

# $req = call_named()
# ($req,$call) = call_named()
throws_ok { my $req         = $client->call_named() } qr/method/;
throws_ok { my ($req,$call) = $client->call_named() } qr/method/;

# call_named('method', 'key');
# call_named('method', 'key1', 'value1', 'key2');
throws_ok { $client->call_named('method', 'key')        } qr/odd number/;
throws_ok { $client->call_named('method', 'k','v','k2') } qr/odd number/;

# $req = call_named(…)
# - call_named('method')
$json_request = $client->call_named('qwe');
jsonrpc2_ok($json_request, 0, 'qwe', undef);

# - call_named('method', 123)
$json_request = $client->call_named('somefunc', first=>123);
jsonrpc2_ok($json_request, 1, 'somefunc', {first=>123});

# - call_named('method', 'qwe', 'asd', 'zxc')
$json_request = $client->call_named('somefunc', first=>'qwe', second=>'asd', third=>'zxc');
jsonrpc2_ok($json_request, 2, 'somefunc', {first=>'qwe', second=>'asd', third=>'zxc'});

# ($req, $call) = call_named(…)
# - call_named('method')
($json_request, $call) = $client->call_named('qwe');
jsonrpc2_ok($json_request, 3, 'qwe', undef);

# - call_named('method', 123)
($json_request, $call) = $client->call_named('somefunc', first=>123);
jsonrpc2_ok($json_request, 4, 'somefunc', {first=>123});

# - call_named('method', 'qwe', 'asd', 'zxc')
($json_request, my $call5) = $client->call_named('somefunc', first=>'qwe', second=>'asd', third=>'zxc');
jsonrpc2_ok($json_request, 5, 'somefunc', {first=>'qwe', second=>'asd', third=>'zxc'});

# - cancel($call)
lives_ok { $client->cancel($call) }
    'cancel';
lives_ok { $client->cancel($call5) }
    'cancel another';

# - cancel same $call again
throws_ok { $client->cancel($call) } qr/no such request/,
    'cancel same $call again';

# - cancel() after response()
($json_request, $call) = $client->call_named('somefunc', first=>123);
$client->response(fake_result($json_request, undef));
throws_ok { $client->cancel($call) } qr/no such request/,
    'cancel after response';

# - our data stored in $call returned by response()
($json_request, $call) = $client->call_named('somefunc', first=>123);
is_deeply $call, {},
    '$call is empty';
$call->{key} = 'value';
(undef,undef,undef,$call) = $client->response(fake_result($json_request, undef));
is_deeply $call, {key=>'value'},
    '$call contain our data';

# - cancel() one of two requests
my ($json_request1, $call1) = $client->call_named('somefunc1');
my ($json_request2, $call2) = $client->call_named('somefunc2');
$client->cancel($call1);
my @response1 = $client->response(fake_result($json_request1, 10));
my @response2 = $client->response(fake_result($json_request2, 20));
is_deeply \@response1, [],
    'response on cancel()ed request';
is_deeply \@response2, [undef,20,undef,$call2],
    'response on not cancel()ed request';


done_testing();
