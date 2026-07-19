use strict;
use warnings;
use Test::More 0.98;

# A resolver returning undef for an object-typed field (or a null item
# inside a list of objects) must complete as null without running the
# selection block. The async lane and the JSON lanes always did this, but
# the sync fast SV lane (the execute_document path with variables) and the
# native value lane (execute_bundle) executed the child block over the
# undef source and fabricated an object of nulls. Pin every lane.

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => { name => { type => $String } },
  tag_resolver => sub { $_[0]{kind} },
);

my $Ship = GraphQL::Houtou::Type::Object->new(
  name => 'Ship',
  interfaces => [ $Node ],
  runtime_tag => 'ship',
  fields => { name => { type => $String } },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      ship => { type => $Ship, resolve => sub { undef } },
      node => { type => $Node, resolve => sub { undef } },
      ships => {
        type => $Ship->list,
        resolve => sub { [ { kind => 'ship', name => 'a' }, undef ] },
      },
      nodes => {
        type => $Node->list,
        resolve => sub { [ { kind => 'ship', name => 'a' }, undef ] },
      },
    },
  ),
  types => [ $Node, $Ship ],
);

my $QUERY = '{ ship { name } node { name } ships { name } nodes { name } }';
my %EXPECTED = (
  ship => undef,
  node => undef,
  ships => [ { name => 'a' }, undef ],
  nodes => [ { name => 'a' }, undef ],
);
my $EXPECTED_JSON_RE = qr/"ship":null.*"ships":\[\{"name":"a"\},null\]/;

subtest 'async auto lane (no variables)' => sub {
  my $runtime = build_native_runtime($schema);
  my $result = $runtime->execute_document($QUERY);
  is_deeply $result, { data => \%EXPECTED }, 'nulls complete as null';
};

subtest 'sync fast SV lane (with variables)' => sub {
  my $runtime = build_native_runtime($schema);
  my $result = $runtime->execute_document($QUERY, variables => {});
  is_deeply $result, { data => \%EXPECTED }, 'nulls complete as null';
};

subtest 'JSON lanes' => sub {
  my $runtime = build_native_runtime($schema);
  like $runtime->execute_document_to_json($QUERY), $EXPECTED_JSON_RE,
    'json lane without variables';
  like $runtime->execute_document_to_json($QUERY, variables => {}), $EXPECTED_JSON_RE,
    'json lane with variables';
};

subtest 'bundle lane (native value tree)' => sub {
  my $runtime = build_native_runtime($schema);
  my $bundle = $runtime->compile_bundle_for_document($QUERY);
  is_deeply $runtime->execute_bundle($bundle), { data => \%EXPECTED },
    'nulls complete as null';
  like $runtime->execute_bundle_to_json($bundle), $EXPECTED_JSON_RE, 'bundle json';
};

subtest 'async lane with promises settling to undef' => sub {
  eval { require Promise::XS; 1 } or plan skip_all => 'Promise::XS not available';

  # Both shapes: a field promise that resolves to undef (loader miss) and
  # per-item promises inside a list where one item settles to undef.
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        ship => {
          type => $Ship,
          resolve => sub { Promise::XS::resolved(undef) },
        },
        ships => {
          type => $Ship->list,
          resolve => sub {
            [ Promise::XS::resolved({ kind => 'ship', name => 'a' }), Promise::XS::resolved(undef) ];
          },
        },
      },
    ),
    types => [ $Node, $Ship ],
  );
  my $runtime = build_native_runtime($async_schema, async => 1);
  my $result = $runtime->execute_document(
    '{ ship { name } ships { name } }',
    on_stall => sub { 0 },
  );
  is_deeply $result, {
    data => { ship => undef, ships => [ { name => 'a' }, undef ] },
  }, 'promise-of-undef completes as null';
};

done_testing;
