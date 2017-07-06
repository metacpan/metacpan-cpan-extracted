use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Mojo::IOLoop;
use Mojolicious::Lite;
use Test::Mojo;

my $tmpdir = tempdir CLEANUP => 1, EXLOCK => 0;
my $file = catfile $tmpdir, 'minion.data';

# Missing backend
eval { plugin Minion => {Something => 'fun'} };
like $@, qr/^Backend "Minion::Backend::Something" missing/, 'right error';

plugin Minion => {Sereal => $file};

app->minion->add_task(
  add => sub {
    my ($job, $first, $second) = @_;
    Mojo::IOLoop->next_tick(
      sub {
        $job->finish($first + $second);
        Mojo::IOLoop->stop;
      }
    );
    Mojo::IOLoop->start;
  }
);

get '/add' => sub {
  my $c = shift;
  my $id = $c->minion->enqueue(add => [$c->param('first'), $c->param('second')] => { queue => 'test'});
  $c->render(text => $id);
};

get '/result' => sub {
  my $c = shift;
  $c->render(text => $c->minion->job($c->param('id'))->info->{result});
};

my $t = Test::Mojo->new;

# Perform jobs automatically
$t->get_ok('/add' => form => {first => 1, second => 2})->status_is(200);
$t->app->minion->perform_jobs({queues => ['test']});
$t->get_ok('/result' => form => {id => $t->tx->res->text})->status_is(200)
  ->content_is('3');
$t->get_ok('/add' => form => {first => 2, second => 3})->status_is(200);
my $first = $t->tx->res->text;
$t->get_ok('/add' => form => {first => 4, second => 5})->status_is(200);
my $second = $t->tx->res->text;
Mojo::IOLoop->delay(sub { $t->app->minion->perform_jobs({queues => ['test']}) })->wait;
$t->get_ok('/result' => form => {id => $first})->status_is(200)
  ->content_is('5');
$t->get_ok('/result' => form => {id => $second})->status_is(200)
  ->content_is('9');
$t->app->minion->reset;

done_testing();
