---
name: kubernetes-comb-svg-core
description: Use before editing or testing Kubernetes::Comb::SVG — the Cell/Layout/SVG seams, the Comb CR fields it reads, layout rules (groups, depth rows, honeycomb), the SVG output contract (self-contained, deterministic, escaped) and how its tests check SVG.
---

# Kubernetes::Comb::SVG — core

`SPEC.md` is the design and the authority. This skill is the map and the traps;
before touching a building block, read its SPEC section (§ numbers below). Code
and SPEC disagree → stop and report it; the SPEC changes first, with the
maintainer, never silently in code.

## Vocabulary

| Term | Means |
|---|---|
| Comb | one unit managed by `Kubernetes::Comb`; here only its custom resource matters |
| CR | the `Comb` custom resource: `metadata`, `spec` (`class`, `dependsOn`, `enabled`, `upstream`, `config`), `status` (`phase`, `conditions`, `endpoints`, `upstream`, `managedResources`) |
| cell | one normalised Comb (`Kubernetes::Comb::SVG::Cell`) — the only thing layout and drawing see |
| phase | `Running`, `Pending`, `Blocked`, `NeedsConfig`, `Disabled`, `Error`, `Stopped`, `NotDeployed`; anything else is `Unknown` |
| borrowed | the Comb takes its service from an upstream layer — `status.upstream` recorded, not unreachable, and phase `Running` or `Pending` (SPEC §3) |
| group | cells sharing the value of the configured `group_label`; no label key is built in |
| depth | row of a cell: 0 without dependencies in the picture, else one below its deepest dependency |

## Three seams (§4)

`Cell` reads the CR · `Layout` places cells and knows neither CR nor SVG ·
`SVG` draws and is the facade (`new(combs => ..., %options)->render`). A CR
field read outside `Cell`, or an SVG string built inside `Layout`, is a seam
break — move it.

## Input is duck-typed (§3)

A plain hash in CR shape, or an object answering `TO_JSON`; a `List` hash with
`items` in place of the array. `Kubernetes::Comb` and `IO::K8s` never appear in
`cpanfile` requires — a test that wants the real CR classes skips when they are
not installed.

## Never die on odd data

Unknown phase, no `status` at all, `spec.enabled: false`, a `dependsOn` name
that is not in the input, a dependency cycle: each gives a picture. A cycle is
the trap — a naive recursive depth loops forever; the cells of a cycle share
one row. Only an element without `metadata.name` is an error.

## Output contract (§6, §8)

- **Deterministic**: no timestamps, no generated random ids, and every hash is
  iterated in sorted order before it reaches the output. Perl's hash order
  changes per process — an unsorted `keys` shows up as a flaky test.
- **Self-contained**: no `<script>`, no `href`/`url()` to anything outside the
  document, system font stack only. Light and dark through one `<style>` with
  CSS custom properties and `prefers-color-scheme`.
- **Escaped**: everything from a CR goes through one escape function for text
  and one for attributes — `& < > " '`. Never interpolate a CR value into the
  SVG directly. A `link` href is allowed only when relative or `http(s):`.
- Numbers in coordinates are rounded to a fixed precision, so the same layout
  prints the same on every platform.
- Phase is shown as text too, never by colour alone.

## Tests (§10)

- No cluster, no network. Fixtures are JSON under `t/data/`.
- Parse the SVG with a real XML parser and assert on elements and attributes
  (`g.comb[data-name]`, `path.dep`), not on string offsets or regexes over the
  whole document.
- Determinism is its own test: render twice, compare bytes.
- `examples/demo.svg` is committed and shown in the README; a test fails when
  it no longer matches what `examples/demo.json` renders to.

## No site policy

An open-source dist: the label key for groups, group names and colours are
options. Nothing in `lib/` names a particular site, cluster or API group.

## Open design points

SPEC §11 lists decisions not yet made. Meeting one during implementation →
surface it with a proposal; the maintainer decides.
