use strict;
use Test::More 0.98;
use Data::Dumper;
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::Mojo;
use Mojo::JSON qw(j);
use Mojolicious::Lite;

# gets put under /api. Magic!
get '/echo' => sub {
  my $self = shift->openapi->valid_input or return;
  $self->render(openapi => $self->req->param('arg'));
}, 'echo';
post '/echo' => sub {
  my $self = shift->openapi->valid_input or return;
  $self->render(openapi => $self->req->json);
}, 'echoPost';
get '/other/:id' => sub {
  my $self = shift->openapi->valid_input or return;
  my $args = $self->validation->output;
  $self->render(openapi => $args->{id});
}, 'query with space';
post '/withdots' => sub {
  my $self = shift->openapi->valid_input or return;
  my $args = $self->validation->output;
  $self->render(
    openapi => +{ 'with.dots' => join '',
      $args->{'arg.dots'},
      $args->{'body.dots'}{'prop.dots'},
      $args->{'body.dots'}{'propwithsub.dots'}[0]{'subprop.dots'},
    },
  );
}, 'query with dots';
get '/enumtest' => sub {
  my $self = shift->openapi->valid_input or return;
  my $args = $self->validation->output;
  $self->render(
    openapi => $args->{enumArg},
  );
}, 'enum.echo';

my $api = plugin OpenAPI => {spec => 'data://main/api.yaml'};
# if don't give app arg, will try to go over socket and deadlock
plugin GraphQL => {convert => [ 'OpenAPI', $api->validator->bundle, app ]};

my $t = Test::Mojo->new;

subtest 'REST request' => sub {
  $t->get_ok(
    '/api/echo?arg=Hello',
  )->json_is(
    'Hello',
  );
};

subtest 'REST post' => sub {
  $t->post_ok('/api/echo', { Content_Type => 'application/json' },
    j {hi=>"there"},
  )->json_is(
    { hi => 'there' },
  );
};

subtest 'GraphQL with POST' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    j { query=>'{echo(arg: "Yo")}' },
  )->json_is(
    { data => { echo => 'Yo' } },
  );
};

subtest 'GraphQL with "object"' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    j {query=>'mutation m {echoPost(body: [{key:"one", value:"two"}]) { key value }}'},
  )->json_is(
    { data => { echoPost => [{key=>"one", value=>"two"}] } },
  );
};

subtest 'GraphQL op with spaces' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    '{"query":"{query_with_space(id: 7)}"}',
  )->json_is(
    { 'data' => { 'query_with_space' => 7 } },
  );
};

subtest 'GraphQL op with dots' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    <<'EOF',
{"query":
  "mutation m {query_with_dots(arg_dots: \"ARGH\", body_dots: { prop_dots: \"!\", propwithsub_dots: [{ subprop_dots: \"?\" }] }) { with_dots }}"
}
EOF
  )->json_is({
    data => {
      query_with_dots => { with_dots => "ARGH!?" },
    }
  });
};

subtest 'GraphQL enum op' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    <<'EOF',
{"query":
  "{enum_echo(enumArg: [EMPTY, dot_space, dot_space, dot_space1, dot_space1, dot_space1])}"
}
EOF
  )->json_is({
    data => {
      enum_echo => [qw(EMPTY dot_space dot_space dot_space1 dot_space1 dot_space1)],
    }
  });
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
    post:
      operationId: echoPost
      parameters:
      - in: body
        name: body
        schema:
          type: object
      responses:
        200:
          description: Echo response
          schema:
            type: object
  /other/{id}:
    get:
      operationId: query with space
      parameters:
      - description: ID of pet to fetch
        format: int64
        in: path
        name: id
        required: true
        type: integer
      responses:
        200:
          description: query response
          schema:
            type: string
  /withdots:
    post:
      operationId: query with dots
      parameters:
      - in: query
        name: arg.dots
        type: string
      - in: body
        name: body.dots
        schema:
          type: object
          properties:
            prop.dots:
              type: string
            propwithsub.dots:
              type: array
              items:
                type: object
                required:
                - subprop.dots
                properties:
                  subprop.dots:
                    type: string
      responses:
        200:
          description: query response
          schema:
            $ref: "#/definitions/HudsonMasterComputermonitorData"
  /enumtest:
    get:
      operationId: enum.echo
      parameters:
      - in: query
        name: enumArg
        type: array
        items:
          type: string
          enum:
            - dot.space
            - dot space
            - ""
      responses:
        200:
          description: query response
          schema:
            type: array
            items:
              $ref: "#/definitions/BigEnum"
definitions:
  HudsonMasterComputermonitorData:
    type: object
    properties:
      with.dots:
        type: string
  BigEnum:
    type: string
    enum:
      - dot.space
      - dot space
      - ""
