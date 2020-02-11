use Test::More tests => 42;
use lib './t';

use_ok('Minion::Backend::Fake');

my $fake = Minion::Backend::Fake->new;

isa_ok($fake, 'Minion::Backend');

can_ok($fake, 'broadcast');
is($fake->broadcast, 1, 'Test method broadcast');

can_ok($fake, 'dequeue');
is($fake->dequeue, 2, 'Test method dequeue');

can_ok($fake, 'enqueue');
is($fake->enqueue, 3, 'Test method enqueue');

can_ok($fake, 'fail_job');
is($fake->fail_job, 4, 'Test method fail_job');

can_ok($fake, 'finish_job');
is($fake->finish_job, 5, 'Test method finish_job');

can_ok($fake, 'history');
is($fake->history, 6, 'Test method history');

can_ok($fake, 'list_jobs');
is($fake->list_jobs, 7, 'Test method list_jobs');

can_ok($fake, 'list_locks');
is($fake->list_locks, 8, 'Test method list_locks');

can_ok($fake, 'list_workers');
is($fake->list_workers, 9, 'Test method list_workers');

can_ok($fake, 'lock');
is($fake->lock, 10, 'Test method lock');

can_ok($fake, 'note');
is($fake->note, 11, 'Test method note');

can_ok($fake, 'receive');
is($fake->receive, 12, 'Test method receive');

can_ok($fake, 'register_worker');
is($fake->register_worker, 13, 'Test method register_worker');

can_ok($fake, 'remove_job');
is($fake->remove_job, 14, 'Test method remove_job');

can_ok($fake, 'repair');
is($fake->repair, 15, 'Test method repair');

can_ok($fake, 'reset');
is($fake->reset, 16, 'Test method reset');

can_ok($fake, 'retry_job');
is($fake->retry_job, 17, 'Test method retry_job');

can_ok($fake, 'stats');
is($fake->stats, 18, 'Test method stats');

can_ok($fake, 'unlock');
is($fake->unlock, 19, 'Test method unlock');

can_ok($fake, 'unregister_worker');
is($fake->unregister_worker, 20, 'Test method unregister_worker');

done_testing();