# ADR 0017 — `Response.created` is a `Langertha::Moment` value object, not a Unix-epoch `Int`

- Status: accepted
- Date: 2026-08-23
- Tags: response, value-objects, time, ollama, dependencies, moose

## Context

`Langertha::Response->created` was declared `Maybe[Int]` — "Unix timestamp (seconds since the
epoch)" — for its whole life. It has exactly **two producers** in the distribution:

| Producer | What the provider sends |
|---|---|
| `Role::OpenAICompatible::chat_response` (line 370) | `created` — an epoch integer |
| `Engine::Ollama::chat_response` (line 321) | `created_at` — RFC3339 with nanoseconds, e.g. `2026-05-05T02:53:03.138043625Z` |

and seven `Langertha::Response->new` call sites overall, five of which never set it at all.

The second producer never fit the type. **GitHub issue #3** (reported 2026-05-05 by *heince*)
is the user-facing consequence: every non-streaming Ollama chat died in the constructor, not
in the HTTP call —

```
Attribute (created) does not pass the type constraint because:
Validation failed for "Maybe[Int]" with value 2026-05-05T02:53:03.138043625Z
  at constructor Langertha::Response::new
```

It stayed open four months. The suite was green throughout because
`t/64_tool_calling_ollama_mock.t` drives `chat_with_tools_f`, and `Role::Tools` works on the
raw `parse_response` HashRef — it never builds a `Langertha::Response`. Only the live,
key-gated tests exercise the croaking path (karr #101 is the general form of that gap).

### The decision this ADR reverses

karr **#92** found the same defect independently on 2026-08-17 and fixed it in commit
`a20f9a6` — **in the engine, deliberately, with the widening of `Response.created` written
down as rejected**:

> Widening `Response.created` was rejected: `created` has exactly two producers
> (`Role::OpenAICompatible` with an epoch Int, and Ollama), so a coercion at the value
> object would buy nothing and would either loosen the type for all 7 `Response->new`
> call sites or need a subtype nobody else uses.

with **ADR 0011** cited as the governing precedent: the engine normalizes, the `Response`
attribute stays engine-agnostic, and the provider's native form stays reachable under `raw` —
the same normalized-plus-native split the `*_seconds` timing keys use.

That fix worked. `Engine::Ollama::_created_at_to_epoch` (45 lines) parsed RFC3339 by hand,
converted offsets, rejected the pre-1000 band (Ollama emits Go's zero `time.Time`,
`0001-01-01T00:00:00Z`, as its "no timestamp" sentinel), numified epoch-shaped values from
Ollama-compatible shims, and dropped the field on anything else so a bad stamp could never
kill a good response. All of that behaviour is worth keeping, and is kept.

**What it cost** is what reopened the question:

- The hand-rolled regex matched the fraction in a **non-capturing** group,
  `(?: \. [0-9]+ )?`. The nanoseconds Ollama actually sends were parsed and thrown away —
  the framework's most precise timestamp source was flattened to whole seconds by the code
  that was supposed to rescue it.
- 45 lines of date parsing sat in an engine class. That is precisely the shape ADR 0001
  removed from the engines for tools: an engine should carry configuration, not wire
  translation.

The maintainer decision of 2026-08-23 (karr **#119**, triggered by karr #117 / GH #3 reaching
the top of the queue) overrules the karr #92 reasoning and moves the parse into a value
object with a wider type. This ADR records that reversal and why the earlier argument does
not survive it.

## Decision

### 1. `Langertha::Moment` — a `Time::Moment` subclass carrying an overload set

`lib/Langertha/Moment.pm` subclasses `Time::Moment` and inherits its entire API (nanosecond
resolution, UTC offsets, comparison, arithmetic). What it *adds* is the overload set that
lets the object sit where a plain Unix timestamp used to:

| Overload | Yields | Why declared |
|---|---|---|
| `0+` | `->epoch` — whole seconds | **The back-compat contract.** Not inherited: `Time::Moment` overloads `""` but *not* `0+`, so a plain `Time::Moment` numifies through its string form and evaluates to its **year**. This alone is why a subclass exists rather than the parent being used directly. |
| `""` | `->to_string` — full ISO-8601, sub-seconds included | Same as the inherited one, declared explicitly so the pair "`0+` is the epoch, `""` is the stamp" is this class's own contract and cannot silently follow a change in the parent. |
| `<=>` | `compare()` against another `Time::Moment`, `epoch <=>` against a number | The inherited overload **dies** on a non-`Time::Moment` operand — which is exactly what `$response->created > $cutoff` written against the old `Int` passes it. |
| `cmp` | ISO-string comparison | |
| `bool` | constant true | Perl would otherwise derive `bool` from `0+`, making the epoch-0 moment — a real instant — false. Same call `Langertha::Response` makes for itself (karr #100). |
| `TO_JSON` | the epoch **number** | See decision 4. |

`fallback => 1`, so everything else derives.

### 2. `Response.created` is `Maybe[Langertha::Moment]`, normalized in `BUILDARGS`

The attribute type is a class, not a scalar type. `around BUILDARGS` runs every incoming
value through `Langertha::Moment->from_wire` before it reaches the type constraint:

```perl
if ( exists $params->{created} ) {
  my $moment = Langertha::Moment->from_wire( $params->{created} );
  if ( defined $moment ) { $params->{created} = $moment }
  else                   { delete $params->{created} }
}
```

`from_wire` is the **one lenient inbound door**, and it never dies. It accepts an existing
`Langertha::Moment` unchanged, any other `Time::Moment` (re-parsed losslessly from its
canonical string), an epoch number or digit string, or an ISO-8601/RFC3339 string parsed with
`from_string(..., lenient => 1)`. `lenient` is chosen rather than defaulted: it is what makes
the new door accept the same set the hand-rolled regex accepted (a space instead of the `T`,
an offset written without its colon, lowercase `t`/`z`) without widening it to non-timestamps
— bare `2026` and `2026-02-22` are still rejected either way.

Everything else — and the pre-1000 sentinel band — returns `undef`, and an `undef` **deletes
the key** rather than setting it. `has_created` is then false and the response is built
regardless. A timestamp is metadata; it must never be able to take a whole provider reply
down with it. That is the GH #3 failure mode, and it is now structurally impossible rather
than avoided by one engine.

Every karr #92 hardening survives, moved rather than rewritten: epoch-shaped shim values,
the `0001-01-01T00:00:00Z` zero-value sentinel, unreadable stamps dropping the field.

### 3. The parse belongs to the value object, not to the engine

`Engine::Ollama::_created_at_to_epoch` is deleted and the engine hands the wire value over
verbatim:

```perl
defined $data->{created_at} ? ( created => $data->{created_at} ) : (),
```

The engine loses 45 lines and its `use Time::Local`. This is **ADR 0001's rule applied to the
inbound half of a non-tool field**: the value object owns the wire translation, the engine
carries no per-shape code. It does not weaken ADR 0011 — the normalized-plus-native split is
intact, the native string still sits untouched under `raw.created_at` (and `raw.created` on
the OpenAI-compatible wire). What moved is *where* the normalization runs, not whether it
happens.

### 4. The number stays the number wherever the field is an interop surface

Two places emit `created` into a structure, and both keep emitting a JSON number:

- `Response::to_hash` numifies deliberately: `created => 0 + $self->created`. The bounded
  Response hash (karr #50) is the interop shape, and this key has been a number since it
  existed. The sub-seconds stay on the object and under `raw`; they were never in this hash.
- `Langertha::Moment::TO_JSON` returns `0 + $_[0]->epoch`, so a moment a caller drops into a
  structure of their own encodes as a number too, under `convert_blessed`.

**`TO_JSON` is an override, not an addition** — `Time::Moment` ships its own, and it returns
the ISO-8601 **string**. Inheriting it would have been the quieter of the two possible bugs:
no error anywhere, just a field silently changing from number to string in every trace, log
and Langfuse payload that carries a response. Locked by `t/91_response_created.t`
(`isnt($created->TO_JSON, $GH3_STAMP, 'Time::Moment::TO_JSON (the ISO string) is overridden,
not inherited')`).

### 5. `Langertha::Moment` is deliberately **not** a Moose class

This is the distribution's one documented exception to the "Moose exclusively, always
`make_immutable`" house rule, and it is asserted by the suite rather than only commented:

```perl
ok(!Langertha::Moment->can('meta'),      'no Moose metaclass');
ok(!Langertha::Moment->can('BUILDARGS'), 'no Moose constructor hooks');
is(reftype(Langertha::Moment->from_epoch(0)), 'SCALAR',
  'instances are the parent XS SCALARs, not Moose hashrefs');
```

`Time::Moment` is XS. Its instances are blessed **SCALARs** holding an opaque struct, and
every constructor (`from_string`, `from_epoch`, `now`) as well as every derivation
(`plus_days`, `with_offset_same_instant`) blesses into the invocant's class **from inside
XS** — never through `Moose::Object::new`. A metaclass laid over that would describe an
object system nothing here uses: `make_immutable` would inline a constructor no code path
calls, and Moose's default hash-based meta-instance does not fit a blessed SCALAR at all.

**`MooseX::NonMoose` was considered and rejected.** It is already a dependency (used by
`Langertha::Request::HTTP`), so the cost would have been zero — but it exists to give a Moose
class Moose *attributes* on top of a foreign parent, by routing `Moose::Object::new` through
`FOREIGNBUILDARGS` into the parent's `new`. This class adds no attributes, and the
constructors that matter (`from_string` / `from_epoch` / `from_wire`) bypass `new` entirely.
NonMoose would add a metaclass, a wrapped `new` nobody calls, and a hash-instance assumption
that is false, in exchange for nothing.

Subclassing is simply the only way to attach an overload set to `Time::Moment` without
polluting every other consumer of it in the process.

## Rationale

### Why the karr #92 argument does not survive

Its three claims, one at a time:

- **"A coercion at the value object would buy nothing."** True only if the destination stays
  a number. The claim silently assumed the destination type was right and the input was
  wrong. The actual defect was the reverse: `Maybe[Int]` was too narrow for the wire it had
  to accept, and the engine-side conversion bought compatibility by *destroying* the extra
  precision — the nanoseconds — that the wider provider was volunteering.
- **"Would loosen the type for all 7 `Response->new` call sites."** It does not. The type is
  *narrowed*, from a scalar type to a class; the leniency lives in `BUILDARGS`, the one gate
  every call site passes through, and is bounded by `from_wire`'s accept list. No call site
  can now pass something that reaches the attribute unvalidated — the opposite of loosening.
- **"Two producers, so it is not worth it."** Producer count is the right argument against a
  heavy *dependency* (see below) and no argument at all about *where the parse lives*.
  ADR 0001's rule is about ownership, not about consumer arithmetic: the engine should not
  own a date parser any more than it should own `format_tools`.

**ADR 0011 is not reversed by this ADR.** karr #92 read 0011 as "normalize to a scalar, in
the engine". 0011's actual split is *engine-agnostic value* vs *engine-native form*, and both
halves are still exactly where 0011 put them: the agnostic value on the `Response` attribute,
the native string verbatim under `raw`. A value object is a normalized value; it is not a
native stage key.

### Why `Time::Moment` — measured against the real GH #3 stamp, not asserted

| Candidate | Result on `2026-05-05T02:53:03.138043625Z` | Verdict |
|---|---|---|
| `Time::Piece` (Core) | `strptime` fails outright — "Error parsing time". No sub-second support at all, and `tzoffset` reads 0, so the offset is lost even when a stamp does parse. | Cannot do the job. |
| `DateTime` | Parses everything, named zones, DST arithmetic — everything wanted and more. Not Core, and pulls `DateTime::Locale`, `DateTime::TimeZone`, `Params::ValidationCompiler`, `Specio`. | Correct but far too heavy for a field with two producers. |
| `Time::Moment` | Parses the stamp directly, keeps the full 138043625 nanoseconds, round-trips byte for byte. Runtime needs only `XSLoader` and `Carp` (Core) plus `Time::HiRes` — **already in the cpanfile**. | Chosen. |

`Time::Moment` costs exactly **one cpanfile line and zero new transitive runtime
dependencies**. XS was not a new barrier: `YAML::XS` is already runtime-required. (The change
also closes an old cpanfile gap by accident — `Time::Local` was never listed although
`Engine::Ollama` used it, being Core; the rewrite dropped the `use`.)

The subclassing itself was **prototyped before implementation**, because subclassing an XS
class that blesses from inside XS is not something to assume: `from_string` returns the
subclass, `0 + $moment` yields `1777949583`, and inherited derivations (`plus_days`) return
the subclass too, so the overloads do not evaporate on the first arithmetic operation. That
is now a regression test rather than a prototype note.

### The give-up, named as such

`Time::Moment` has **no named time zones and no DST arithmetic**. This is accepted, not
overlooked. It is tenable because every provider in the distribution stamps `created` either
in UTC (`Z`) or as a bare epoch integer — without exception today.

**This is the assumption that would flip this ADR.** Two distinct ways it can break:

1. A provider begins sending a stamp with a **real non-zero offset**. `from_wire` preserves
   it correctly and `<=>` still orders by instant, but `cmp` compares ISO strings — so string
   ordering stops agreeing with instant ordering across differently-offset stamps.
2. A consumer needs a **named zone or DST-aware calendar arithmetic** on a provider stamp.
   `Time::Moment` cannot do it at any price; that is the case in which the `DateTime` row of
   the table above has to be re-read with a different answer.

Neither is speculative work today. Both are the reasons this paragraph exists.

### Why one object rather than an attribute pair

The obvious cheaper fix — keep the `Int` and hang a `created_nanoseconds` beside it — was not
taken. One value means one object; a second field would give consumers two places to look, a
"which one is authoritative" question on every read, and a third state (nanoseconds present,
epoch absent) that means nothing. The provider's own form stays reachable under `raw` for
anybody who wants the bytes.

## Consequences

**Unchanged** — every numeric idiom written against the old `Int` still returns exactly what
it returned:

```perl
0 + $response->created                  # 1777949583
$response->created == 1777949583        # true
$response->created > $cutoff            # as before — and no longer dies, see the '<=>' row
sprintf '%d', $response->created        # 1777949583
sort { $a->created <=> $b->created } @responses
looks_like_number($response->created)   # still true, via 0+
$response->to_hash->{created}           # a plain number, as it always was
```

**Changed** — four idioms do not survive the move to an object, and they are the release-note
surface:

- **String context is the stamp, not the digits.** `"$response->created"` interpolates
  `2026-05-05T02:53:03.138043625Z`. `eq` against the epoch digits is now false, a hash keyed
  by `created` re-keys itself, and `Data::Dumper` prints a blessed scalar. This is the point
  of the change, not a side effect — the string form is where the sub-seconds live.
- **`ref` and `blessed` are no longer empty.** Code branching on "is this field a reference"
  takes the other path.
- **A JSON encoder without `convert_blessed` dies on it** — the same way it already dies on
  `usage`, `tool_calls` and `rate_limit`, which have been objects for longer. With
  `convert_blessed` it is the epoch number (decision 4). `Response::to_hash` and the
  `Response`'s own `TO_JSON` are unaffected. Note the shape of this break: it is the GH #3
  failure mode moved from the framework's constructor to a caller's own encoder.
- **Boolean context at epoch 0 is now true**, where the old `Int` `0` was false.
  `has_created` remains the predicate for "did the provider report a stamp at all" and is
  unaffected.

Further:

- **`Time::Moment` becomes a runtime dependency.** One line in `cpanfile`; no new transitive
  runtime deps.
- **Ollama's nanoseconds now survive the whole path.** The GH #3 reporter's stamp goes in and
  comes back out byte-identical — the precision the karr #92 fix silently discarded.
- **The distribution now has one deliberate, test-asserted exception to "Moose exclusively".**
  A well-meant "convert this to Moose" is caught by `t/91_response_created.t`, not by a user.
- **Test coverage.** `t/91_response_created.t` (13 subtests) covers the value object, the
  overload contract, the non-Moose assertion, the `from_wire` accept/reject matrix, the GH #3
  end-to-end path and the JSON surface. The karr #92 hardenings stay locked in
  `t/70_response.t` against the real captured server fixtures.
- **Cross-links.** **ADR 0001** — value objects own the wire translation; this is that rule
  applied to the inbound half of a non-tool field. **ADR 0011** — reaffirmed, not reversed:
  normalized value on the `Response`, native form under `raw`; what this ADR corrects is
  karr #92's reading of it as "a scalar, converted in the engine". **ADR 0003** — the same
  instinct on the response side: one canonical shape per field, no parallel representations.
- **`CONTEXT.md`** gains **Langertha::Moment** and **`from_wire`** under "Response-side
  observability (sibling seams)" — vocabulary only; the reasoning stays here.

## Future work

- karr **#119** (in review) — the implementation ticket. Two things remain open on it and
  neither is a design question: `Time::Moment` is not installed on the maintainer machine, so
  the suite cannot run there until it is, and the two new files need `git add -N` so
  `Git::GatherDir` sees them in a `dzil` build.
- karr **#120** — `Role::JSON::_build__json` builds `JSON::MaybeXS->new(utf8 => 1, canonical
  => 1)` with **no** `convert_blessed`, while six value objects' POD calls `convert_blessed`
  "the house default". `$engine->json->encode` therefore dies on a `Langertha::Moment`, as it
  already would on a `Usage` or a `ToolCall`. Latent today; deliberately not fixed as a
  drive-by inside this change, because it touches the encoder every engine builds every
  request with.
- karr **#121** — `RateLimit.requests_reset` / `tokens_reset` are `Maybe[Str]` documented as
  holding "seconds, RFC 3339 timestamp, or epoch". Same untyped-wire-value shape as the old
  `created`, but the shapes are not all the same *kind*: a bare `60` is a duration, and
  `from_wire` would turn it into an instant in 1970. Any fix has to decide "when" vs "in how
  long" first — `Langertha::Moment` is not a drop-in there.
