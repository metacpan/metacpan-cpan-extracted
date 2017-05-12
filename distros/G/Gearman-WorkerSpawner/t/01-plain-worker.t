use strict;
use warnings;

# test a simple worker with a function that adds 5 to its input

use Test::More tests => 9;

use FindBin '$Bin';
use Gearman::WorkerSpawner;

my $spawner = Gearman::WorkerSpawner->new;

push @INC, "$Bin/lib";

$spawner->add_worker(class => 'TestWorker');
pass('added worker');

$spawner->wait_until_all_ready;
pass('worker ready');

$spawner->add_task(Gearman::Task->new(testfunc => \3, {
    on_complete => sub {
        my $ref = shift;
        is(ref $ref, 'SCALAR', 'got ref back');
        my $result = $$ref;
        is($result, 8, 'function computed value');
    },
}));
pass('manual task created');

# test auto-creation of Gearman::Task
$spawner->add_task(testfunc => \3, {
    on_complete => sub {
        pass('Gearman::Task finished');
    },
});
pass('Gearman::Task created');

Danga::Socket->AddTimer(1, sub {
    pass('delayed task submitted');
    $spawner->add_task(Gearman::Task->new(testfunc => \3, {
        on_complete => sub {
            pass('delayed task completed');
            exit;
        },
    }));
});

Danga::Socket->EventLoop;
