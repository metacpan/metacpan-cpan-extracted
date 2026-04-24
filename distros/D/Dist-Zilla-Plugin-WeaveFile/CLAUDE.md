# CLAUDE.md — Dist::Zilla::Plugin::WeaveFile

<!-- IAS Framework Template v1.2 — https://codeberg.org/openearth/ias
     Generated from CLAUDE.template.md.j2 by ias/tools/generate-claudemd.py.
     Keep all gates even if slim — the protocol's value compounds across sessions. -->

## MANDATORY: L2D&D\\|/D2L&D Pre-Flight (read EVERY session before writing ANY code)

This is the **L2D&D\\|/D2L&D spiral** (Learning to Do \\|/ Doing to Learn) with **CONDOC** (Continuous Documentation). Learning, doing, and documenting are inseparable — all three must be CONSCIOUS and SIMULTANEOUS. Documentation is not a step after work — it IS the work. If you changed something and no doc was updated, the change is incomplete.

The JSON files are the proof. If `.ias/supply-chain.json` shows level 0 for a component you just used, you skipped the spiral. If a procedure has no guide, a future team member can't reproduce it.

### Gate 0: Session Start (EVERY session, NO exceptions)

**FIRST RESPONSE — MANDATORY:** Regardless of what the user's first message says, your VERY FIRST response in every new session MUST be the Gate 0 cost check. Read `.ias/session-costs.json` (live file only — archives are read on demand), compute the Gate 0 cost estimate from `.ias/gate0-manifest.json`, present the table, and ask "Proceed with Gate 0?" THEN address whatever the user originally asked.- Read `.ias/supply-chain.json` — know what's forked, built, assimilated
- Read `.ias/entities.json` — know all canonical names- Scan `.claude/projects/*/memory/MEMORY.md` — check for feedback corrections- **Cost check (pre-read):** Read `.ias/session-costs.json` FIRST (before the other config reads). **Stale session cleanup:** Scan `active_sessions` — any entry with `status: "active"` from a DIFFERENT session ID is stale (previous session exited without Gate 9). For each: close its `current_period`, move to `completed_sessions`, roll costs into `cumulative`. Report: "Recovered N stale session(s), $X rolled into cumulative." Then create YOUR session's entry. Check `pricing.last_verified` — if > 30 days stale, warn. Compute Gate 0 cost estimate using `.ias/gate0-manifest.json` pre-computed sizes, present table, ask "Proceed with Gate 0?" Wait for confirmation.
- **Archive housekeeping:** if `.ias/session-costs.json` is > 15k chars OR contains sessions ended > retain-days ago, propose `python3 tools/archive-session-costs.py --retain-days N` (default N=3; user may override at Gate 0 prompt). Archive target: `.ias/archive/session-costs/YYYY-MM.json`. See `ias/protocol/cost-tracking-v1.0.md` §Archive.
- **Cost report (post-read):** After executing Gate 0 reads, show the same table with actual char counts. Store as a `gate0` period. Open a `work_1` period.
- **Graceful exit reminder:** At the end of the Gate 0 post-read report, include: "Tip: say 'closing session' before /exit so costs can be finalized."
### CONDOC: Continuous Documentation (fires DURING every gate, not after)

Every action produces documentation as a side effect. Not "do then document" — "document AS you do."

- **Learning something?** Update BOTH the component's `.ias/supply-chain/<name>.json` projection AND `.ias/supply-chain.json` mother in the SAME commit, then `tools/project-supply-chain.py --regen`. Narrative lives in the projection's `key_learnings` + `gotchas_found`.
- **Building a procedure?** Write the guide AS you figure out the steps, not after.
- **Hitting a gotcha?** Add to `tools/shell-gotchas.md` IMMEDIATELY, before fixing the code.
- **Changing config?** Update the doc that references it IN THE SAME EDIT SESSION.
- **Writing a script?** The script's `--help` and the companion `.md` guide are written TOGETHER.
- **Spawning an agent?** IMMEDIATELY after the Agent tool returns, log the cost to `.ias/session-costs.json`.
- **Test:** If you just did something and a new team member couldn't reproduce it from the docs alone, you skipped CONDOC.

### Gate 1: Before Touching Any External Component- Find component in `.ias/supply-chain.json`. Check `assimilation.level`.
- If level < 2: **STOP.** Read its docs/source FIRST. Update JSON + skill file BEFORE coding.
- If `fork` is null and `critical: true`: **STOP.** Fork it first. You cannot use what you don't control.
- After reading source: update `.ias/supply-chain.json` (level, docs_read, key_learnings) BEFORE writing code.
### Gate 2: Before Writing Any Entity Name- Look it up in `.ias/entities.json`. If not there, add it first.
- After any entity name change: run validation.- Goal: a clean **bijection** — each key maps to exactly one string, each string maps back to exactly one key.
### Gate 5: Before Testing / Running Scripts

- **Dry-run first**: every script that creates/modifies/deletes must have `--dry-run`
- **Test one, then many**: create one item, verify, then batch
- **Test ALL code paths**: tear down state to exercise both forks of every if-then-else- **Testing ladder**: Local → Dev → Production (or the subset your project uses). Never skip a level.- After file generation: check exists AND non-zero size

### Gate 6: Before Adding ANY Dependency

