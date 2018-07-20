# NAME

FCGI::Client - client library for fastcgi protocol

# SYNOPSIS

    use FCGI::Client;

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    ) or die $!;
    my $client = FCGI::Client::Connection->new( sock => $sock );
    my ( $stdout, $stderr ) = $client->request(
        +{
            REQUEST_METHOD => 'GET',
            QUERY_STRING   => 'foo=bar',
        },
        ''
    );

# DESCRIPTION

FCGI::Client is client library for fastcgi protocol.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom @\*(#RJKLFHFSDLJF gmail.com>

# THANKS TO

peterkeen

# SEE ALSO

[FCGI](https://metacpan.org/pod/FCGI), [http://www.fastcgi.com/drupal/node/6?q=node/22](http://www.fastcgi.com/drupal/node/6?q=node/22)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
