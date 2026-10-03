# Kubernetes::Comb::SVG — Design Spec

Status: first draft by the coordinator, 2026-10-02. Open points are in §11.

## 1. Idea

A cluster run with `Kubernetes::Comb` holds one `Comb` custom resource per
Comb. This dist turns a set of those CRs into **one SVG picture**: a honeycomb
with one hexagon per Comb, coloured by phase, with the dependencies drawn
between them. The picture is a plain string — a web page embeds it, a CLI
writes it to a file. Whoever shows it (for example a status page in a site's
own tooling) fetches the CRs and serves the result; this dist does neither.

## 2. Goals and non-goals

Goals:

- One call from data to a complete, self-contained SVG document.
- Readable at a glance: which Combs exist, which are healthy, what blocks what.
- Deterministic: same input, same bytes — so tests can pin output and a page
  can cache it.
- Safe to embed: every string from the cluster is escaped.
- Light: no cluster client, no web framework, no image libraries.

Non-goals:

- No cluster access. The caller hands in the CRs.
- No web server, no HTML page, no JavaScript, no live updating.
- No raster output (PNG) and no layout engine dependency (Graphviz).
- No site policy: label keys, group names and colours are configuration.

## 3. Input

`combs` is an array reference. Each element is one Comb CR, either

- a plain hash in CR shape (what `kubectl get combs -o json` puts in `items`), or
- an object that answers `TO_JSON` with such a hash (the IO::K8s classes
  `Kubernetes::Comb::CRD::Comb` do).

A hash with `items` (a `List`) is accepted in place of the array.
`Kubernetes::Comb` and `IO::K8s` are **not** dependencies: the input is duck-typed.

Fields read, all optional except the name:

| CR path | Used for |
|---|---|
| `metadata.name` | cell label and identity (required) |
| `metadata.namespace` | tooltip |
| `metadata.labels.<group_label>` | group, when `group_label` is set |
| `spec.class` | tooltip |
| `spec.enabled` | `false` → drawn as `Disabled` even without a status |
| `spec.dependsOn` | dependency edges and row placement |
| `status.phase` | colour and phase text; missing → `Unknown` |
| `status.conditions[].message` | tooltip, when the phase is not `Running` |
| `status.conditions[].reason` | the visible reason line, when the phase is not `Running` (§6) |
| `status.endpoints[]` | tooltip (`name port`) |
| `status.upstream` | "borrowed" marking (see below); `class`, `context` and `via` in the tooltip |

Phases known to `Kubernetes::Comb`: `Running`, `Pending`, `Blocked`,
`NeedsConfig`, `Disabled`, `Error`, `Stopped`, `NotDeployed` — the eight its
`CombStatus` names, in that order. `Stopped` (scaled to zero on purpose) and
`NotDeployed` (nothing rolled out yet) are states of rest, not faults. Any
other string is drawn as `Unknown` with the original text in the tooltip —
never an exception.

**Borrowed.** A cell is borrowed when the Comb really takes its service from
an upstream: `status.upstream` is recorded, its `reachable` is not `false`,
and the phase is `Running` or `Pending`. Those are the two phases
`Kubernetes::Comb` ends its upstream path in, with the bridge in place
(`Pending` while the upstream itself is not `Running`). In any other phase a
recorded `status.upstream` is only what an earlier step left behind, or an
upstream the Comb did not get to — `NeedsConfig`, `Blocked`, `Disabled`,
`Error` — and the cell is not marked. The record still shows in the tooltip.

**Identity.** A cell is identified by `namespace/name` (by `name` alone when
the CR has no namespace), so `kubectl get combs -A` may carry the same name in
two namespaces. A `spec.dependsOn` entry is `name` or `namespace/name`, as in
`Kubernetes::Comb`: a bare `name` means the Comb of that name in the
dependent's own namespace, else the only Comb of that name in the input;
anything that matches no cell, or more than one, is a missing dependency. Of
two CRs with the same identity the first is kept.

## 4. Building blocks

| Module | Job |
|---|---|
| `Kubernetes::Comb::SVG` | facade: `new(combs => ..., %options)`, `render` returns the SVG string |
| `Kubernetes::Comb::SVG::Cell` | one normalised Comb: name, namespace, class, phase, depends_on, endpoints, borrowed, group, message, reason |
| `Kubernetes::Comb::SVG::Layout` | places cells: groups, rows, columns, coordinates, canvas size |
| `bin/comb-svg` | reads JSON from a file or stdin, prints the SVG |

