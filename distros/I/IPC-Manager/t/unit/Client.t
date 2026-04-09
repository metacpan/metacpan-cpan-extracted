use Test2::V0;

use IPC::Manager::Client;
use IPC::Manager::Client::LocalMemory;
use IPC::Manager::Serializer::JSON;

my $SERIALIZER = 'IPC::Manager::Serializer::JSON';
my $PROTOCOL   = 'IPC::Manager::Client::LocalMemory';

subtest 'base class abstract methods croak' => sub {
    for my $method (qw/have_ready_messages handles_for_select
                       reset_handles_for_peer_change handles_for_peer_change
                       get_messages peer_exists peer_pid peers
                       read_stats send_message spawn write_stats all_stats/) {
        like(
            dies { IPC::Manager::Client->$method },
            qr/Not Implemented/,
            "$method croaks in base class",
        );
    }
};

subtest 'viable returns false on base class' => sub {
    ok(!IPC::Manager::Client->viable, "base class viable() returns false");
};

subtest 'have_pending_messages defaults to 0' => sub {
    is(IPC::Manager::Client->have_pending_messages, 0, "default is 0");
};

subtest 'have_handles_for_select defaults to 0' => sub {
    is(IPC::Manager::Client->have_handles_for_select, 0, "default is 0");
};

subtest 'have_handles_for_peer_change defaults to 0' => sub {
    is(IPC::Manager::Client->have_handles_for_peer_change, 0, "default is 0");
};

subtest 'init requires serializer, route, id' => sub {
    my $route = $PROTOCOL->spawn();
    like(
        dies { $PROTOCOL->new(route => $route, id => 'x') },
        qr/'serializer' is a required/,
        "requires serializer",
    );
    like(
        dies { $PROTOCOL->new(serializer => $SERIALIZER, id => 'x') },
        qr/'route' is a required/,
        "requires route",
    );
    like(
        dies { $PROTOCOL->new(serializer => $SERIALIZER, route => $route) },
        qr/'id' is a required/,
        "requires id",
    );
    $PROTOCOL->unspawn($route);
};

subtest 'id may not begin with underscore' => sub {
    my $route = $PROTOCOL->spawn();
    like(
        dies { $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => '_bad') },
        qr/may not begin with an underscore/,
        "underscore id rejected",
    );
    $PROTOCOL->unspawn($route);
};

subtest 'pid_check' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'test_pid_check');
    ok(lives { $con->pid_check }, "pid_check passes in same pid");
    $con->{pid} = $$ + 99999;
    like(dies { $con->pid_check }, qr/wrong PID/, "pid_check fails in wrong pid");
    $con->{pid} = $$;
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'build_message' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'builder');
    my $msg = $con->build_message('peer1', {data => 1});
    isa_ok($msg, ['IPC::Manager::Message']);
    is($msg->from, 'builder', "from is set to client id");
    is($msg->to, 'peer1', "to is set");
    is($msg->content, {data => 1}, "content is set");
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'build_message with named args' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'builder2');
    my $msg = $con->build_message(to => 'peer1', content => {data => 1});
    is($msg->from, 'builder2', "from is set");
    is($msg->to, 'peer1', "to is set");
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'local_clients' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'local1');
    my @locals = IPC::Manager::Client->local_clients($route);
    ok(scalar(grep { $_->id eq 'local1' } @locals), "local client found");
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'local_clients requires route' => sub {
    like(dies { IPC::Manager::Client->local_clients() }, qr/'route' is required/, "route required");
};

subtest 'try_message - scalar context' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'tryer');
    my $ok = $con->try_message(to => 'nonexistent', content => 'x');
    ok(!$ok, "try_message returns false on failure");
    ok($@, "\$\@ is set on failure");
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'try_message - list context' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'tryer2');
    my ($ok, $err) = $con->try_message(to => 'nonexistent', content => 'x');
    ok(!$ok, "try_message returns false on failure");
    ok($err, "error message returned");
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'stats initialized' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'stats1');
    is($con->stats, {read => {}, sent => {}}, "stats initialized");
    $con->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'disconnect sets disconnected' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'disc1');
    ok(!$con->disconnected, "not disconnected initially");
    $con->disconnect;
    ok($con->disconnected, "disconnected after disconnect");
    $PROTOCOL->unspawn($route);
};

subtest 'double disconnect is a no-op' => sub {
    my $route = $PROTOCOL->spawn();
    my $con = $PROTOCOL->new(serializer => $SERIALIZER, route => $route, id => 'disc2');
    $con->disconnect;
    ok(lives { $con->disconnect }, "second disconnect is fine");
    $PROTOCOL->unspawn($route);
};

done_testing;
