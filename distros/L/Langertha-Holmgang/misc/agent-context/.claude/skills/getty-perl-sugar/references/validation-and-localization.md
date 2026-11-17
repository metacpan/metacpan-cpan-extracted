# Preflight validation, cache promotion, and localization

**Read when:** adding `validation_step`, reusable validation outputs, or localized
labels in a long-running process.

## Three validation boundaries

Declaration validation checks the syntax and shape of metadata. Plan validation
checks the composed graph, activation policy, and compatibility of its pieces.
Runtime validation checks actual inputs and outputs. A `validation_step` is a
separate domain operation, not a replacement for the first two boundaries.

Distinguish a pure precondition from a remote probe and from an operation that
changes state. A preflight check that creates a resource is already performing
workflow work. It needs side-effect authorization, retry policy, and observability.
Do not hide provisioning behind a “validation” label to make a dry run appear safe.

## Reusing preflight output

A validated probe might produce useful data that the main execution can reuse.
Promote it to a result only if the target step identity, input identity, result schema,
semantic revision, authorization scope, and freshness policy match. Validate the
promoted value just as if the step had returned it during execution.

Record the provenance of reused data and whether it came from validation, an earlier
run, or a cache. A credential check performed before approval may be stale after
approval. A successful remote lookup does not guarantee that the external resource
still exists. Define expiry or reconciliation rules for time-sensitive observations.

Do not copy a validation cache wholesale into the result hash. That can mark unrelated
or failed steps complete, bypass dependency checks, and leak data between tenants.
Cache promotion belongs at the same validated completion boundary as ordinary output.

## Localize presentation, not identity

Store a stable step key and a message identifier. Resolve the label in the current
request or display locale. Translating a label once during module loading can retain
the daemon-start locale for later users.

The original draft uses `N_()` as a translation marker and `l()` as a translator.
Those spellings are project/library conventions, not universal Perl functions.
Use the selected localization library's marker and translator and configure its
message extractor accordingly. Locale::TextDomain, for example, documents deferred
extraction markers such as `N__`; do not mechanically substitute names without
checking the library.

Do not use translated labels as step keys, database identifiers, cache keys, or
metric dimensions. Stable identifiers survive locale changes and wording edits.
Store interpolation arguments separately from the message identifier and render
them with the library's pluralization/context support when needed.

## Tests and scope

Test that static introspection does not run validation probes, failed checks prevent
execution, stale caches are rejected, and promoted values obey result schemas.
For localization, load a class once, render labels in two locales, and verify that
its keys and plan identity remain unchanged. Do not change the process-global locale
unsafely in a concurrent server just to render a single label.

**Bundled status:** cache promotion and localization adapters are design guidance.
The reference implementation stores plain English labels and has no validation
keyword or translation dependency.
