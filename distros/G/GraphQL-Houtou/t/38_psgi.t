use strict;
use warnings;
use Test::More;
use JSON::PP ();

use GraphQL::Houtou::PSGI;
use GraphQL::Houtou::DataLoader;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $ID);

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS is required for async execution tests';
}

my @batch_calls;

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => {
        type => $String,
        args => { name => { type => $String } },
        resolve => sub { my (undef, $args) = @_; 'hello ' . ($args->{name} // 'world') },
      },
      user => {
        type => GraphQL::Houtou::Type::Object->new(
          name => 'User', fields => { name => { type => $String } }),
        args => { id => { type => $ID } },
        resolve => sub {
          my (undef, $args, $context) = @_;
          return $context->{users}->load($args->{id});
        },
      },
      whoami => {
        type => $String,
        resolve => sub { my (undef, undef, $context) = @_; $context->{remote_user} },
      },
      boom => { type => $String, resolve => sub { die "kaboom\n" } },
    },
  ),
);

my $app = GraphQL::Houtou::PSGI->new(
  schema => $schema,
  graphiql => 1,
  context => sub {
    my ($env) = @_;
    my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
      my ($ids) = @_;
      push @batch_calls, [@$ids];
      return [ map { { name => "user-$_" } } @$ids ];
    });
    my $context = { users => $users, remote_user => $env->{REMOTE_USER} };
    return ($context, GraphQL::Houtou::DataLoader->on_stall_for($users));
  },
)->to_app;

sub request {
  my (%args) = @_;
  my $target = $args{app} // $app;
  my $body = $args{body} // '';
  open my $input, '<', \$body or die $!;
  my $res = $target->({
    REQUEST_METHOD => $args{method} // 'POST',
    CONTENT_TYPE => $args{content_type} // 'application/json',
    CONTENT_LENGTH => length $body,
    HTTP_ACCEPT => $args{accept} // 'application/json',
    REMOTE_USER => $args{remote_user},
    'psgi.input' => $input,
  });
  return ($res->[0], { @{ $res->[1] } }, join('', @{ $res->[2] }));
}

sub graphql {
  my ($payload, %args) = @_;
  my ($status, $headers, $body) = request(
    body => JSON::PP::encode_json($payload), %args);
  my $decoded = eval { JSON::PP::decode_json($body) };
  return ($status, $decoded, $headers);
}

subtest 'sync query over POST' => sub {
  my ($status, $res, $headers) = graphql({
    query => 'query Q($name: String) { hello(name: $name) }',
    variables => { name => 'houtou' },
  });
  is $status, 200, 'status 200';
  like $headers->{'Content-Type'}, qr{application/json}, 'json content type';
  is_deeply $res, { data => { hello => 'hello houtou' } }, 'envelope';
};

subtest 'async DataLoader query batches per request' => sub {
  @batch_calls = ();
  my ($status, $res) = graphql({
    query => '{ a: user(id: "1") { name } b: user(id: "2") { name } }',
  });
  is $status, 200, 'status 200';
  is_deeply $res->{data}, {
    a => { name => 'user-1' }, b => { name => 'user-2' },
  }, 'loader-resolved data';
  is scalar @batch_calls, 1, 'one batch for the request';
};

subtest 'async => 1 passes through to the runtime' => sub {
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'AsyncQuery',
      fields => {
        greeting => {
          type => $String,
          resolve => sub { Promise::XS::resolved('hi from a promise') },
        },
      },
    ),
  );

  # Without the declaration the sync JSON lane refuses promise resolvers.
  # That is a server misconfiguration, not a request error: a 500 with a
  # generic body, with the async => 1 / on_stall hint warned to the logs.
  my $sync_app = GraphQL::Houtou::PSGI->new(schema => $async_schema)->to_app;
  my @warnings;
  my ($bad_status, $bad_res) = do {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    graphql({ query => '{ greeting }' }, app => $sync_app);
  };
  is $bad_status, 500, 'promise resolver without the declaration is refused';
  is $bad_res->{errors}[0]{message}, 'Internal server error',
    'response body stays generic';
  like "@warnings", qr/async|on_stall/, 'the log line points at async => 1 / on_stall';

  my $async_app = GraphQL::Houtou::PSGI->new(
    schema => $async_schema, async => 1)->to_app;
  my ($status, $res) = graphql({ query => '{ greeting }' }, app => $async_app);
  is $status, 200, 'status 200';
  is_deeply $res, { data => { greeting => 'hi from a promise' } },
    'pre-resolved promise completes on the async lane';
};

