# ADR 0002 — Deterministic grading at the end state

- Status: accepted
- Date: 2026-11-04
- Source: the project brief of 2026-11-04; cai-platform `docs/entwurf-evals.md` §3.0
- Tags: grading, simulation, tools

## Context

Judge models and text comparison measure how an answer sounds, drift with the judge, and
cannot tell a correct fix from a well-written wrong one. cai-platform removed its judge and
grades only the state its simulated devices end up in; that turned out sharp and
reproducible.

## Decision

- **Graded is only what the model brought about through tools.** Rules check the end state
  of the world (`state`, `unchanged_except`), and calls only where the task needs them
  (`calls`, `not_called`, `only_tools`). No judge model, no rubric, no free-text comparison,
  no partial credit for similar answers. The text of the final answer does not count.
- **Every correct path counts.** There is exactly one correct class of end states; where two
  paths would lead to different end states, the task names the one.
- **Tools reveal nothing.** Only general tools with real syntax, the same for every case of a
  suite. No tool or parameter name names the fault.
- **The simulation understands the commands.** A change is visible in every later read. A
  command that does not exist on the simulated system gets the real error. A real command the
  simulator does not model gets a neutral answer and is recorded as a simulation gap; a
  failed case with a gap is *uncertain*, not failed.
- **Side damage shows up.** Restarts, stopped services and foreign configuration removed all
  change the state, and every case's "nothing else changed" rule sees them.
- **Nothing runs on a real system.** Simulators work only on their state.
- **Every case checks itself on every load** (lint): doing nothing fails, the reference
  solution and every alternative pass without a failed call or a gap, every wrong solution
  fails, at least one required rule checks the end state; a mock replaying the reference
  solution passes twice identically, a text-only mock fails. A case that does not hold does
  not load.

## Consequences

- A wrong verdict is fixed in the case or in the simulator, never by loosening lint.
- Simulators carry most of the code; a gap is a work item for the simulator, not for the
  model.
