use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::RPC::Spec::Client;

my $obj;

is(exception { $obj = JSON::RPC::Spec::Client->new }, undef, 'new')
  or diag explain $obj;

my $json_string;
subtest 'standard' => sub {
    $json_string = $obj->compose(
        'list.max' => [1, 5, 9],
        1
    );

    like($json_string, qr/\Q"jsonrpc":"2.0"\E/, 'JSON-RPC 2.0')
      or diag explain $json_string;
    like($json_string, qr/\Q"method":"list.max"\E/, 'method')
      or diag explain $json_string;
    like($json_string, qr/\Q"params":[1,5,9]\E/, 'params')
      or diag explain $json_string;
    like($json_string, qr/\Q"id":1\E/, 'id') or diag explain $json_string;
};

subtest 'notification' => sub {
    $json_string = $obj->compose('list.max' => [1, 5, 9]);
    unlike($json_string, qr/\Q"id":\E/) or diag explain $json_string;
};

subtest 'handles' => sub {
    my $obj = JSON::RPC::Spec->new;
    is(exception { $obj->compose(echo => 'Hello') }, undef, 'handle compose')
      or diag explain $obj;
};

done_testing;
