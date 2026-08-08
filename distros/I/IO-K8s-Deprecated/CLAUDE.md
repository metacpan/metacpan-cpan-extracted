# CLAUDE.md — IO::K8s::Deprecated

**MANDATORY: load the `perl-core` skill via the Skill tool before editing any
Perl code in this repo.** It encodes Getty's house rules; the
`io-k8s-deprecated` skill (`.claude/skills/io-k8s-deprecated/SKILL.md`)
layers the tombstone-specific procedure on top and is auto-loaded into the
sharedir at build time.

## Core concept: PAUSE-takeover tombstones

`IO::K8s::Deprecated` has no runtime behaviour of its own. It exists purely
so an IO::K8s class that is genuinely gone does not leave its old CPAN name
permanently resolving to stale, superseded code — PAUSE has no delete.

PAUSE indexes per **module name**, not per distribution: it resolves a
module name to whichever shipped release — of any distribution, including a
later release of the *same* one — carries the highest `$VERSION` for that
name. IO::K8s ships ~700 classes from a single distribution, so a genuine
removal orphans a name in-distribution: PAUSE does not know or care that the
dist is still actively released, so the old name orphans the same way a
cross-distribution rename would.

**Not every internally-deprecated class needs a tombstone here.** Two false
starts worth knowing about, both discovered while building this dist:

1. IO::K8s shipped ~76 `*List` classes (`PodList`, `ServiceList`, ...) as
   soft-deprecated warning stubs (`warn`, not `die`) since its very first
   `1.00` release, pointing callers at the unified `IO::K8s::List`. As long
   as they kept shipping under their own name in every release, there was
   no PAUSE orphan and no tombstone was warranted — only once `IO-K8s`
   actually stopped shipping them (after `1.100`) did they become genuine
   tombstone candidates. That removal, and this dist's 76 tombstones for
   it, are the "Consolidated into IO::K8s::List" entries below.
2. The Cilium v1.19.2 upgrade in `IO-K8s` `1.100` initially looked like it
   orphaned 8 `cilium.io/v2alpha1` class names (6 renamed to `v2`, 2 dropped
   outright) — tombstones were drafted for all 8. But `io-k8s-p5` already
   has an established convention of keeping multiple API versions of a
   resource side by side rather than deleting old ones (Apps
   V1beta1/V1beta2/V1 all still ship). The Cilium classes were restored in
   `IO-K8s` to match that convention instead of being tombstoned — always
   check whether "renamed/removed" should instead be "restored for
   backward compat" before drafting a tombstone.

Each *genuinely* orphaned class gets a stub package here under the OLD
name, versioned above the last `IO-K8s` release that shipped that name,
taking the PAUSE index entry over. The stub `die`s immediately on load,
naming the replacement. Full mechanism and the step-by-step "add a new
tombstone" procedure (including the audit method, and how to distinguish a
genuine orphan from the two false-start patterns above) are in the
`io-k8s-deprecated` skill, not duplicated here.

## Version policy — normal dzil versioning, no per-file overrides

`dist.ini` has **no** `version_finder` restriction. Every file -- the main
module and all 80 tombstones alike -- versions normally and uniformly with
the rest of the distribution (`RewriteVersion::Transitional` /
`BumpVersionAfterRelease`), same as `IO-K8s` itself. The starting version,
`1.105`, was chosen for one reason: it's safely past `IO-K8s 1.100`, the
last CPAN release that shipped any of these module names. Since `IO-K8s`
will never ship these names again (they're permanently gone, not just
between releases) and this dist's version only ever increases, `1.105`
stays ahead of that target for good. Full reasoning:
`lib/IO/K8s/Deprecated.pm`'s "VERSION POLICY" section.

If a future tombstone needs a name whose last-shipped version exceeds
whatever version this dist has reached by then, that's an ordinary
version-ordering check before release -- not a reason to reintroduce
per-file version overrides.

## Current tombstones

80 modules total, two shapes, all versioned `$VERSION = '1.105'` (safely
past `IO-K8s` `1.100`, the last release that shipped every one of these
names):

- **76 "consolidated" tombstones** — the old per-resource `*List` classes
  IO-K8s consolidated into the generic `IO::K8s::List`. Full list:
  `lib/IO/K8s/Deprecated.pm`'s POD, or `t/01-tombstones.t`'s
  `@old_list_classes` array.
- **4 "removed, no successor" tombstones** — the classic
  `resource.k8s.io/v1alpha3` DRA control-plane-controller allocation
  classes (`PodSchedulingContext` + its `Spec`/`Status`,
  `ResourceClaimSchedulingStatus`), dropped when DRA graduated to GA at
  `resource.k8s.io/v1` with an architecturally different model. Unlike the
  List classes, these never had a soft-deprecation warning period — they
  were genuinely removed outright. List: `lib/IO/K8s/Deprecated.pm`'s POD,
  or `t/01-tombstones.t`'s `@classic_dra_removed` array.

No Cilium tombstones, and no tombstones for the admission/auth/flowcontrol
classes flagged in a later upstream sync either — see "Version policy"
false-start #2 above and `lib/IO/K8s/Deprecated.pm`'s "CONSIDERED BUT NOT
TOMBSTONED" section for both.

## Adding a new tombstone

Do not improvise this — follow the procedure in the `io-k8s-deprecated`
skill (`.claude/skills/io-k8s-deprecated/SKILL.md`): find the old module's
last released version, confirm it's a genuine orphan (not soft-deprecated
in place, not restored for backward compat), create the stub, add it to
`t/01-tombstones.t`, update this dist's main-module POD table and this
file's summary above, add a `Changes` entry.

## Boundary / dependencies

No IO::K8s runtime code, no dependency on IO::K8s core — every tombstone is
self-contained (no `use IO::K8s`, no `use IO::K8s::APIObject`, no `use
Moo`). Keep it that way; a tombstone's only job is to load fast and die
with a clear message.

## Testing

```bash
prove -lr t/
```

`t/00-load.t` loads the real main module (`IO::K8s::Deprecated`) and must
load cleanly. `t/01-tombstones.t` asserts every tombstone dies on load —
the 76 List-consolidation ones with a message pointing at `IO::K8s::List`,
the 4 classic-DRA ones with a "removed, no successor" message pointing at
the current `resource.k8s.io/v1` API.
