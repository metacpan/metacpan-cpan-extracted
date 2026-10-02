---
name: langertha-adr
description: Use when recording or backfilling an Architecture Decision Record in Langertha, or when asked whether a decision is ADR-worthy.
user-invocable: false
---

ADRs capture the **WHY** behind architecturally-significant Langertha decisions, so the
rationale survives refactors, releases and the next person who is tempted to "simplify" a seam
back into the engines. Read the existing `docs/adr/` entries as the canonical examples —
codify the format, do not reinvent it.

## Format

- File: `docs/adr/NNNN-kebab-title.md` — `NNNN` zero-padded 4 digits, monotonic per repo
- H1: `# ADR NNNN — Title` (em-dash)
- Metadata as a bullet list, directly under H1:
  - `- Status: proposed | accepted | superseded | deprecated`
  - `- Date: YYYY-MM-DD`
  - `- Tags: a, b, c`
  - optional, when they apply: `- Cross-links: ADR NNNN, CONTEXT.md`, `- Supersedes: ADR NNNN`
    / `- Superseded-in-part-by: ADR NNNN`, `- karr: #NNN`
- Sections (`##`): `Context` · `Decision` · `Rationale` · `Consequences`
- Optional last section: `## Future work` — drift to reconcile or follow-ups that should not
  block; name the karr ticket and stop. Don't do that work in the ADR.

## Amend, don't fork

When a later change refines an accepted decision without replacing its mechanism, append
`## Update (kNNN — <what changed, one line>)` to that ADR, stating the new fact and why. Keep
`Status: accepted`. Write a new ADR only when the mechanism itself is replaced; then set
`Supersedes:` on the new one and `Superseded-in-part-by:` (or `Status: superseded`) on the old.

## What counts as ADR-worthy

Two sorts, **both** count:

1. **Deliberate centralization / seam** — a decision to route many engines through one place:
   the `tool_wire_format` tag and the Tool/ToolCall/ToolResult/ToolChoice value objects; the
   `%ROLE_TO_CAPS` capability registry; `Response.tool_calls` as the single tool-call shape;
   the `chat_f` auto-rewrite matrix; the `TranscriptionBase` split; the model-scoped capability
   tables; the sync fallback of the `_f` transport.
2. **Deliberate keep** — structure a review tempted us to change and we chose **not** to (e.g.
   keeping a per-format branch explicit rather than over-abstracting it).

Architecturally significant = touches the public API, engine/role composition, the tool
wire-translation seam, capabilities, structured-output handling, request-control wire formats,
response observability seams, streaming, or the async transport. Raider decisions (since ADR
0026) are recorded in langertha-raider's own `docs/adr/`; 0007/0008 stay here as history.
**Not** ADR-worthy: local style, naming, single-use code.

## Where ADRs come from — backfill, structure first

Langertha is not a fork, so there is no upstream baseline to diff against. Recover decisions
already living in the structure:

1. **Structure first** — walk the `Langertha::` namespaces: what is centralized, what each
   base class / role owns, which seam every engine routes through.
2. **Code is the ground truth** — read the actual dispatch (`Role::Tools`, `Role::Capabilities`,
   the value objects). Public method names matter: cite them exactly.
3. **`CONTEXT.md`** is the distilled vocabulary of the tools-lane discussion — the strongest
   single record of intent for that area. Hold it against the code; where they disagree, that
   drift is a finding (record it, or file a karr reconciliation ticket).
4. **Git history** — the refactor commits and their messages confirm the WHY.
5. To judge significance, use the implementer vocabulary in `langertha-internals` (and the
   public API in `perl-ai-langertha`).

## Two run modes

- **audit-only** — report which significant decisions lack an ADR (a gap list); file gaps as
  karr tickets. Write no files. Good for a gentle first pass and recurring drift checks.
- **audit+write** — the same survey, then write the missing ADRs in the format above.

## Numbering

Per repo, monotonic from `0001`. Read the existing `docs/adr/` for the highest number; never reuse.

Parallel worktree branches pick numbers independently. Before merging, re-read `docs/adr/` on
the target branch; if the number is taken, the later branch renumbers (file name, H1 and every
reference).

Every new ADR also gets its one-line entry in the ADR index in `CLAUDE.md`, and a row in the
area map below, in the same commit.

## Which ADR owns which area

Read the owning ADR before changing an area. A change that contradicts it amends that ADR in
the same change, or stops and reports.

| Area | ADRs |
|---|---|
| Tool value objects, `tool_wire_format`, inbound `extract` / outbound `to` | 0001, 0010, `CONTEXT.md` |
| Server-side tools (`ServerTool`, `server_tools`, `server_tool_calls`, citations) | 0030 |
| `Response.tool_calls` as the single source | 0003 |
| Structured output ↔ forced tool, the `chat_f` rewrite matrix | 0005 |
| Capability registry, per-engine / per-model corrections, pairwise exclusions | 0002, 0019, 0021, 0024 |
| Learned model capabilities (metadata probe, `ModelProbe`, `model_metadata_format`) | 0032 |
| Dialect inheritance vs capability roles, `*Compatible` envelopes, `-excludes` | 0006, 0013, 0015, 0016, 0020 |
| Wire extras on the body / `Response` | 0004 |
| Request-side controls (reasoning, cache, knobs), temperature gate | 0009, 0012, 0023, 0025 |
| Gemini bound `cachedContent` vs request `systemInstruction` / `tools` / `toolConfig` | 0035 |
| Normalizing a provider's wire spelling | 0018 |
| Response observability: timing, `created`, rate-limit reset | 0011, 0017, 0022 |
| Usage cache counts, `Pricing` cache rates, `Cost` | 0031 |
| Runtime metrics scrape | 0014 |
| Async transport, sync fallback | 0027 |
| Redirects: credential policy on both transports (`HTTP::Redirect`, `HTTP::UserAgent`) | 0036 |
| Connection pinning (`connect_address`, DNS rebinding) | 0037 |
| Distribution boundary (Raider extraction) | 0026 (0007/0008 history) |

## Companion

`CONTEXT.md` is the domain language (ubiquitous terms), not a decision log — ADRs link to it,
they don't restate it. Langertha implementer vocabulary → `langertha-internals`.
