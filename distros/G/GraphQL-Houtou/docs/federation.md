# Federation 2 subgraph support

GraphQL::Houtou can run as an Apollo Federation 2 subgraph. Gateway/Router and
supergraph composition are deliberately external; use Apollo Router or another
compatible implementation for those responsibilities.

## Building a subgraph

```perl
use GraphQL::Houtou qw(build_subgraph_schema);

my $schema = build_subgraph_schema(
  <<'SDL',
extend schema
  @link(url: "https://specs.apollo.dev/federation/v2.9", import: ["@key"])

type Query { product(upc: String!): Product }
type Product @key(fields: "upc") {
  upc: String!
  name: String!
}
SDL
  resolvers => {
    Query => {
      product => sub {
        my (undef, $args, $context) = @_;
        return $context->{products}->load($args->{upc});
      },
    },
  },
  entity_resolvers => {
    Product => sub {
      my ($representation, $context) = @_;
      return $context->{products}->load($representation->{upc});
    },
  },
  max_representations => 100,
);
```

The builder adds `_Any`, `_Service`, the dynamic `_Entity` union, `_service`,
`_entities`, and Federation 2 directive definitions. The `_Entity` union
contains object types with a resolvable `@key`; `resolvable: false` keys do not
create an entity lookup entry.

## Entity resolvers

`entity_resolvers` must contain one callback for every resolvable entity type.
Each callback receives the representation and request context. It may return:

- an entity hash reference;
- `undef` when the entity does not exist;
- a `Promise::XS` resolving to either value.

Houtou restores `__typename` on returned hashes for union dispatch. Entity
results remain in representation order. Returning DataLoader promises is the
preferred database-backed shape because multiple representations can then be
resolved in one batch.

Every representation must have a string `__typename` and contain all fields
from at least one resolvable key. Nested FieldSets are checked recursively.
Invalid types, missing keys, malformed results, and over-limit batches fail
closed as GraphQL field errors without calling further entity resolvers.

## Schema and FieldSet validation

The authored SDL is returned verbatim from `_service.sdl`, including its
Federation annotations. Add the Federation 2 `@link` application and imports
to that SDL. Standard imported directive names are supported; directive
renaming through `@link(as:)` is not yet supported.

Houtou validates the executable subgraph shape and `@key` FieldSets, but it
does not replace composition validation. Directives such as `@external`,
`@requires`, `@provides`, and `@override` are preserved for the composer; run
Rover or the deployment's composition pipeline before publishing an SDL.

At schema construction time, every resolvable `@key(fields:)` is parsed as a
FieldSet and checked against the schema. Unknown fields, invalid syntax,
arguments, aliases, directives, and missing nested selections are rejected
before the runtime is built. This work is outside the request hot path.

## Complexity and security

`max_representations` defaults to 100. `_entities` performs one O(n) pass and
uses an O(1) hash lookup for each `__typename`; key checks are proportional to
the small number of fields in the declared keys. Database and network work
should be batched by DataLoader.

Subgraphs are trusted service endpoints, not public GraphQL APIs. Restrict them
to the Router with network policy and service authentication. Apply the same
body, depth, node, cost, timeout, and rate limits as a public Houtou endpoint,
and do not log raw representations when they may contain sensitive keys.

## Compatibility boundary

The module implements the subgraph execution surface. It does not implement:

- Gateway/Router query planning;
- supergraph composition;
- managed schema publication;
- Federation subscriptions;
- renamed Federation directive namespaces.

Composition compatibility should be checked with the Router/Rover version used
by the deployment whenever the subgraph SDL changes.
