---
name: io-k8s-deprecated
description: Use when an IO::K8s class was removed and needs a CPAN tombstone, or when auditing IO-K8s for orphaned module names.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# IO::K8s::Deprecated

Permanent home for "tombstone" redirect stub modules: when an IO::K8s class
gets genuinely renamed or retired -- actually stops shipping under its old
name -- the old module name stays indexed on PAUSE against the last release
that shipped it, forever -- PAUSE has no delete. Anyone still running
`cpanm Old::Module::Name` (or a cpanfile pinning it) would keep installing
the stale, dead code with no hint a replacement exists.

This dist ships a tombstone for each such name: a stub package under the OLD
module name whose only job is to `die` immediately on load, naming the
replacement module.

## The CPAN-takeover mechanism

PAUSE indexes each module name to whichever shipped release -- of **any**
distribution -- carries the **highest `$VERSION`** for that module name.
IO::K8s ships all ~700 of its API and CRD classes from a single
distribution (`IO-K8s`), so a genuine removal is an **in-distribution**
one: a later `IO-K8s` release drops a class without moving it anywhere
else. PAUSE does not care that "the dist is still actively released" -- it
only sees that no shipped release contains that module name above the
version of the last one that did, so the name is orphaned exactly the same
way a cross-distribution rename would orphan it. Releasing
`IO-K8s-Deprecated` with an `Old::Module::Name` package versioned higher
than the last `IO-K8s` release that shipped that name takes over the PAUSE
index entry for it.

## Before drafting a tombstone: rule out the three false starts

All of these happened to this dist -- check for them **before** writing a
tombstone, not after:

1. **Soft-deprecated in place, still shipping.** IO::K8s carried ~76
   `*List` classes (`PodList`, `ServiceList`, ...) as `warn`-on-load stubs
   pointing at the unified `IO::K8s::List`, continuously, since its very
   first `1.00` release. As long as a module keeps shipping under its own
   name in every release -- even as a stub that only warns -- PAUSE never
   orphans it and no tombstone is needed. A tombstone only became
   warranted once `IO-K8s` actually stopped shipping the files (a real
   `git diff --diff-filter=D` deletion between release tags), not when it
   merely started warning on load. Grep `use strict; use warnings; warn
   __PACKAGE__` patterns and check whether the file is *present* at the
   current release tag before assuming it's gone.
2. **Restored for backward compatibility.** `IO-K8s`'s Cilium v1.19.2
   upgrade (`1.010` -> `1.100`) initially dropped 8 `cilium.io/v2alpha1`
   classes (6 promoted to `v2`, 2 removed outright), and tombstones were
   drafted for all 8. But `io-k8s-p5` already has an established
   convention of keeping multiple API versions of the same resource side
   by side rather than deleting superseded ones (e.g. `Autoscaling`
   `V1`/`V2` and `Cilium` `V2alpha1`/`V2` ship concurrently). The right fix
   was to restore the Cilium classes in `IO-K8s` itself, matching that
   convention -- not to tombstone them. **Before tombstoning a
   rename/removal that looks like "just a newer API version of the same
   CRD", check whether `io-k8s-p5` already has a precedent of keeping the
   old version around, and prefer proposing a restore there over drafting
   a tombstone here.**
3. **Shipped by `IO-K8s` again.** Release `1.105` tombstoned
   `Apimachinery::Pkg::Apis::Meta::V1::APIGroupList` and
   `::APIResourceList` together with the `*List` sweep, because `IO-K8s`
   had carried them as the same kind of warning stub. They are the
   `meta.v1` discovery Kinds, not lists of resources, and `IO-K8s` `1.106`
   shipped both again as real classes. Both dists install the same file
   path, so installing this one after `IO-K8s` overwrote the working
   classes with die-stubs. Both tombstones were removed. **A name `IO-K8s`
   ships -- still or again -- never gets a tombstone, and a tombstone
   whose name comes back is deleted, not re-versioned.** This one differs
   from the other two: the tombstone was defensible when drafted and went
   wrong later, through a release of the other dist. So it is not a
   one-time check -- `t/02-name-guard.t` compares every package shipped
   here against the current `IO-K8s` and must run (not skip) before every
   release.

## Auditing IO-K8s for orphaned module names

The audit starts from the PAUSE index, because that is what `cpanm`
resolves: every module name the index maps to an `IO-K8s` tarball other
than the current release is an orphan, whatever release it came from.
`IO-K8s` `0.01` to `0.03` (JLMARTIN, 2018) count as much as the `1.x`
series -- their 212 orphans are the "retired API version" tombstones.

```bash
curl -sO https://www.cpan.org/modules/02packages.details.txt.gz
# which IO-K8s tarballs still hold index entries, and how many
zcat 02packages.details.txt.gz | awk '$3 ~ /\/IO-K8s-[0-9]/ {print $3}' | sort | uniq -c
# the names of one older tarball -- each needs a tombstone here
zcat 02packages.details.txt.gz | awk '$3 ~ /\/IO-K8s-0\.03\.tar\.gz$/ {print $1}'
```

The target state: every name mapped to `IO-K8s` or `IO-K8s-Deprecated`
is shipped by the current `io-k8s-p5` (`package` lines under `lib/`) or by
this dist, and by exactly one of the two.

The git history then tells what happened to a name. Every CPAN release has
a tag (`git tag -l --sort=v:refname`, checked against the MetaCPAN release
list), and a tag's classes sit under `lib/` or, for `0.01` to `0.03`, under
`auto-lib/`:

