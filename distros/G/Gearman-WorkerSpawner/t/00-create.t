use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Gearman::WorkerSpawner', ':all') };

my $spawner = Gearman::WorkerSpawner->new;
ok($spawner, 'WorkerSpawner created');
