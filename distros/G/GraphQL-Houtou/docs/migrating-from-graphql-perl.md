# Migrating from graphql-perl

GraphQL::Houtou is source-compatible with many graphql-perl type and resolver
definitions, but it is not a drop-in replacement for `GraphQL::Execution`.
Treat the change as an application migration: build the Houtou schema and
runtime once at worker startup, update execution call sites, and verify error
and asynchronous behavior before switching traffic.

This guide covers graphql-perl 0.54 applications using either SDL
(schema-first) or Perl type objects (code-first).

## What remains familiar

- Field resolvers receive `($source, $args, $context, $info)`.
- Object fields use `type`, `args`, `resolve`, `description`, and deprecation
  metadata with shapes close to graphql-perl.
- Built-in scalar exports such as `$String`, `$Int`, `$Boolean`, and `$ID`
  have direct Houtou equivalents.
- Custom scalar `serialize` and `parse_value` callbacks may throw to reject a
  value.
- The default resolver calls a coderef stored in a source hash and calls a
  method with the field name on a blessed source.

The Houtou resolver may receive additional arguments after `$info`. Write
resolvers using the first four arguments unless the application intentionally
depends on Houtou-specific data.

## Important differences

| Area | graphql-perl | GraphQL::Houtou |
| --- | --- | --- |
| Execution call | Positional `execute(...)` arguments | Named options on `execute()` or a reusable native runtime |
| Runtime | Interpreter and promise adapter selected per call | Native XS runtime; build once and reuse |
| Async abstraction | Injectable `promise_code` | `Promise::XS` only, driven synchronously with `on_stall` |
| Global field resolver | May be passed to `execute()` | No request-level global `field_resolver`; attach resolvers to the schema |
| Parser AST | graphql-perl AST | Houtou's canonical graphql-perl-style AST; internal details are not an interchange contract |
| Validation | Older executable validation behavior | September 2025 query/mutation validation before execution |
| Subscriptions | Ecosystem-dependent implementations exist | Execution fails closed; no event stream or streaming transport |
| HTTP integration | Framework plugins are common | Plain PSGI adapter; framework plugins are not drop-in compatible |
| Persisted operations | Application-specific | Compiled programs and fixed native bundles |

Error messages are not a compatibility API. Houtou follows graphql-js-style
wording in several coercion and validation errors, rejects invalid documents
that graphql-perl may execute, and omits `errors` entirely on a successful
response. Assert error categories, paths, and locations instead of matching a
complete message string.

## Execution API migration

A typical graphql-perl call uses positional arguments:

```perl
my $result = GraphQL::Execution::execute(
  $schema,
  $document,
  $root_value,
  $context,
  $variables,
  $operation_name,
  $field_resolver,
  $promise_code,
);
```

The direct Houtou equivalent uses named options:

```perl
use GraphQL::Houtou qw(execute);

my $result = execute(
  $schema,
  $document,
  {
    root_value     => $root_value,
    context        => $context,
    variables      => $variables,
    operation_name => $operation_name,
  },
);
```

For a production service, compile the schema runtime once instead:

```perl
use GraphQL::Houtou qw(build_native_runtime);

# Worker startup
my $runtime = build_native_runtime(
  $schema,
  program_cache_max  => 1_000,
  max_depth          => 20,
  max_nodes          => 5_000,
  max_cost           => 10_000,
  default_list_size  => 20,
  allow_introspection => 0,
);

# Request time. Repeated documents use the compiled-program cache.
my $result = $runtime->execute_document(
  $document,
  root_value     => $root_value,
  context        => $context,
  variables      => $variables,
  operation_name => $operation_name,
);
```

Prefer `execute_document_to_json()` at an HTTP boundary when the response is
immediately encoded. It avoids constructing and then walking a complete Perl
response envelope.

Do not pass `promise_code` or an execution engine selector. Houtou rejects
`promise_code`, recognizes `Promise::XS` directly, and always uses the native
runtime.

