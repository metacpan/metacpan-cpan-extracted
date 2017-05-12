# Minion::Backend::Storable [![Build Status](https://travis-ci.org/niczero/minion-backend-storable.svg?branch=master)](https://travis-ci.org/niczero/minion-backend-storable)

  A file-based backend for [Minion](https://github.com/kraih/minion).

```perl
use Mojolicious::Lite;

plugin Minion => {File => '/some/path/minion.data'};

# Slow task
app->minion->add_task(slow_log => sub {
  my ($job, $msg) = @_;
  sleep 5;
  $job->app->log->debug(qq{Received message "$msg".});
});

# Perform job in a background worker process
get '/log' => sub {
  my $c = shift;
  $c->minion->enqueue(slow_log => [$c->param('msg') // 'no message']);
  $c->render(text => 'Your message will be logged soon.');
};

app->start;
```

Just start one or more background worker processes in addition to your web
server.

  ./myapp.pl minion worker
