# Parser Internals

## Scope

This document describes the parser implementation in the current source tree.
It covers the public parser, the validation-only diagnostics path, location
tracking, resource limits, ownership, and the older internal parser helpers
that remain compiled but are not part of the public parser contract.

For the public AST contract, see `GraphQL::Houtou` and
`t/21_public_parser_api.t`. For repeatable measurements, use
`util/parser-benchmark.pl`.

## Public API and output shape

The public entry points are:

```perl
my $document = GraphQL::Houtou::parse($source);

my $document_without_locations = GraphQL::Houtou::parse_with_options(
  $source,
  { no_location => 1 },
);
```

`parse_with_options()` accepts only `no_location`. The old dialect and engine
selectors are not supported.

Both functions return the canonical Houtou AST: a graphql-perl-style arrayref
of definitions. It is made from ordinary Perl hashes, arrays, and scalar
values. For example, an executable operation has `kind => "operation"` and a
`selections` array. The public API does not return a graphql-js `Document`
node and does not expose a choice of AST dialect.

The call path is deliberately short:

```text
GraphQL::Houtou::parse / parse_with_options
  -> GraphQL::Houtou::XS::Parser::parse_xs
  -> gql_parse_document
  -> gql_parse_definitions
  -> recursive-descent definition/value/selection parsers
  -> Perl AST (AV/HV/SV)
```

`parse_xs()` is implemented in `lib/GraphQL/Houtou.xs`; the lexer and direct
AST builder are in `src/parser_graphqlperl_runtime.h`, with token and error
helpers in `src/parser_core.h`.

## Lexer and parser state

`gql_parser_t`, declared in `src/bootstrap.h`, is a stack-local cursor over a
borrowed source buffer. It records:

- source pointer, byte length, and current byte position;
- current token kind and token/value spans;
- whether the source scalar carries Perl's UTF-8 flag;
- the optional line-start index used for locations;
- recursive nesting depth and total token count;
- an optional validation diagnostics sink.

The parser does not copy the complete source. Token text is copied into an
`SV` only when it is needed in the returned AST or in an error. Punctuation
and lookahead are represented by offsets and token kinds.

The grammar is implemented as recursive descent. Definitions are parsed one
at a time and appended directly to the result `AV`; nodes and child
collections are constructed as their productions are recognized. There is no
second public-AST conversion pass.

## AST allocation

The public parser constructs its final result directly with Perl values:

- document and repeated children: `AV`;
- definitions, fields, directives, and other nodes: `HV`;
- names and scalar payloads: `SV`;
- the document return value: an array reference.

This creates many small Perl allocations, but avoids building a C tree and
then materializing the same tree again. It also lets schema compilation and
existing Perl callers consume the result without an adapter.

Because the parser returns mutable Perl data, callers that cache an AST must
treat it as immutable themselves or make an application-level copy before
modifying it.

## Locations

Unless `no_location` is true, `gql_parser_init()` scans the source once and
builds an array of line-start byte offsets. A node location is then calculated
from its token offset using that index and stored in graphql-perl form:

```perl
location => { line => 1, column => 3 }
```

Line and column numbers are one-based. `LF`, `CR`, and `CRLF` line endings are
handled, with `CRLF` counted as a single break.

The line-start array is registered with Perl's save stack. It is therefore
released by scope unwinding on both success and `croak`, including malformed
or adversarial documents. With `no_location => 1`, the initial source scan and
per-node location hashes are skipped; this is the preferred parser mode when
locations are not consumed.

## Errors and validation diagnostics

A syntax failure throws a blessed `GraphQL::Houtou::Error`. The message names
the expected token or unexpected input, and `locations` identifies the parser
position. Parser errors are exceptions at the parser API boundary; the
runtime and PSGI layers convert request failures into GraphQL error envelopes.

Validation has a separate internal entry point:

```text
_parse_with_diagnostics_xs
  -> gql_parse_document_for_validation
```

