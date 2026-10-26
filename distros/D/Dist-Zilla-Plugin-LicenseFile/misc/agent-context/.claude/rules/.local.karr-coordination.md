---
description: Coordinating work on a karr board — always in scope for the orchestrating agent, serialized board writes, cross-repo handoff.
---

# Coordination — karr board

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — use it
directly; skill `kanban-issues-karr-coordination` holds the full command surface. Git-native
kanban; state lives in `refs/karr/*`, one board per repo.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

**Serialize board writes when fanning out.** Implementation may run in parallel; collect the
results, then loop `move`/`handoff`/`sync` one after another — N of them landing at once has
OOM-rebooted a host.

**Check once, act.** No background poll loops on the board.

**Drift found mid-change becomes a ticket**, not scope creep.

**Cross-repo work is a ticket on the other repo's board** — never a silent edit there,
unless the project rules allow direct edits.
