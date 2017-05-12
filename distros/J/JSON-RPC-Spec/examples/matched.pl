#!/usr/bin/env perl
use utf8;

package MyApp::Calc;
use 5.012;
use List::Util ();

sub jsonrpc_sum {
    my $class  = shift;
    my $params = shift;
    return List::Util::sum @{$params};
}

sub jsonrpc_max { List::Util::max @{$_[1]} }

package main;
use 5.012;
use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::RPC::Spec;

my $rpc = JSON::RPC::Spec->new;
$rpc->register(
    'list.{action}' => sub {
        my ($param, $matched) = @_;
        my $action = 'jsonrpc_' . $matched->{action};
        return MyApp::Calc->$action($param);
    }
);

say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "list.sum", "params": [1,2,3,4,5], "id": 1}'
);    # -> {"result":15,"jsonrpc":"2.0","id":1}

say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "list.max", "params": [1,7,3,4,5], "id": 1}'
);    # -> {"id":1,"jsonrpc":"2.0","result":7}

say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "list.times", "params": [1,7,3,4,5], "id": 1}'
  )
  ; # -> {"id":1,"jsonrpc":"2.0","error":{"message":"Internal error","data":"Can't locate object method \"jsonrpc_times\" via package \"MyApp::Calc\" at examples/matched.pl line 28.\n","code":-32603}}


$rpc->register(
    'echo.{action}' => sub {
        my ($params, $matched) = @_;
        return $matched->{action};
    }
);
say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "echo.hoge", "params": [1, 2, 3, 4, 5], "id": 1}'
);    # -> {"id":1,"result":"hoge","jsonrpc":"2.0"}