It returns the same canonical AST plus a diagnostics array used for checks
that are most efficient while parsing, such as duplicate names. The public
`parse()` path leaves `validation_errors` null, so this bookkeeping does not
add allocations to the ordinary parser hot path.

Parsing establishes grammatical structure. Executable-document validation,
schema validation, variable coercion, depth/node/cost policy, and execution
are later phases and should not be added to the public parser loop merely
because they inspect an AST.

## Resource limits

The native parser applies two compile-time safety ceilings before validation:

- `GQL_PARSER_MAX_DEPTH` defaults to 512 recursive selection/input-value
  levels. This protects the C stack from deeply nested hostile input.
- `GQL_PARSER_MAX_TOKENS` defaults to 1,000,000 tokens. This bounds flat input
  that would otherwise create an unbounded number of AST allocations.

Exceeding either limit raises a request error instead of terminating the
worker. These parser ceilings complement, rather than replace, the PSGI body
limit and runtime `max_depth`, `max_nodes`, and `max_cost` policies.

The constants can be overridden at build time, but changing them changes the
process-level exposure to untrusted documents and must be backed by stack and
memory measurements.

## Strings, block strings, and UTF-8

The lexer operates on byte offsets while preserving the source scalar's UTF-8
flag on values copied into Perl scalars. Regular string escapes and the
GraphQL `BlockStringValue` indentation algorithm are applied during parsing.
Coverage for escaped triple quotes, blank-line trimming, indentation, and
`CRLF` handling lives in `t/21_public_parser_api.t`.

Byte offsets are an internal detail. The public location contract is line and
column, and callers must not infer character offsets from internal spans.

## Internal files and retained machinery

The parser-related headers currently have these responsibilities:

- `src/bootstrap.h`: shared token, parser-state, location-context, and IR type
  declarations plus forward declarations;
- `src/parser_core.h`: token/error and shared location/rewrite helpers;
- `src/parser_graphqlperl_runtime.h`: public direct parser and canonical AST
  construction;
- `src/parser_shared_ast.h`: small constructors and sorted-hash-key helpers
  shared by parser/schema code;
- `src/parser_ast_runtime.h`: internal graphql-js-shaped AST and lazy
  materialization support;
- `src/parser_ir_runtime.h`: internal executable IR parsing/building and
  conversion helpers.

The last two headers reflect earlier parser and compatibility work. Some of
their helpers are still compiled and used by internal materialization code,
but they do not define the public `parse()` path or its return dialect. Do not
optimize, document, or extend them on the assumption that every request passes
through an IR arena: the current public parser does not.

`GraphQL::Houtou::Parser::Internal::LazyLoc` and the tied lazy-array classes
in `lib/GraphQL/Houtou/XS/Parser.pm` are likewise internal implementation
types. Applications must not construct them or rely on their storage layout.

## Performance work

Use `util/parser-benchmark.pl` to compare the location and no-location public
paths against the same input:

```console
perl -Iblib/lib -Iblib/arch util/parser-benchmark.pl \
  --file t/kitchen-sink.graphql --count -5
```

The benchmark labels retain `graphql_perl_*` because they describe the AST
shape, not a selectable engine.

Before changing representation, profile the complete parse workload. The
most plausible costs are final `HV`/`AV` allocation, scalar copying/unescaping,
and location construction. Replacing the final AST with a C tree is not an
automatic improvement: the public contract would still require
materialization, adding a conversion pass and a second live representation.

For changes to parser C code:

1. preserve the canonical AST contract in `t/21_public_parser_api.t`;
2. add adversarial cases to `t/51_parser_depth_limit.t`,
   `t/52_node_limit.t`, or `t/53_parser_adversarial.t` as appropriate;
3. run `minil test` and the ASan/fuzz robustness jobs for ownership-sensitive
   changes;
4. measure both location modes before claiming a performance improvement.
