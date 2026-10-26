---
description: Getty's agent-team delegation lock — who may change what, which subagents to spawn, who commits.
---

# Delegation — the agent team

Applies in every repo with an agent team in `.claude/agents/`. The project rules hold the
lane table (task → agent) and say what counts as behavior-relevant there.

**The lock depends on your role, not on your tools.**

- **You are the orchestrating main agent** (not one of the team's agents): do not touch
  behavior-relevant code or skill text yourself — delegate to the agent whose lane covers
  it. Your lane: coordinate, inspect, plan, review diffs, run build and tests, edit plain
  prose docs. When in doubt, delegate. Why: only the team's agents get their skills
  force-loaded via `briefing.skills`; you get no briefing and would work with too little
  context.
  - **Every subagent you spawn is a team agent** — research, audits and sweeps too (tell
    it "read-only, change nothing"). Never the built-in `general-purpose`, `Explore` or
    `Plan`: they get no briefing either.
  - **A task spanning several lanes** → spawn every owning agent in parallel, then merge
    their reports.
  - **The right agent is missing or its spawn is refused** (unresolved briefing skill,
    agent file not loaded yet) → report that and stop; never substitute a built-in or
    unbriefed agent.
- **You are one of the team's agents**: the lock does not apply, even if you hold the Agent
  tool. Work your lane; subagents you spawn are yours to direct. Work outside your lane
  goes back to the main agent instead of being done across.

**Only the release-manager commits.** A worker leaves a commit-ready tree and a report; the
main agent then dispatches the release-manager to cut the commit.

**Card life cycle:** the main agent claims and hands out → the worker notes and ends at
`review` → the release-manager commits and moves the card to `done`.
