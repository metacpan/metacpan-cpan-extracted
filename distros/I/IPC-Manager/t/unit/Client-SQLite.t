use Test2::V0;

my $CLASS      = 'IPC::Manager::Client::SQLite';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

skip_all "SQLite driver not available" unless eval { require IPC::Manager::Client::SQLite; $CLASS->viable };

use IPC::Manager::Serializer::JSON;

subtest 'viable' => sub {
    ok($CLASS->viable, "SQLite is viable");
};

subtest 'spawn and unspawn' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    ok($route, "spawn returns a route");
    ok(-f $route, "route is a file on disk");
    like($route, qr/\.sqlite$/, "route has .sqlite suffix");

    $CLASS->unspawn($route);
    ok(!-e $route, "file removed after unspawn");
};

subtest 'escape' => sub {
    is($CLASS->escape, '`', "escape is backtick");
};

subtest 'connect and disconnect' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('cd1', $SERIALIZER, $route);

    isa_ok($con, [$CLASS], "connect returns correct class");
    is($con->id, 'cd1', "id is correct");
    ok(!$con->disconnected, "not disconnected initially");

    $con->disconnect;
    ok($con->disconnected, "disconnected after disconnect");

    $CLASS->unspawn($route);
};

subtest 'send and get messages' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('sg1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('sg2', $SERIALIZER, $route);

    $con1->send_message(sg2 => {hello => 'world'});

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 1, "one message received");
    is($msgs[0]->from, 'sg1', "from is correct");
    is($msgs[0]->to, 'sg2', "to is correct");
    is($msgs[0]->content, {hello => 'world'}, "content is correct");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'multiple messages ordering' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('mo1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('mo2', $SERIALIZER, $route);

    $con1->send_message(mo2 => 'first');
    $con1->send_message(mo2 => 'second');
    $con1->send_message(mo2 => 'third');

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 3, "three messages");
    my @contents = map { $_->content } @msgs;
    is(\@contents, ['first', 'second', 'third'], "messages in order");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peers' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('p1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('p2', $SERIALIZER, $route);
    my $con3 = $CLASS->connect('p3', $SERIALIZER, $route);

    is([$con1->peers], ['p2', 'p3'], "con1 sees p2 and p3");

    $con1->disconnect;
    $con2->disconnect;
    $con3->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peer_exists and peer_pid' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('pe1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('pe2', $SERIALIZER, $route);

    ok($con1->peer_exists('pe2'), "peer_exists for connected peer");
    ok(!$con1->peer_exists('nonexistent'), "peer_exists for missing peer");

    is($con1->peer_pid('pe2'), $$, "peer_pid returns correct pid");
    is($con1->peer_pid('nonexistent'), undef, "peer_pid returns undef for missing");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'send to nonexistent peer dies' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('sn1', $SERIALIZER, $route);

    like(
        dies { $con->send_message(nobody => 'oops') },
        qr/Client 'nobody' does not exist/,
        "sending to nonexistent peer croaks",
    );

    $con->disconnect;
    $CLASS->unspawn($route);
};

subtest 'stats tracking' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('st1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('st2', $SERIALIZER, $route);

    $con1->send_message(st2 => 'a');
    $con1->send_message(st2 => 'b');
    $con2->get_messages;

    is($con1->stats->{sent}{st2}, 2, "sent count");
    is($con2->stats->{read}{st1}, 2, "read count");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'broadcast' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('bc1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('bc2', $SERIALIZER, $route);
    my $con3 = $CLASS->connect('bc3', $SERIALIZER, $route);

    $con1->broadcast({mass => 'msg'});

    my @m2 = $con2->get_messages;
    my @m3 = $con3->get_messages;
    my @m1 = $con1->get_messages;

    is(scalar @m2, 1, "con2 got broadcast");
    is(scalar @m3, 1, "con3 got broadcast");
    is(scalar @m1, 0, "con1 did not get own broadcast");

    is($m2[0]->content, {mass => 'msg'}, "broadcast content correct");

    $con1->disconnect;
    $con2->disconnect;
    $con3->disconnect;
    $CLASS->unspawn($route);
};

subtest 'post_disconnect_hook deactivates client' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('dh1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('dh2', $SERIALIZER, $route);

    ok($con1->peer_pid('dh2'), "dh2 has pid before disconnect");

    $con2->disconnect;
    ok(!$con1->peer_pid('dh2'), "dh2 pid gone after disconnect");

    $con1->disconnect;
    $CLASS->unspawn($route);
};

subtest 'get_messages returns empty when none' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('em1', $SERIALIZER, $route);

    my @msgs = $con->get_messages;
    is(scalar @msgs, 0, "no messages when none sent");

    $con->disconnect;
    $CLASS->unspawn($route);
};

done_testing;
