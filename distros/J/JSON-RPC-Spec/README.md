[![Build Status](https://travis-ci.org/nqounet/p5-json-rpc-spec.svg?branch=main)](https://travis-ci.org/nqounet/p5-json-rpc-spec) [![Coverage Status](http://codecov.io/github/nqounet/p5-json-rpc-spec/coverage.svg?branch=main)](https://codecov.io/github/nqounet/p5-json-rpc-spec?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/JSON-RPC-Spec.svg)](https://metacpan.org/release/JSON-RPC-Spec)
# NAME

JSON::RPC::Spec - Yet another JSON-RPC 2.0 Implementation

# SYNOPSIS

```perl
use strict;
use JSON::RPC::Spec;

my $rpc = JSON::RPC::Spec->new;

# server
$rpc->register(echo => sub { $_[0] });
print $rpc->parse(
    '{"jsonrpc": "2.0", "method": "echo", "params": "Hello, World!", "id": 1}'
);    # -> {"jsonrpc":"2.0","result":"Hello, World!","id":1}

# client
print $rpc->compose(echo => 'Hello, World!', 1);
  # -> {"jsonrpc":"2.0","method":"echo","params":"Hello, World!","id":1}
```

# DESCRIPTION

JSON::RPC::Spec is Yet another JSON-RPC 2.0 Implementation.

JSON format string execute registered method.

JSON::RPC - PSGI

The tightly also supports BATCH.

As a feature.
1\. JSON string to JSON string.
2\. Simple register callback.

# FUNCTIONS

## new

constructor.

options ["coder" in JSON::RPC::Spec::Common](https://metacpan.org/pod/JSON%3A%3ARPC%3A%3ASpec%3A%3ACommon#coder) and ["router"](#router) are available.

## register

```perl
# method => code refs
use List::Util qw(max);
$rpc->register(max => sub { max(@{$_[0]}) });

# method matching via Router::Simple
$rpc->register('myapp.{action}' => sub {
    my ($params, $match) = @_;
    my $action = $match->{action};
    return MyApp->new->$action($params);
});
```

register method.

## parse

```perl
my $result = $rpc->parse(
    '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
);    # returns JSON encoded string -> {"id":1,"result":11,"jsonrpc":"2.0"}
```

parse JSON and triggered method. returns JSON encoded string.

## parse\_without\_encode

```perl
my $result = $rpc->parse_without_encode(
    '{"jsonrpc": "2.0", "method": "max", "params": [9,4,11,0], "id": 1}'
);    # returns hash -> {id => 1, result => 11, jsonrpc => '2.0'}
```

parse JSON and triggered method. returns HASH.

## compose

See ["compose" in JSON::RPC::Spec::Client](https://metacpan.org/pod/JSON%3A%3ARPC%3A%3ASpec%3A%3AClient#compose) for full documentation.

## router

similar [Router::Simple](https://metacpan.org/pod/Router%3A%3ASimple).

# DEBUGGING

You can set the `PERL_JSON_RPC_SPEC_DEBUG` environment variable to get some advanced diagnostics information printed to `STDERR`.

```
PERL_JSON_RPC_SPEC_DEBUG = 1
```

# SEE ALSO

[JSON::RPC](https://metacpan.org/pod/JSON%3A%3ARPC)

[JSON::RPC::Dispatcher](https://metacpan.org/pod/JSON%3A%3ARPC%3A%3ADispatcher)

[JSON::RPC::Common](https://metacpan.org/pod/JSON%3A%3ARPC%3A%3ACommon)

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

nqounet <mail@nqou.net>
