use Test2::V0;

use IPC::Manager::Client::MessageFiles;
use IPC::Manager::Serializer::JSON;
use File::Temp qw/tempdir/;
use File::Spec;

my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

subtest 'path and pidfile' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pathtest');

    my $path = $con->path;
    is($path, File::Spec->catfile($dir, 'pathtest'), "path is route/id");
    ok(-d $path, "path directory created");

    my $pidfile = $con->pidfile;
    like($pidfile, qr/pathtest\.pid$/, "pidfile ends with .pid");
    ok(-e $pidfile, "pidfile exists");

    $con->disconnect;
};

subtest 'resume_file' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'restest');

    my $rf = $con->resume_file;
    like($rf, qr/restest\.resume$/, "resume file path");
    ok(!$con->have_resume_file, "no resume file initially");

    $con->disconnect;
};

subtest 'write_pid and clear_pid' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pidtest');

    my $pidfile = $con->pidfile;
    ok(-e $pidfile, "pidfile exists after init");

    open(my $fh, '<', $pidfile) or die "open: $!";
    chomp(my $pid = <$fh>);
    close($fh);
    is($pid, $$, "pidfile contains current pid");

    $con->clear_pid;
    ok(!-e $pidfile, "pidfile removed after clear_pid");

    # write it back so disconnect works
    $con->write_pid;
    ok(-e $pidfile, "pidfile re-created");

    $con->disconnect;
};

subtest 'stats_file, write_stats, read_stats' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'statstest');

    my $sf = $con->stats_file;
    like($sf, qr/statstest\.stats$/, "stats file path");

    $con->write_stats;
    ok(-e $sf, "stats file written");

    my $stats = $con->read_stats;
    is($stats, {read => {}, sent => {}}, "stats round-trip");

    $con->disconnect;
};

subtest 'all_stats' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'as1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'as2');

    $con1->send_message(as2 => 'hi');
    $con2->get_messages;

    $con1->write_stats;
    $con2->write_stats;

    my $all = $con1->all_stats;
    ok(exists $all->{as1}, "as1 stats present");
    ok(exists $all->{as2}, "as2 stats present");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'peers' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'p1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'p2');

    my @peers = $con1->peers;
    is(\@peers, ['p2'], "peers returns other client");

    my @peers2 = $con2->peers;
    is(\@peers2, ['p1'], "peers from con2 perspective");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'peer_exists' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pe1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pe2');

    ok($con1->peer_exists('pe2'), "peer pe2 exists");
    ok(!$con1->peer_exists('nope'), "nonexistent peer");

    like(dies { $con1->peer_exists(undef) }, qr/'peer_id' is required/, "requires peer_id");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'peer_pid' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con1 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pp1');
    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'pp2');

    my $pid = $con1->peer_pid('pp2');
    is($pid, $$, "peer pid matches");

    my $no_pid = $con1->peer_pid('nonexistent');
    ok(!$no_pid, "no pid for nonexistent peer");

    $con1->disconnect;
    $con2->disconnect;
};

subtest 'requeue_message and read_resume_file' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'rq1');

    my $msg = IPC::Manager::Message->new(from => 'other', to => 'rq1', content => {requeued => 1});
    $con->requeue_message($msg);
    ok($con->have_resume_file, "resume file created");

    my @msgs = $con->read_resume_file;
    is(scalar @msgs, 1, "one message in resume file");
    is($msgs[0]->content, {requeued => 1}, "content preserved");
    ok(!$con->have_resume_file, "resume file removed after read");

    $con->disconnect;
};

subtest 'reconnect restores path' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'rc1');
    my $path = $con->path;
    ok(-d $path, "path exists");

    $con->suspend;

    my $con2 = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'rc1', reconnect => 1);
    is($con2->path, $path, "path matches on reconnect");
    $con2->disconnect;
};

subtest 'post_disconnect_hook removes path' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $con = IPC::Manager::Client::MessageFiles->new(serializer => $SERIALIZER, route => $dir, id => 'dh1');
    my $path = $con->path;
    ok(-d $path, "path exists before disconnect");
    $con->disconnect;
    ok(!-e $path, "path removed after disconnect");
};

subtest 'spawn and unspawn' => sub {
    my $route = IPC::Manager::Client::MessageFiles->spawn();
    ok(-d $route, "spawn creates a directory");

    IPC::Manager::Client::MessageFiles->unspawn($route);
    ok(!-e $route, "unspawn removes the directory");
};

done_testing;