- Add to `.ias/supply-chain.json` with assimilation level- Add to project manifest (`dist.ini:Prereqs`)- Check license compatibility
- Check jurisdiction if relevant (e.g., US CLOUD Act exposure for EU-resident projects — a US-controlled vendor may be compelled to disclose data regardless of where servers sit)
- Update CLAUDE.md if it changes the dev workflow
### Gate 8: Output Discipline (ALWAYS)

- Never output file content to screen — Write it to disk with Write tool
- If no target path given, write to `scratch/{timestamp}.txt` and say where
- Minimize whitespace in all output. Every character costs the user money.
- When user asks "give me content for X": write directly, don't show on screen
- When generating content bound for an external tool (messaging platforms, PDF generators, deployment configs, etc.): write to `scratch/` or the destination path, report the path only — never echo the content itself. Content that will be consumed by another tool never needs to flow through the chat.
- Dates and times: use the system clock (`date +%Y-%m-%d`, `date -u +%Y-%m-%dT%H:%M:%SZ`) rather than relying on a context-provided `currentDate` field. Context clocks and system clocks can drift (time zones, UTC vs local, cache staleness) and every surface that records the date should agree.

### Gate 9: After Writing Code, Testing, OR Succeeding (D2L&D — the return spiral)

This gate fires on ALL outcomes — failure, success, and everything between. Success is ESPECIALLY easy to skip because it feels done. It isn't done until documented.

- **After failure:** Record gotcha → `tools/shell-gotchas.md`. Update the component's `.ias/supply-chain/<name>.json` projection AND `.ias/supply-chain.json` mother in the same commit, then `tools/project-supply-chain.py --regen`.
- **After success:** Document WHAT worked, WHICH code paths were verified. A success that isn't recorded is a success that can't be reproduced.
- **After any change:** Update projection + mother (`.ias/supply-chain/<name>.json` + `.ias/supply-chain.json`) for component state; new entities go in the mother `.ias/entities.json`, then `tools/project-entities.py --regen` + validate.
- **Test:** Ask yourself: "If a new team member ran this tomorrow with only the docs, would they succeed?" If no, Gate 9 is incomplete.- **Cost period close:** Close your current open period in `.ias/session-costs.json`. Set `closed_by: "session_end"`, finalize estimated tokens and cost.
- **On git commit:** Close current cost period with `closed_by: "commit"`, `commit_sha: "<sha>"`. Open a new period.
## Project overview

Add files to project by weaving them POD documents and other files

## Common commands

```bash
# Add the key commands your project uses — build, test, run, deploy.
# Example lines for common stacks:
#   make build && make test
#   pytest
#   cargo test
#   npm test
#   go test ./...```

## Entity registry**`.ias/entities.json`** is the canonical registry of every named entity in the project (services, domains, repos, bots, env vars, file paths, tool commands). Before writing any entity name in code, config, or docs, look it up in this file. If it's not there, add it first.
## Verify first, then proceed

Before running expensive or parallel operations, verify that prerequisites actually worked. Exit code 0 and "looks like it ran" is not enough.

- After builds: check binary sizes, symlinks, `--version`
- After installs: `file /path/to/binary` — is it what you expect?
- After file generation: check exists AND non-zero size
- **General rule:** Don't run N parallel jobs against an unverified dependency. Test one first.

## Development philosophy — local first, baby steps, all paths

### Baby steps

1. **Dry run first** — before any script that creates, modifies, or deletes
2. **Test one, then many** — verify one before batching
3. **Test all code paths** — tear down state and test both forks of every if-then-else4. **Local → Dev → Production** (or your project's equivalent) — never skip a level
### L2D&D\\|/D2L&D — Learning to Do \\|/ Doing to Learn

Learning and doing are not sequential — they are an inseparable spiral. You learn BY doing, and doing without learning is waste. Both directions must be conscious.

- **L2D (Learning to Do):** Read docs/source → Understand → THEN write code. Never code against unread source.
- **D2L (Doing to Learn):** When you hit a gotcha, record it. Update assimilation. Doing deepens learning.
- **Nondual:** Read-code-discover-record is one continuous spiral. `.ias/supply-chain.json` tracks where you are on the spiral for each component.

**Concrete rules:**1. Before using a critical component, check its `assimilation.level` in `.ias/supply-chain.json`
2. If level < 2, READ ITS DOCS AND SOURCE before writing code that uses it
3. If `fork` is null and `critical` is true, FORK IT FIRST
4. Record every gotcha in `tools/shell-gotchas.md` — doing feeds back to learning
5. Update `assimilation` fields after reading — persists across sessions
## Output token discipline

Every character Claude outputs costs the user tokens.

1. **Never show file content on screen when you can Write it directly.**
2. **Minimize whitespace.** No decorative blank lines, no padded comments.
3. **When the user asks "give me the content for X"**, write directly to disk.
4. **scratch/ directory** exists for temporary output. It is gitignored.
## Hook-based gate enforcement

Gates 3, 4, and 8 are mechanically enforced via Claude Code PreToolUse hooks. The hooks intercept tool calls, pattern-match against known unsafe commands, and block with a remediation message before execution.**Hook scripts:** `.claude/hooks/ias/` (copied from IAS framework). Run `bash .claude/hooks/ias/tests/run-all.sh` to verify.**Configuration:** `.claude/settings.json` (hooks section).
**Rule registry:** See `hooks/rules/REGISTRY.md` in the IAS repo for the full list of enforced patterns.

If a hook blocks your command, read the reason message — it will explain the safe alternative. The hooks enforce rules already in the gates above; they just make the enforcement mechanical rather than behavioural.