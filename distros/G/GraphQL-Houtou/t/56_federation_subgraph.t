use 5.024;
use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_deeply);

use GraphQL::Houtou qw(build_subgraph_schema execute);

my $SDL = <<'SDL';
extend schema
  @link(url: "https://specs.apollo.dev/federation/v2.9", import: ["@key"])

type Query {
  product(upc: String!): Product
}

type Product @key(fields: "upc") {
  upc: String!
  name: String!
}
SDL

my $schema = build_subgraph_schema(
  $SDL,
  resolvers => {
    Query => {
      product => sub {
        my (undef, $args) = @_;
        return { upc => $args->{upc}, name => "product-$args->{upc}" };
      },
    },
  },
  entity_resolvers => {
    Product => sub {
      my ($representation) = @_;
      return {
        upc => $representation->{upc},
        name => "entity-$representation->{upc}",
      };
    },
  },
  max_representations => 2,
);

subtest '_service returns the authored subgraph SDL' => sub {
  my $result = execute($schema, '{ _service { sdl } }');
  is $result->{data}{_service}{sdl}, $SDL, 'SDL is preserved verbatim';
};

subtest '_entities resolves representations in input order' => sub {
  my $result = execute(
    $schema,
    'query Entities($representations: [_Any!]!) {'
      . ' _entities(representations: $representations) {'
      . '   ... on Product { upc name }'
      . ' }'
      . '}',
    {
      representations => [
        { __typename => 'Product', upc => 'a' },
        { __typename => 'Product', upc => 'b' },
      ],
    },
  );
  cmp_deeply $result, {
    data => {
      _entities => [
        { upc => 'a', name => 'entity-a' },
        { upc => 'b', name => 'entity-b' },
      ],
    },
  }, 'entity results preserve representation order';
};

subtest 'representation work is bounded' => sub {
  my $result = execute(
    $schema,
    'query Entities($representations: [_Any!]!) {'
      . ' _entities(representations: $representations) { ... on Product { upc } }'
      . '}',
    {
      representations => [
        map { +{ __typename => 'Product', upc => "p$_" } } 1 .. 3
      ],
    },
  );
  ok exists $result->{errors}, 'over-limit request reports an execution error';
  like $result->{errors}[0]{message}, qr/max_representations/, 'limit is explicit';
};

subtest 'unknown entity types fail closed' => sub {
  my $result = execute(
    $schema,
    'query Entities($representations: [_Any!]!) {'
      . ' _entities(representations: $representations) { ... on Product { upc } }'
      . '}',
    { representations => [ { __typename => 'Unknown', id => 1 } ] },
  );
  ok exists $result->{errors}, 'unknown typename reports an execution error';
  like $result->{errors}[0]{message}, qr/Unknown Federation entity type/, 'type is rejected';
};

subtest 'representations must satisfy a declared key' => sub {
  my $result = execute(
    $schema,
    'query Entities($representations: [_Any!]!) {'
      . ' _entities(representations: $representations) { ... on Product { upc } }'
      . '}',
    { representations => [ { __typename => 'Product', name => 'no-key' } ] },
  );
  ok exists $result->{errors}, 'missing key reports an execution error';
  like $result->{errors}[0]{message}, qr/does not satisfy any \@key/,
    'key failure is explicit';
};

subtest 'resolvable entities require resolvers' => sub {
  my $ok = eval { build_subgraph_schema($SDL); 1 };
  ok !$ok, 'schema construction fails';
  like $@, qr/Missing entity resolver for 'Product'/, 'missing resolver is named';
};

subtest 'builder does not mutate caller resolver maps' => sub {
  my $resolvers = { Query => { product => sub { return } } };
  build_subgraph_schema(
    $SDL,
    resolvers => $resolvers,
    entity_resolvers => { Product => sub { return } },
  );
  is_deeply [ sort keys %{ $resolvers->{Query} } ], ['product'],
    'Federation fields were added to a private copy';
};

subtest 'Promise::XS entity resolvers stay on the async lane' => sub {
  plan skip_all => 'Promise::XS is not available'
    if !eval { require Promise::XS; 1 };
  my $async_schema = build_subgraph_schema(
    $SDL,
    entity_resolvers => {
      Product => sub {
        my ($representation) = @_;
        return Promise::XS::resolved({
          upc => $representation->{upc}, name => 'promised',
        });
      },
    },
  );
  my $runtime = $async_schema->build_native_runtime(async => 1);
  my $result = $runtime->execute_document(
    'query Entities($representations: [_Any!]!) {'
      . ' _entities(representations: $representations) {'
      . '   ... on Product { upc name }'
      . ' }'
      . '}',
    variables => {
      representations => [ { __typename => 'Product', upc => 'p' } ],
    },
  );
  is $result->{data}{_entities}[0]{name}, 'promised',
    'promise result is tagged and completed';
};

subtest 'key FieldSets are validated when the schema is built' => sub {
  my $ok = eval {
    build_subgraph_schema(<<'SDL', entity_resolvers => { Product => sub { {} } });
type Query { product: Product }
type Product @key(fields: "missing") { upc: String! }
SDL
    1;
  };
  ok !$ok, 'unknown key field rejects the schema';
  like $@, qr/Product\.missing.*does not exist/, 'invalid coordinate is named';

  $ok = eval {
    build_subgraph_schema(<<'SDL', entity_resolvers => { Product => sub { {} } });
type Query { product: Product }
type Organization { id: ID! }
type Product @key(fields: "organization") { organization: Organization! }
SDL
    1;
  };
  ok !$ok, 'composite key field requires a nested selection';
  like $@, qr/composite field 'Product\.organization' requires a selection/,
    'missing nested selection is explicit';
};

subtest 'subgraphs without entities expose only _service' => sub {
  my $plain = build_subgraph_schema(<<'SDL');
type Query { hello: String }
SDL
  my $service = execute($plain, '{ _service { sdl } }');
  like $service->{data}{_service}{sdl}, qr/type Query/, '_service is available';

  my $entities = execute($plain, '{ _entities(representations: []) { __typename } }');
  ok exists $entities->{errors}, '_entities is not added without entity types';
};

done_testing;
