[![Actions Status](https://github.com/AnaTofuZ/GraphQL-Houtou/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/AnaTofuZ/GraphQL-Houtou/actions?workflow=test)
# NAME

GraphQL::Houtou - XS-backed GraphQL parser and execution toolkit for Perl

# SYNOPSIS

    use GraphQL::Houtou qw(execute build_native_runtime compile_native_bundle);
    use GraphQL::Houtou::Schema;
    use GraphQL::Houtou::Type::Object;
    use GraphQL::Houtou::Type::Scalar qw($String);

    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name   => 'Query',
        fields => {
          hello => { type => $String, resolve => sub { 'world' } },
        },
      ),
    );

    # --- one-off ---
    my $result = execute($schema, '{ hello }');

    # --- dynamic queries with variables (production) ---
    my $runtime = build_native_runtime($schema);
    my $result  = $runtime->execute_document(
      '{ user(id: $id) }', variables => { id => 42 },
    );

    # --- fixed query, maximum throughput (no variables) ---
    my $bundle  = compile_native_bundle($schema, '{ hello }');
    my $result  = $runtime->execute_bundle($bundle);

# DESCRIPTION

GraphQL::Houtou provides an XS-first GraphQL parser and runtime for Perl.
The parser surface returns the library's canonical Perl AST, while
execution runs through compiled programs on a native (XS) VM.

The toolkit is built around the shape of a real web application:

- **SQL-backed schemas with batching** - resolvers return promises from a
loader ([GraphQL::Houtou::DataLoader](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3ADataLoader) is bundled) and the runtime's
stall-flush hook collapses N+1 lookups into one query per nesting level,
while callers still receive a finished response synchronously
- **direct JSON responses** - `execute_to_json` renders the response as
UTF-8 JSON bytes inside the XS lane without materializing the Perl
envelope, for both sync and batching schemas
- **an HTTP endpoint in one line** - [GraphQL::Houtou::PSGI](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3APSGI) serves
GraphQL over HTTP (plus GraphiQL) on any PSGI server with no Plack
dependency
- **persisted-query artifacts** - fixed queries compile once into native
bundles for maximum throughput; variable-bearing queries compile into
reusable programs with an automatic per-query cache

# USAGE

## Parsing

The default `parse()` entry point returns the canonical parser AST used by
this library.

    my $ast = parse($source);

Computing location data costs real time. If you do not need `location`
information, pass `no_location => 1` through `parse_with_options()` -
recommended for throughput-sensitive workloads:

    my $ast = parse_with_options($source, {
      no_location => 1,
    });

## Building a schema from SDL

`build_schema()` turns a Schema Definition Language document into an
executable [GraphQL::Houtou::Schema](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3ASchema). Field resolvers, abstract type
dispatch, and custom scalar coercion can be attached through the
`resolvers` option:

    use GraphQL::Houtou qw(build_schema execute);

    my $schema = build_schema(<<'SDL',
    type Query {
      dog(id: ID = "1"): Dog
      pets: [Pet!]
    }
    interface Pet { name: String! }
    type Dog implements Pet { name: String! }
    SDL
      resolvers => {
        Query => {
          dog  => sub { my (undef, $args) = @_; load_dog($args->{id}) },
          pets => sub { all_pets() },
        },
        Pet => { resolve_type => sub { 'Dog' } },
      },
    );

    my $result = execute($schema, '{ dog { name } }');

Fields without an explicit resolver use the graphql-perl/graphql-js-style
default resolver. A hash value that is a coderef is called as
`($args, $context, $info)`; other hash values are returned directly. A
blessed source method matching the field name is called as
`($args, $context, $info)`. Explicit field resolvers always take precedence.
Because method lookup follows normal Perl semantics, field names such as
`can`, `isa`, or `DOES` may resolve inherited `UNIVERSAL` methods and
produce a field error whose message includes Perl source location details;
use an explicit resolver for such names on blessed sources.
Custom scalars default to pass-through `serialize` / `parse_value`; supply
your own through `resolvers` when coercion matters. `@deprecated`,
`@specifiedBy`, `@oneOf`, and `repeatable` directive definitions in the
SDL are reflected on the built types. The same functionality is available as
`GraphQL::Houtou::Schema->from_doc($sdl, %opts)` and
`->from_ast($ast, %opts)`. Type-system extensions in the same SDL
document are merged before the executable schema is constructed.