## Schema-first migration

### graphql-perl shape

A graphql-perl SDL application commonly builds the type system from a
document and supplies behavior through a root hash or framework adapter:

```graphql
type Query {
  user(id: ID!): User
}

type User {
  id: ID!
  name: String!
}
```

```perl
my $root_value = {
  user => sub {
    my ($args, $context, $info) = @_;
    return $context->{users}->find($args->{id});
  },
};
```

### Houtou shape

Attach top-level and non-default field behavior while building the schema:

```perl
use GraphQL::Houtou qw(build_schema build_native_runtime);

my $schema = build_schema($sdl,
  resolvers => {
    Query => {
      user => sub {
        my (undef, $args, $context, $info) = @_;
        return $context->{users}->find($args->{id});
      },
    },
  },
);

my $runtime = build_native_runtime($schema);
```

The resolver map is keyed by GraphQL type name and field name. It also holds
type-level hooks:

```perl
my $schema = build_schema($sdl,
  resolvers => {
    SearchResult => {
      resolve_type => sub {
        my ($value) = @_;
        return $value->isa('MyApp::User') ? 'User' : 'Post';
      },
    },
    DateTime => {
      serialize   => sub { $_[0]->iso8601 },
      parse_value => sub { MyApp::DateTime->parse($_[0]) },
    },
  },
);
```

Keep the SDL and resolver table at process scope. Calling `build_schema()` or
`build_native_runtime()` per request discards most of the performance benefit
and repeatedly performs schema validation.

Type-system extensions, descriptions, repeatable directives, `@deprecated`,
`@specifiedBy`, and `@oneOf` are accepted in SDL. Invalid schemas are rejected
at construction time, before requests reach resolvers.

### Moving a global field resolver

Houtou has no request-level equivalent of graphql-perl's
`$field_resolver`. If a plugin such as a DBIC or OpenAPI converter returns a
schema, root value, and global resolver, choose one of these migrations:

1. generate `resolvers => { Type => { field => $callback } }` entries while
   converting the schema;
2. expose values or methods on returned domain objects and use the default
   resolver;
3. wrap only the fields that require naming, authorization, or conversion
   policy with explicit resolvers.

Do not emulate a global resolver inside every request. Generate the mapping
once when the schema is assembled.

## Code-first migration

Code-first schemas are generally a mechanical namespace conversion. A
graphql-perl definition such as:

```perl
use GraphQL::Schema;
use GraphQL::Type::Object;
use GraphQL::Type::Scalar qw($ID $String);

my $User = GraphQL::Type::Object->new(
  name => 'User',
  fields => {
    id   => { type => $ID->non_null },
    name => { type => $String },
  },
);
```

becomes:

```perl
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($ID $String);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  fields => {
    id   => { type => $ID->non_null },
    name => { type => $String },
  },
);

my $Query = GraphQL::Houtou::Type::Object->new(
  name => 'Query',
  fields => {
    user => {
      type => $User,
      args => { id => { type => $ID->non_null } },
      resolve => sub {
        my (undef, $args, $context) = @_;
        return $context->{users}->find($args->{id});
      },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => $Query,
  types => [ $User ],
);
```

Review constructors rather than applying an unrestricted search-and-replace.
Interfaces and unions require concrete types to be reachable through the
schema's `types` registry, and abstract types require `resolve_type` behavior.
Call `$schema->assert_valid` during application startup; runtime compilation
also validates the schema.

## Default resolver behavior

The default resolver is intentionally close to graphql-perl and graphql-js:

1. On a blessed source, a method named for the GraphQL field is called as
   `$source->$field($args, $context, $info)`.
2. Otherwise, a hash key with that name is read.
3. If the hash value is a coderef (or callable object), it is called as
   `$value->($args, $context, $info)`.
4. Other hash values are returned directly.

