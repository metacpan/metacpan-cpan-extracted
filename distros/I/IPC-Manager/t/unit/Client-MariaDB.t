use Test2::V0;
use IPC::Manager::Client::MariaDB;
use IPC::Manager::Serializer::JSON;

my $CLASS      = 'IPC::Manager::Client::MariaDB';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

skip_all "MariaDB driver not available" unless $CLASS->viable;

subtest 'viable' => sub {
    ok($CLASS->viable, "MariaDB is viable");
};

subtest 'escape' => sub {
    is($CLASS->escape, '`', "escape is backtick");
};

subtest 'default_attrs' => sub {
    is($CLASS->default_attrs, {AutoCommit => 1}, "default_attrs has AutoCommit");
};

subtest 'spawn connect disconnect unspawn' => sub {
    my ($route, $stash) = $CLASS->spawn(serializer => $SERIALIZER);
    ok($route, "spawn returns a route");

    my $con = $CLASS->connect('cd1', $SERIALIZER, $route);
    isa_ok($con, [$CLASS], "connect returns correct class");
    is($con->id, 'cd1', "id is correct");

    $con->disconnect;
    ok($con->disconnected, "disconnected");

    $CLASS->unspawn($route, $stash);
};

subtest 'send and get messages' => sub {
    my ($route, $stash) = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('sg1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('sg2', $SERIALIZER, $route);

    $con1->send_message(sg2 => {hello => 'world'});

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 1, "one message received");
    is($msgs[0]->content, {hello => 'world'}, "content correct");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route, $stash);
};

subtest 'peers' => sub {
    my ($route, $stash) = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('p1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('p2', $SERIALIZER, $route);

    is([$con1->peers], ['p2'], "con1 sees p2");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route, $stash);
};

subtest 'send to nonexistent peer dies' => sub {
    my ($route, $stash) = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('sn1', $SERIALIZER, $route);

    like(
        dies { $con->send_message(nobody => 'oops') },
        qr/Client 'nobody' does not exist/,
        "sending to nonexistent peer croaks",
    );

    $con->disconnect;
    $CLASS->unspawn($route, $stash);
};

done_testing;
