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

my $server = JSON::RPC2::Server->new();
$server->register('func', sub{ return 42 });

my $Response;

# - execute:
#   * need 2 params
throws_ok { $server->execute()                  } qr/2 params/;
throws_ok { $server->execute("")                } qr/2 params/;
throws_ok { $server->execute("",sub{},undef)    } qr/2 params/;
#   * second param is CODE
throws_ok { $server->execute("",undef)          } qr/callback/;
throws_ok { $server->execute("",$server)        } qr/callback/;
throws_ok { $server->execute("",[])             } qr/callback/;
throws_ok { $server->execute("",{})             } qr/callback/;

# - received from client json is:
#   * not a json

execute(undef);
is $Response->{error}{code}, -32700,
    'not json';
is $Response->{error}{message}, 'Parse error.';

execute('bad json');
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute([]);
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: empty Array.';

execute({});
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

#   * not an Object

execute('null');
is $Response->{error}{code}, -32700,
    'not Object';
is $Response->{error}{message}, 'Parse error.';

execute('true');
like $Response->{error}{code}, qr/-32600|-32700/ms;
like $Response->{error}{message}, qr/Invalid Request: expect Array or Object|Parse error/ms;

execute('false');
like $Response->{error}{code}, qr/-32600|-32700/ms;
like $Response->{error}{message}, qr/Invalid Request: expect Array or Object|Parse error/ms;

execute('3.14');
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute('"string"');
is $Response->{error}{code}, -32700;
is $Response->{error}{message}, 'Parse error.';

execute('[]');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: empty Array.';

#   * absent "jsonrpc"

execute('{}');
is $Response->{error}{code}, -32600,
    'no "jsonrpc"';
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"key":0}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

#   * value of "jsonrpc" isn't "2.0"

execute('{"jsonrpc":null}');
is $Response->{error}{code}, -32600,
    '"jsonrpc": not "2.0"';
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":true}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":[]}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":{}}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":0}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":2}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":2.0}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":"2"}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

execute('{"jsonrpc":"2.00"}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {jsonrpc}="2.0".';

#   * value of "id" isn't: null, number or string

execute('{"jsonrpc":"2.0","id":true}');
is $Response->{error}{code}, -32600,
    '"id" not a number';
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

execute('{"jsonrpc":"2.0","id":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

execute('{"jsonrpc":"2.0","id":[]}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

execute('{"jsonrpc":"2.0","id":{}}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {id} is scalar.';

#   * value of "method" isn't number/string

execute('{"jsonrpc":"2.0","id":null}');
is $Response->{error}{code}, -32600,
    '"method" not a string';
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":true}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":[]}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

execute('{"jsonrpc":"2.0","id":0,"method":{}}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {method} is String.';

#   * value of "method" isn't a string, not a 'func'

execute('{"jsonrpc":"2.0","id":0,"method":0}');
is $Response->{error}{code}, -32601,
    '"method" not a func';
is $Response->{error}{message}, 'Method not found.';

execute('{"jsonrpc":"2.0","id":0,"method":""}');
is $Response->{error}{code}, -32601;
is $Response->{error}{message}, 'Method not found.';

execute('{"jsonrpc":"2.0","id":0,"method":"bad method"}');
is $Response->{error}{code}, -32601;
is $Response->{error}{message}, 'Method not found.';

#   * "method":"func", value of "params" isn't ARRAY/HASH

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":null}');
is $Response->{error}{code}, -32600,
    '"params" not an Array or Object';
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":true}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":false}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":""}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';

execute('{"jsonrpc":"2.0","id":0,"method":"func","params":42}');
is $Response->{error}{code}, -32600;
is $Response->{error}{message}, 'Invalid Request: expect {params} is Array or Object.';


done_testing();


sub execute {
    my ($json) = @_;
    $Response = undef;
    $server->execute($json, sub { $Response = decode_json($_[0]) });
}


