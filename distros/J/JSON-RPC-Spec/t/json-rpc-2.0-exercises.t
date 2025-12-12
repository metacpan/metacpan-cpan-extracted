use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);
use List::Util    qw(sum any);
use Scalar::Util  qw(looks_like_number);

my $rpc;
is(exception { $rpc = JSON::RPC::Spec->new }, undef, 'new')
  or diag explain $rpc;

$rpc->register(
    sum => sub {
        my @numbers = @{$_[0]};
        die "rpc_invalid_params: items must be numbers"
          if any { !looks_like_number($_) } @numbers;
        return sum(@numbers);
    }
);

subtest 'invalid params' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"2.0","method":"sum","params":["a", "b"],"id":2}');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Invalid params: items must be numbers',
      'invalid params and message';
};

subtest 'invalid jsonrpc version' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"1.0","method":"sum","params":[1,2],"id":6}');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is_deeply $res,
      {
        "jsonrpc" => "2.0",
        "error"   => {
            "code"    => -32600,
            "message" => "Invalid Request: jsonrpc must be '2.0'"
        },
        "id" => 6
      },
      'invalid jsonrpc version'
      or diag explain $res;
};

subtest 'invalid jsonrpc version 2' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":2,"method":"sum","params":[1,2],"id":6}');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is_deeply $res,
      {
        "jsonrpc" => "2.0",
        "error"   => {
            "code"    => -32600,
            "message" => "Invalid Request: jsonrpc must be '2.0'"
        },
        "id" => 6
      },
      'invalid jsonrpc version'
      or diag explain $res;
};

subtest 'invalid id(HASH)' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"2.0","method":"sum","params":[1,2],"id":{}}');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is_deeply $res,
      {
        "jsonrpc" => "2.0",
        "error"   => {
            "code"    => -32600,
            "message" => "Invalid Request"
        },
        "id" => undef
      },
      'invalid id'
      or diag explain $res;
};

subtest 'invalid id(ARRAY)' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"2.0","method":"sum","params":[1,2],"id":[]}');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is_deeply $res,
      {
        "jsonrpc" => "2.0",
        "error"   => {
            "code"    => -32600,
            "message" => "Invalid Request"
        },
        "id" => undef
      },
      'invalid id'
      or diag explain $res;
};

subtest 'invalid id(BOOLEAN)' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"2.0","method":"sum","params":[1,2],"id":false}');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is_deeply $res,
      {
        "jsonrpc" => "2.0",
        "error"   => {
            "code"    => -32600,
            "message" => "Invalid Request"
        },
        "id" => undef
      },
      'invalid id'
      or diag explain $res;
};

subtest 'valid id(NULL)' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"2.0","method":"sum","params":[1,2],"id":null}');
    is ref $res, 'HASH';
    is_deeply $res,
      {
        jsonrpc => "2.0",
        result  => 3,
        id      => undef
      },
      'valid id'
      or diag explain $res;
};

subtest 'valid id(String)' => sub {
    my $res;
    $res = $rpc->parse_without_encode(
        '{"jsonrpc":"2.0","method":"sum","params":[1,2],"id":"!\"#$%&()"}');
    is ref $res, 'HASH';
    is_deeply $res,
      {
        jsonrpc => "2.0",
        result  => 3,
        id      => q{!"#$%&()}
      },
      'valid id'
      or diag explain $res;
};

done_testing;
