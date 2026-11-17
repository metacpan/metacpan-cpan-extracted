# Attribute sugar and generated forms

**Read when:** introducing `config_attribute`, `user_input`, UI labels, or typed
configuration introspection.

## Keep configuration metadata beside the attribute

A user-facing field commonly needs a label, help text, group, order, widget hint,
visibility rule, and sensitivity flag. Attaching those to the attribute avoids
maintaining an independent form definition that drifts from the object model.
Moose supports attribute traits that add metadata such as a label to the attribute
metaclass.

Use `with_meta` for a declaration that normalizes your domain options and calls
`$meta->add_attribute`. The trait stores custom metadata; it is not a new domain
object. A shared helper should distinguish Moose attribute options from UI options
and reject unknown names rather than passing arbitrary keys through blindly.

A sensible separation is a trait module, one attribute-declaration helper, a metadata
projection function, and UI-specific renderers. The workflow planner should consume
only configuration values relevant to activation and execution. It should not need
to understand HTML widgets.

## Do not confuse three forms of validation

Moose type constraints protect object-level values according to their defined
semantics. JSON Schema describes a wire-format contract. UI validation improves the
user experience. None is automatically a complete implementation of the others.

A UI `min` or `max` hint does not enforce server-side bounds. A `required` input
field and a Moose attribute with a lazy default may have different meanings.
An opaque custom Moose constraint cannot always be translated into a portable
JSON Schema. An enum widget does not make an arbitrary input authorized.

Choose a canonical specification for simple shared constraints and implement
explicit mappings. Flag unmappable constraints rather than silently dropping them.
Always validate submitted values server-side before executing side effects.

## Attribute access is not always passive

Introspection should examine metadata without instantiating a task or invoking
readers where possible. Accessing a lazy attribute can run a builder; evaluating
a visibility predicate can execute application code. Do not trigger a credential
lookup or expensive connection merely to render a configuration form.

When inheritance matters, collect inherited attributes through an appropriate
metadata traversal rather than assuming only locally declared attributes exist.
Preserve explicit field order. Avoid arbitrary hash ordering as a form-layout policy.

## Sensitive fields and updates

Mark secret fields explicitly and project only safe metadata. Never place current
secret values in generated forms, manifests, logs, tool descriptions, or examples.
Separate “unchanged secret” from “set to empty,” and make clear which fields may be
updated while a run is active. A change affecting a preflight predicate requires a
new bound plan, not an invisible mutation to an ongoing run.

Store label identifiers and render translations in the request's locale. The same
class may serve several users with different locales. See
`validation-and-localization`.

## Test the projection, not just the declaration

Test attribute creation, trait presence, inherited metadata, ordering, unknown
options, redaction, and server-side rejection of values a client bypasses. Test that
introspection does not invoke lazy builders. Snapshot both the canonical field spec
and the safe public projection.

**Bundled status:** this is a production-extension recipe. The reference library
uses ordinary Moose attributes and does not ship `config_attribute` or form rendering.
