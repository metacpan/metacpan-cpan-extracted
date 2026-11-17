# Exporters, ownership, and namespace cleanup

**Read when:** building class/role entry points or debugging declarations registered
under the wrong package.

## Pick an ownership strategy deliberately

With `Moose::Exporter`, `also` includes another Moose-style exporter's interface;
`as_is` exports ordinary functions; `with_meta` prepends the importing target's
metaclass to the keyword call. A custom `init_meta` can initialize the target and
perform additional integration. These are distinct responsibilities.

For new Moose-based sugar, prefer:

```perl
sub step {
  my ($meta, @arguments) = @_;
  Example::Sugar::Registry::register_step($meta->name, undef, @arguments);
}
```

The class and role entry points each declare `with_meta => ['step']`. Normal helper
calls are now safe because ownership is explicit. Use this for metadata-only
keywords too; needing `$meta->add_attribute` is not the only reason to use
`with_meta`. Package-generating integrations should examine `meta_lookup` rather
than adding another fixed-depth `caller(N)` assumption.

For an established caller-based DSL, retain compatibility:

```perl
sub step {
  my ($owner, $file, $line) = caller;
  return register_for($owner, $file, $line, @_);
}
sub transparent_role_step { goto &Some::Existing::step }
```

This excerpt illustrates an ownership boundary; `register_for` and the target name
are application functions, not bundled APIs. `caller` reports the invoking package.
An ordinary intermediary changes that package. `goto &target` replaces the current
subroutine frame and passes its current `@_`; code after that transfer cannot run,
and localized state in the discarded frame does not survive. Capture ownership
explicitly when a wrapper needs logging or post-processing.

Do not assert that every wrapper needs `goto`. Explicit-owner wrappers do not.
Do not assume direct re-exports, custom import targets, parameterized role generators,
and runtime method calls all have identical caller behavior. Test each supported
import form. Calling `$object->step(...)` is not a supported declaration interface.

## Class and role entry points

Load `Moose ()` in the class exporter and `Moose::Role ()` in the role exporter.
Use `also => ['Moose']` and `also => ['Moose::Role']` respectively. The latter should
not construct a concrete task instance or attach unrelated execution state at import.
The shared backend should have no knowledge of how ownership was discovered.

A class `init_meta` may apply a small runner role automatically. Make repeated import
idempotent and never empty an existing registry. Be cautious with runner-role
`requires` clauses: import happens before later class declarations, so a required
method declared farther down may not yet exist when the role is applied. Choose
late finalization or explicit `with` for integrations needing completed consumers.

## Cleanup and immutability are different

Use the matching `no Your::DSL` to request cleanup of that exporter's functions;
use `namespace::autoclean` when additional imported helpers also need removal.
Verify `$class->can('step')` is false while actual runner methods remain available.
`no Moose` alone does not describe cleanup of every custom export. Directly
re-exported third-party functions have exporter-specific cleanup caveats.

`make_immutable` optimizes/finalizes Moose class metadata; it neither freezes your
separate registry nor substitutes for cleanup. Do it after class composition and
attribute declarations, and define a separate DSL finalization policy.

**Executable checks:** `t/10-caller.t` exercises real Perl call frames;
`t/70-moose.t` exercises actual Moose integration when Moose is installed.
