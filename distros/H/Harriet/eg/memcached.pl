$ENV{TEST_MEMCACHED} ||= do {
    require Test::TCP;
    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            exec '/usr/bin/memcached', '-p', $port;
            die $!;
        }
    );
    $HARRIET_GUARDS::MEMCACHED = $server;
    '127.0.0.1:' . $server->port;
};
