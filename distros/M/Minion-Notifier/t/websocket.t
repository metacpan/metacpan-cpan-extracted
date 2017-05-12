BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
my $t = Test::Mojo->new;

plugin Minion => { SQLite => ':temp:' };
my $minion = app->minion;

use Mercury;
my $m_ua = Mojo::UserAgent->new;
my $url = $m_ua->server->app(Mercury->new)->nb_url->path('/bus/jobs')->scheme('ws');
plugin 'Minion::Notifier', {transport => $url};
my $notifier = app->minion_notifier;
$notifier->transport->ua($m_ua);
Mojo::IOLoop->one_tick; # ensure that setup_listener is called

$minion->add_task(live => sub { return 1 });
$minion->add_task(die  => sub { die 'argh' });

my ($id, $job, $worker);
END { $worker->unregister if $worker }

any '/live' => sub {
  my $c = shift;
  my @events;
  $notifier->on(job => sub {
    my (undef, $id, $event) = @_;
    push @events, [$id, $event];

    if ($event eq 'enqueue') {
      Mojo::IOLoop->next_tick(sub {
        $worker = $minion->worker->register;
        $job = $worker->dequeue(0);
      });
    } elsif ($event eq 'dequeue') {
      Mojo::IOLoop->next_tick(sub { $job->perform });
    } else {
      $c->render(json => {id => $id, events => \@events});
    }
  });
  $id = $minion->enqueue('live');
};

$t->get_ok('/live')
  ->status_is(200)
  ->json_is('/id' => $id);

my @expect = (
  [$id => 'enqueue'],
  [$id => 'dequeue'],
  [$id => 'finished'],
);
$t->json_is('/events' => \@expect)
  ->or(sub{ diag $t->tx->res->body });

done_testing;

