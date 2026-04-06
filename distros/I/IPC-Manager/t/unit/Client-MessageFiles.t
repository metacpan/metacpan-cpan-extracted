use Test2::V0;

use IPC::Manager::Client::MessageFiles;
use IPC::Manager::Serializer::JSON;
use File::Temp qw/tempdir/;
use File::Spec;

my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

subtest 'viable' => sub {
    ok(IPC::Manager::Client::MessageFiles->viable, "MessageFiles is always viable");
};

subtest 'check_path and path_type' => sub {
    my $dir = tempdir(CLEANUP => 1);
    ok(IPC::Manager::Client::MessageFiles->check_path($dir), "check_path on directory");
    ok(!IPC::Manager::Client::MessageFiles->check_path('/nonexistent/path/zzz'), "check_path on missing");
    is(IPC::Manager::Client::MessageFiles->path_type, 'subdir', "path_type");
};

subtest 'send and get messages' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'sg1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'sg2');

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
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'mo1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'mo2');

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

subtest 'pending_messages and ready_messages' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pr1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pr2');

    ok(!$con2->ready_messages, "no ready messages initially");

    $con1->send_message(pr2 => 'hi');

    ok($con2->ready_messages, "ready messages after send");

    $con2->get_messages;
    # After get_messages the internal ready_count cache is stale (still
    # reflects the previous message_files() call).  A second
    # message_files() readdir refreshes it.
    $con2->message_files('ready');
    ok(!$con2->ready_messages, "no ready messages after get + refresh");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'message_files returns correct ext' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'mf1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'mf2');

    $con1->send_message(mf2 => 'test');

    my $ready = $con2->message_files('ready');
    ok($ready, "got ready files");
    ok(ref($ready) eq 'ARRAY', "ready is arrayref");
    ok(scalar @$ready > 0, "has ready files");

    my $pend = $con2->message_files('pend');
    ok(!$pend, "no pending files (they are already ready)");

    $con2->get_messages;
    $con1->disconnect;
    $con2->disconnect;
};

subtest 'dir_handle' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'dh1');

    my $dh = $con->dir_handle;
    ok($dh, "got dir handle");

    my $dh2 = $con->dir_handle;
    is($dh, $dh2, "dir handle is cached");

    $con->disconnect;
};

subtest 'pre_disconnect_hook renames directory' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pdh1');

    my $orig_path = $con->path;
    ok(-d $orig_path, "original path exists");

    $con->pre_disconnect_hook;

    ok(!-d $orig_path, "original path gone after pre_disconnect_hook");
    my $new_path = File::Spec->catfile($dir, '_pdh1');
    ok(-d $new_path, "renamed path exists");

    $con->{disconnected} = 1;
};

subtest 'stats tracking' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'st1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'st2');

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
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'bc1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'bc2');
    my $con3 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'bc3');

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

done_testing;
