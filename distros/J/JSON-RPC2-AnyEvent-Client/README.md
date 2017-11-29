# NAME

JSON::RPC2::AnyEvent::Client - Asynchronous nonblocking JSON RPC2 client with method mapping

# SYNOPSIS

    use JSON::RPC2::AnyEvent::Client;

    # create tcp connection
    my $rpc = JSON::RPC2::AnyEvent::Client->new(
        host     => "127.0.0.1",
        port     => 5555,
        on_error => sub{ die $_[0] } 
    );

    # call
    $rpc->sum( 1, 2, sub{
        my ( $failed, $result, $error ) = @_;
        print $result unless $failed || $error;
    })

    # call remote function with simple configure
    $rpc->service('agent')->listed()->remote_function( 'param1', 'param2', sub{
        my ( $failed, $result, $error ) = @_;
    })

    # some more constructor arguments
    my $rpc = JSON::RPC2::AnyEvent::Client->new(
        url     => "https://$host:$port/api", # http/https transport
        service => 'agent',
        call    => 'listed' || 'named',
        service => '_service',  # rename any this module methods
    );

    # destroy rpc connection when done
    $rpc->destroy;

# DESCRIPTION

JSON::RPC2::AnyEvent::Client is JSON RPC2 client, with
tcp/http/https transport. Remote functions is mapped to local
client object methods. For example remote function fn(...) is
called as $c->fn(...,cb). Params of function is params of remote
functions with additional one at the end of param list.
Additional last param is result handler soubroutine.

Implementation is based on JSON RPC2 implementation
[JSON::RPC2::Client](https://metacpan.org/pod/JSON::RPC2::Client). Transport implementation is based
on [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle) for tcp, and on [AnyEvent::HTTP](https://metacpan.org/pod/AnyEvent::HTTP)
for http/https.

The 'tcp' implementation use persistent connection, that make
tcp connection at object creation and use it all object life time.
The http/https persistence is AnyEvent::HTTP implementation
dependent and currently it is not persistent for idempotent
requsests (JSON RPC2 need POST requset). See description of
'persistent' and 'keepalive' params of [AnyEvent::HTTP](https://metacpan.org/pod/AnyEvent::HTTP).

# METHODS

- $rpc = **new** JSON::RPC2::AnyEvent::Client host=>'example.com', ...

    The constructor supports arguments as `key => value` pairs.

    - host => 'example.com'

        The hostname or ip address. This enable tcp transport.
        The special value "unix/" used to connect to unix domain
        socket. Current version support unix domain socket only
        for 'tcp' transport.

    - port => 5555

        The tcp port number or unix domain socket path. Used togather
        with 'host' param.

    - on\_error = sub{ die $\_\[0\] }

        The transport error handler callback. Remote RPC service errors
        does not mapped to this handler. This error also will emit
        all alredy waited for result callback handlers.

    - url => "https://$host:$port/api/rpc"

        The url of requst. This enables http/https transport.

    - service => 'agent'

        Set the service name, it will be prefix before remote function
        name with dot as separator. So if service is 'agent' then call
        like $rpc->remote\_fn(), then `agent.remote_fn` will be called

    - call => 'listed' || 'named'

        Type of RPC call, default listed.

    - simplify\_errors => 1

        This option change callback api from two error to one by unify
        transport error with text error message from remote server.
        This option allow to simplify result callback writing but make
        less compatible with rpc protocol. It also make result callback
        impossible to recognize type of error is it transport or remote.
        This is usable for simple applications. See result callback
        handler for more info.

    - any\_method\_name => 'remap\_method\_name'

        If remote server have method with same name as in this module,
        it is possible to rename this module `method_name` to another
        name `remap_method_name`

- **service** ( "service\_name" )

    Set remote service name, if undef - then no service name used.

- **listed**

    RPC listed call type will be used.

- **named**

    RPC named call type will be used.

- **any other name** ( $param1, $param2, ..., $cb )

    Any method name will called via RPC on remote server. 
    Last param must be result handler callback cb(). 

# RESULT HANDLER CALLBACK

The result callback handler is a soubroutine that called
when rpc function is called and result is arrived or
an error occured. There three param of callback is
`( $fail, $result, $error );`

The $fail is transport error. It is string that contain
description of communication or data decoding error.

The $result is server responce, valid only when there
is no fail or error.

The $error is described in rpc protocol standart remote
server error responce. It is valid only when no fail.

There is special case for simple applications enabled by
`simplify_errors` constructor argument. The result callback
at this case have only two params. First param is transport
error if any or text error message arrived from remote service.
Simplified callback prototype is:
`( $error, $result );`

# DEPENDENCIES

- [AnyEvent::Handle](https://metacpan.org/pod/AnyEvent::Handle);
- [AnyEvent::HTTP](https://metacpan.org/pod/AnyEvent::HTTP);
- [JSON::RPC2::Client](https://metacpan.org/pod/JSON::RPC2::Client);
- [JSON::XS](https://metacpan.org/pod/JSON::XS)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Serguei Okladnikov <oklaspec@gmail.com>
