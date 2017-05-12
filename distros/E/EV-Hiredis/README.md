# NAME

EV::Hiredis - Asynchronous redis client using hiredis and EV

# SYNOPSIS

    use EV::Hiredis;
    
    my $redis = EV::Hiredis->new;
    $redis->connect('127.0.0.1');
    
    # or
    my $redis = EV::Hiredis->new( host => '127.0.0.1' );
    
    # command
    $redis->set('foo' => 'bar', sub {
        my ($res, $err) = @_;
    
        print $res; # OK
    
        $redis->get('foo', sub {
            my ($res, $err) = @_;
    
            print $res; # bar
    
            $redis->disconnect;
        });
    });
    
    # start main loop
    EV::run;

# DESCRIPTION

EV::Hiredis is a asynchronous client for Redis using hiredis and [EV](https://metacpan.org/pod/EV) as backend.

This module connected to [EV](https://metacpan.org/pod/EV) with C-Level interface so that it runs faster.

# ANYEVENT INTEGRATION

[AnyEvent](https://metacpan.org/pod/AnyEvent) has a support for EV as its one of backends, so [EV::Hiredis](https://metacpan.org/pod/EV::Hiredis) can be used in your AnyEvent applications seamlessly.

# NO UTF-8 SUPPORT

Unlike other redis modules, this module doesn't support utf-8 string.

This module handle all variables as bytes. You should encode your utf-8 string before passing commands like following:

    use Encode;
    
    # set $val
    $redis->set(foo => encode_utf8 $val, sub { ... });
    
    # get $val
    $redis->get(foo, sub {
        my $val = decode_utf8 $_[0];
    });

# METHODS

## new(%options);

Create new [EV::Hiredis](https://metacpan.org/pod/EV::Hiredis) instance.

Available `%options` are:

- host => 'Str'
- port => 'Int'

    Hostname and port number of redis-server to connect.

- path => 'Str'

    UNIX socket path to connect.

- on\_error => $cb->($errstr)

    Error callback will be called when a connection level error occurs.

    This callback can be set by `$obj->on_error($cb)` method any time.

- on\_connect => $cb->()

    Connection callback will be called when connection successful and completed to redis server.

    This callback can be set by `$obj->on_connect($cb)` method any time.

- loop => 'EV::loop',

    EV loop for running this instance. Default is `EV::default_loop`.

All parameters are optional.

If parameters about connection (host&port or path) is not passed, you should call `connect` or `connect_unix` method by hand to connect to redis-server.

## connect($hostname, $port)

## connect\_unix($path)

Connect to a redis-server for `$hostname:$port` or `$path`.

on\_connect callback will be called if connection is successful, otherwise on\_error callback is called.

## command($commands..., $cb->($result, $error))

Do a redis command and return its result by callback.

    $redis->command('get', 'foo', sub {
        my ($result, $error) = @_;

        print $result; # value for key 'foo'
        print $error;  # redis error string, undef if no error
    });

If any error is occurred, `$error` presents the error message and `$result` is undef.
If no error, `$error` is undef and `$result` presents response from redis.

NOTE: Alternatively all commands can be called via AUTOLOAD interface.

    $redis->command('get', 'foo', sub { ... });

is equivalent to:

    $redis->get('foo', sub { ... });

## disconnect

Disconnect from redis-server. This method is usable for exiting event loop.

## on\_error($cb->($errstr))

Set new error callback to the instance.

## on\_connect($cb->())

Set new connect callback to the instance.

# AUTHOR

Daisuke Murase <typester@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2013 Daisuke Murase All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
