---
name: kubernetes-comb-svg-core
description: Use for any work on Kubernetes::Comb::SVG or bin/comb-svg — the Cell/Layout/SVG seams, the Comb CR fields, the depth and packed layouts, the SVG contract and the CLI.
---

# kubernetes-comb-svg — Kern

`SPEC.md` is the design and the authority. This skill is the map and the traps;
before touching a building block, read its SPEC section (§ numbers below). Code
and SPEC disagree → report it; the SPEC changes first, with the maintainer.

## Vocabulary

| Term | Means |
|---|---|
| Comb | one unit managed by `Kubernetes::Comb`; here only its custom resource matters |
| CR | the `Comb` custom resource: `metadata`, `spec` (`class`, `dependsOn`, `enabled`, `upstream`, `config`), `status` (`phase`, `conditions`, `endpoints`, `upstream`, `managedResources`) |
| cell | one normalised Comb (`Kubernetes::Comb::SVG::Cell`) — the only thing layout and drawing see |
| phase | `Running`, `Pending`, `Blocked`, `NeedsConfig`, `Disabled`, `Error`, `Stopped`, `NotDeployed`; anything else is `Unknown` |
| borrowed | the Comb takes its service from an upstream layer — `status.upstream` recorded, its `reachable` not false, phase `Running` or `Pending` (SPEC §3) |
| group | cells sharing the value of the configured `group_label`; no label key is built in |
| depth | row of a cell: 0 without dependencies in the picture, else one below its deepest dependency |

## Three seams (§4)

`Cell` reads the CR · `Layout` places cells and knows neither CR nor SVG ·
`SVG` draws and is the facade (`new(combs => ..., %options)->render`). A CR
field read outside `Cell`, or an SVG string built inside `Layout`, is a seam
break — move it.

- `Kubernetes::Comb::SVG->new(combs => ..., %options)->render` — the facade;
  the input is read when the picture is first needed, not by the constructor.
- `Cell->from_cr($cr, %options)` — one cell; `Cell->cells_from($input, %options)`
  — the cells of a set, with `dependencies` and `missing` resolved.
- `Layout->new(cells => ..., %options)->layout` — plain data: `width`, `height`,
  `groups`, `cells`, `edges`.
- `SVG->cell_class` / `SVG->layout_class` — the classes in use; override them
  to read the CRs or place the cells differently.

## Options (§7)

`combs` (required) · `title` (`Combs`) · `group_label` (none) · `layout`
(`depth` or `packed`) · `columns` (`6`) · `rows` (none) · `aspect` (`16/9`) ·
`size` (`56`) · `edges` (`1`, `0` in `packed`) · `legend` (`1`) · `link`
(none) · `theme` (the built-in colours) · `blink` (none) · `blink_seconds`
(`1.2`). In `packed` only a `columns` the caller gave counts, its default 6
leaves the grid to `rows` and `aspect`; `theme` keys are case-sensitive and a
colour in no plain syntax falls back to the built-in one; `link` is a coderef
`($cell) → href`, without a flag on the command line.

## Two layouts (§5)

**depth** (the default): groups stacked top to bottom in name order, the cells
without a group last; inside a group a cell sits one row below its deepest
dependency, the depth computed over all cells, so an edge between groups
still points right; the cells of a row are sorted by name, then id.

**packed** (the status monitor): the dependencies play no part in the
placement — the cells of a group are sorted by `id` and fill the rows left to
right, top to bottom, so a phase change moves nothing. Each group is its own
block. The grid comes from `columns`, else `rows`, else `aspect` (default
`16/9`); of two equally close shapes the one with fewer columns wins.

## Input is duck-typed (§3)

A plain hash in CR shape, or an object answering `TO_JSON`; a `List` hash with
`items` in place of the array. `TO_JSON` is asked at most eight times, so an
object that answers itself does not hang. `Kubernetes::Comb` and `IO::K8s` are
not dependencies; the test that wants the real CR classes skips without them.

`spec.enabled` and `status.upstream.reachable` are read as a tri-state: unset
is true, only a false value (`false`, `0`, `''`, the string `false`) says no.
A disabled cell has the phase `Disabled` even without a status.

**Dependency resolution.** `namespace/name` is the cell with that id; a bare
`name` is the cell of that name in the dependent's own namespace, else the
only cell of that name in the input. No match, or several equally good ones,
makes the entry missing — it stays in the tooltip and out of the layout. Of two
CRs with one id the first is kept.

**Never die.** An unknown phase, no `status` at all, `spec.enabled: false`, a
`dependsOn` name that is not in the input, a dependency cycle: each gives a
picture. A cycle is the trap — a naive recursive depth loops forever; the
cells of a cycle share one depth, below their deepest dependency outside it.
Only an element without `metadata.name` is an error.