The inverse direction is `print_schema()` (also available as
`$schema->to_doc`), which renders any schema back to SDL — including
schemas assembled from Perl type objects:

    use GraphQL::Houtou qw(print_schema);
    my $sdl = print_schema($schema);

Built-in scalars, introspection meta types, and the specified directives
(`@include`, `@skip`, `@deprecated`, `@specifiedBy`) are omitted from
the output, matching graphql-js `printSchema`. Types are emitted sorted by
name, so the output is stable and diff-friendly.

## Batching resolvers (DataLoader / the on\_stall hook)

SQL-backed schemas avoid the N+1 problem by batching: resolvers return
promises from a loader, and the queued keys are fetched in one query when
execution cannot proceed any further. Pass an `on_stall` callback to
`execute()` (or `execute_document` / `execute_program`) to drive this:

    use GraphQL::Houtou::DataLoader;

    my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
      my ($ids) = @_;
      my %row = map { $_->{id} => $_ } $db->select_users_in(@$ids);
      return [ map { $row{$_} } @$ids ];
    });

    my $result = execute($schema, $query, $variables,
      context => { users => $users },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
    );

With `on_stall` the request runs on the async-capable lane and is driven
to completion internally: whenever every remaining field is waiting on a
promise, the callback is invoked and must make progress (return its
dispatch count) by resolving promises - flushing loaders, typically. The
finished response is returned synchronously; callers never see promises.
If the callback reports no progress while promises remain pending, the
request fails with a deadlock error instead of hanging.

The contract is loader-agnostic: anything that can resolve the pending
promises may implement `on_stall`. [GraphQL::Houtou::DataLoader](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3ADataLoader) is the
bundled reference implementation, following the dataloader-js semantics:
`load($key)` returns one promise per key, `load_many(\@keys)` returns a
single promise of the values in key order, and instances cache per key
(create one loader per request).

### Declaring an async schema (async => 1)

Batching is the normal deployment shape, so runtimes accept a single
declaration instead of per-request plumbing:

    my $runtime = build_native_runtime($schema, async => 1);

An async runtime starts every request on the async-capable lane: promise
resolvers work with or without variables, `execute_document` returns the
settled envelope (or a promise while pending), and
`execute_document_to_json` renders JSON as soon as the response settles.
Per-request `on_stall` hooks compose with it as usual and remain the way
DataLoader batches are flushed.

Without the declaration, requests with variables run on the synchronous
fast lane, which cannot suspend. A resolver returning a Promise::XS
promise there fails immediately with an error pointing at `async => 1`
and `on_stall` - promise objects never leak into response data.
`strict_sync => 1` forces the strict sync lane even on an async runtime.

### Execution lane option

Execution always uses the XS native runtime. Normally the runtime chooses the
synchronous or async-capable lane from `async`, variables, and `on_stall`.

`strict_sync => 1` explicitly pins a request to the strict synchronous
fast lane, including on a runtime built with `async => 1`. Use it only
when promise-returning resolvers must be rejected for that request. There is
no supported Pure Perl execution path.

## Serving JSON responses directly

When the response is going straight onto the wire (PSGI handlers and other
HTTP servers), `execute_to_json()` renders the GraphQL response as UTF-8
JSON bytes entirely inside the XS fast lane - the Perl response hash is
never materialized and no JSON module runs:

    use GraphQL::Houtou qw(execute_to_json);
    my $bytes = execute_to_json($schema, '{ users { id name } }');
    # => {"data":{"users":[...]}}

