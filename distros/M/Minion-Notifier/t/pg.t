BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojolicious::Lite;

use Test::More;
plan skip_all => 'set TEST_ONLINE_PG to a postgresql url to run test'
  unless my $url = $ENV{TEST_ONLINE_PG};

use Test::Mojo;
use Mojo::IOLoop;

require Mojo::Pg;

plugin Minion => { Pg => $url };
my $minion = app->minion;

plugin 'Minion::Notifier';
my $notifier = app->minion_notifier;
Mojo::IOLoop->one_tick; # ensure that setup_listener is called

$minion->add_task(live => sub { shift->finish('done') });
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

my $t = Test::Mojo->new;
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

