use strict;
use warnings;

# start a whole bunch of workers at once to probe for race conditions

use Test::More tests => 2;

use FindBin '$Bin';
use Gearman::WorkerSpawner;

my $spawner = Gearman::WorkerSpawner->new;

push @INC, "$Bin/lib";

$spawner->add_worker(
    class       => 'LargeWorker',
    num_workers => 10,
    config      => rand(),
);
pass('added workers');

$spawner->wait_until_all_ready;
pass('workers ready');
