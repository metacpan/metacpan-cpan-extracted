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

my ($json_request, $call);

my $client = JSON::RPC2::Client->new();

# $req = call()
# ($req,$call) = call()
throws_ok { my $req         = $client->call() } qr/method/;
throws_ok { my ($req,$call) = $client->call() } qr/method/;

# $req = call(…)
# - call('method')
$json_request = $client->call('qwe');
jsonrpc2_ok($json_request, 0, 'qwe', undef);

# - call('method', 123)
$json_request = $client->call('somefunc', 123);
jsonrpc2_ok($json_request, 1, 'somefunc', [123]);

# - call('method', 'qwe', 'asd', 'zxc')
$json_request = $client->call('somefunc', 'qwe', 'asd', 'zxc');
jsonrpc2_ok($json_request, 2, 'somefunc', ['qwe', 'asd', 'zxc']);

# ($req, $call) = call(…)
# - call('method')
($json_request, $call) = $client->call('qwe');
jsonrpc2_ok($json_request, 3, 'qwe', undef);

# - call('method', 123)
($json_request, $call) = $client->call('somefunc', 123);
jsonrpc2_ok($json_request, 4, 'somefunc', [123]);

# - call('method', 'qwe', 'asd', 'zxc')
($json_request, my $call5) = $client->call('somefunc', 'qwe', 'asd', 'zxc');
jsonrpc2_ok($json_request, 5, 'somefunc', ['qwe', 'asd', 'zxc']);

# - cancel($call)
lives_ok { $client->cancel($call) }
    'cancel';
lives_ok { $client->cancel($call5) }
    'cancel another';

# - cancel same $call again
throws_ok { $client->cancel($call) } qr/no such request/,
    'cancel same $call again';

# - cancel() after response()
($json_request, $call) = $client->call('somefunc', 123);
$client->response(fake_result($json_request, undef));
throws_ok { $client->cancel($call) } qr/no such request/,
    'cancel after response';

# - our data stored in $call returned by response()
($json_request, $call) = $client->call('somefunc', 123);
is_deeply $call, {},
    '$call is empty';
$call->{key} = 'value';
(undef,undef,undef,$call) = $client->response(fake_result($json_request, undef));
is_deeply $call, {key=>'value'},
    '$call contain our data';

# - cancel() one of two requests
my ($json_request1, $call1) = $client->call('somefunc1');
my ($json_request2, $call2) = $client->call('somefunc2');
$client->cancel($call1);
my @response1 = $client->response(fake_result($json_request1, 10));
my @response2 = $client->response(fake_result($json_request2, 20));
is_deeply \@response1, [],
    'response on cancel()ed request';
is_deeply \@response2, [undef,20,undef,$call2],
    'response on not cancel()ed request';


done_testing();
