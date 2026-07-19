use 5.024;
use strict;
use warnings;

use JSON::PP ();
use Test::More;

use GraphQL::Houtou qw(build_native_runtime execute);
use GraphQL::Houtou::PSGI;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => { type => $String, resolve => sub { 'world' } },
    },
  ),
);

subtest 'introspection remains enabled by default' => sub {
  my $result = build_native_runtime($schema)->execute_document(
    '{ __schema { queryType { name } } }',
  );
  is $result->{data}{__schema}{queryType}{name}, 'Query',
    'the hardening option is opt-in';
};

subtest 'execute recognizes the policy as an option hash' => sub {
  my $result = execute(
    $schema,
    '{ __schema { queryType { name } } }',
    { allow_introspection => 0 },
  );
  is $result->{errors}[0]{extensions}{code}, 'INTROSPECTION_DISABLED',
    'the convenience API does not mistake the option hash for variables';
};

subtest 'runtime policy rejects schema introspection but permits typename' => sub {
  my $runtime = build_native_runtime(
    $schema, allow_introspection => 0, program_cache_max => 10,
  );
  my $query = '{ schema: __schema { queryType { name } } }';

  for my $attempt (1 .. 2) {
    my $result = $runtime->execute_document($query, validate => 0);
    ok !exists $result->{data}, "attempt $attempt has no data";
    is $result->{errors}[0]{extensions}{code}, 'INTROSPECTION_DISABLED',
      "attempt $attempt has a stable error code";
    like $result->{errors}[0]{message}, qr/__schema/, 'original field name reported';
    ok $result->{errors}[0]{locations}[0]{line}, 'source location retained';
  }

  is_deeply $runtime->execute_document('{ __typename hello }'), {
    data => { __typename => 'Query', hello => 'world' },
  }, '__typename remains available';

  my $many = $runtime->execute_document(
    '{ a: __schema { queryType { name } } b: __type(name: "Query") { name } }',
  );
  is scalar @{ $many->{errors} }, 1,
    'the policy fails fast instead of amplifying errors per forbidden field';
};

subtest 'fragments, __type, JSON, and per-request overrides are covered' => sub {
  my $runtime = build_native_runtime($schema, allow_introspection => 0);
  my $query = <<'GRAPHQL';
query Inspect { ...Lookup }
fragment Lookup on Query { __type(name: "Query") { name } }
GRAPHQL
  my $decoded = JSON::PP::decode_json(
    $runtime->execute_document_to_json($query),
  );
  is $decoded->{errors}[0]{extensions}{code}, 'INTROSPECTION_DISABLED',
    'JSON lane rejects introspection inside a fragment';

  my $allowed = $runtime->execute_document(
    '{ __type(name: "Query") { name } }', allow_introspection => 1,
  );
  is $allowed->{data}{__type}{name}, 'Query', 'request override can enable trusted use';

  my $blocked_again = $runtime->execute_document(
    '{ __type(name: "Query") { name } }', allow_introspection => 0,
  );
  is $blocked_again->{errors}[0]{extensions}{code}, 'INTROSPECTION_DISABLED',
    'cache entry created by an allowed request cannot bypass the policy';
};

subtest 'PSGI exposes the runtime policy as a request error' => sub {
  my $app = GraphQL::Houtou::PSGI->new(
    schema => $schema,
    allow_introspection => 0,
  )->to_app;
  my $body = JSON::PP::encode_json({ query => '{ __schema { queryType { name } } }' });
  open my $input, '<', \$body or die $!;
  my $response = $app->({
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/json',
    CONTENT_LENGTH => length($body),
    HTTP_ACCEPT => 'application/json',
    'psgi.input' => $input,
  });
  my $decoded = JSON::PP::decode_json(join q(), @{ $response->[2] });
  is $response->[0], 400, 'policy rejection is an HTTP request error';
  is $decoded->{errors}[0]{extensions}{code}, 'INTROSPECTION_DISABLED',
    'PSGI retains the machine-readable code';
};

done_testing;
