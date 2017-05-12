use Mojo::Base -strict;

use Test::More tests => 5;
use Test::Mojo;


use_ok 'Flower';
use_ok 'Flower::Nodes';

my $t = Test::Mojo->new('Flower');
$t->app->config->{nodes} = Flower::Nodes->new('127.0.0.1', 1234);
my $uuid = $t->app->config->{nodes}->self->uuid;

ok ($uuid, 'uuid exists');

$t->post_ok('/REST/1.0/ping')
  ->status_is(200);
#  ->content_type_is('application/json')
#  ->json_content_is({'result' => 'ok', uuid => $uuid});

