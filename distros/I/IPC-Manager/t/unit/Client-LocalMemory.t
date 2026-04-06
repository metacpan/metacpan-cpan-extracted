use Test2::V0;

use IPC::Manager::Client::LocalMemory;
use IPC::Manager::Serializer::JSON;

my $CLASS      = 'IPC::Manager::Client::LocalMemory';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

subtest 'viable' => sub {
    ok($CLASS->viable, "LocalMemory is always viable");
};

subtest 'spawn and unspawn' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    ok($route, "spawn returns a route");
    like($route, qr/^localmemory-\d+$/, "route has expected format");

    ok($CLASS->peer_exists_in_store($route), "store exists after spawn");
    $CLASS->unspawn($route);
    ok(!$CLASS->peer_exists_in_store($route), "store gone after unspawn");
};

subtest 'connect and disconnect' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('cd1', $SERIALIZER, $route);

    isa_ok($con, [$CLASS], "connect returns correct class");
    is($con->id, 'cd1', "id is correct");
    is($con->route, $route, "route is correct");
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

subtest 'ready_messages' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('rm1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('rm2', $SERIALIZER, $route);

    ok(!$con2->ready_messages, "no ready messages initially");

    $con1->send_message(rm2 => 'hi');
    ok($con2->ready_messages, "ready messages after send");

    $con2->get_messages;
    ok(!$con2->ready_messages, "no ready messages after get");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'pending_messages always 0' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('pm1', $SERIALIZER, $route);
    is($con->pending_messages, 0, "pending_messages always returns 0");
    $con->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peers' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('p1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('p2', $SERIALIZER, $route);
    my $con3 = $CLASS->connect('p3', $SERIALIZER, $route);

    is([$con1->peers], ['p2', 'p3'], "con1 sees p2 and p3");
    is([$con2->peers], ['p1', 'p3'], "con2 sees p1 and p3");

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

subtest 'peer_active' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('pa1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('pa2', $SERIALIZER, $route);

    ok($con1->peer_active('pa2'), "peer_active for running peer");
    ok(!$con1->peer_active('nonexistent'), "peer_active for missing peer");

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

subtest 'duplicate client id dies' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('dup1', $SERIALIZER, $route);

    like(
        dies { $CLASS->connect('dup1', $SERIALIZER, $route) },
        qr/Client 'dup1' already exists/,
        "duplicate client id croaks",
    );

    $con1->disconnect;
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

subtest 'write_stats and read_stats' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('ws1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('ws2', $SERIALIZER, $route);

    $con1->send_message(ws2 => 'x');
    $con2->get_messages;

    $con1->write_stats;
    $con2->write_stats;

    my $s1 = $con1->read_stats;
    my $s2 = $con2->read_stats;

    is($s1->{sent}{ws2}, 1, "written/read sent stat");
    is($s2->{read}{ws1}, 1, "written/read read stat");

    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'all_stats' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('as1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('as2', $SERIALIZER, $route);

    $con1->send_message(as2 => 'y');
    $con2->get_messages;

    $con1->write_stats;
    $con2->write_stats;

    my $all = $con1->all_stats;
    ok($all->{as1}, "all_stats has as1");
    ok($all->{as2}, "all_stats has as2");
    is($all->{as1}{sent}{as2}, 1, "all_stats sent correct");
    is($all->{as2}{read}{as1}, 1, "all_stats read correct");

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

subtest 'post_disconnect_hook removes client' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('dh1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('dh2', $SERIALIZER, $route);

    ok($con2->peer_exists('dh1'), "dh1 exists before disconnect");

    $con1->disconnect;
    ok(!$con2->peer_exists('dh1'), "dh1 gone after disconnect");

    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'suspend and reconnect' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('sr1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('sr2', $SERIALIZER, $route);

    $con1->send_message(sr2 => {before => 'suspend'});
    $con2->suspend;

    $con1->send_message(sr2 => {during => 'suspend'});

    my $con2b = $CLASS->reconnect('sr2', $SERIALIZER, $route);
    ok($con2b, "reconnected");

    my @msgs = $con2b->get_messages;
    is(scalar @msgs, 2, "got both messages after reconnect");
    my @contents = map { $_->content } @msgs;
    is(\@contents, [{before => 'suspend'}, {during => 'suspend'}], "messages preserved across suspend");

    $con1->disconnect;
    $con2b->disconnect;
    $CLASS->unspawn($route);
};

subtest 'try_message success and failure' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('tm1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('tm2', $SERIALIZER, $route);

    my $ok = $con1->try_message(tm2 => 'hello');
    ok($ok, "try_message returns true on success");

    my ($ok2, $err) = $con1->try_message(nonexistent => 'fail');
    ok(!$ok2, "try_message returns false for missing peer");
    ok($err, "error returned for missing peer");

    $con2->get_messages;    # drain before disconnect
    $con1->disconnect;
    $con2->disconnect;
    $CLASS->unspawn($route);
};

subtest 'select not supported' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con = $CLASS->connect('sel1', $SERIALIZER, $route);

    ok(!$con->have_handles_for_select, "no select support");
    ok(!$con->have_handles_for_peer_change, "no peer change handle support");

    $con->disconnect;
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

subtest 'messages between multiple pairs' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con1 = $CLASS->connect('mp1', $SERIALIZER, $route);
    my $con2 = $CLASS->connect('mp2', $SERIALIZER, $route);
    my $con3 = $CLASS->connect('mp3', $SERIALIZER, $route);

    $con1->send_message(mp2 => 'for-2');
    $con1->send_message(mp3 => 'for-3');
    $con2->send_message(mp1 => 'back-to-1');

    my @m1 = $con1->get_messages;
    my @m2 = $con2->get_messages;
    my @m3 = $con3->get_messages;

    is(scalar @m1, 1, "con1 got 1 message");
    is($m1[0]->content, 'back-to-1', "con1 content correct");

    is(scalar @m2, 1, "con2 got 1 message");
    is($m2[0]->content, 'for-2', "con2 content correct");

    is(scalar @m3, 1, "con3 got 1 message");
    is($m3[0]->content, 'for-3', "con3 content correct");

    $con1->disconnect;
    $con2->disconnect;
    $con3->disconnect;
    $CLASS->unspawn($route);
};

subtest 'reconnect to nonexistent client dies' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    like(
        dies { $CLASS->reconnect('ghost', $SERIALIZER, $route) },
        qr/Client 'ghost' does not exist/,
        "reconnect to missing client croaks",
    );

    $CLASS->unspawn($route);
};

subtest 'unspawn removes store' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    ok($CLASS->peer_exists_in_store($route), "store exists");
    $CLASS->unspawn($route);
    ok(!$CLASS->peer_exists_in_store($route), "store removed");
};

done_testing;
