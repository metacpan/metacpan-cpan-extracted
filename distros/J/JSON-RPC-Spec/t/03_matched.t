use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);
use Router::Simple;

my $coder  = JSON->new->utf8;
my $router = Router::Simple->new;

my $rpc;

is(
    exception {
        $rpc = JSON::RPC::Spec->new(
            coder  => $coder,
            router => $router
          )
    },
    undef,
    'args in array'
) or diag explain $rpc;
isa_ok $rpc, 'JSON::RPC::Spec';

$rpc->register(
    'test.{matched}' => sub {
        my ($params, $matched) = @_;
        is ref $matched, 'HASH', 'matched hash';
        ok exists $matched->{matched}, 'exists matched key';
        ok !exists $matched->{'.callback'}, 'delete internal used key';
        return $matched;
    }
);

$rpc->register(
    'match' => sub {
        my ($params, $matched) = @_;
        is ref $matched, 'HASH', 'matched hash';
        ok !exists $matched->{'.callback'}, 'delete internal used key';
        return $matched;
    }
);

subtest 'placeholder' => sub {
    my $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"test.ok","params":1,"id":1}');
    like $res, qr/"result":\{"matched":"ok"\}/, 'return ok' or diag explain $res;

    $res = $rpc->parse(
        '{"jsonrpc":"2.0","method":"test.ok.ok","params":1,"id":1}');
    like $res, qr/"result":\{"matched":"ok\.ok"\}/, 'return ok.ok'
      or diag explain $res;
};

subtest 'normal match' => sub {
    my $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"match","params":1,"id":1}');
    like $res, qr/"result":\{\}/, 'return empty hash' or diag explain $res;
};

subtest 'no match' => sub {
    my $res
      = $rpc->parse('{"jsonrpc":"2.0","method":"test.ok/","params":1,"id":1}');
    like $res, qr/"Method not found"/, 'method not found' or diag explain $res;
};

done_testing;
