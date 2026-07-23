package GraphQL::Houtou;

use 5.014;
use strict;
use warnings;
use Exporter 'import';
use XSLoader ();
use GraphQL::Houtou::Runtime::LazyInfo ();

our $VERSION = '0.03';
our $XS_BUNDLE_LOADED = 0;
our @EXPORT_OK = qw(
  parse
  parse_with_options
  build_schema
  print_schema
  execute
  execute_native
  execute_to_json
  compile_runtime
  build_runtime
  build_native_runtime
  compile_native_program
  compile_native_bundle
  compile_native_bundle_descriptor
  build_subgraph_schema
);

sub _bootstrap_xs {
  return 1 if $XS_BUNDLE_LOADED++;
  XSLoader::load('GraphQL::Houtou', $VERSION);
  return 1;
}

sub parse {
  my ($source) = @_;
  require GraphQL::Houtou::XS::Parser;
  return GraphQL::Houtou::XS::Parser::parse_xs($source, undef);
}

sub parse_with_options {
  my ($source, $options) = @_;
  $options ||= {};
  for my $key (keys %{$options}) {
    next if $key eq 'no_location';
    die "Unknown parser option '$key'.\n";
  }
  my $no_location = $options->{no_location};
  require GraphQL::Houtou::XS::Parser;
  return GraphQL::Houtou::XS::Parser::parse_xs($source, $no_location);
}

sub build_schema {
  my ($doc, %opts) = @_;
  require GraphQL::Houtou::Schema;
  return GraphQL::Houtou::Schema->from_doc($doc, %opts);
}

sub build_subgraph_schema {
  require GraphQL::Houtou::Federation;
  return GraphQL::Houtou::Federation::build_subgraph_schema(@_);
}

sub print_schema {
  my ($schema) = @_;
  return $schema->to_doc;
}

sub compile_runtime {
  my ($schema, %opts) = @_;
  return $schema->compile_runtime(%opts);
}

sub build_runtime {
  my ($schema, %opts) = @_;
  return $schema->build_runtime(%opts);
}

sub build_native_runtime {
  my ($schema, %opts) = @_;
  return $schema->build_native_runtime(%opts);
}

sub compile_native_bundle {
  my ($schema, $document, %opts) = @_;
  return $schema->compile_native_bundle($document, %opts);
}

sub compile_native_program {
  my ($schema, $document, %opts) = @_;
  return $schema->compile_native_program($document, %opts);
}

sub compile_native_bundle_descriptor {
  my ($schema, $document, %opts) = @_;
  return $schema->compile_native_bundle_descriptor($document, %opts);
}

sub execute_native {
  my ($schema, $document, %opts) = @_;
  return $schema->execute_native($document, %opts);
}

sub execute_to_json {
  my ($schema, $document, $variables, %opts) = @_;
  $opts{variables} = $variables if defined $variables;
  my $runtime = $schema->build_native_runtime;
  return $runtime->execute_document_to_json($document, %opts);
}

sub execute {
  my ($schema, $document, $variables_or_opts, @rest) = @_;
  my %opts;
  my %known_option = map { ($_ => 1) } qw(
    variables
    vars
    root_value
    context
    operation_name
    on_stall
    promise_code
    strict_sync
    max_depth
    max_nodes
    max_cost
    default_list_size
    allow_introspection
  );

  if (@rest) {
    my $third_is_hash = ref($variables_or_opts) eq 'HASH';
    if ($third_is_hash && !grep { $known_option{$_} } keys %{$variables_or_opts}) {
      # execute($schema, $query, \%variables, %opts): the positional hash
      # is the variables payload, not part of the options.
      %opts = @rest;
      $opts{variables} = $variables_or_opts if !exists $opts{variables};
    } else {
      %opts = ($third_is_hash ? (%{$variables_or_opts}) : (), @rest);
    }
  } elsif (ref($variables_or_opts) eq 'HASH') {
    if (grep { $known_option{$_} } keys %{$variables_or_opts}) {
      %opts = %{$variables_or_opts};
      if (!exists $opts{variables}) {
        $opts{variables} = delete $opts{vars} if exists $opts{vars};
      } elsif (exists $opts{vars} && !exists $opts{variables}) {
        $opts{variables} = delete $opts{vars};
      }
    } else {
      $opts{variables} = $variables_or_opts;
    }
  } elsif (defined $variables_or_opts) {
    $opts{variables} = $variables_or_opts;
  }

  die "promise_code is no longer supported; Promise::XS is detected automatically.\n"
    if exists $opts{promise_code};

  my $runtime = $schema->build_native_runtime;
  return $runtime->execute_document($document, %opts);
}