subtest 'per-request context sees the PSGI env' => sub {
  my ($status, $res) = graphql({ query => '{ whoami }' }, remote_user => 'alice');
  is $res->{data}{whoami}, 'alice', 'context builder received $env';
};

subtest 'field errors stay in a 200 envelope' => sub {
  my ($status, $res) = graphql({ query => '{ boom hello }' });
  is $status, 200, 'execution errors are not transport errors';
  is $res->{data}{boom}, undef, 'failed field is null';
  is $res->{data}{hello}, 'hello world', 'sibling field survives';
  is $res->{errors}[0]{message}, 'kaboom', 'error captured';
};

subtest 'pre-execution failures return 400' => sub {
  my ($status, $res) = graphql({ query => '{ nope' });
  is $status, 400, 'parse error is a 400';
  like $res->{errors}[0]{message}, qr/\S/, 'error message present';

  ($status, $res) = graphql({ variables => {} });
  is $status, 400, 'missing query is a 400';

  my ($s2) = request(body => 'not-json');
  is $s2, 400, 'malformed JSON body is a 400';
};

subtest 'operationName selects the operation' => sub {
  my $doc = 'query A { hello } query B { whoami }';
  my ($status, $res) = graphql(
    { query => $doc, operationName => 'B' }, remote_user => 'bob');
  is $status, 200, 'status 200';
  is_deeply $res->{data}, { whoami => 'bob' }, 'operation B executed';

  # Second identical request runs on the cached-program hot path.
  ($status, $res) = graphql(
    { query => $doc, operationName => 'B' }, remote_user => 'bob');
  is $status, 200, 'repeat request status 200';
  is_deeply $res->{data}, { whoami => 'bob' }, 'cached operation B executed';

  ($status, $res) = graphql({ query => $doc, operationName => 'A' });
  is $status, 200, 'sibling operation status 200';
  is_deeply $res->{data}, { hello => 'hello world' },
    'operation A resolves under its own cache key';

  ($status, $res) = graphql({ query => $doc, operationName => 'C' });
  is $status, 400, 'unknown operationName is a 400';
  like $res->{errors}[0]{message}, qr/"C"/, 'names the missing operation';
};

subtest 'content negotiation' => sub {
  my ($status, $res, $headers) = graphql(
    { query => '{ hello }' },
    accept => 'application/graphql-response+json');
  like $headers->{'Content-Type'}, qr{application/graphql-response\+json},
    'graphql-response+json honored';

  my ($s2) = request(body => '{}', content_type => 'text/plain');
  is $s2, 415, 'wrong content type is a 415';
};

subtest 'GET serves GraphiQL when enabled, 405 otherwise' => sub {
  my ($status, $headers, $body) = request(method => 'GET', accept => 'text/html');
  is $status, 200, 'GraphiQL page served';
  like $headers->{'Content-Type'}, qr{text/html}, 'html content type';
  like $body, qr/graphiql/i, 'page mentions graphiql';
  like $body, qr{graphiql\@5\.2\.4}, 'pins the supported GraphiQL release';
  like $body, qr{\@graphiql/react\@0\.37\.7},
    'pins the matching GraphiQL React package';
  like $body, qr{graphiql/setup-workers/esm\.sh},
    'loads the GraphiQL 5 worker setup';

  my ($s2, $h2) = request(method => 'GET', accept => 'application/json');
  is $s2, 405, 'non-html GET is a 405';

  my ($s3) = request(method => 'DELETE');
  is $s3, 405, 'other methods are a 405';
};

subtest 'oversized request bodies are rejected with 413' => sub {
  my $small_app = GraphQL::Houtou::PSGI->new(
    schema => $schema, max_body_size => 256,
  )->to_app;

  my ($ok_status) = request(
    app => $small_app,
    body => JSON::PP::encode_json({ query => '{ hello }' }),
  );
  is $ok_status, 200, 'a body under the cap is served';

  my $big = JSON::PP::encode_json({ query => '{ hello }', variables => { pad => 'x' x 1024 } });
  my ($by_length) = request(app => $small_app, body => $big);
  is $by_length, 413, 'a body over the cap is a 413';

  my $default_app = GraphQL::Houtou::PSGI->new(schema => $schema)->to_app;
  my ($default_ok) = request(
    app => $default_app,
    body => JSON::PP::encode_json({ query => '{ hello }', variables => { pad => 'x' x 4096 } }),
  );
  is $default_ok, 200, 'the 1 MiB default admits an ordinary padded body';
};

done_testing;
