---
name: kubernetes-rest-deprecated
description: "Kubernetes::REST::Deprecated -- permanent home for CPAN redirect (tombstone) stub modules covering Kubernetes::REST classes genuinely removed from the Kubernetes-REST distribution's own release history. Covers the PAUSE-takeover mechanism, how to tell a genuine orphan from a soft-deprecated-in-place or deprecated-in-name-only class, the audit method, and the procedure for adding a new tombstone."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Kubernetes::REST::Deprecated

Permanent home for "tombstone" redirect stub modules: when a
Kubernetes::REST class gets genuinely renamed or retired -- actually stops
shipping under its old name -- the old module name stays indexed on PAUSE
against the last release that shipped it, forever -- PAUSE has no delete.
Anyone still running `cpanm Old::Module::Name` (or a cpanfile pinning it)
would keep installing the stale, dead code with no hint a replacement
exists.

This dist ships a tombstone for each such name: a stub package under the OLD
module name whose only job is to `die` immediately on load, naming the
replacement module.

## The CPAN-takeover mechanism

PAUSE indexes each module name to whichever shipped release -- of **any**
distribution -- carries the **highest `$VERSION`** for that module name.
Kubernetes::REST ships all of its API classes from a single distribution
(`Kubernetes-REST`), so a genuine removal is an **in-distribution** one: a
later `Kubernetes-REST` release drops a class without moving it anywhere
else. PAUSE does not care that "the dist is still actively released" -- it
only sees that no shipped release contains that module name above the
version of the last one that did, so the name is orphaned exactly the same
way a cross-distribution rename would orphan it. Releasing
`Kubernetes-REST-Deprecated` with an `Old::Module::Name` package versioned
higher than the last `Kubernetes-REST` release that shipped that name takes
over the PAUSE index entry for it.

## Before drafting a tombstone: rule out the two false starts

Both apply here, mirroring the sibling `io-k8s-deprecated` skill's
precedent for `IO::K8s` -- check for them **before** writing a tombstone,
not after:

1. **Soft-deprecated in place, still shipping.** Kubernetes::REST's 1.000
   "v1 rewrite" kept shipping the entire old v0 API (1012 classes: one
   `Call::*` per operation plus 10 helper modules) as `warn`-on-load stubs,
   continuously, from `1.000` through `1.104`. As long as a module keeps
   shipping under its own name in every release -- even as a stub that only
   warns -- PAUSE never orphans it and no tombstone is needed. A tombstone
   only became warranted once `Kubernetes-REST` actually stopped shipping
   the files (a real deletion between release tags), not when it merely
   started warning on load. Grep for the runtime `warn __PACKAGE__` pattern
   and check whether the file is *present* at the current release tag
   before assuming it's gone.
2. **Deprecated in name only, still functional.** The
   `Kubernetes::REST::V0Group` family (`V0Group` itself + 17 subclasses:
   `Core`, `Apps`, `Batch`, `Networking`, `RbacAuthorization`,
   `Admissionregistration`, `Apiextensions`, `Apiregistration`,
   `Authentication`, `Authorization`, `Autoscaling`, `Certificates`,
   `Coordination`, `Events`, `Policy`, `Scheduling`, `Storage`) carries
   `DEPRECATED` in its `ABSTRACT` and POD, exactly like the 1012 tombstoned
   classes -- but unlike them it is a working `AUTOLOAD`-based
   compatibility shim: it still translates old-style calls (e.g.
   `$api->Core->ListNamespacedPod(...)`) into real calls against the new
   API, and `Kubernetes::REST` itself still wires up `$api->Core` /
   `$api->Apps` etc. as live accessors (`sub Core { shift->_v0_group('Core')
   }`). A class whose documentation says "deprecated" but whose code still
   works and still ships is not an orphan. **Before tombstoning anything
   with "DEPRECATED" in its POD, `grep -rn "extends
   'Kubernetes::REST::V0Group'"` and `grep -rn "Kubernetes::REST::Call"`
   across the live `Kubernetes::REST` lib -- a hit in either means it's
   still live code or still referenced, not a genuine orphan.**

## Auditing Kubernetes-REST for orphaned module names

Method: diff the set of `package X;` names present at a `Kubernetes-REST`
release tag against the set present at a later tag (or current HEAD) -- a
file *deletion*, not a content change.