1;
__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou - XS-backed GraphQL parser and execution toolkit for Perl

=head1 SYNOPSIS

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

=head1 DESCRIPTION

GraphQL::Houtou provides an XS-first GraphQL parser and runtime for Perl.
The parser surface returns the library's canonical Perl AST, while
execution runs through compiled programs on a native (XS) VM.

The toolkit is built around the shape of a real web application:

=over 4

=item *

B<SQL-backed schemas with batching> - resolvers return promises from a
loader (L<GraphQL::Houtou::DataLoader> is bundled) and the runtime's
stall-flush hook collapses N+1 lookups into one query per nesting level,
while callers still receive a finished response synchronously

=item *

B<direct JSON responses> - C<execute_to_json> renders the response as
UTF-8 JSON bytes inside the XS lane without materializing the Perl
envelope, for both sync and batching schemas

=item *

B<an HTTP endpoint in one line> - L<GraphQL::Houtou::PSGI> serves
GraphQL over HTTP (plus GraphiQL) on any PSGI server with no Plack
dependency

=item *

B<persisted-query artifacts> - fixed queries compile once into native
bundles for maximum throughput; variable-bearing queries compile into
reusable programs with an automatic per-query cache

=back

=head1 USAGE

=head2 Parsing

The default C<parse()> entry point returns the canonical parser AST used by
this library.

    my $ast = parse($source);

Computing location data costs real time. If you do not need C<location>
information, pass C<no_location =E<gt> 1> through C<parse_with_options()> -
recommended for throughput-sensitive workloads:

    my $ast = parse_with_options($source, {
      no_location => 1,
    });

=head2 Building a schema from SDL

C<build_schema()> turns a Schema Definition Language document into an
executable L<GraphQL::Houtou::Schema>. Field resolvers, abstract type
dispatch, and custom scalar coercion can be attached through the
C<resolvers> option:

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
C<($args, $context, $info)>; other hash values are returned directly. A
blessed source method matching the field name is called as
C<($args, $context, $info)>. Explicit field resolvers always take precedence.
Because method lookup follows normal Perl semantics, field names such as
C<can>, C<isa>, or C<DOES> may resolve inherited C<UNIVERSAL> methods and
produce a field error whose message includes Perl source location details;
use an explicit resolver for such names on blessed sources.
Custom scalars default to pass-through C<serialize> / C<parse_value>; supply
your own through C<resolvers> when coercion matters. C<@deprecated>,
C<@specifiedBy>, C<@oneOf>, and C<repeatable> directive definitions in the
SDL are reflected on the built types. The same functionality is available as
C<< GraphQL::Houtou::Schema->from_doc($sdl, %opts) >> and
C<< ->from_ast($ast, %opts) >>. Type-system extensions in the same SDL
document are merged before the executable schema is constructed.

The inverse direction is C<print_schema()> (also available as
C<< $schema->to_doc >>), which renders any schema back to SDL — including
schemas assembled from Perl type objects:

    use GraphQL::Houtou qw(print_schema);
    my $sdl = print_schema($schema);

Built-in scalars, introspection meta types, and the specified directives
(C<@include>, C<@skip>, C<@deprecated>, C<@specifiedBy>) are omitted from
the output, matching graphql-js C<printSchema>. Types are emitted sorted by
name, so the output is stable and diff-friendly.

=head2 Batching resolvers (DataLoader / the on_stall hook)

