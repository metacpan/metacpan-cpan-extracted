use Minion;

my $minion = Minion->new(API => 'http://localhost:3000/my-api');

$minion->add_task(storage2 => sub {
    my $job = shift;

    $job->app->log->debug('Taks storage2 ready');
    $job->finish('OK');
});

my $worker = $minion->worker;
$worker->status->{jobs} = 2;
$worker->run;
