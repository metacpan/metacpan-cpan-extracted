use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);

my $rpc;
is(exception { $rpc = JSON::RPC::Spec->new }, undef, 'new')
  or diag explain $rpc;

my $coder = JSON->new->utf8;

subtest 'method register' => sub {
    my $result;
    is(
        exception {
            $result = $rpc->register(echo => sub { $_[0] })
        },
        undef,
        'call'
    ) or diag explain $result;
    isa_ok $result, 'JSON::RPC::Spec' or diag explain $result;
};

subtest 'method parse' => sub {
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
        my $result;
        is(exception { $result = $rpc->parse($json_string); }, undef, 'call')
          or diag explain $result;

        is_deeply $coder->decode($result),
          +{
            jsonrpc => '2.0',
            id      => $id,
            result  => $content
          },
          'result'
          or diag explain $result;
    }
};

subtest 'empty string' => sub {
    my $result;
    is(exception { $result = $rpc->parse('') }, undef, 'call')
      or diag explain $result;
    is_deeply $coder->decode($result),
      +{
        jsonrpc => '2.0',
        id      => undef,
        error   => {
            code    => -32600,
            message => 'Invalid Request'
        }
      },
      'empty request'
      or diag explain $result;
};

subtest 'result is empty string' => sub {
    my $id          = time;
    my $json_string = $coder->encode(
        {
            jsonrpc => '2.0',
            id      => $id,
            method  => 'echo',
            params  => ''
        }
    );
    my $result;
    is(
        exception {
            $result = $rpc->parse($json_string)
        },
        undef,
        'call'
    ) or diag explain $result;
    is_deeply $coder->decode($result),
      +{
        jsonrpc => '2.0',
        id      => $id,
        result  => ''
      },
      'result is empty string'
      or diag explain $result;
};

subtest 'custom error' => sub {
    $rpc->register(echo_die => sub { die $_[0] });
    for my $content ("Hello\n", [1, 2], {foo => 'bar'}) {
        my $id          = time;
        my $json_string = $coder->encode(
            {
                jsonrpc => '2.0',
                id      => $id,
                method  => 'echo_die',
                params  => $content
            }
        );
        my $result;
        is(
            exception {
                $result = $rpc->parse($json_string)
            },
            undef,
            'call'
        ) or diag explain $result;
        is_deeply $coder->decode($result),
          +{
            jsonrpc => '2.0',
            id      => $id,
            error   => {
                code    => -32603,
                message => 'Internal error',
                data    => $content
            }
          },
          'result has error object'
          or diag explain $result;
    }
};

done_testing;
