# NAME

JSON::Schema::Validate - Lean, recursion-safe JSON Schema validator (Draft 2020-12)

# SYNOPSIS

    use JSON::Schema::Validate;
    use JSON ();

    my $schema = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id'     => 'https://example.org/s/root.json',
        type      => 'object',
        required  => [ 'name' ],
        properties => {
            name => { type => 'string', minLength => 1 },
            next => { '$dynamicRef' => '#Node' },
        },
        '$dynamicAnchor' => 'Node',
        additionalProperties => JSON::false,
    };

    my $js = JSON::Schema::Validate->new( $schema )
        ->compile
        ->content_checks
        ->ignore_unknown_required_vocab
        ->register_builtin_formats
        ->trace
        ->trace_limit(200); # 0 means unlimited

    my $ok = $js->validate({ name => 'head', next=>{ name => 'tail' } })
        or die( $js->error );

    print "ok\n";

# VERSION

v0.2.0

# DESCRIPTION

`JSON::Schema::Validate` is a compact, dependency-light validator for [JSON Schema](https://json-schema.org/) draft 2020-12. It focuses on:

- Correctness and recursion safety (supports `$ref`, `$dynamicRef`, `$anchor`, `$dynamicAnchor`).
- Draft 2020-12 evaluation semantics, including `unevaluatedItems` and `unevaluatedProperties` with annotation tracking.
- A practical Perl API (constructor takes the schema; call `validate` with your data; inspect `error` / `errors` on failure).
- Builtin validators for common `format`s (date, time, email, hostname, ip, uri, uuid, JSON Pointer, etc.), with the option to register or override custom format handlers.

This module is intentionally minimal compared to large reference implementations, but it implements the parts most people rely on in production.

## Supported Keywords (2020-12)

- Types

    `type` (string or array of strings), including union types. Unions may also include inline schemas (e.g. `type => [ 'integer', { minimum => 0 } ]`).

- Constant / Enumerations

    `const`, `enum`.

- Numbers

    `multipleOf`, `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`.

- Strings

    `minLength`, `maxLength`, `pattern`, `format`.

- Arrays

    `prefixItems`, `items`, `contains`, `minContains`, `maxContains`,
    `uniqueItems`, `unevaluatedItems`.

- Objects

    `properties`, `patternProperties`, `additionalProperties`, `propertyNames`, `required`, `dependentRequired`, `dependentSchemas`, `unevaluatedProperties`.

- Combinators

    `allOf`, `anyOf`, `oneOf`, `not`.

- Conditionals

    `if`, `then`, `else`.

- Referencing

    `$id`, `$anchor`, `$ref`, `$dynamicAnchor`, `$dynamicRef`.

## Formats

Call `register_builtin_formats` to install default validators for the following `format` names:

- `date-time`, `date`, `time`, `duration`

    Leverages [DateTime](https://metacpan.org/pod/DateTime) and [DateTime::Format::ISO8601](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AISO8601) when available (falls back to strict regex checks). Duration uses [DateTime::Duration](https://metacpan.org/pod/DateTime%3A%3ADuration).

- `email`, `idn-email`

    Uses [Regexp::Common](https://metacpan.org/pod/Regexp%3A%3ACommon) with `Email::Address` if available.

- `hostname`, `idn-hostname`

    `idn-hostname` uses [Net::IDN::Encode](https://metacpan.org/pod/Net%3A%3AIDN%3A%3AEncode) if available; otherwise, applies a permissive Unicode label check and then `hostname` rules.

- `ipv4`, `ipv6`

    Strict regex-based validation.

- `uri`, `uri-reference`, `iri`

    Reasonable regex checks for scheme and reference forms (heuristic, not a full RFC parser).

- `uuid`

    Hyphenated 8-4-4-4-12 hex.

- `json-pointer`, `relative-json-pointer`

    Conformant to RFC 6901 and the relative variant used by JSON Schema.

- `regex`

    Checks that the pattern compiles in Perl.

Custom formats can be registered or override builtins via `register_format` or the `format => { ... }` constructor option (see ["METHODS"](#methods)).

# CONSTRUCTOR

## new

    my $js = JSON::Schema::Validate->new( $schema, %opts );

Build a validator from a decoded JSON Schema (Perl hash/array structure), and returns the newly instantiated object.

Options (all optional):

- `compile => 1|0`

    Defaults to `0`

    Enable or disable the compiled-validator fast path.

    When enabled and the root has not been compiled yet, this triggers an initial compilation.

- `content_assert => 1|0`

    Defaults to `0`

    Enable or disable the content assertions for the `contentEncoding`, `contentMediaType` and `contentSchema` trio.

    When enabling, built-in media validators are registered (e.g. `application/json`).

- `format => \%callbacks`

    Hash of `format_name => sub{ ... }` validators. Each sub receives the string to validate and must return true/false. Entries here take precedence when you later call `register_builtin_formats` (i.e. your callbacks remain in place).

- `ignore_unknown_required_vocab => 1|0`

    Defaults to `0`

    If enabled, required vocabularies declared in `$vocabulary` that are not advertised as supported by the caller will be _ignored_ instead of causing the validator to `die`.

    You can also use `ignore_req_vocab` for short.

- `max_errors`

    Defaults to `200`

    Sets the maximum number of errors to be recorded.

- `normalize_instance => 1|0`

    Defaults to `1`

    When true, the instance is round-tripped through [JSON](https://metacpan.org/pod/JSON) before validation, which enforces strict JSON typing (strings remain strings; numbers remain numbers). This matches Python `jsonschema`’s type behaviour. Set to `0` if you prefer Perl’s permissive numeric/string duality.

- `trace`

    Defaults to `0`

    Enable or disable tracing. When enabled, the validator records lightweight, bounded trace events according to ["trace\_limit"](#trace_limit) and ["trace\_sample"](#trace_sample).

- `trace_limit`

    Defaults to `0`

    Set a hard cap on the number of trace entries recorded during a single `validate` call (`0` = unlimited).

- `trace_sample => $percent`

    Enable probabilistic sampling of trace events. `$percent` is an integer percentage in `[0,100]`. `0` disables sampling. Sampling occurs per-event, and still respects ["trace\_limit"](#trace_limit).

- `vocab_support => {}`

    A hash reference of support vocabularies.

# METHODS

## compile

    $js->compile;       # enable compilation
    $js->compile(1);    # enable
    $js->compile(0);    # disable

Enable or disable the compiled-validator fast path.

When enabled and the root hasn’t been compiled yet, this triggers an initial compilation.

Returns the current object to enable chaining.

## content\_checks

    $js->content_checks;     # enable
    $js->content_checks(1);  # enable
    $js->content_checks(0);  # disable

Turn on/off content assertions for the `contentEncoding`, `contentMediaType` and `contentSchema` trio.

When enabling, built-in media validators are registered (e.g. `application/json`).

Returns the current object to enable chaining.

## POD::Coverage enable\_content\_checks

## error

    my $msg = $js->error;

Returns the first error [JSON::Schema::Validate::Error](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate%3A%3AError) object out of all the possible errors found (see ["errors"](#errors)), if any.

When stringified, the object provides a short, human-oriented message for the first failure.

## errors

    my $array_ref = $js->errors;

All collected [error objects](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate%3A%3AError) (up to the internal `max_errors` cap).

## get\_trace

    my $trace = $js->get_trace; # arrayref of trace entries (copy)

Return a **copy** of the last validation trace (array reference of hash references) so callers cannot mutate internal state. Each entry contains:

    {
        inst_path  => '#/path/in/instance',
        keyword    => 'node' | 'minimum' | ...,
        note       => 'short string',
        outcome    => 'pass' | 'fail' | 'visit' | 'start',
        schema_ptr => '#/path/in/schema',
    }

## get\_trace\_limit

    my $n = $js->get_trace_limit;

Accessor that returns the numeric trace limit currently in effect. See ["trace\_limit"](#trace_limit) to set it.

## ignore\_unknown\_required\_vocab

    $js->ignore_unknown_required_vocab;     # enable
    $js->ignore_unknown_required_vocab(1);  # enable
    $js->ignore_unknown_required_vocab(0);  # disable

If enabled, required vocabularies declared in `$vocabulary` that are not advertised as supported by the caller will be _ignored_ instead of causing the validator to `die`.

Returns the current object to enable chaining.

## is\_compile\_enabled

    my $bool = $js->is_compile_enabled;

Read-only accessor.

Returns true if compilation mode is enabled, false otherwise.

## is\_content\_checks\_enabled

    my $bool = $js->is_content_checks_enabled;

Read-only accessor.

Returns true if content assertions are enabled, false otherwise.

## is\_trace\_on

    my $bool = $js->is_trace_on;

Read-only accessor.

Returns true if tracing is enabled, false otherwise.

## is\_unknown\_required\_vocab\_ignored

    my $bool = $js->is_unknown_required_vocab_ignored;

Read-only accessor.

Returns true if unknown required vocabularies are being ignored, false otherwise.

## register\_builtin\_formats

    $js->register_builtin_formats;

Registers the built-in validators listed in ["Formats"](#formats). Existing user-supplied format callbacks are preserved if they already exist under the same name.

User-supplied callbacks passed via `format => { ... }` are preserved and take precedence.

## register\_content\_decoder

    $js->register_content_decoder( $name => sub{ ... } );

Register a content **decoder** for `contentEncoding`. The callback receives a single argument: the raw data, and should return one of:

- a decoded scalar (success);
- `undef` (failure);
- or the triplet `( $ok, $msg, $out )` where `$ok` is truthy on success,
`$msg` is an optional error string, and `$out` is the decoded value.

The `$name` is lower-cased internally. Returns the current object.

Throws an exception if the second argument is not a code reference.

## register\_format

    $js->register_format( $name, sub { ... } );

Register or override a `format` validator at runtime. The sub receives a single scalar (the candidate string) and must return true/false.

## register\_media\_validator

    $js->register_media_validator( 'application/json' => sub{ ... } );

Register a media **validator/decoder** for `contentMediaType`. The callback receives 2 arguments:

- `$bytes`

    The data to validate

- `\%params`

    A hash reference of media-type parameters (e.g. `charset`).

It may return one of:

- `( $ok, $msg, $decoded )` — canonical form. On success `$ok` is true, `$msg` is optional, and `$decoded` can be either a Perl structure or a new octet/string value.
- a reference — treated as success with that reference as `$decoded`.
- a defined scalar — treated as success with that scalar as `$decoded`.
- `undef` or empty list — treated as failure.

The media type key is lower-cased internally.

It returns the current object.

It throws an exception if the second argument is not a code reference.

## set\_comment\_handler

    $js->set_comment_handler(sub
    {
        my( $schema_ptr, $text ) = @_;
        warn "Comment at $schema_ptr: $text\n";
    });

Install an optional callback for the Draft 2020-12 `$comment` keyword.

`$comment` is annotation-only (never affects validation). When provided, the callback is invoked once per encountered `$comment` string with the schema pointer and the comment text. Callback errors are ignored.

If a value is provided, and is not a code reference, a warning will be emitted.

This returns the current object.

## set\_resolver

    $js->set_resolver( sub { my( $absolute_uri ) = @_; ...; return $schema_hashref } );

Install a resolver for external documents. It is called with an absolute URI (formed from the current base `$id` and the `$ref`) and must return a Perl hash reference representation of a JSON Schema. If the returned hash contains `'$id'`, it will become the new base for that document; otherwise, the absolute URI is used as its base.

## set\_vocabulary\_support

    $js->set_vocabulary_support( \%support );

Declare which vocabularies the host supports, as a hash reference:

    {
        'https://example/vocab/core' => 1,
        ...
    }

Resets internal vocabulary-checked state so the declaration is enforced on next `validate`.

It returns the current object.

## trace

    $js->trace;    # enable
    $js->trace(1); # enable
    $js->trace(0); # disable

Enable or disable tracing. When enabled, the validator records lightweight, bounded trace events according to ["trace\_limit"](#trace_limit) and ["trace\_sample"](#trace_sample).

It returns the current object for chaining.

## trace\_limit

    $js->trace_limit( $n );

Set a hard cap on the number of trace entries recorded during a single `validate` call (`0` = unlimited).

It returns the current object for chaining.

## trace\_sample

    $js->trace_sample( $percent );

Enable probabilistic sampling of trace events. `$percent` is an integer percentage in `[0,100]`. `0` disables sampling. Sampling occurs per-event, and still respects ["trace\_limit"](#trace_limit).

It returns the current object for chaining.

## validate

    my $ok = $js->validate( $data );

Validate a decoded JSON instance against the compiled schema. Returns a boolean.
On failure, inspect `$js->error` to retrieve the [error object](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate%3A%3AError) that stringifies for a concise message (first error), or `$js->errors` for an array reference of [error objects](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate%3A%3AError) like:

    my $err = $js->error;
    say $err->path; # #/properties~1name
    say $err->message; # string shorter than minLength 1
    say "$err"; # error object will stringify

# BEHAVIOUR NOTES

- Recursion & Cycles

    The validator guards on the pair `(schema_pointer, instance_address)`, so self-referential schemas and cyclic instance graphs won’t infinite-loop.

- Union Types with Inline Schemas

    `type` may be an array mixing string type names and inline schemas. Any inline schema that validates the instance makes the `type` check succeed.

- Booleans

    For practicality in Perl, `type => 'boolean'` accepts JSON-like booleans (e.g. true/false, 1/0 as strings) as well as Perl boolean objects (if you use a boolean class). If you need stricter behaviour, you can adapt `_match_type` or introduce a constructor flag and branch there.

- Unevaluated\*

    Both `unevaluatedItems` and `unevaluatedProperties` are enforced using annotation produced by earlier keyword evaluations within the same schema object, matching draft 2020-12 semantics.

- RFC rigor and media types

    [URI](https://metacpan.org/pod/URI)/`IRI` and media‐type parsing is intentionally pragmatic rather than fully RFC-complete. For example, `uri`, `iri`, and `uri-reference` use strict but heuristic regexes; `contentMediaType` validates UTF-8 for `text/*; charset=utf-8` and supports pluggable validators/decoders, but is not a general MIME toolkit.

- Compilation vs. Interpretation

    Both code paths are correct by design. The interpreter is simpler and great while developing a schema; toggle `->compile` when moving to production or after the schema stabilises. You may enable compilation lazily (call `compile` any time) or eagerly via the constructor (`compile => 1`).

# WHY ENABLE `COMPILE`?

When `compile` is ON, the validator precompiles a tiny Perl closure for each schema node. At runtime, those closures:

- avoid repeated hash lookups for keyword presence/values;
- skip dispatch on absent keywords (branchless fast paths);
- reuse precompiled child validators (arrays/objects/combinators);
- reduce allocator churn by returning small, fixed-shape result hashes.

In practice this improves steady-state throughput (especially for large/branchy schemas, or hot validation loops) and lowers tail latency by minimising per-instance work. The trade-offs are:

- a one-time compile cost per node (usually amortised quickly);
- a small memory footprint for closures (one per visited node).

If you only validate once or twice against a tiny schema, compilation will not matter; for services, batch jobs, or streaming pipelines it typically yields a noticeable speedup. Always benchmark with your own schema+data.

# CREDITS

Albert from OpenAI for his invaluable help.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[perl](https://metacpan.org/pod/perl), [DateTime](https://metacpan.org/pod/DateTime), [DateTime::Format::ISO8601](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AISO8601), [DateTime::Duration](https://metacpan.org/pod/DateTime%3A%3ADuration), [Regexp::Common](https://metacpan.org/pod/Regexp%3A%3ACommon), [Net::IDN::Encode](https://metacpan.org/pod/Net%3A%3AIDN%3A%3AEncode), [JSON::PP](https://metacpan.org/pod/JSON%3A%3APP)

[JSON::Schema](https://metacpan.org/pod/JSON%3A%3ASchema), [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator)

[python-jsonschema](https://github.com/python-jsonschema/jsonschema),
[fastjsonschema](https://github.com/horejsek/python-fastjsonschema),
[Pydantic](https://docs.pydantic.dev),
[RapidJSON Schema](https://rapidjson.org/md_doc_schema.html)

# COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
