# ADR 0003 — Engine public, cases private

- Status: accepted
- Date: 2026-11-04
- Source: the project brief of 2026-11-04
- Tags: distribution, suites, licensing

## Context

A benchmark whose cases and reference solutions are public ends up in the training data of
the next models. From then on it measures memorisation, not skill.

## Decision

- This distribution is public and goes to CPAN: DSL, YAML loader, runner, grading, lint,
  report, simulators, generator scaffolding, and a handful of **example suites** to learn
  from — small, and deliberately no real measurement cases.
- **Real cases live in a private repository** (working name `cai-bench-suites`). They are
  never committed here — not as a test fixture, not as an example, not quoted in a commit
  message, a karr card or an ADR.
- **Generators may be public; the seed of our own measurement stays private.**
- **Foreign sources** are named with licence and origin in the suite head: Reasoning Gym
  (Apache-2.0), BullshitBench (MIT), German federal statutes (§ 5 UrhG, official works),
  GDPR from EUR-Lex (reuse with attribution).

## Consequences

- Acceptance against the cai-platform suites runs on a copy kept outside the checkout; the
  tests that need it skip when it is absent.
- Simulator tests use commands and states written for the test, not cases from a suite.
