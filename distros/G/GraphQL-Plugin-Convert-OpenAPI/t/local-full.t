use strict;
use Test::More 0.98;
use Data::Dumper;
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::Mojo;

{
  package MyApp;
  use Mojo::Base "Mojolicious";
  use Mojo::JSON qw(j);

  sub startup {
    my $self = shift;
    my $r = $self->routes;
    # gets put under /api. Magic!
    $r->get('/echo' => sub {
      my $self = shift->openapi->valid_input or return;
      $self->render(openapi => j $self->validation->output);
    }, 'echo');
    my $api = $self->plugin(OpenAPI => {spec => 'data://main/api.yaml'});
    # if don't give app arg, will try to go over socket and deadlock
    $self->plugin(GraphQL => {convert => [ qw(OpenAPI), $api->validator->bundle, $self ]});
  }
}

my $t = Test::Mojo->new('MyApp');

subtest 'REST request' => sub {
  $t->get_ok(
    '/api/echo?arg=Hello',
  )->content_like(
    qr/Hello/,
  );
};

subtest 'GraphQL with POST' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    '{"query":"{echo(arg: \"Yo\")}"}',
  )->json_is(
    { 'data' => { 'echo' => '{"arg":"Yo"}' } },
  )->or(sub { diag explain shift->tx->res->json });
};

done_testing;

__DATA__

@@ api.yaml
swagger: '2.0'
info:
  version: '0.42'
  title: Dummy example
schemes: [ http ]
basePath: "/api"
paths:
  /echo:
    get:
      operationId: echo
      parameters:
      - in: query
        name: arg
        type: string
      responses:
        200:
          description: Echo response
          schema:
            type: string
