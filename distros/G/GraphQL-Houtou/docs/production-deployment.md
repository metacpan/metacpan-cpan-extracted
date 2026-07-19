# Production deployment guide

This guide describes the supported 0.01 production shape: query and mutation
requests over POST to a process-based PSGI deployment. Subscription execution
and long-lived streaming transports are not supported.

## Process model

Use a prefork PSGI server and scale with worker processes, not Perl ithreads.
Construct one immutable schema and native runtime per worker and reuse it for
all requests handled by that worker. Set `program_cache_max` to a bounded value
appropriate for the number of distinct dynamic documents expected per worker.

Do not share live database handles across `fork`. Establish a worker-local
database pool after the worker is created, and acquire a handle for each
request. DataLoaders and their caches must be request-scoped; construct them in
the PSGI `context` callback and return their combined `on_stall` hook.

```perl
my $app = GraphQL::Houtou::PSGI->new(
  schema            => $schema,
  program_cache_max => 1_000,
  max_body_size     => 256 * 1024,
  max_depth         => 20,
  max_nodes         => 2_000,
  max_cost          => 10_000,
  default_list_size => 20,
  graphiql           => 0,
  context => sub {
    my ($env) = @_;
    my $dbh = $worker_pool->checkout;
    my $users = GraphQL::Houtou::DataLoader->new(
      batch => sub { batch_users($dbh, $_[0]) },
    );
    return (
      { dbh => $dbh, users => $users, request_id => $env->{HTTP_X_REQUEST_ID} },
      GraphQL::Houtou::DataLoader->on_stall_for($users),
    );
  },
)->to_app;
```

Return or release checked-out database handles with request middleware or a
request-context guard. The example above only shows where the handle belongs;
the exact cleanup mechanism depends on the pool.

## Resource limits

Keep `max_body_size` enabled. The default is 1 MiB; most applications can use a
smaller cap. Configure `max_depth`, `max_nodes`, and `max_cost` together:

- `max_depth` limits deeply nested selection trees;
- `max_nodes` limits broad alias and field floods;
- `max_cost` applies schema field weights and list multipliers;
- `default_list_size` estimates list expansion when a field has no explicit
  `list_size`.

Cost is an estimate, not a database row limit. Every list resolver must still
enforce pagination and a maximum page size. Assign larger schema `cost` values
to expensive searches and external-service calls, and realistic `list_size`
values to list fields. Persisted documents are not exempt from these limits.

Apply IP, account, or API-key rate limits before the PSGI app. Rate limiting
and query cost solve different problems: cost bounds one accepted request,
while rate limiting bounds aggregate work.

## Timeouts and cancellation

Set request timeouts at the reverse proxy and PSGI server, plus shorter
timeouts on database and outbound HTTP operations. Houtou cannot cancel an
arbitrary blocking resolver after it has entered Perl or a database driver, so
an outer HTTP timeout alone does not release the worker promptly.

Promise-returning resolvers must either settle or be driven by a working
`on_stall` hook. Treat scheduler-deadlock errors as server failures and alert
on them; do not retry them inside the same request.

## HTTP and security policy

The bundled adapter accepts execution requests only with POST and
`Content-Type: application/json`. It returns request errors as HTTP 400,
oversized bodies as 413, unsupported media as 415, internal failures as 500,
and field execution errors in a normal HTTP 200 GraphQL response.

Terminate TLS and apply authentication, CORS, rate limiting, and request IDs in
a reverse proxy or PSGI middleware. Do not log raw variables by default: they
commonly contain credentials or personal data. Useful structured fields are
request ID, authenticated principal, operation name, document hash, status,
duration, cost, and error codes. Avoid returning internal exception text to
clients; the PSGI adapter already converts uncaught execution failures to a
generic 500 response and writes the detail to the server error log.

Disable GraphiQL in production. The bundled page loads JavaScript and CSS from
`esm.sh`; enabling it requires outbound browser access and a CSP that permits
that CDN. If an operator UI is required, protect it with authentication and
serve pinned assets under an explicitly reviewed CSP.

For public endpoints that do not need schema discovery, construct the runtime
or PSGI adapter with `allow_introspection => 0`. This rejects `__schema` and
`__type` during the bounded document request stage while retaining
`__typename`. The decision is part of the program-cache policy signature, so a
query previously allowed by an administrative request cannot bypass a later
disabled request. GraphiQL requires introspection and should remain disabled on
the same public endpoint. Direct `execute_program` and bundle APIs consume trusted,
prevalidated deployment artifacts and are intentionally outside this dynamic
document policy; do not expose arbitrary artifact loading to clients.

## Federation subgraphs

`GraphQL::Houtou::Federation` makes a Houtou schema usable behind an
Apollo-compatible Gateway or Router. Keep the subgraph on a private network or
require service authentication; clients should only reach the Router.
`_service` exposes the authored SDL and `_entities` exposes entity lookup
across types, so neither field should be treated as harmless public
introspection.

Keep `max_representations` bounded and use request-scoped DataLoaders from
entity resolvers to avoid one database query per representation. The subgraph
still needs the ordinary body, depth, node, cost, timeout, and rate limits.
The Router and supergraph composition lifecycle are separate services and
should be deployed, monitored, and upgraded independently.

## Graceful restart and capacity

On deploy, stop routing new requests to a worker, allow in-flight requests to
finish up to a bounded drain timeout, then terminate it. Database handles and
other worker-local resources should be closed during worker shutdown. There
are no subscription streams to drain in the 0.01 profile.

Choose worker count from load measurements rather than CPU count alone. Before
release, test the real server, database pool, schema, and resolver mix with
cache hits and misses, slow and failing resolvers, and graceful restarts.
Record throughput, p50/p95/p99 latency, CPU, RSS, database utilization, error
rate, and behavior during a long soak. Leave headroom for tail latency and a
worker being restarted.

`examples/sqlite-blog/` is a self-contained qualification workload with a
prefork PSGI launch command, SQLite WAL storage, request-scoped DataLoaders,
startup-compiled persisted operations, English/Japanese data, a seed script,
and an HTTP smoke test. Use it to validate the deployment mechanics before
substituting the production database and schema.

## Release checklist

- process-based workers; no ithreads;
- worker-local database pools and request-scoped DataLoaders;
- bounded program cache, body, depth, node, cost, and page sizes;
- proxy/server/database/outbound timeouts configured;
- authentication, rate limiting, request IDs, and redacted structured logs;
- GraphiQL disabled or separately authenticated with reviewed CSP;
- graceful drain verified under load;
- production-shaped load and soak results recorded.
