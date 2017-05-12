[![Build Status](https://travis-ci.org/nqounet/p5-json-rpc-lite.png?branch=master)](https://travis-ci.org/nqounet/p5-json-rpc-lite)
# NAME

JSON::RPC::Lite - Simple Syntax JSON RPC 2.0 Server Implementation

# SYNOPSIS

    # app.psgi
    use JSON::RPC::Lite;
    method 'echo' => sub {
        return $_[0];
    };
    method 'empty' => sub {''};
    as_psgi_app;

    # run
    $ plackup app.psgi

# DESCRIPTION

JSON::RPC::Lite is sinatra-ish style JSON RPC 2.0 Server Implementation.

# FUNCTIONS

## method

    method 'method_name1' => sub { ... };
    method 'method_name2' => sub { ... };

register method

## as\_psgi\_app

    as_psgi_app;

run as PSGI app.

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

nqounet <mail@nqou.net>