The same lane is available on a reusable runtime:

    my $runtime = build_native_runtime($schema);
    my $bytes = $runtime->execute_document_to_json($query, variables => \%vars);
    my $bytes = $runtime->execute_bundle_to_json($bundle);   # persisted queries

Properties:

- roughly twice the effective throughput of `execute()` followed by
a JSON module, since response hashes and arrays are never built
- response keys appear in query field order, as the GraphQL spec
recommends (plain `execute()` returns Perl hashes, which cannot preserve
order)
- the envelope matches `execute()`: `"data"` plus `"errors"`
(message and path) only when execution errors occurred
- without `on_stall`, the lane is synchronous - a resolver returning
a Promise::XS promise croaks

### Batching resolvers and JSON output

`execute_to_json()` and `execute_document_to_json()` accept the same
`on_stall` option as `execute()`. The request then runs on the
async-capable lane and the completed response is serialized to JSON bytes
directly from the native result tree when it resolves - the Perl envelope
hash is still never built:

    my $loader = GraphQL::Houtou::DataLoader->new(batch => \&batch_users);
    my $bytes = execute_to_json(
      $schema, $query, \%vars,
      context  => { users => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );

Two properties differ from the synchronous JSON lane: response keys appear
in completion order (synchronously resolved fields first, batched fields
as they settle) rather than query order, and Boolean-typed leaves render
as the resolver returned them (`0`/`1`) rather than JSON booleans,
matching what `execute()` plus a JSON module produces for the same async
request. JSON object member order carries no meaning, and both points are
slated to converge with the sync lane as the async hot path work lands.

## Serving over HTTP (PSGI)

[GraphQL::Houtou::PSGI](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3APSGI) turns a schema into a GraphQL over HTTP endpoint
on any PSGI server, with optional GraphiQL. Responses go through the
direct-JSON lane, and per-request DataLoaders fit in the `context`
builder:

    # app.psgi
    use GraphQL::Houtou::PSGI;
    GraphQL::Houtou::PSGI->new(
      schema => $schema,
      graphiql => 1,
      context => sub {
        my ($env) = @_;
        my $users = GraphQL::Houtou::DataLoader->new(batch => \&batch_users);
        return ({ users => $users },
                GraphQL::Houtou::DataLoader->on_stall_for($users));
      },
    )->to_app;

## API Selection Guide

Choose the execution API that fits your use case.

### One-off or development execution

    my $result = execute($schema, '{ hello }');
    my $result = execute($schema, '{ user(id: $id) }', { id => 42 });

`execute()` is the simplest entry point. It builds and caches a native
runtime automatically. Use this for one-off calls or during development.

### Repeated execution with different variables (dynamic queries)

For production workloads where the same schema serves many queries or the
same query with different variable sets, obtain a runtime once and reuse it:

    my $runtime = build_native_runtime($schema);

    # compile_program result is cached per query string (FIFO, default 1000).
    # Repeated calls with the same query string skip the compiler entirely.
    my $result = $runtime->execute_document($query, variables => \%vars);

You can tune the cache size:

    my $runtime = build_native_runtime($schema, program_cache_max => 500);

### Production query cost limits

Native runtimes reject weighted queries above `max_cost` (default 10,000).
Every field costs 1 unless its schema definition supplies `cost`. A list
multiplies its child selection cost by `list_size`, or by
`default_list_size` (default 10) when the field has no explicit estimate:

    users => {
        type      => $User->list,
        cost      => 2,
        list_size => 50,
        resolve   => sub { ... },
    }

    my $runtime = build_native_runtime(
        $schema,
        max_cost          => 5_000,
        default_list_size => 20,
    );

The cost walk runs in XS on cache misses and stops as soon as the budget is
exceeded. Cached programs retain the limit signature they passed; a stricter
per-call override is checked again. Keep resolver-side pagination limits as a
second line of defense because `list_size` is an estimate, not a runtime row
counter.

### Persisted queries

A persisted query is a pre-compiled artifact stored outside the automatic
program cache and reused across requests by application code.

**Fixed query (no variables)** — compile once into a native bundle at startup,
execute any number of times with zero compile overhead per request:

    use GraphQL::Houtou qw(build_native_runtime compile_native_bundle);

    my $runtime = build_native_runtime($schema);
    my %store = (
      hello => compile_native_bundle($schema, '{ hello }'),
    );

    # request time
    my $result = $runtime->execute_bundle($store{hello});

**Variable-bearing query** — compile once into a program object; supply
different variables per request:

    my $runtime = build_native_runtime($schema);
    my %store = (
      greet => $runtime->compile_program(
        'query($name: String){ greet(name: $name) }',
      ),
    );

    # request time — same compiled program, different variables each call
    my $alice = $runtime->execute_program(
      $store{greet}, variables => { name => 'alice' },
    );
    my $bob = $runtime->execute_program(
      $store{greet}, variables => { name => 'bob' },
    );

**Bundle descriptor** — a serialisable representation of a fixed query bundle,
useful when the artifact must cross a process boundary or be stored on disk:

    use GraphQL::Houtou qw(build_native_runtime compile_native_bundle_descriptor);

    # at build / warm-up time
    my %store = (
      hello => compile_native_bundle_descriptor($schema, '{ hello }'),
    );

    # request time
    my $result = $runtime->execute_bundle_descriptor($store{hello});

Use a native bundle object for in-process reuse; use a descriptor when the
artifact needs to be serialised.

### Fixed queries compiled at boot time (maximum throughput)

If your query is known at startup and uses **no GraphQL variables**, compile it
once into a native bundle and reuse it across all requests:

    my $bundle  = compile_native_bundle($schema, '{ hello }');
    my $runtime = build_native_runtime($schema);

    # Hot path — no Perl VM compile overhead per request
    my $result  = $runtime->execute_bundle($bundle);

**Important:** a native bundle bakes argument values into its binary
representation at compile time. Queries that accept GraphQL variables
(`$id`, `$name`, etc.) must use the dynamic query path above — passing
variables to `execute_bundle` at request time is not supported.

### Async / Promise resolvers

Declare promise-returning schemas with `async => 1`
(see ["Declaring an async schema (async => 1)"](#declaring-an-async-schema-async-1)):

    my $runtime = build_native_runtime($schema, async => 1);

Requests that pass an `on_stall` hook run on the async-capable lane in
any case, so DataLoader deployments work with or without the declaration.
Without either, requests run on the synchronous fast lane and a resolver
returning a promise fails with an error pointing at both options - promise
objects never leak into response data.

Mutation fields always execute serially: each resolver is called only after
the previous resolver's promise has resolved, in conformance with the GraphQL
specification.

Only `Promise::XS` promises are recognized. Generic promise adapters and
`promise_code` injection are no longer part of the active runtime path.

# PARSER SURFACE

The public parser surface is fixed to the library's canonical parser AST.
`parse_with_options()` only accepts parser-local knobs such as
`no_location`.

# BENCHMARK SNAPSHOT

Medians from `util/execution-benchmark-checkpoint.pl` (repeat 3) on one
development machine, 2026-07-15. Resolver return values are not cached;
the numbers measure request throughput with compiled artifacts reused
across requests.

    perl util/execution-benchmark-checkpoint.pl --repeat 3
    perl util/execution-benchmark-checkpoint.pl --include-async --case async_preresolved

- **Dynamic queries** (`execute_document` with variables, program cache
hit): `192k/s` with varying variable values; `199k-325k/s` across the
nested-object, list, and abstract query shapes.
- **Direct JSON responses**: `execute_document_to_json` `463k/s`;
`execute_bundle_to_json` `894k/s` on the same list-of-objects shape.
- **Persisted native bundles** (`execute_bundle`, fixed query):
`611k-683k/s` across the same shapes.
- **Async lane** (20-item x 3-field list, resolvers returning pre-resolved
`Promise::XS` promises): `60k/s` for a whole-list promise (the
DataLoader "promise of array" shape) against `97k/s` for the identical
query on the sync lane - within `1.6x` and still narrowing. Direct JSON
on the async lane runs at `63k/s`; one promise per item at `29k/s`.

## Compared with graphql-perl

Same machine, same 20-item x 3-field list-of-objects query, both sides
executing to a JSON response. `util/execution-benchmark.pl` runs the
upstream lanes automatically when a `graphql-perl` checkout sits next
to this repository:

    graphql-perl, query string each request        5.0k/s
    graphql-perl, pre-parsed AST + reused schema    23k/s
    GraphQL::Houtou execute_document_to_json       463k/s
    GraphQL::Houtou execute_bundle_to_json         894k/s

Against upstream's fastest configuration (pre-parsed AST), the dynamic
document lane is roughly `20x` and persisted bundles roughly `39x`.
The async lane - resolvers returning promises, which upstream's executor
resolves through its own promise plumbing - still clears upstream's sync
numbers by more than `2x`.

For methodology and reproducible commands, see
`docs/execution-benchmark.md`.

# CAVEATS

## Supported execution profile

Version 0.01 supports GraphQL queries and mutations. Subscription syntax,
schema roots, introspection, and document validation are supported, but
subscription execution and streaming transports are not. Attempting to
execute a subscription fails closed with a `SUBSCRIPTION_NOT_SUPPORTED`
request error.

The PSGI adapter accepts GraphQL execution requests over POST. GET query
execution, `@defer`, `@stream`, WebSocket/SSE subscriptions, a Federation
Gateway/Router, and generic promise adapters are outside the 0.01 profile.
Federation 2 subgraph execution is provided by
[GraphQL::Houtou::Federation](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3AFederation). Only `Promise::XS` promises are recognized.

Fixed native bundles are for variable-free queries. Use compiled native
programs for persisted queries that accept variables.

## Perl ithreads are not supported

The runtime keeps request and schema state in C structures referenced by
opaque XS handles. Duplicating those raw pointers across `ithreads` would
lead to double frees, so every handle class defines `CLONE_SKIP`, making
thread clones drop them (they become `undef` in the child thread) instead
of crashing. Use process-based concurrency (prefork PSGI servers or fork)
for parallelism.

# SEE ALSO

- [GraphQL::Houtou::Schema](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3ASchema) - schema construction and runtime factory
- [GraphQL::Houtou::Runtime::NativeRuntime](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3ARuntime%3A%3ANativeRuntime) - the request-time execution API
- [GraphQL::Houtou::DataLoader](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3ADataLoader) - bundled batching loader
- [GraphQL::Houtou::PSGI](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3APSGI) - GraphQL over HTTP endpoint
- [GraphQL::Houtou::Federation](https://metacpan.org/pod/GraphQL%3A%3AHoutou%3A%3AFederation) - Apollo Federation 2 subgraph support
- `docs/` in the distribution - architecture, benchmarks, and design history
- `docs/production-deployment.md` - prefork deployment and operations checklist

# NAME ORIGIN

The name `Houtou` comes from several overlapping references:

- Japanese `hotou` / "treasured sword" (宝刀)
- Yamanashi's noodle dish `houtou` (ほうとう)
- the VTuber `宝灯桃汁` (Houtou Momojiru)

# ACKNOWLEDGEMENTS

GraphQL::Houtou is strongly influenced by GraphQL for Perl
(`graphql-perl`). We gratefully acknowledge its design and implementation
as an important foundation for this project. See
[GraphQL on MetaCPAN](https://metacpan.org/pod/GraphQL) and the
[graphql-perl source repository](https://github.com/graphql-perl/graphql-perl).

# LICENSE

Copyright (C) anatofuz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

anatofuz <anatofuz@gmail.com>
