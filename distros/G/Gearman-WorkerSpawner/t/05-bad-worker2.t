use strict;
use warnings;

# test that spawner dies if a supervisor fails

use Test::More tests => 2;

use FindBin '$Bin';
use Gearman::WorkerSpawner;

my $spawner = Gearman::WorkerSpawner->new;

push @INC, "$Bin/lib";

open STDERR, '>', '/dev/null';

$spawner->add_worker(class => 'BadWorker2');

eval { Danga::Socket->EventLoop; };
ok($@, 'EventLoop bailed');
like($@, qr/supervisor died/, 'error message');