Method lookup has priority over a same-named hash key on a blessed hash
object. This is useful for DBIC-style row objects, but means fields named
`can`, `isa`, or `DOES` can find inherited `UNIVERSAL` methods. Define an
explicit resolver for those names.

A blessed hash without a matching method falls back to its hash key. This is
more permissive than graphql-perl; add an explicit resolver if the distinction
matters to application policy.

## Async resolvers and DataLoader

Houtou accepts `Promise::XS` promises only. It drives them to completion
during the request; it does not return a framework promise to a Mojolicious or
Future event loop.

For promise-returning resolvers:

```perl
my $runtime = build_native_runtime($schema, async => 1);

my $result = $runtime->execute_document(
  $query,
  context  => $request_context,
  on_stall => GraphQL::Houtou::DataLoader->on_stall_for(
    values %{ $request_context->{loaders} },
  ),
);
```

Create DataLoaders per request so cached values and database handles cannot
cross tenants. Reuse the schema and runtime, not request-scoped loaders.
Mutation top-level fields remain serial even when they return promises.

An evented graphql-perl/Mojolicious application needs an architectural
decision: move GraphQL handling to prefork PSGI with bounded blocking I/O, or
retain the existing executor. There is no transparent `promise_code` bridge.

## Persisted operations

For a known operation with variables, compile a reusable native program at
startup:

```perl
my $program = $runtime->compile_program(
  'query User($id: ID!) { user(id: $id) { id name } }',
);

my $result = $runtime->execute_program(
  $program,
  variables => { id => $id },
  context   => $context,
);
```

For a fixed operation without variables, a native bundle is faster:

```perl
use GraphQL::Houtou qw(compile_native_bundle);

my $bundle = compile_native_bundle($schema, '{ viewer { id name } }');
my $json = $runtime->execute_bundle_to_json($bundle, context => $context);
```

Bundle arguments are baked into the artifact. Do not use a fixed bundle for
operations that accept GraphQL variables. See `persisted-queries.md` for
descriptor storage and cache details.

## PSGI migration

`GraphQL::Houtou::PSGI` is a plain PSGI application and can be mounted below
Plack middleware:

```perl
use GraphQL::Houtou::PSGI;

my $app = GraphQL::Houtou::PSGI->new(
  schema              => $schema,
  context             => sub { build_request_context($_[0]) },
  allow_introspection => 0,
  max_body_size       => 1_048_576,
  max_depth           => 20,
  max_nodes           => 5_000,
  max_cost            => 10_000,
)->to_app;
```

Framework plugins for graphql-perl are not API-compatible with this adapter.
Move authentication, request IDs, timeouts, rate limiting, and database-handle
lifetime into Plack middleware or the context factory.

The 0.01 adapter executes POST requests. GET query execution, multipart
uploads, APQ negotiation, WebSocket/SSE subscriptions, `@defer`, and `@stream`
are outside the supported profile.

## Staged rollout checklist

1. Run the graphql-perl and Houtou schemas side by side in tests using the
   same fixtures, variables, context, and root values.
2. Compare `data`, error `path`, and error `locations`; do not require identical
   message wording.
3. Exercise nullable and Non-Null failures, invalid variables, aliases,
   fragments, interfaces/unions, custom scalars, and mutation ordering.
4. Confirm every old global-field-resolver and framework-plugin hook has an
   explicit replacement.
5. Compile the runtime once per worker and create database handles and
   DataLoaders at the correct process/request scope.
6. Enable depth, node, cost, pagination, body-size, timeout, and rate limits.
7. Compare the direct JSON lane with the old HTTP response, including UTF-8
   and boolean values.
8. Load-test the real prefork server, database pool, cache-hit mixture, slow
   resolvers, worker recycling, and graceful restart before switching public
   traffic.

See `production-deployment.md` for the operational checklist and
`spec-conformance-september-2025.md` for the exact supported GraphQL profile.