SQL-backed schemas avoid the N+1 problem by batching: resolvers return
promises from a loader, and the queued keys are fetched in one query when
execution cannot proceed any further. Pass an C<on_stall> callback to
C<execute()> (or C<execute_document> / C<execute_program>) to drive this:

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

With C<on_stall> the request runs on the async-capable lane and is driven
to completion internally: whenever every remaining field is waiting on a
promise, the callback is invoked and must make progress (return its
dispatch count) by resolving promises - flushing loaders, typically. The
finished response is returned synchronously; callers never see promises.
If the callback reports no progress while promises remain pending, the
request fails with a deadlock error instead of hanging.

The contract is loader-agnostic: anything that can resolve the pending
promises may implement C<on_stall>. L<GraphQL::Houtou::DataLoader> is the
bundled reference implementation, following the dataloader-js semantics:
C<load($key)> returns one promise per key, C<load_many(\@keys)> returns a
single promise of the values in key order, and instances cache per key
(create one loader per request).

=head3 Declaring an async schema (async => 1)

Batching is the normal deployment shape, so runtimes accept a single
declaration instead of per-request plumbing:

    my $runtime = build_native_runtime($schema, async => 1);

An async runtime starts every request on the async-capable lane: promise
resolvers work with or without variables, C<execute_document> returns the
settled envelope (or a promise while pending), and
C<execute_document_to_json> renders JSON as soon as the response settles.
Per-request C<on_stall> hooks compose with it as usual and remain the way
DataLoader batches are flushed.

Without the declaration, requests with variables run on the synchronous
fast lane, which cannot suspend. A resolver returning a Promise::XS
promise there fails immediately with an error pointing at C<async =E<gt> 1>
and C<on_stall> - promise objects never leak into response data.
C<strict_sync =E<gt> 1> forces the strict sync lane even on an async runtime.

=head3 Execution lane option

Execution always uses the XS native runtime. Normally the runtime chooses the
synchronous or async-capable lane from C<async>, variables, and C<on_stall>.

C<strict_sync =E<gt> 1> explicitly pins a request to the strict synchronous
fast lane, including on a runtime built with C<async =E<gt> 1>. Use it only
when promise-returning resolvers must be rejected for that request. There is
no supported Pure Perl execution path.

=head2 Serving JSON responses directly

When the response is going straight onto the wire (PSGI handlers and other
HTTP servers), C<execute_to_json()> renders the GraphQL response as UTF-8
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

=over 4

=item * roughly twice the effective throughput of C<execute()> followed by
a JSON module, since response hashes and arrays are never built

=item * response keys appear in query field order, as the GraphQL spec
recommends (plain C<execute()> returns Perl hashes, which cannot preserve
order)

=item * the envelope matches C<execute()>: C<"data"> plus C<"errors">
(message and path) only when execution errors occurred

=item * without C<on_stall>, the lane is synchronous - a resolver returning
a Promise::XS promise croaks

=back

=head3 Batching resolvers and JSON output

C<execute_to_json()> and C<execute_document_to_json()> accept the same
C<on_stall> option as C<execute()>. The request then runs on the
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
as the resolver returned them (C<0>/C<1>) rather than JSON booleans,
matching what C<execute()> plus a JSON module produces for the same async
request. JSON object member order carries no meaning, and both points are
slated to converge with the sync lane as the async hot path work lands.

=head2 Serving over HTTP (PSGI)

L<GraphQL::Houtou::PSGI> turns a schema into a GraphQL over HTTP endpoint
on any PSGI server, with optional GraphiQL. Responses go through the
direct-JSON lane, and per-request DataLoaders fit in the C<context>
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

=head2 API Selection Guide

Choose the execution API that fits your use case.

=head3 One-off or development execution

    my $result = execute($schema, '{ hello }');
    my $result = execute($schema, '{ user(id: $id) }', { id => 42 });

C<execute()> is the simplest entry point. It builds and caches a native
runtime automatically. Use this for one-off calls or during development.

