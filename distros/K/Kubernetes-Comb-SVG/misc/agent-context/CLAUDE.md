# CLAUDE.md

## Project

**Kubernetes::Comb::SVG** — renders a set of `Kubernetes::Comb` custom resources
as one self-contained SVG honeycomb: one hexagon per Comb, coloured by phase,
with dependency edges. Data in, SVG string out — no cluster access, no server.

The design is in `SPEC.md` — read it before changing anything. An open-source
CPAN distribution: no site-specific policy (label keys, group names and colours
are configuration).

## Build

Dist::Zilla with `[@Author::GETTY]`, dependencies in `cpanfile`.

```bash
prove -lr t/        # whole suite, no cluster and no network needed
dzil test
perl -Ilib examples/demo.pl   # regenerates examples/demo.svg
```

## Invariants

- **Data in, string out.** `combs` are CR-shaped hashes or objects answering
  `TO_JSON`; `render` returns the SVG. `Kubernetes::Comb` and `IO::K8s` are not
  dependencies.
- **Deterministic.** Same input, same bytes: no timestamps, no random ids, hash
  keys sorted before they reach the output.
- **Self-contained output.** No script, no external reference (font,
  stylesheet, image) in the SVG.
- **Everything from a CR is escaped** wherever it lands — text, `<title>`,
  attributes.
- **Never die on odd data.** Unknown phase, missing status, dependency cycle,
  unknown dependency name → a picture, not an exception. Only an element
  without a name is an error.
- **Three seams.** `Cell` reads the CR, `Layout` places cells, `SVG` draws.

## Conventions

- Moo. Inline POD per `[@Author::GETTY]` PodWeaver (`=attr`, `=method`,
  `=seealso`), `# ABSTRACT:` on every `.pm`.
- `use Module;` to load.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/kubernetes-comb-svg-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `kubernetes-comb-svg-worker` (default) |
| Write/extend tests, fixtures under `t/data/` | `kubernetes-comb-svg-test-writer` |
| POD in the house format | `kubernetes-comb-svg-pod-writer` |
| Commits, packaging (`dist.ini`, `Changes`, `LICENSE`, CI), card → done, pre-release audit | `kubernetes-comb-svg-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Architecture and invariants live in the
project skill `.claude/skills/kubernetes-comb-svg-core/`; the shared house skills are
installed by skilletor from `.claude/skilletor.json` (gitignored build artifacts —
change them in their source repo, never here).
