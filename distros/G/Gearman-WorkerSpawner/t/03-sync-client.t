use strict;
use warnings;

use Test::More tests => 2;

use FindBin '$Bin';
use Gearman::Server;
use Gearman::WorkerSpawner;

use_ok('Gearman::WorkerSpawner::BaseWorker::Client');

push @INC, "$Bin/lib";

my $port = 17003;

# fork off a gearman server
my $gearmand_pid = fork;
die "fork failed: $!" unless defined $gearmand_pid;
if (!$gearmand_pid) {
    my $server = Gearman::Server->new;
    $server->create_listening_sock($port);
    Danga::Socket->EventLoop();
    exit;
}

sleep 1;

# fork off a worker
my $worker_pid = fork;
die "fork failed: $!" unless defined $worker_pid;
if (!$worker_pid) {
    my $spawner = Gearman::WorkerSpawner->new(gearmand => "localhost:$port");
    $spawner->add_worker(class => 'MethodWorker');
    Danga::Socket->EventLoop;
    exit;
}

# parent is client

sleep 1;

my $client = Gearman::WorkerSpawner::BaseWorker::Client->new;
$client->job_servers("localhost:$port");

my $value = 5;
my ($ret) = $client->run_method(echo => $value);
is($ret, $value, "echo $value");

END {
kill 'INT', $gearmand_pid, $worker_pid;
}
