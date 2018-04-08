use warnings;
use strict;
use lib 't';
use share;

# REQUEST:
# {
#   "jsonrpc": "2.0",
#   "id": 123,                          # except notify_named()
#   "method": "remote_func",
#   "params": [1,'a',123],              # remote_func(1,'a',123)
#   or
#   "params": {name=>'Alex',…},         # remote_func(name => 'Alex', …)
# }

my $json_request;

my $client = JSON::RPC2::Client->new();


# notify_named()
throws_ok { $client->notify_named() } qr/method/;

# notify_named('method', 'key');
# notify_named('method', 'key1', 'value1', 'key2');
throws_ok { $client->notify_named('method', 'key')        } qr/odd number/;
throws_ok { $client->notify_named('method', 'k','v','k2') } qr/odd number/;

# notify_named('method')
$json_request = $client->notify_named('qwe');
jsonrpc2_ok($json_request, undef, 'qwe', undef);

# notify_named('method', 123)
$json_request = $client->notify_named('somefunc', first=>123);
jsonrpc2_ok($json_request, undef, 'somefunc', {first=>123});

# notify_named('method', 'qwe', 'asd', 'zxc')
$json_request = $client->notify_named('somefunc', first=>'qwe', second=>'asd', third=>'zxc');
jsonrpc2_ok($json_request, undef, 'somefunc', {first=>'qwe', second=>'asd', third=>'zxc'});


done_testing();
