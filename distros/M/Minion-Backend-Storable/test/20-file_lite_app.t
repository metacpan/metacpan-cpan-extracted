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

plugin Minion => {Storable => $file};

app->minion->add_task(
  increment => sub {
    my $job = shift;
    Mojo::IOLoop->next_tick(
      sub {
        my $guard = $job->minion->backend->_guard->_write;
        ++$guard->_data->{counter};
        Mojo::IOLoop->stop;
      }
    );
    Mojo::IOLoop->start;
  }
);

get '/increment' => sub {
  my $c = shift;
  $c->minion->enqueue('increment');
  $c->render(text => 'Incrementing soon!');
};

get '/count' => sub {
  my $c = shift;
  my $guard = $c->minion->backend->_guard;
  $c->render(text => $guard->_data->{counter});
};

my $t = Test::Mojo->new;

# Perform jobs automatically
$t->get_ok('/increment')->status_is(200)->content_is('Incrementing soon!');
$t->app->minion->perform_jobs;
$t->get_ok('/count')->status_is(200)->content_is('1');
$t->get_ok('/increment')->status_is(200)->content_is('Incrementing soon!');
$t->get_ok('/increment')->status_is(200)->content_is('Incrementing soon!');
Mojo::IOLoop->delay(sub { $t->app->minion->perform_jobs })->wait;
$t->get_ok('/count')->status_is(200)->content_is('3');
$t->app->minion->reset;

done_testing();
