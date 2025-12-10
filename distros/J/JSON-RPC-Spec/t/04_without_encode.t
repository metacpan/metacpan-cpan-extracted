use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);

my $rpc;
is(exception { $rpc = JSON::RPC::Spec->new }, undef, 'new')
  or diag explain $rpc;

my $coder = JSON->new->utf8;
$rpc->register(echo       => sub { $_[0] });
$rpc->register(emit_error => sub { die $_[0] });

subtest 'parse' => sub {
    for my $content ('Hello', [1, 2], {foo => 'bar'}) {
        my $id          = time;
        my $json_string = $coder->encode(
            {
                jsonrpc => '2.0',
                id      => $id,
                method  => 'echo',
                params  => $content
            }
        );
        my $res;
        is(exception { $res = $rpc->parse_without_encode($json_string) },
            undef, 'parse_without_encode')
          or diag explain $res;
        is_deeply $res,
          {
            jsonrpc => '2.0',
            id      => $id,
            result  => $content
          },
          'result'
          or diag explain $res;
    }
};

subtest 'register error' => sub {
    my $register;
    like(
        exception { $register = $rpc->register },
        qr/pattern required/,
        'register requires params'
    ) or diag explain $register;
    like(
        exception { $register = $rpc->register('pattern') },
        qr/code required/,
        'register requires code reference'
    ) or diag explain $register;
};

subtest 'parse error' => sub {
    my $res;
    $res = $rpc->parse_without_encode('');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Invalid Request', '"" -> Invalid Request';

    $res = $rpc->parse_without_encode('[');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Parse error', '"[" -> Parse error';

    $res = $rpc->parse_without_encode('[]');
    is ref $res, 'HASH';
    ok exists $res->{error};
    is $res->{error}{message}, 'Invalid Request', '"[]" -> Invalid Request';

    $res = $rpc->parse_without_encode('[{}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      '"[{}]" -> Invalid Request';

    $res
      = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":"","id":1}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method empty -> Invalid Request';

    $res = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":""}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'invalid method -> ignore notification';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":".anything","id":1}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method start at dot -> Invalid Request';

    $res
      = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":".anything"}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'invalid method -> ignore notification';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"123456789","id":1}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method number only -> Invalid Request';

    $res
      = $rpc->parse_without_encode('[{"jsonrpc":"2.0","method":"123456789"}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid Request',
      'method number only -> Invalid Request';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"404notfount","id":1}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Method not found', 'Method not found';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"404notfount"}]');
    ok !$res, 'Method not found -> notification';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"emit_error","id":1}]');
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Internal error', 'Internal error';

    $res = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"emit_error"}]');
    ok !$res, 'Internal error -> notification';

    $res
      = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"emit_error","params":"rpc_invalid_params","id":1}]'
      );
    is ref $res,      'ARRAY';
    is ref $res->[0], 'HASH';
    ok exists $res->[0]{error};
    is $res->[0]{error}{message}, 'Invalid params', 'Invalid params';

    $res
      = $rpc->parse_without_encode(
        '[{"jsonrpc":"2.0","method":"emit_error","params":"rpc_invalid_params"}]'
      );
    ok !$res, 'Invalid params -> notification';
};

done_testing;
