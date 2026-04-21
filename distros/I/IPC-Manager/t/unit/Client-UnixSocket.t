use Test2::V0;
use Test2::Require::Module 'IO::Socket::UNIX' => '1.55';

use File::Temp qw/tempdir/;
use IPC::Manager::Client::UnixSocket;
use IPC::Manager::Serializer::JSON;

my $CLASS      = 'IPC::Manager::Client::UnixSocket';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

subtest 'viable' => sub {
    ok($CLASS->viable, "UnixSocket is viable");
};

subtest 'path_type' => sub {
    is($CLASS->path_type, 'UNIX Socket', "path_type");
};

subtest 'suspend not supported' => sub {
    ok(!$CLASS->suspend_supported, "suspend_supported returns false");
};

subtest 'connect and disconnect' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'cd1');

    isa_ok($con, [$CLASS], "connect returns correct class");
    is($con->id, 'cd1', "id is correct");
    ok(!$con->disconnected, "not disconnected initially");

    $con->disconnect;
    ok($con->disconnected, "disconnected after disconnect");
};

subtest 'send and get messages' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'sg1');
    my $con2 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'sg2');

    $con1->send_message(sg2 => {hello => 'world'});

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 1, "one message received");
    is($msgs[0]->from, 'sg1', "from is correct");
    is($msgs[0]->to, 'sg2', "to is correct");
    is($msgs[0]->content, {hello => 'world'}, "content is correct");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'multiple messages ordering' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'mo1');
    my $con2 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'mo2');

    $con1->send_message(mo2 => 'first');
    $con1->send_message(mo2 => 'second');
    $con1->send_message(mo2 => 'third');

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 3, "three messages");
    my @contents = map { $_->content } @msgs;
    is(\@contents, ['first', 'second', 'third'], "messages in order");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'have_handles_for_select' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'sel1');

    ok($con->have_handles_for_select, "has select handles");
    my @handles = $con->handles_for_select;
    ok(@handles, "returns handles");

    $con->disconnect;
};

subtest 'stats tracking' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'st1');
    my $con2 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'st2');

    $con1->send_message(st2 => 'a');
    $con1->send_message(st2 => 'b');
    $con2->get_messages;

    is($con1->stats->{sent}{st2}, 2, "sent count");
    is($con2->stats->{read}{st1}, 2, "read count");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'broadcast' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'bc1');
    my $con2 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'bc2');
    my $con3 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'bc3');

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
};

subtest 'suspend croaks' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'sus1');

    like(
        dies { $con->suspend },
        qr/suspend is not supported/,
        "suspend croaks",
    );

    $con->disconnect;
};

subtest 'get_messages returns empty when none' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'em1');

    my @msgs = $con->get_messages;
    is(scalar @msgs, 0, "no messages when none sent");

    $con->disconnect;
};

subtest 'long peer names survive sun_path limit' => sub {
    # Force a predictable short tmpdir so there is room to exercise long ids.
    my $dir = tempdir('ipcm-uXXXXXX', TMPDIR => 1, CLEANUP => 1);

    my $long_id = "ll-" . ("z" x 200);
    my $con1 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => $long_id);
    my $con2 = $CLASS->new(serializer => $SERIALIZER, route => $dir, id => 'short');

    ok($con2->peer_exists($long_id), "peer_exists sees long-named peer");
    is([$con2->peers], [$long_id], "peers() returns the real long name");

    $con2->send_message($long_id => {hi => 'long'});
    my @msgs = $con1->get_messages;
    is(scalar(@msgs), 1, "long-named peer received one message");
    is($msgs[0]->content, {hi => 'long'}, "content round-trips");
    is($msgs[0]->to, $long_id, "'to' is the real long name");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'route too long for sun_path croaks clearly' => sub {
    my $dir = tempdir('ipcm-uXXXXXX', TMPDIR => 1, CLEANUP => 1);
    # Create a deep subdirectory to push the route past the sun_path ceiling.
    my $deep = $dir;
    my $seg  = 'x' x 20;
    $deep .= "/$seg" for 1 .. 6; # ~120+ chars
    require File::Path;
    File::Path::make_path($deep);
    like(
        dies {
            my $con = $CLASS->new(serializer => $SERIALIZER, route => $deep, id => 'anything');
        },
        qr/sun_path limit/,
        "route too long croaks with sun_path message",
    );
};

done_testing;
