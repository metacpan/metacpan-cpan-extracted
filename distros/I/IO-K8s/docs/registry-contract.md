# Complete k8s attribute registry contract — design

Status: design proposal (karr #28). Not implemented. This document specifies
the target contract so future work can move requiredness and element-level
type metadata into the registry instead of leaving them in Moo internals.

## 1. Why this exists

The `k8s` DSL in `IO::K8s::Resource` registers every attribute in
`%IO::K8s::Resource::_attr_registry` (class → attr → info hash). That
registry is the single source of truth for inflation, serialization
(`TO_JSON`), schema comparison (`compare_to_schema`) and the merged @ISA
views in `IO::K8s::Role::Resource` (`_k8s_attr_info` / `_k8s_attributes`).

Two pieces of metadata are NOT in the registry today, which forces tests and
tooling to reach into Moo:

1. **Requiredness.** `_k8s` passes `required => 1` to Moo's `has`, but the
   registry info hash carries no `required` flag. `t/42_registry_synthesis_roundtrip.t`
   reads it from `Moo->_constructor_maker_for($class)->all_attribute_specs`
   (line 136) instead.
2. **Complex array element types.** `_k8s`'s Type::Tiny array branch only
   recognises `Str`/`Int`/`Bool` as element types and sets
   `is_array_of_str` / `is_array_of_int` / `is_array_of_bool`. An array of
   `Quantity` or `Time` (e.g. `k8s validValues => [Quantity]` in
   `IO::K8s::Api::Resource::V1::CapacityRequestPolicy`) registers with no
   flags at all. `t/42` falls back to stringifying the Moo `isa` constraint
   (`isa_text_for`, line 155) to learn the element type.

## 2. Current registry entry shape

Per attribute, `_k8s` stores a hash with a subset of:

| key | meaning |
|---|---|
| `is_str` / `is_int` / `is_bool` | scalar type flags |
| `is_int_or_string` / `is_quantity` / `is_time` | special scalar types |
| `is_object` | single object reference |
| `is_array_of_str` / `is_array_of_int` / `is_array_of_bool` | scalar arrays |
| `is_array_of_objects` | array of class instances |
| `is_hash_of_str` / `is_hash_of_objects` | hash maps |
| `is_inline_struct` | inline struct (auto-generated inner class) |
| `class` | target class for object/array-of-objects/hash-of-objects |
| `json_key` | original JSON field name when it differs from the Perl attr |

## 3. Target contract

Extend the info hash with two fields, populated by `_k8s` at registration
time. Both are additive — existing consumers that ignore unknown keys keep
working, so this is not a breaking change.

### 3.1 `required` (Bool)

`_k8s` already computes `$required` (from the `!` suffix or the
`required` marker). Store it:

```perl
$info{required} = $required ? 1 : 0;
```

Consumers: `t/42`'s `required_flags_for` can read the registry instead of
`all_attribute_specs`; `compare_to_schema` can report missing required
fields distinctly from optional ones.

### 3.2 `element_type` (Str) for arrays

For every array registration, record the element type name. The Type::Tiny
branch already has `$type_name`; the string branch has `$inner`. Store the
canonical name:

```perl
$info{element_type} = $type_name;   # 'Str' | 'Int' | 'Bool' | 'Quantity' | 'Time' | ...
```

For `is_array_of_objects`, `element_type` is the expanded class name (same
value as `class`). Consumers: `t/42`'s `isa_text_for` fallback disappears;
`compare_to_schema` can type-check array elements without Moo introspection.

## 4. Migration path

1. Add the two fields in `IO::K8s::Resource::_k8s` (one commit, no behavior
   change — the flags are written but nothing reads them yet).
2. Switch `t/42` to read `required` and `element_type` from the registry;
   keep the Moo introspection as a cross-check assertion for one release.
3. Extend `compare_to_schema` to use `required` / `element_type`.
4. Optionally: a `t/49_registry_contract.t` that asserts every registered
   attribute carries the full contract (no flag-less entries), turning the
   `[Quantity]`-array gap into a compile-time-style regression test.

## 5. Out of scope

- Changing the `k8s` DSL surface or the registry's public shape.
- Moving requiredness enforcement out of Moo (Moo stays the constructor).
- AutoGen: generated classes go through the same `_k8s`, so they inherit
  the contract for free.