Reading the CR happens only in `Cell`; drawing only in `SVG`; `Layout` knows
neither CR nor SVG — it takes cells and returns coordinates.

## 5. Layout

- **Groups.** With `group_label` set, cells are grouped by that label's value;
  cells without it go to a last, unnamed group. Without `group_label` there is
  one group. Groups are stacked top to bottom in name order, each with its
  name as a heading.
- **Rows by dependency depth.** Inside a group, a cell with no dependency in
  the picture is in row 0; otherwise it is one row below its deepest
  dependency. So "what must be up first" is always above.
- **Cycles and unknown names.** A `dependsOn` name that is not in the input is
  ignored for placement and listed in the tooltip as missing. A dependency
  cycle must not hang or die: the cells of a cycle share one row.
- **Order.** Inside a row, cells are sorted by name.
- **Honeycomb.** Pointy-top hexagons; every second row is shifted by half a
  cell, so rows interlock. A row longer than `columns` (default 6) wraps into
  the next rows.
- Depth is computed over all cells, so an edge between groups still points
  the right way.

### Packed layout — the status monitor

`layout => 'packed'` is for a wall screen: every Comb visible at once, as one
compact honeycomb, so that anything not green stands out immediately.

- Dependencies play no part in placement: cells are sorted by
  `namespace/name` and fill the rows left to right, top to bottom. A cell
  keeps its place as long as the set of Combs is the same — phases changing
  never moves anything.
- The grid is chosen by the caller, in this order of precedence:
  `columns` (cells per row), else `rows` (number of rows; columns follow from
  the cell count), else `aspect` (width divided by height of the target area,
  for example `16/9`; the column count whose honeycomb comes closest to that
  shape is used). With none of the three, `aspect` defaults to `16/9`.
- Groups still work when `group_label` is set: each group is its own packed
  block. Without it there is one block.
- Edges default to off in packed layout (`edges => 1` turns them back on).
- The default `layout` stays `'depth'` (rows by dependency depth, as above).

## 6. The picture

- Root `<svg>` with `xmlns`, a `viewBox` and no fixed pixel size — it scales
  with its container. `role="img"`, plus `<title>` and `<desc>` (from `title`
  and a generated one-line summary such as "6 Combs: 5 Running, 1 Blocked").
- One `<style>` element inside the SVG, colours as CSS custom properties, and
  a `@media (prefers-color-scheme: dark)` block. No external reference of any
  kind: no web font, no stylesheet link, no image, no script.
- One `<g class="comb phase-<phase>">` per cell, with `data-name` and
  `data-phase`, holding: a `<title>` tooltip, the hexagon, the name, and the
  phase as text below it. Phase is never carried by colour alone.
- A name that does not fit on one line is broken into two lines after a
  hyphen, a dot or an underscore — at the break that leaves the shorter
  longest line — and, when that is still too wide, set in a smaller font.
  Only what fits neither way is cut with an ellipsis; the full name stays in
  the tooltip. A name that fits on one line is drawn as before.
- **Reason.** A cell that is not `Running` shows why, in small text
  under the phase text — a wall screen has no tooltip. What does not fit on
  one line is broken into two, at a space or before a capital inside a word
  (`Missing` / `Prerequisites`); only what still does not fit the cell's
  width is cut with an ellipsis. The text is the `reason` of the `Ready` condition,
  else of the first condition that is not `True`; a reason that only repeats
  the phase (`Disabled`, `Stopped`) or says `NotChecked` tells nothing, and
  the first line of that condition's `message` stands in. Without either
  there is no line. A `Running` cell never has one.
- **Borrowed** (the Comb really borrows, §3): dashed outline and a small
  line naming the upstream context. The tooltip names the upstream of every
  cell that records one — its class and context, and `via` — and says so when
  the cell is not borrowing from it.
- **Disabled**: muted fill and text.
- **Edges**: one `<path class="dep">` per dependency, from the dependent cell
  to its dependency, with an arrowhead at the dependency. Edges are thin and half transparent
  and are drawn before the cells; hexagon fills are translucent, so a long
  edge crossing other cells stays visible through their fills and under
  their labels — while each cell stays one `<g>`.
