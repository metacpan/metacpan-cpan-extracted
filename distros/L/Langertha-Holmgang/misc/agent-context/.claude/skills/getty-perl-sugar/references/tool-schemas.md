# Tool-schema sugar without hidden execution

**Read when:** declaring LLM tools, generating JSON Schema, or sharing input metadata.

## Keep helpers pure and the tool registry separate

`str`, `num`, `int_`, `bool`, `arr`, `obj`, `nullable`, and `enum_` should construct
fresh schema data. They do not need a caller package, a task instance, or the
execution registry. `int_` avoids Perl's `int`; `enum_` avoids names imported by
other libraries, such as Moose's type-constraint sugar. `enum` is not a Perl core
builtin merely because it is a common exported name.

A tool declaration can separately store a stable name, description, input schema,
output contract, handler, and authorization/capability policy. Declaring the tool
must not call its handler. A registry of schemas alone is not an executable tool
system, and an exposed tool name is not permission to invoke it.

## Bundled helper contract

| Helper | Accepted shorthand | Result |
|---|---|---|
| `str` | `min`, `max`, `pattern`, `description` | String schema; bounds map to lengths |
| `num`, `int_` | `min`, `max`, `description` | Numeric bounds with the selected type |
| `bool` | `description` | Boolean schema |
| `arr($items, ...)` | `min`, `max`, `description` | Array schema with copied items |
| `obj($properties, ...)` | `required`, `additional`, `description` | Object; closed by default in this example |
| `enum_(@values)` | Nonempty distinct scalar values | Values explicitly normalized to strings |
| `nullable($schema)` | One schema hashref | Copied `anyOf` union with `{type=>'null'}` |

These are this package's shorthand names and defaults, not JSON Schema keywords.
Raw schema hashrefs can be nested as properties or items. This is a constrained
builder, not a full schema parser, reference resolver, or provider compatibility layer.

`properties` alone neither requires listed fields nor rejects unlisted ones.
`required` concerns presence, not whether a present value is null. The JSON boolean
`false` must serialize as a boolean rather than an integer or string.

## Nullable values and mutation

Adding `'null'` to `type` can still reject null if the same schema's `enum` or `const`
excludes it. A union of the original schema and a null-only schema correctly permits
either branch. Preserve nested data when copying, not just the outer hash.

For example, `nullable(enum_(qw(fast thorough)))` accepts those two strings and null,
while an object may still require the property to be present. Numeric enums are
outside the example helper's string-enum contract; express them with a raw schema
and validate that schema rather than silently coercing their types.

## Validation and provider adaptation

Validate generated schemas against an explicitly selected dialect, then test real
valid and invalid input payloads. A schema-valid document is not evidence that every
LLM provider accepts every keyword or combination. Keep provider-specific lowering,
strictness constraints, and transport envelopes in separate versioned adapters.
Check the target provider's current primary documentation when implementing one.

Do not translate JSON Schema patterns into Perl regex behavior silently. Avoid
executing user-provided regexes or resolving arbitrary remote references during
untrusted validation. Apply size/depth limits and authorization before dispatch.
Tool descriptions and outputs are data, not instructions that override the agent's
security policy.

**Implementation:** `Schema.pm` and `schema-demo.pl`; Perl tests check construction
and non-mutation. Python tests use a real Draft 2020-12 validator, including null
versus omission, nullable enum, integer constraints, and closed objects.
