use strict;
use Test::More 0.98;
use Test::Fatal;

use Router::Simple;
use JSON::RPC::Spec::Procedure;

my $router       = Router::Simple->new;
my $callback_key = 'cb';
$router->connect(
    echo => {
        $callback_key => sub { $_[0] }
    }
);

my $proc;
is(
    exception {
        $proc = JSON::RPC::Spec::Procedure->new(
            router        => $router,
            _callback_key => $callback_key
        )
    },
    undef,
    'new'
) or diag explain $proc;
isa_ok $proc, 'JSON::RPC::Spec::Procedure';

subtest 'new hashref' => sub {
    is(
        exception {
            $proc = JSON::RPC::Spec::Procedure->new(
                {
                    router        => $router,
                    _callback_key => $callback_key
                }
            )
        },
        undef,
        'new'
    ) or diag explain $proc;
};

subtest 'parse' => sub {
    my $res = $proc->parse(
        {
            jsonrpc => '2.0',
            method  => 'echo',
            params  => 'Hello, World!',
            id      => 1
        }
    );

    is_deeply $res,
      {
        jsonrpc => '2.0',
        result  => 'Hello, World!',
        id      => 1
      },
      'result'
      or diag explain $res;
};

subtest 'trigger' => sub {
    my $params = 'Hello, trigger!';
    my $res    = $proc->_trigger('echo', $params);
    is $res, $params, 'trigger' or diag explain $res;
};

subtest 'router missing' => sub {
    my $res;
    like(
        exception { $res = JSON::RPC::Spec::Procedure->new },
        qr/\QMissing required arguments\E/,
        'router requred'
    ) or diag explain $res;
};

done_testing;
