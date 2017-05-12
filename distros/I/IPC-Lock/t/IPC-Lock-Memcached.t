use Test::More tests => 8;
BEGIN { use_ok('IPC::Lock::Memcached') };
BEGIN { use_ok('IO::Socket::INET') };

my $socket = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => 'http(11211)',
    Proto    => 'tcp'
);

SKIP: {
    skip 'Memcached not found running', 6 unless($socket);
    my $object = IPC::Lock::Memcached->new({
        memcached_servers => ['localhost:11211'],
    });
    
    my $key = "$$.testing";
    ok($object && ref $object && ref $object eq 'IPC::Lock::Memcached', 'instantiation');
    ok($object->lock($key), "$key locked $object");
    ok(!$object->lock($key), "$key still locked");
    ok($object->memcached->get($key), "$key exists in memcached");
    ok($object->unlock, "$key unlocked");
    ok(!$object->memcached->get($key), "$key deleted from memcached");
}
