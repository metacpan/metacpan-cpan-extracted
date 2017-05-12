#!/usr/bin/env perl
use utf8;
use 5.012;

use JSON::RPC::Spec;


my $rpc = JSON::RPC::Spec->new;
$rpc->register(echo => sub { $_[0] });
say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}'
);    # -> {"jsonrpc":"2.0","result":"Hello, World!","id":1}


use List::Util qw(max);
$rpc->register(max => sub { max(@{$_[0]}) });
say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}')
  ;    # -> {"id":1,"result":11,"jsonrpc":"2.0"}


sub factorial {
    my $num = shift;
    return $num > 1 ? $num * factorial($num - 1) : 1;
}
$rpc->register(factorial => \&factorial);
say $rpc->parse(
    '{"jsonrpc": "2.0", "method": "factorial", "params": 5, "id": 1}')
  ;    # -> {"result":120,"id":1,"jsonrpc":"2.0"}


