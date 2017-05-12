# NAME

MessagePack::RPC::HTTP::Client - Perl version of msgpack-rpc-over-http (ruby) client.

# SYNOPSIS

    use MessagePack::RPC::HTTP::Client;
    my $client = MessagePack::RPC::HTTP::Client->new("http://remote.server.local/");
    my $result = $client->call("remoteMethodName", "param1", "param2");

# DESCRIPTION

MessagePack::RPC::HTTP::Client is a version of 'msgpack-rpc-over-http' client in Perl.

Current version of this module supports only sync call. Async call and streams are not supported now.

# LICENSE

Copyright (C) TAGOMORI Satoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

TAGOMORI Satoshi <tagomoris@gmail.com>
