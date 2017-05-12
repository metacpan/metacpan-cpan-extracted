use Mojo::Base -strict;

use Test::More tests => 6;
use Test::Mojo;

use_ok 'Flower';
use_ok 'Flower::Nodes';
use_ok 'Flower::Files';

my $t = Test::Mojo->new('Flower');
$t->app->config->{nodes} = Flower::Nodes->new('127.0.0.1', 1234);
$t->app->config->{nodes}->self->set_files(Flower::Files->new());

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/flower/i);
