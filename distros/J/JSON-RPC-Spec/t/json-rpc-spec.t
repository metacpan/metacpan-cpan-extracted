use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);

use lib '.';
use t::Fake::New;
use t::Fake::Decode;
use t::Fake::Encode;
use t::Fake::JSON;
use t::Fake::Match;

my $obj;
subtest 'standard' => sub {
    is(exception { $obj = JSON::RPC::Spec->new }, undef, 'new')
      or diag explain $obj;
    like ref $obj->coder, qr/JSON/, 'coder like JSON' or diag explain $obj;
    isa_ok $obj->router,     'Router::Simple'             or diag explain $obj;
    isa_ok $obj->_procedure, 'JSON::RPC::Spec::Procedure' or diag explain $obj;
    is $obj->_jsonrpc, '2.0', '_jsonrpc default' or diag explain $obj;
};

subtest 'coder change' => sub {
    like(
        exception { $obj = JSON::RPC::Spec->new(coder => undef) },
        qr/\QCan't call method "can" on an undefined value\E/,
        'coder undef'
    ) or diag explain $obj;

    like(
        exception {
            $obj = JSON::RPC::Spec->new(coder => t::Fake::Decode->new)
        },
        qr/\Qmethod encode required\E/,
        'coder has decode only'
    ) or diag explain $obj;

    like(
        exception {
            $obj = JSON::RPC::Spec->new(coder => t::Fake::Encode->new)
        },
        qr/\Qmethod decode required\E/,
        'coder has encode only'
    ) or diag explain $obj;

    is(
        exception { $obj = JSON::RPC::Spec->new(coder => t::Fake::JSON->new) },
        undef,
        'coder has encode and decode'
    ) or diag explain $obj;
};

subtest 'router change' => sub {
    like(
        exception { $obj = JSON::RPC::Spec->new(router => undef) },
        qr/\QCan't call method "can" on an undefined value\E/,
        'router undef'
    ) or diag explain $obj;

    is(
        exception {
            $obj = JSON::RPC::Spec->new(router => t::Fake::Match->new)
        },
        undef,
        'router has match'
    ) or diag explain $obj;
};

subtest 'extra args' => sub {
    $obj = JSON::RPC::Spec->new;
    $obj->register(
        echo => sub {
            is shift, 'Hello, World!', 'is params';
            is_deeply shift, +{},               'is_deeply matched';
            is_deeply shift, +{key => 'value'}, 'is_deeply extra_args';
            is shift,     0, 'second args';
            is scalar @_, 0, 'no more args';
            return;
        }
    );
    my $json_string
      = '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}';
    my $res    = $obj->parse($json_string, +{key => 'value'}, 0);
    my $coder  = JSON->new;
    my $result = $coder->decode($res);
    is_deeply $result,
      +{
        id      => 1,
        result  => undef,
        jsonrpc => '2.0'
      },
      'is_deeply result';
};

done_testing;
