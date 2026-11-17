# ADR 0001 — Sibling distribution, name, and extraction from cai-platform

- Status: accepted
- Date: 2026-11-04
- Source: the project brief of 2026-11-04
- Tags: distribution, naming, dependencies, migration

## Context

CitiAI's platform (`cai-platform`) measures models with tasks at simulated devices, graded
at the end state (`CAI::Platform::Eval::*`: Suite, World, Grader, Runner, Batch, the `Sim::*`
simulators and the `Gen::*` generators; 15 suites, over 200 cases). The principle has proven
itself, but it is bound to the platform: its model client, its database, its admin UI.
Measuring any Langertha engine, writing cases in Perl and sharing the engine as a CPAN
distribution needs it in a dist of its own.

## Decision

- Dist `Langertha-Holmgang`, namespace `Langertha::Holmgang`, repo
  github.com/Getty/langertha-holmgang — the sibling pattern of `langertha-knarr`,
  `langertha-raider` and `langertha-skeid`. The main module `Langertha::Holmgang` carries
  the DSL.
- **Dependency direction is one-way:** Holmgang → Langertha, never back. A model call goes
  through a Langertha engine; tokens come from `Langertha::Usage`. Anything Holmgang needs
  from Langertha and Langertha lacks becomes a card on the langertha board.
- The evaluation core is **lifted** out of cai-platform, not rewritten from scratch:
  behaviour that cai-platform's tests pin down keeps its meaning here. Platform parts (the
  model client `CAI::Platform::ModelTester`, database rows, admin UI, the master's queue per
  target) stay behind; Holmgang gets its own runner over Langertha.
- Afterwards cai-platform depends on Holmgang and keeps only storage, display and the model
  catalogue.
- Version line starts at **0.001**.

## Consequences

- During the extraction, cai-platform is the reference: a difference in a mock run between
  the two runners is a defect until explained.
- cai-platform is not edited from here. Work it needs goes to its own board.