```bash
cd <io-k8s-p5 checkout>
git ls-tree -r --name-only <tag> | grep -E '^(auto-)?lib/.*\.pm$'   # classes shipped then
```

A name present at an older release tag but absent from the newer one (and
absent from every release tag in between and after) is a candidate --
UNLESS a later release re-introduced it (then PAUSE already points at the
current, correct code and no tombstone is needed; this is exactly what
happened with the restored Cilium classes). Use
`git log --diff-filter=DR -M --summary <old>..<new> -- 'lib/IO/K8s/<Area>/*'`
to see whether git detected the change as a rename (confirms the successor
class) or a straight deletion (confirms no replacement) -- do not guess the
successor from the file path alone; read the commit message and diff the
old and new file's `k8s spec => ...` / `api_version` to confirm behavior
didn't also change silently. Then apply the false-start checks above
before concluding a tombstone is actually warranted.

## Tombstone shapes

### 1. Renamed -- die pointing at a single successor

For a class that moved to one specific new name (e.g. a CRD API version
promotion where the old version was NOT kept for backward compat, unlike
the Cilium case above).

### 2. Consolidated -- die pointing at one shared generic replacement

For a batch of old classes replaced by a single generic class. Model:
the 74 `*List` tombstones, all pointing at `IO::K8s::List`. Because every
member of the batch shares the same successor and the same die-message
shape, generate the tombstone files and the `t/01-tombstones.t` entries
from a flat list of old names rather than hand-writing each one -- see
`t/01-tombstones.t`'s `@old_list_classes` array for the pattern (a plain
array + loop, not a per-tombstone hash with per-entry `type`/`match`,
since there's only one shape and one successor in play).

### 3. Removed -- die with no successor, no false rename claim

For a class deleted outright with nothing replacing it. The `die` message
must say plainly the module was removed and why, and must **not** claim a
rename or name a "replacement" that doesn't exist.

Consequences shared by all three shapes:

- **No per-file version override.** `dist.ini` has no `version_finder`
  restriction -- every file in this dist, main module and tombstones
  alike, versions normally and uniformly with dzil
  (`RewriteVersion::Transitional` / `BumpVersionAfterRelease`), exactly
  like `IO-K8s` itself. There is nothing to hand-maintain here: the dist's
  version only ever increases, so once it starts past the target it stays
  past it.
- **The dist's version must beat the last `IO-K8s` release that shipped
  the old name** -- currently `1.100`, hence this dist starting at `1.105`
  -- found via `cpanm --info IO::K8s` or IO-K8s's release git tags (`git
  tag -l --sort=v:refname`; `git ls-tree` the tag to confirm the name was
  actually there). A tombstoned name is one `IO-K8s` no longer ships, so
  there's no need to round up generously the way a genuinely
  contested/still-shipping name would require -- and should `IO-K8s` ship
  it again, the answer is to delete the tombstone (false start #3), not to
  out-version it. If a *future* tombstone
  batch targets a name IO-K8s shipped past whatever version this dist has
  reached by then, check that before releasing and bump first if needed.
- **The `die` is unconditional, at the top level, and starts its line with
  `die __PACKAGE__`.** `t/02-name-guard.t` asserts every stub carries
  exactly that line, so a stub installed over a class `IO-K8s` ships is
  recognisable as a tombstone, and it fails for a stub written any other
  way.
- **The module does nothing else.** No POD-only doc stub, no re-export, no
  `use base` of the replacement, and critically **no `use
  IO::K8s::APIObject`** -- a tombstone must not register itself as a live
  (if empty) API object. Just `die` on load.

Model files: `lib/IO/K8s/Api/Extensions/V1beta1/Ingress.pm` (renamed shape),
`lib/IO/K8s/Api/Core/V1/PodList.pm` (consolidated shape),
`lib/IO/K8s/Api/Policy/V1beta1/PodSecurityPolicy.pm` (removed shape).

## Adding a new tombstone (procedure)

1. **Find the old module's last released `$VERSION`** and confirm it's a
   genuine orphan via the audit method and the false-start checks
   above.
2. **Create the stub(s)** at `lib/<Old/Namespace>.pm` (path matches the OLD
   module name). Pick the shape above and model it on the matching
   existing tombstone.
3. **Add test coverage** in `t/01-tombstones.t` -- for a single tombstone
   or a small renamed/removed batch, extend inline; for a consolidated
   batch sharing one successor, add to (or start) a flat array + loop like
   `@old_list_classes`, not a per-entry hash.
4. **Update `lib/IO/K8s/Deprecated.pm`'s POD** -- add the name(s) to
   "CURRENT TOMBSTONES", grouped under the right shape heading.
5. **Update `README.md`'s tombstone summary** to match.
6. **Add a `Changes` entry** under `{{$NEXT}}`.
7. **Verify**: `prove -lr t/` green with `t/02-name-guard.t` actually run
   against a current `io-k8s-p5` checkout next to this one (a skip there
   is not a pass), `dzil build` clean, and confirm the
   dist's current version already exceeds the new tombstone's target
   version (bump before release if not -- normal versioning applies here,
   nothing special to check per-file). Do not `dzil release` without the
   maintainer's explicit go-ahead.

## Boundary

This dist ships no IO::K8s runtime code and has no dependency on IO::K8s
core -- each tombstone is fully self-contained (no `use IO::K8s`, no `use
IO::K8s::APIObject`, no `use Moo`). Keep it that way: a tombstone's only job
is to load fast and die with a clear message, nothing more.