```bash
cd <kubernetes-rest checkout>
git tag -l --sort=v:refname                        # find release tags (vX.Y.Z or X.Y.Z)
git ls-tree -r --name-only <old-tag> -- lib | grep '\.pm$'   # packages shipped then
# compare against:
git ls-tree -r --name-only <new-tag-or-HEAD> -- lib | grep '\.pm$'  # packages shipped now
```

A name present at an older release tag but absent from the newer one (and
absent from every release tag in between and after) is a candidate --
UNLESS a later release re-introduced it (then PAUSE already points at the
current, correct code and no tombstone is needed). Then apply the two
false-start checks above before concluding a tombstone is actually
warranted. Also check whether the file's runtime content is an empty
`warn`-and-nothing-else stub (genuine orphan candidate) versus real code
(like `V0Group`) before assuming "the POD says deprecated" is sufficient.

## Tombstone shape used here: consolidated, one shared successor

All 1012 tombstones in this dist share the exact same shape: every one of
them redirects to the same successor -- the unified API on
`Kubernetes::REST` itself (`list`, `get`, `create`, `update`, `patch`,
`delete`, `watch`, ...). Because every member of a batch like this shares
the same successor and the same die-message shape, generate the tombstone
files and the `t/01-tombstones.t` entries from a flat list of old names
rather than hand-writing each one -- see `t/01-tombstones.t`'s
`@deprecated_classes` array for the pattern.

For a future rename to one specific new name (not a bulk consolidation),
use a per-entry die message naming that specific successor instead of the
shared one.

Consequences shared by all tombstones, regardless of shape:

- **No per-file version override.** `dist.ini` has no `version_finder`
  restriction -- every file in this dist, main module and tombstones
  alike, versions normally and uniformly with dzil
  (`RewriteVersion::Transitional` / `BumpVersionAfterRelease`), exactly
  like `Kubernetes::REST` itself. There is nothing to hand-maintain here:
  the dist's version only ever increases, so once it starts past the
  target it stays past it.
- **The dist's version must beat the last `Kubernetes-REST` release that
  shipped the old name** -- currently `1.104`, hence this dist starting at
  `1.105` (found via `cpanm --info Kubernetes::REST` or Kubernetes-REST's
  release git tags). Since `Kubernetes::REST` will never ship these names
  again, there's no need to round up generously the way a genuinely
  contested/still-shipping name would require -- the very next version is
  enough. If a *future* tombstone batch targets a name Kubernetes-REST
  shipped past whatever version this dist has reached by then, check that
  before releasing and bump first if needed.
- **The module does nothing else.** No POD-only doc stub, no re-export, no
  `use base` of the replacement, and critically **no `use Moo`** -- a
  tombstone must not register itself as a live (if empty) API object. Just
  `die` on load.

Model files: any `lib/Kubernetes/REST/Call/**/*.pm` in this dist (the
consolidated shape), e.g. `lib/Kubernetes/REST/Apis.pm` for a top-level
helper.

## Adding a new tombstone (procedure)

1. **Find the old module's last released `$VERSION`** and confirm it's a
   genuine orphan via the audit method and the two false-start checks
   above.
2. **Create the stub(s)** at `lib/<Old/Namespace>.pm` (path matches the OLD
   module name). Model it on an existing tombstone.
3. **Add test coverage** in `t/01-tombstones.t` -- for a batch sharing one
   successor, add to the flat `@deprecated_classes` array; for a
   one-to-one rename, add a dedicated assertion block instead.
4. **Update `lib/Kubernetes/REST/Deprecated.pm`'s POD** -- add the name(s)
   to "CURRENT TOMBSTONES", update the grouped counts.
5. **Update `README.md`'s tombstone summary** to match.
6. **Add a `Changes` entry** under `{{$NEXT}}`.
7. **Verify**: `prove -lr t/` green, `dzil build` clean, and confirm the
   dist's current version already exceeds the new tombstone's target
   version (bump before release if not -- normal versioning applies here,
   nothing special to check per-file). Do not `dzil release` without the
   maintainer's explicit go-ahead.

## Boundary

This dist ships no Kubernetes::REST runtime code and has no dependency on
Kubernetes::REST core -- each tombstone is fully self-contained (no `use
Kubernetes::REST`, no `use Moo`). Keep it that way: a tombstone's only job
is to load fast and die with a clear message, nothing more.
