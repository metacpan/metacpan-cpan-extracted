---
name: dbio-adr
description: Use when recording or backfilling an Architecture Decision Record in a DBIO repo, or when asked whether a decision is ADR-worthy.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

ADRs capture the **WHY** behind architecturally-significant DBIO decisions, so the
rationale survives squashes, forks and refactors. The convention below already exists in
the family (`dbio-sybase/docs/adr/0001`, `dbio-duckdb/docs/adr/0001`) — **codify it, never
reinvent it**.

## Format (read the two existing ADRs as the canonical examples)

- File: `docs/adr/NNNN-kebab-title.md` — `NNNN` zero-padded 4 digits, monotonic **per repo**
- H1: `# ADR NNNN — Title` (em-dash)
- Metadata as a bullet list, directly under H1:
  - `- Status: proposed | accepted | superseded | deprecated`, optionally followed by ` — <qualifier>` (e.g. `accepted — superseded in part by ADR 0030`)
  - `- Date: YYYY-MM-DD`
  - `- Tags: a, b, c` (optional)
- Sections (`##`): `Context` · `Decision` · `Rationale` (optional — may fold into Decision) · `Consequences`
- Optional last section: `## Future architecture work (tracked cross-repo, not here)` — when a
  related change is owned by another repo, name the karr ticket and stop. Don't do that work here.
- **Reference code by module path + sub/method name, never by line number.** Line numbers drift on every refactor (the ADR 0034 refs moved twice in two days); write `_resolve_find_query` in `lib/DBIO/ResultSet.pm`, not `lib/DBIO/ResultSet.pm:804`.

## What counts as ADR-worthy

Two sorts, **both** count:

1. **Divergence** — where DBIO deliberately differs from DBIx::Class (fork decisions: Fork-rename,
   SQL::Translator made optional, Loader → DBIO::Generate, `apply_limit` over `limit_dialect`,
   async storage model, native Deploy/Introspect/Diff), or where a driver differs from the
   standard driver pattern (duckdb: FKs omitted from install DDL).
2. **Deliberate keep** — structure that a review tempted us to change and we chose **not** to
   (sybase: keep the per-engine subdir-helper layout for cross-driver symmetry).

Architecturally significant = touches public API, SQL generation, transactions,
Deploy/Introspect/Diff, the driver pattern, type mapping, async, or cross-driver symmetry.
**Not** ADR-worthy: local style, naming, single-use code.

## Where ADRs come from — two directions

- **Forward** (a decision crystallising now): `improve-codebase-architecture` /
  `grill-with-docs` write the ADR as the decision is made. They presuppose `docs/adr/`.
- **Backward** (this skill's archaeology — recover decisions already in the structure):
  1. **Structure first** — walk the `DBIO::` namespaces: what's renamed, removed, added.
  2. **Upstream diff** — hold `DBIO::X` against `DBIx::Class::X`; the divergence *is* the
     decision. (Core only — drivers diff against the standard driver pattern instead.)
  3. **Git history** — the fork/squash commit and its messages.
  4. **karr boards across the family** — the pre-squash diagnostic tickets already record fork
     divergences with `file:line` rationale (e.g. `apply_limit` replacing `limit_dialect`; the
     native-Deploy `deployment_statements()` contract change; the deliberate paren-restore in
     `DBIO::SQLMaker`). Read core's board and the driver boards (`karr list` / `karr show`).
  5. **Archived specs** — one confirming source among the above, **never the starting point**.
     Do not begin from the archived superpowers specs; begin from structure, confirm the WHY here.

  To judge significance, load the repo's architecture skill on demand — [[dbio-core]] in core,
  [[dbio-driver-development]] in a driver.

## Cross-repo ownership (critical)

A decision owned by **core** gets a **core** ADR — never duplicated in a driver. When a driver
review surfaces a core-owned consolidation, file a karr ticket to core and record it under
`## Future architecture work (tracked cross-repo, not here)` (see `dbio-duckdb/docs/adr/0001`).
Who owns what → [[dbio-coordination]].

## Two run modes

- **audit-only** — report which significant decisions lack an ADR (a gap list); file gaps as
  karr tickets. Write no files. Good for a gentle first pass and for recurring drift checks.
- **audit+write** — the same survey, then write the missing ADRs in the format above.

## Correcting an accepted ADR

An accepted ADR is not rewritten silently. Two cases:

- **Pure enumeration or structure** (a list of modules, a count, a file layout that was or
  became wrong): correct it **inline**. No trace is needed; the ADR states what is true.
- **A consequence that was true when the ADR was written** and was overtaken later: leave
  the text, and add a **dated addendum**. At the affected passage put an
  `**Amended YYYY-MM-DD (kNN):**` pointer saying what changed in one or two sentences and
  naming the addendum; at the end of the ADR add a `## Addendum YYYY-MM-DD — <what changed> (karr kNN)`
  section with the detail. Examples in core: ADR 0032 (amended 2026-07-27 and 2026-09-25)
  and ADR 0053 (addendum 2026-10-04). A decision that is replaced as a whole is not an
  amendment: write a new ADR and set the old one's Status to `superseded`.

## Numbering

Per repo, monotonic from `0001`. Read the existing `docs/adr/` for the highest number; never reuse. A driver ADR that elaborates a core ADR takes its own next number and names the core one in its context ("Core ADR NNNN"); it may carry the core number as a tag (`adr-0030`), not as its file number.

## Companion

`CONTEXT.md` is the domain language (ubiquitous terms), not a decision log — ADRs link to it,
they don't restate it. DBIO architecture vocabulary → [[dbio-core]].
