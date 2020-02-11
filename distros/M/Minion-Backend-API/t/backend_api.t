use Test::More tests => 41;
use Mojolicious::Lite;

put '/broadcast' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 1
        }
    );
};

post '/dequeue' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 2
        }
    );
};

post '/enqueue' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 3
        }
    );
};

patch '/fail-job' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 4
        }
    );
};

patch '/finish-job' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 5
        }
    );
};

get '/history' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 6
        }
    );
};

get '/list-jobs' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 7
        }
    );
};

get '/list-locks' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 8
        }
    );
};

get '/list-workers' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 9
        }
    );
};

get '/lock' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 10
        }
    );
};

patch '/note' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 11
        }
    );
};

patch '/receive' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 12
        }
    );
};

post '/register-worker' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 13
        }
    );
};

del '/remove-job' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 14
        }
    );
};

post '/repair' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 15
        }
    );
};

post '/reset' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 16
        }
    );
};

put '/retry-job' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 17
        }
    );
};

get '/stats' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 18
        }
    );
};

del '/unlock' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 19
        }
    );
};

del '/unregister-worker' => sub {    
    shift->render(
        json => {
            success => 1,
            result => 20
        }
    );
};

use_ok('Minion::Backend::API');

my $api = Minion::Backend::API->new('');

isa_ok($api, 'Minion::Backend');

can_ok($api, 'broadcast');
is($api->broadcast, 1, 'Test request broadcast');

can_ok($api, 'dequeue');
eval{ is($api->dequeue, 2, 'Test request dequeue') };

can_ok($api, 'enqueue');
is($api->enqueue, 3, 'Test request enqueue');

can_ok($api, 'fail_job');
is($api->fail_job, 4, 'Test request fail_job');

can_ok($api, 'finish_job');
is($api->finish_job, 5, 'Test request finish_job');

can_ok($api, 'history');
is($api->history, 6, 'Test request history');

can_ok($api, 'list_jobs');
is($api->list_jobs, 7, 'Test request list_jobs');

can_ok($api, 'list_locks');
is($api->list_locks, 8, 'Test request list_locks');

can_ok($api, 'list_workers');
is($api->list_workers, 9, 'Test request list_workers');

can_ok($api, 'lock');
is($api->lock, 10, 'Test request lock');

can_ok($api, 'note');
is($api->note, 11, 'Test request note');

can_ok($api, 'receive');
is($api->receive, 12, 'Test request receive');

can_ok($api, 'register_worker');
is($api->register_worker, 13, 'Test request register_worker');

can_ok($api, 'remove_job');
is($api->remove_job, 14, 'Test request remove_job');

can_ok($api, 'repair');
is($api->repair, 15, 'Test request repair');

can_ok($api, 'reset');
is($api->reset, 16, 'Test request reset');

can_ok($api, 'retry_job');
is($api->retry_job, 17, 'Test request retry_job');

can_ok($api, 'stats');
is($api->stats, 18, 'Test request stats');

can_ok($api, 'unlock');
is($api->unlock, 19, 'Test request unlock');

can_ok($api, 'unregister_worker');
is($api->unregister_worker, 20, 'Test request unregister_worker');

done_testing();