=head3 Repeated execution with different variables (dynamic queries)

For production workloads where the same schema serves many queries or the
same query with different variable sets, obtain a runtime once and reuse it:

    my $runtime = build_native_runtime($schema);

    # compile_program result is cached per query string (FIFO, default 1000).
    # Repeated calls with the same query string skip the compiler entirely.
    my $result = $runtime->execute_document($query, variables => \%vars);

You can tune the cache size:

    my $runtime = build_native_runtime($schema, program_cache_max => 500);

=head3 Production query cost limits

Native runtimes reject weighted queries above C<max_cost> (default 10,000).
Every field costs 1 unless its schema definition supplies C<cost>. A list
multiplies its child selection cost by C<list_size>, or by
C<default_list_size> (default 10) when the field has no explicit estimate:

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
second line of defense because C<list_size> is an estimate, not a runtime row
counter.

=head3 Persisted queries

A persisted query is a pre-compiled artifact stored outside the automatic
program cache and reused across requests by application code.

B<Fixed query (no variables)> — compile once into a native bundle at startup,
execute any number of times with zero compile overhead per request:

    use GraphQL::Houtou qw(build_native_runtime compile_native_bundle);

    my $runtime = build_native_runtime($schema);
    my %store = (
      hello => compile_native_bundle($schema, '{ hello }'),
    );

    # request time
    my $result = $runtime->execute_bundle($store{hello});

B<Variable-bearing query> — compile once into a program object; supply
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

B<Bundle descriptor> — a serialisable representation of a fixed query bundle,
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

=head3 Fixed queries compiled at boot time (maximum throughput)

If your query is known at startup and uses B<no GraphQL variables>, compile it
once into a native bundle and reuse it across all requests:

    my $bundle  = compile_native_bundle($schema, '{ hello }');
    my $runtime = build_native_runtime($schema);

    # Hot path — no Perl VM compile overhead per request
    my $result  = $runtime->execute_bundle($bundle);

B<Important:> a native bundle bakes argument values into its binary
representation at compile time. Queries that accept GraphQL variables
(C<$id>, C<$name>, etc.) must use the dynamic query path above — passing
variables to C<execute_bundle> at request time is not supported.

=head3 Async / Promise resolvers

Declare promise-returning schemas with C<async =E<gt> 1>
(see L<< /"Declaring an async schema (async => 1)" >>):

    my $runtime = build_native_runtime($schema, async => 1);

Requests that pass an C<on_stall> hook run on the async-capable lane in
any case, so DataLoader deployments work with or without the declaration.
Without either, requests run on the synchronous fast lane and a resolver
returning a promise fails with an error pointing at both options - promise
objects never leak into response data.

Mutation fields always execute serially: each resolver is called only after
the previous resolver's promise has resolved, in conformance with the GraphQL
specification.

Only C<Promise::XS> promises are recognized. Generic promise adapters and
C<promise_code> injection are no longer part of the active runtime path.

=head1 PARSER SURFACE

The public parser surface is fixed to the library's canonical parser AST.
C<parse_with_options()> only accepts parser-local knobs such as
C<no_location>.

=head1 BENCHMARK SNAPSHOT

Medians from C<util/execution-benchmark-checkpoint.pl> (repeat 3) on one
development machine, 2026-07-15. Resolver return values are not cached;
the numbers measure request throughput with compiled artifacts reused
across requests.

    perl util/execution-benchmark-checkpoint.pl --repeat 3
    perl util/execution-benchmark-checkpoint.pl --include-async --case async_preresolved

=over 4

=item *

B<Dynamic queries> (C<execute_document> with variables, program cache
hit): C<192k/s> with varying variable values; C<199k-325k/s> across the
nested-object, list, and abstract query shapes.

=item *

B<Direct JSON responses>: C<execute_document_to_json> C<463k/s>;
C<execute_bundle_to_json> C<894k/s> on the same list-of-objects shape.

=item *

B<Persisted native bundles> (C<execute_bundle>, fixed query):
C<611k-683k/s> across the same shapes.