- **Legend**: the phases that occur, with their colours and counts.
- With a `link` callback, a cell is wrapped in `<a href="...">`.

Default colours (overridable through `theme`): Running green, Pending amber,
Blocked orange, NeedsConfig violet, Disabled grey, Error red, Stopped cyan,
NotDeployed blue, Unknown slate. The two states of rest take cool colours,
away from the warm ones that mean "look here".
Text must stay readable on every fill in both light and dark mode.

**Theme.** A `theme` value is either one colour, used in light and dark, or a
hash `{ light => ..., dark => ... }`. Besides the phases, the keys `bg`, `fg`,
`muted`, `border` and `edge` recolour the picture's own surfaces, so it can
match the page or screen it sits on. Only plain colour syntax is accepted
(hex, `rgb()`/`hsl()`, a colour name); anything else falls back to the default.

**Blink.** `blink => [ 'Error', 'Blocked' ]` makes the cells of those phases
pulse, through a CSS animation inside the SVG's own `<style>` — no script.
`blink_seconds` (default `1.2`) sets the period. Inside
`@media (prefers-reduced-motion: reduce)` the animation is off and the cell
gets a thicker outline instead, so the signal survives without motion.

**Styling from outside.** When the SVG is inlined into a page, that page's CSS
can restyle it: every colour is a custom property (`--comb-running`,
`--comb-error`, ... `--comb-bg`) on the root element, and every cell carries
`class="comb phase-<phase>"`. The property and class names are part of the
public interface and documented in the POD.

## 7. Options

| Option | Default | Meaning |
|---|---|---|
| `combs` | required | the CRs, see §3 |
| `title` | `Combs` | SVG `<title>` and the heading |
| `group_label` | none | label key that names a cell's group |
| `layout` | `depth` | `depth` (rows by dependency depth) or `packed` (§5, status monitor) |
| `columns` | `6` | cells per row; in `depth` layout a longer row wraps |
| `rows` | none | `packed` only: number of rows, when `columns` is not given |
| `aspect` | `16/9` | `packed` only: target width/height, when neither `columns` nor `rows` is given |
| `size` | `56` | hexagon radius in SVG units |
| `edges` | `1`, `0` in `packed` | draw dependency edges |
| `legend` | `1` | draw the legend |
| `link` | none | coderef `($cell) → href or undef` |
| `theme` | built in | hash `phase or surface → colour` or `→ { light, dark }`, merged over the defaults |
| `blink` | none | phases whose cells pulse |
| `blink_seconds` | `1.2` | period of the pulse |

## 8. Escaping

Every value that comes from a CR — names, namespaces, messages, label values,
contexts — is XML-escaped wherever it lands: text, `<title>`, attributes. A
`link` result is escaped as an attribute and refused unless it is relative or
`http:`/`https:`. A Comb named `</svg><script>` must come out as text.

## 9. CLI

    kubectl get combs -A -o json | comb-svg --group-label app.kubernetes.io/part-of > combs.svg
    comb-svg combs.json --title "Lab" --columns 4 --no-legend
    comb-svg combs.json --layout packed --aspect 16:9 --blink Error,Blocked --color Error=#ff0033

Reads a `List`, an array of CRs or one CR; writes the SVG to stdout. Bad JSON
or an element without `metadata.name` → message on stderr, exit 1.

## 10. Testing

- No cluster, no network, ever. Fixtures are JSON files under `t/data/`.
- The output is parsed with a real XML parser in the tests (test-only
  dependency) — well-formed, and assertions look at elements and attributes,
  not at string positions.
- Pinned behaviours: every phase; unknown phase; missing status; disabled;
  borrowed; groups; depth rows; wrap at `columns`; cycle; unknown dependency;
  escaping (text and attribute); `link`; `edges`/`legend` off; determinism
  (two renders are byte-identical); empty input gives a valid, empty picture.
- `examples/demo.pl` renders `examples/demo.json` to `examples/demo.svg`; the
  committed `demo.svg` is what the README links to, and a test checks it is
  current. `examples/png.sh` renders both example pictures to PNG for the
  README and the POD; the PNG files are not part of the release and no test
  checks them.

## 11. Open points

- Whether a cell should show pod readiness (`2/3`) — needs data the CR does
  not carry today.
- Whether groups should be laid out side by side on wide canvases.
- An HTML wrapper with auto-refresh is the caller's job for now.
