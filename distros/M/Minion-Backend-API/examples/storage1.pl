use Mojolicious::Lite;

plugin 'Minion' => {
    API => 'http://localhost:3000/my-api',
};

app->minion->add_task(storage1 => sub {
    my $jog = shift;

    $job->app->log->debug('Taks storage1 ready');
    $job->finish('OK');
});

app->start;