## The picture (§6, §8)

One `<svg class="comb-svg" role="img">` with `xmlns`, a `viewBox` and no fixed
pixel size, labelled by `<title id="comb-title">` and `<desc id="comb-desc">`
(a generated summary such as "6 Combs: 5 Running, 1 Blocked"). Nothing outside
the document is referenced — the arrowhead is a `<marker>` inside it, no
`<script>`, no web font, system font stack only; light and dark through one
`<style>` with CSS custom properties and `prefers-color-scheme`.

**Deterministic.** No timestamps, no generated random ids. The order of the
output is fixed by the code, not by Perl's hash order: the phases have a
fixed order, the rows are sorted by name and id, the edges by `from` then
`to`. Coordinates are rounded to two decimals, so the same layout prints the
same everywhere. An unsorted `keys` makes the picture and the tests flaky.

**Escaped.** Everything from a CR goes through the one escape function for
text and the one for attributes: `& < > " '` become entities, characters XML
1.0 cannot carry are dropped, and everything outside ASCII is written as a
numeric character reference — so the document is pure ASCII whatever the
cluster sent. Never interpolate a CR value into the SVG directly. A `link`
href is allowed only when relative or `http(s):`; a dying callback leaves the
cell without a link.

**The markup is a public interface.** The custom properties (`--comb-running`,
`--comb-error`, … `--comb-bg`) and the class names (`comb`, `phase-<Phase>`,
`borrowed`, `disabled`, `hex`, `name`, `phase`, `reason`, `upstream`,
`legend-item`) are documented interface; the rest of the markup is not promised
to stay. A cell is a `<g class="comb phase-<Phase>">` with `data-name`,
`data-id` and `data-phase`, a dependency a `<path class="dep">` with
`data-from`/`data-to`, the legend a `<g class="legend">` per phase that
occurs. Only the rules that are needed are written: the `.name-small` and the
`.reason` rule go into the `<style>` only when a cell needs them — adding a
rule unconditionally changes the bytes of every picture.

**Text in a cell.** Text is estimated, not measured: 0.59 of the font size per
character. A name that does not fit is broken into two lines after a hyphen, a
dot or an underscore; when the two lines are too wide the name takes a smaller
font; what fits neither way is cut, the full name stays in the tooltip.

**The reason line.** A cell that is not `Running` shows why, in small text
under the phase. The text is the `reason` of the `Ready` condition, else of
the first condition that is not `True`; a reason that only repeats the phase
or says `NotChecked` tells nothing, and the first line of its `message`
stands in. A `Running` cell never has one.

## The CLI (§9)

`bin/comb-svg` reads JSON (a `List`, an array of CRs or one CR) from a file or
standard input and writes the SVG to standard output. Its flags: `--title`,
`--group-label`, `--layout`, `--columns`, `--rows`, `--aspect`, `--size`,
`--edges`/`--no-edges`, `--legend`/`--no-legend`, `--color KEY=COLOUR`
(repeatable), `--blink PHASES`, `--blink-seconds`, `--help`, `--version`.

`--aspect` takes `16:9`, `16/9` or a plain number. `--color` takes
`KEY=COLOUR` or `KEY=LIGHT,DARK`; a comma inside parentheses does not
separate. The options are case-sensitive and are not abbreviated. Exit 0 after
the SVG was written, and for `--help` and `--version`; exit 1 on any error,
with one line `comb-svg: message` on standard error.

## Tests (§10)

- No cluster, no network. Fixtures are JSON under `t/data/` — `cell/`,
  `layout/`, `svg/`, `cli/`. `t/00-load.t` loads the modules, `t/10-cell.t` the
  reading of a CR, `t/20-layout.t`/`t/25-packed.t` the layouts, `t/30-svg.t` the
  picture, `t/40-cli.t` the script as a process, `t/50-demo.t` the examples.
- Parse the SVG with a real XML parser (`XML::LibXML` with an XPath context)
  and assert on elements and attributes (`g.comb[data-name]`, `path.dep`), not
  on string offsets or regexes over the whole document. Determinism is its
  own test: render twice, compare bytes.
- `t/50-demo.t` runs `examples/demo.pl` and compares the bytes with the
  committed `examples/demo.svg` and `examples/monitor.svg`; a change to the
  drawing fails the suite until the examples are regenerated. `examples/png.sh`
  renders the two pictures to PNG; no test checks them.

```bash
prove -lr t/                 # the suite, offline
perl -Ilib examples/demo.pl  # regenerates the committed examples
```

## Boundaries

Nothing in `lib/` names a particular site, cluster or API group: the label key
for groups, group names and colours are options. SPEC §11 lists open decisions
— meeting one means a proposal, and the maintainer decides.
