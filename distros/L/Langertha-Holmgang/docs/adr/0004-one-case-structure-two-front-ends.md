# ADR 0004 — One case structure, two front ends

- Status: accepted
- Date: 2026-11-04
- Source: the project brief of 2026-11-04
- Tags: dsl, yaml, format

## Context

cai-platform's suites are data in suite format 2 (`suite.yaml` plus one file per case under
`cases/`), and over 200 cases exist in it. Writing new cases — above all generated ones —
is easier in Perl, with loops, a seed and templates.

## Decision

- **Suite format 2 loads unchanged.** The existing cases are not rewritten in one go; a
  loader change that would need a case edit is a regression.
- **A Perl DSL** in the style of `Test::More`, Moose or Dancer describes suites, cases and
  generators. Generators are plain Perl; a fixed seed always yields the same cases.
- **Both front ends build the same internal case structure** and feed the same lint and the
  same runner. Nothing downstream knows where a case came from.
- **DSL suites export to YAML**, so cases stay readable and comparable without Perl.

## Consequences

- The internal case structure is the contract; it is designed once, from format 2, and the
  DSL is sugar over it.
- Acceptance: one suite written in both forms gives identical results.
