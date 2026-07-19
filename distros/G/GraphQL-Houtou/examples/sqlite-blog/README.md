# SQLite persisted-query blog

This standalone example is a production-shaped GraphQL::Houtou workload. It
serves a small English/Japanese blog through PSGI, stores state in SQLite, and
accepts only startup-compiled persisted operations.

It demonstrates Query, Mutation, Interface, Union, `@deprecated`, `@oneOf`,
schema and executable descriptions, variables, UTF-8 data, request-scoped
DataLoaders, and three resolver result shapes:

- `Post` is a blessed Perl object whose scalar properties use the default
  method resolver;
- `Author`, `Tag`, `Comment`, and `BlogStats` use plain hash references;
- `health` is a direct scalar.

## Run

Build GraphQL::Houtou from the repository root, then install the example-only
dependencies and start the application:

```sh
perl Build.PL
./Build build
cd examples/sqlite-blog
carton install
carton exec -- plackup --port 8081 -I../../lib -I../../blib/arch app.psgi
```

Open <http://127.0.0.1:8081/>. GraphiQL is available at
<http://127.0.0.1:8081/graphiql>. The database is initialized automatically at
`var/blog.sqlite3`; set `BLOG_DB` to use another path.

GraphiQL intentionally uses a separate dynamic endpoint with introspection.
The production-shaped `/graphql` endpoint remains persisted-only. Set
`BLOG_GRAPHIQL=0` when running an untrusted or benchmark deployment.

For a prefork qualification run:

```sh
BLOG_GRAPHIQL=0 carton exec -- start_server --port 8081 -- \
  plackup -s Starlet --workers 4 -I../../lib -I../../blib/arch app.psgi
```

Each worker opens its own SQLite handle after fork. WAL mode and a busy timeout
allow concurrent readers and serialize the deliberately small write workload.

## Persisted protocol

`POST /graphql` accepts JSON with an operation id and variables, never a raw
query:

```json
{"id":"Feed","variables":{"limit":20}}
```

Unknown ids return HTTP 404. The allowlist and native programs are built at
application startup from `operations.graphql`; request execution does not
parse or compile GraphQL text.

Useful ids are `Feed`, `PostById`, `NodeById`, `Search`, `Stats`,
`CreatePost`, and `AddComment`. `GET /operations` returns their ids for
diagnostics.

## Load qualification

Initialize representative data with `script/seed.pl 10000 20`, then drive the
persisted endpoint with a tool such as `wrk`, `oha`, or `vegeta`. Mix Feed,
PostById, Search, CreatePost, missing ids, and malformed variables. Record:

- throughput and p50/p95/p99 latency;
- per-worker RSS and CPU;
- SQLite busy/timeout errors;
- DataLoader batch counts from the `Server-Timing` response header;
- graceful restart/drain behavior;
- cold program-cache startup and a long steady-state soak.

The example is intentionally not an authentication or HTML-sanitization
reference. Treat mutation access and rendered post bodies accordingly.
