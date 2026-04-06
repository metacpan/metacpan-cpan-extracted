use Test2::V0;

use Test2::Require::Module 'Atomic::Pipe';

use IPC::Manager::Client::AtomicPipe;
use IPC::Manager::Serializer::JSON;
use File::Temp qw/tempdir/;

my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

subtest 'viable' => sub {
    ok(IPC::Manager::Client::AtomicPipe->viable, "AtomicPipe is viable when Atomic::Pipe available");
};

subtest 'check_path and path_type' => sub {
    is(IPC::Manager::Client::AtomicPipe->path_type, 'FIFO', "path_type is FIFO");
    ok(!IPC::Manager::Client::AtomicPipe->check_path('/tmp'), "directory is not a FIFO");
};

subtest 'send and get messages' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'ap1');
    my $con2 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'ap2');

    $con1->send_message(ap2 => {hello => 'pipe'});

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 1, "one message received");
    is($msgs[0]->from, 'ap1', "from correct");
    is($msgs[0]->content, {hello => 'pipe'}, "content correct");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'multiple messages' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'mp1');
    my $con2 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'mp2');

    $con1->send_message(mp2 => 'first');
    $con1->send_message(mp2 => 'second');

    my @msgs = $con2->get_messages;
    is(scalar @msgs, 2, "two messages");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'handles_for_select' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'hs1');

    ok($con->have_handles_for_select, "has handles for select");
    my @handles = $con->handles_for_select;
    ok(scalar @handles > 0, "got select handles");

    $con->disconnect;
};

subtest 'fill_buffer' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'fb1');
    my $con2 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'fb2');

    # No messages - fill_buffer should return 0
    my $filled = $con2->fill_buffer;
    ok(!$filled, "no messages to fill");

    $con1->send_message(fb2 => 'buffered');

    $filled = $con2->fill_buffer;
    ok($filled, "filled buffer with a message");

    # Get messages clears buffer
    my @msgs = $con2->get_messages;
    ok(scalar @msgs >= 1, "got buffered message");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'broadcast' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'b1');
    my $con2 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'b2');
    my $con3 = IPC::Manager::Client::AtomicPipe->new(serializer => $SERIALIZER, route => $dir, id => 'b3');

    $con1->broadcast({mass => 'pipe'});

    my @m2 = $con2->get_messages;
    my @m3 = $con3->get_messages;

    is(scalar @m2, 1, "con2 got broadcast");
    is(scalar @m3, 1, "con3 got broadcast");

    $con1->disconnect;
    $con2->disconnect;
    $con3->disconnect;
};

done_testing;
