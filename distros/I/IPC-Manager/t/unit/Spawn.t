use Test2::V0;
use Test2::IPC;

use IPC::Manager::Spawn;
use IPC::Manager::Client::LocalMemory;
use IPC::Manager::Serializer::JSON;

my $PROTOCOL   = 'IPC::Manager::Client::LocalMemory';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

subtest 'init requires protocol, route, serializer' => sub {
    like(
        dies { IPC::Manager::Spawn->new(route => '/tmp', serializer => $SERIALIZER, guard => 0) },
        qr/'protocol' is a required/,
        "requires protocol",
    );
    like(
        dies { IPC::Manager::Spawn->new(protocol => $PROTOCOL, serializer => $SERIALIZER, guard => 0) },
        qr/'route' is a required/,
        "requires route",
    );
    like(
        dies { IPC::Manager::Spawn->new(protocol => $PROTOCOL, route => '/tmp', guard => 0) },
        qr/'serializer' is a required/,
        "requires serializer",
    );
};

subtest 'basic construction' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    is($spawn->protocol, $PROTOCOL, "protocol");
    is($spawn->route, $route, "route");
    is($spawn->serializer, $SERIALIZER, "serializer");
    is($spawn->pid, $$, "pid defaults to current");

    $PROTOCOL->unspawn($route);
};

subtest 'info and stringification' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    my $info = $spawn->info;
    ok($info, "info returns a string");
    is("$spawn", $info, "stringification returns info");

    my $decoded = IPC::Manager::Serializer::JSON->deserialize($info);
    is($decoded, [$PROTOCOL, $SERIALIZER, $route], "info contains protocol, serializer, route");

    $PROTOCOL->unspawn($route);
};

subtest 'connect returns client' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    my $con = $spawn->connect('test1');
    isa_ok($con, [$PROTOCOL]);
    is($con->id, 'test1', "id matches");

    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'sanity_delta with no mismatch' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    my $con1 = $spawn->connect('c1');
    my $con2 = $spawn->connect('c2');

    $con1->send_message(c2 => 'hello');
    $con2->get_messages;

    $con1->disconnect;
    $con2->disconnect;

    my $delta = $spawn->sanity_delta;
    is($delta, undef, "no delta when messages match");

    $PROTOCOL->unspawn($route);
};

subtest 'sanity_delta detects mismatch' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    my $con1 = $spawn->connect('d1');
    my $con2 = $spawn->connect('d2');

    $con1->send_message(d2 => 'hello');

    $con1->disconnect;
    $con2->{disconnected} = 1;
    $con2->write_stats;

    my $delta = $spawn->sanity_delta;
    ok($delta, "delta detected");
    ok($delta->{"d1 -> d2"}, "mismatch found for d1 -> d2");

    $PROTOCOL->unspawn($route);
};

subtest 'sanity_check dies on mismatch' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    my $con1 = $spawn->connect('e1');
    my $con2 = $spawn->connect('e2');

    $con1->send_message(e2 => 'hello');
    $con1->disconnect;
    $con2->{disconnected} = 1;
    $con2->write_stats;

    like(dies { $spawn->sanity_check }, qr/mismatch/, "sanity_check dies on mismatch");

    $PROTOCOL->unspawn($route);
};

subtest 'sanity_check passes when clean' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    my $con1 = $spawn->connect('f1');
    my $con2 = $spawn->connect('f2');

    $con1->send_message(f2 => 'hi');
    $con2->get_messages;

    $con1->disconnect;
    $con2->disconnect;

    ok(lives { $spawn->sanity_check }, "sanity_check passes");

    $PROTOCOL->unspawn($route);
};

subtest 'shutdown cleans up' => sub {
    my $route = $PROTOCOL->spawn();
    my $spawn = IPC::Manager::Spawn->new(
        protocol   => $PROTOCOL,
        route      => $route,
        serializer => $SERIALIZER,
        guard      => 0,
    );

    ok($PROTOCOL->peer_exists_in_store($route), "route exists before shutdown");
    $spawn->shutdown;
    ok(!$PROTOCOL->peer_exists_in_store($route), "route removed after shutdown");
};

done_testing;
