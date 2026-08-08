# CLAUDE.md — Kubernetes::REST::Deprecated

**MANDATORY: load the `perl-core` skill via the Skill tool before editing any
Perl code in this repo.** It encodes Getty's house rules; the
`kubernetes-rest-deprecated` skill
(`.claude/skills/kubernetes-rest-deprecated/SKILL.md`) layers the
tombstone-specific procedure on top and is auto-loaded into the sharedir at
build time.

## Core concept: PAUSE-takeover tombstones

`Kubernetes::REST::Deprecated` has no runtime behaviour of its own. It
exists purely so a `Kubernetes::REST` class that is genuinely gone does not
leave its old CPAN name permanently resolving to stale, superseded code --
PAUSE has no delete.

PAUSE indexes per **module name**, not per distribution: it resolves a
module name to whichever shipped release -- of any distribution, including
a later release of the *same* one -- carries the highest `$VERSION` for
that name. A genuine in-distribution removal orphans a name the same way a
cross-distribution rename would.

## What's tombstoned here, and what deliberately isn't

`Kubernetes::REST` `1.000` (2026-02-13, the "v1 rewrite") replaced its
entire old per-endpoint v0 API with a single unified object-oriented API.
Rather than deleting the old classes outright at that point, `1.000`
through `1.104` kept shipping all of them as soft-deprecated warning stubs
(`warn`, not `die`) -- so there was no PAUSE orphan yet and no tombstone was
warranted (see the `io-k8s-p5-deprecated` precedent this dist follows for
why: a class that keeps shipping under its own name, even as a stub, is
never orphaned). Only once `Kubernetes-REST` actually dropped the files
(the change this dist ships alongside) did they become genuine tombstone
candidates.

**Two different things looked "deprecated" and only one of them belongs
here:**

1. **1012 old per-endpoint `Call::*` classes + 10 v0-only helper modules**
   -- pure 7-line stubs whose only runtime effect was `warn`, never
   functional, no live code anywhere referenced them (`grep -rn
   "REST::Call"` across the live `Kubernetes::REST` lib turned up nothing).
   Genuine orphans. Tombstoned here.
2. **The `Kubernetes::REST::V0Group` family** (`V0Group` + 17 subclasses:
   `Core`, `Apps`, `Batch`, `Networking`, `RbacAuthorization`, etc.) --
   reads as deprecated in its `ABSTRACT` and POD too, but is a working
   `AUTOLOAD`-based compatibility shim: it still translates old-style calls
   (`$api->Core->ListNamespacedPod(...)`) into real calls against the new
   API, and `Kubernetes::REST` itself still wires up `$api->Core` /
   `$api->Apps` etc. as live accessors (`sub Core { shift->_v0_group('Core')
   }`). Still shipping, still functional -- not an orphan, no tombstone.
   **Before ever tombstoning something with "DEPRECATED" in its POD, grep
   for `extends 'Kubernetes::REST::V0Group'` and for
   `Kubernetes::REST::Call` usage in the live lib to confirm it's actually
   dead, not just discouraged.**

## Version policy — normal dzil versioning, no per-file overrides

`dist.ini` has **no** `version_finder` restriction. Every file --
the main module and all 1012 tombstones alike -- versions normally and
uniformly with the rest of the distribution
(`RewriteVersion::Transitional` / `BumpVersionAfterRelease`), same as
`Kubernetes::REST` itself. The starting version, `1.105`, was chosen for
one reason: it's the next version after `Kubernetes-REST 1.104`, the last
CPAN release that shipped any of these module names. Since
`Kubernetes::REST` will never ship these names again (they're permanently
gone, not just between releases) and this dist's version only ever
increases, `1.105` stays ahead of that target for good. Full reasoning:
`lib/Kubernetes/REST/Deprecated.pm`'s "VERSION POLICY" section.

If a future tombstone needs a name whose last-shipped version exceeds
whatever version this dist has reached by then, that's an ordinary
version-ordering check before release -- not a reason to reintroduce
per-file version overrides.

## Current tombstones

1012 modules, all one shape: the old v0 API (per-endpoint `Call::*`
classes + 10 helper modules), last shipped as a warning stub in
`Kubernetes-REST` `1.104`; every file in this dist, including these,
carries `$VERSION = '1.105'`. Full list: `lib/Kubernetes/REST/Deprecated.pm`'s POD (grouped
summary) or `t/01-tombstones.t`'s `@deprecated_classes` array (exhaustive).

No `V0Group`-family tombstones -- see "What's tombstoned here" above and
`lib/Kubernetes/REST/Deprecated.pm`'s "CONSIDERED BUT NOT TOMBSTONED"
section.

## Adding a new tombstone

Do not improvise this — follow the procedure in the
`kubernetes-rest-deprecated` skill
(`.claude/skills/kubernetes-rest-deprecated/SKILL.md`): find the old
module's last released version, confirm it's a genuine orphan (not
soft-deprecated in place, not merely deprecated-in-name-only like
`V0Group`), create the stub, add it to `t/01-tombstones.t`, update this
dist's main-module POD table and this file's summary above, add a `Changes`
entry.

## Boundary / dependencies

No Kubernetes::REST runtime code, no dependency on Kubernetes::REST core --
every tombstone is self-contained (no `use Kubernetes::REST`, no `use
Moo`). Keep it that way; a tombstone's only job is to load fast and die
with a clear message.

## Testing

```bash
prove -lr t/
```

`t/00-load.t` loads the real main module (`Kubernetes::REST::Deprecated`)
and must load cleanly. `t/01-tombstones.t` asserts every tombstone dies on
load with a message pointing at `Kubernetes::REST`.
