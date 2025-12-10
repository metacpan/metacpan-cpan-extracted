use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);

# JSON-RPC 2.0 Specification
# http://www.jsonrpc.org/specification#examples
my $coder = JSON->new->utf8;

my $rpc;
is(exception { $rpc = JSON::RPC::Spec->new({coder => $coder}) },
    undef, 'args in HASH')
  or diag explain $rpc;
isa_ok $rpc, 'JSON::RPC::Spec';

is(
    exception {
        $rpc->register(
            sum => sub {
                my ($params) = @_;
                my $sum = 0;
                for my $num (@{$params}) {
                    $sum += $num;
                }
                return $sum;
            }
        )
    },
    undef,
    'register code refs'
) or diag explain $rpc;

sub subtract {
    my ($params) = @_;
    if (ref $params eq 'HASH') {
        return $params->{minuend} - $params->{subtrahend};
    }
    return $params->[0] - $params->[1];
}

is(exception { $rpc->register(subtract => \&subtract) },
    undef, 'register sub refs')
  or diag explain $rpc;

$rpc->register(update       => sub {1});
$rpc->register(get_data     => sub { ['hello', 5] });
$rpc->register(notify_sum   => sub {1});
$rpc->register(notify_hello => sub {1});

subtest 'rpc call with positional parameters' => sub {
    my $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": 19, "id": 1}')
      or diag explain $res;

    $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": [23, 42], "id": 2}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": -19, "id": 2}')
      or diag explain $res;
};

subtest 'rpc call with named parameters' => sub {
    my $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": 19, "id": 3}')
      or diag explain $res;

    $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 42, "subtrahend": 23}, "id": 4}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": 19, "id": 4}')
      or diag explain $res;
};

subtest 'a Notification' => sub {
    my $res = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}');
    ok !$res or diag explain $res;

    $res = $rpc->parse('{"jsonrpc": "2.0", "method": "foobar"}');
    ok !$res or diag explain $res;
};

subtest 'rpc call of non-existent method' => sub {
    my $res = $rpc->parse('{"jsonrpc": "2.0", "method": "foobar", "id": "1"}');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}'
      ) or diag explain $res;
};

subtest 'rpc call with invalid JSON' => sub {
    my $res = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call with invalid Request object' => sub {
    my $res = $rpc->parse('{"jsonrpc": "2.0", "method": 1, "params": "bar"}');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call Batch, invalid JSON' => sub {
    my $res = $rpc->parse(
        '[
  {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
  {"jsonrpc": "2.0", "method"
]'
    );
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call with an empty Array' => sub {
    my $res = $rpc->parse('[]');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call with an invalid Batch (but not empty)' => sub {
    my $res = $rpc->parse('[1]');
    is_deeply $coder->decode($res), $coder->decode(
        '[
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
]'
    ) or diag explain $res;
};

subtest 'rpc call with invalid Batch' => sub {
    my $res = $rpc->parse('[1,2,3]');
    is_deeply $coder->decode($res), $coder->decode(
        '[
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
]'
    ) or diag explain $res;
};

subtest 'rpc call Batch' => sub {
    my $res = $rpc->parse(
        '[
        {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
        {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
        {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
        {"foo": "boo"},
        {"jsonrpc": "2.0", "method": "foo.get", "params": {"name": "myself"}, "id": "5"},
        {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
    ]'
    );
    is_deeply $coder->decode($res), $coder->decode(
        '[
        {"jsonrpc": "2.0", "result": 7, "id": "1"},
        {"jsonrpc": "2.0", "result": 19, "id": "2"},
        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
        {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "5"},
        {"jsonrpc": "2.0", "result": ["hello", 5], "id": "9"}
    ]'
    ) or diag explain $res;
};

subtest 'rpc call Batch (all notifications)' => sub {
    my $res = $rpc->parse(
        '[
        {"jsonrpc": "2.0", "method": "notify_sum", "params": [1,2,4]},
        {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]}
    ]'
    );
    ok !$res or diag explain $res;
};

done_testing;