=item *

B<Async lane> (20-item x 3-field list, resolvers returning pre-resolved
C<Promise::XS> promises): C<60k/s> for a whole-list promise (the
DataLoader "promise of array" shape) against C<97k/s> for the identical
query on the sync lane - within C<1.6x> and still narrowing. Direct JSON
on the async lane runs at C<63k/s>; one promise per item at C<29k/s>.

=back

=head2 Compared with graphql-perl

Same machine, same 20-item x 3-field list-of-objects query, both sides
executing to a JSON response. C<util/execution-benchmark.pl> runs the
upstream lanes automatically when a C<graphql-perl> checkout sits next
to this repository:

    graphql-perl, query string each request        5.0k/s
    graphql-perl, pre-parsed AST + reused schema    23k/s
    GraphQL::Houtou execute_document_to_json       463k/s
    GraphQL::Houtou execute_bundle_to_json         894k/s

Against upstream's fastest configuration (pre-parsed AST), the dynamic
document lane is roughly C<20x> and persisted bundles roughly C<39x>.
The async lane - resolvers returning promises, which upstream's executor
resolves through its own promise plumbing - still clears upstream's sync
numbers by more than C<2x>.

For methodology and reproducible commands, see
C<docs/execution-benchmark.md>.

=head1 CAVEATS

=head2 Supported execution profile

Version 0.01 supports GraphQL queries and mutations. Subscription syntax,
schema roots, introspection, and document validation are supported, but
subscription execution and streaming transports are not. Attempting to
execute a subscription fails closed with a C<SUBSCRIPTION_NOT_SUPPORTED>
request error.

The PSGI adapter accepts GraphQL execution requests over POST. GET query
execution, C<@defer>, C<@stream>, WebSocket/SSE subscriptions, a Federation
Gateway/Router, and generic promise adapters are outside the 0.01 profile.
Federation 2 subgraph execution is provided by
L<GraphQL::Houtou::Federation>. Only C<Promise::XS> promises are recognized.

Fixed native bundles are for variable-free queries. Use compiled native
programs for persisted queries that accept variables.

=head2 Perl ithreads are not supported

The runtime keeps request and schema state in C structures referenced by
opaque XS handles. Duplicating those raw pointers across C<ithreads> would
lead to double frees, so every handle class defines C<CLONE_SKIP>, making
thread clones drop them (they become C<undef> in the child thread) instead
of crashing. Use process-based concurrency (prefork PSGI servers or fork)
for parallelism.

=head1 SEE ALSO

=over 4

=item * L<GraphQL::Houtou::Schema> - schema construction and runtime factory

=item * L<GraphQL::Houtou::Runtime::NativeRuntime> - the request-time execution API

=item * L<GraphQL::Houtou::DataLoader> - bundled batching loader

=item * L<GraphQL::Houtou::PSGI> - GraphQL over HTTP endpoint

=item * L<GraphQL::Houtou::Federation> - Apollo Federation 2 subgraph support

=item * C<docs/> in the distribution - architecture, benchmarks, and design history

=item * C<docs/production-deployment.md> - prefork deployment and operations checklist

=back

=head1 NAME ORIGIN

The name C<Houtou> comes from several overlapping references:

=over 4

=item *

Japanese C<hotou> / "treasured sword" (宝刀)

=item *

Yamanashi's noodle dish C<houtou> (ほうとう)

=item *

the VTuber C<宝灯桃汁> (Houtou Momojiru)

=back

=head1 ACKNOWLEDGEMENTS

GraphQL::Houtou is strongly influenced by GraphQL for Perl
(C<graphql-perl>). We gratefully acknowledge its design and implementation
as an important foundation for this project. See
L<GraphQL on MetaCPAN|https://metacpan.org/pod/GraphQL> and the
L<graphql-perl source repository|https://github.com/graphql-perl/graphql-perl>.

=head1 LICENSE

Copyright (C) anatofuz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

anatofuz E<lt>anatofuz@gmail.comE<gt>

=cut
