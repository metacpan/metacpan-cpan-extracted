---
name: kanban-issues-karr-cli
description: Use when picking up, claiming, handing off or creating agent tickets with the karr CLI, or when reading a repo's karr board.
---

# karr — Kanban Assignment & Responsibility Registry

Git-native kanban board for multi-agent work. The board is the repository's
`refs/karr/*`: commands read and write those refs directly and sync them with
the remote; nothing lands in the work tree. In prose (commit subjects, card
bodies) a card is `k12`, never `#12` — the forge resolves `#12` against its
own issue 12.

## Name yourself once

```bash
export KARR_CLAIM=$(karr agent-name)     # the checkout's directory name, e.g. "karr"
```

Claims are matched by name: `--claim` stamps it, `handoff` checks it,
`list --claimed-by` selects on it. Every command that takes `--claim` defaults
to `KARR_CLAIM`, so export it once per session and leave `--claim` off. An
explicit `--claim NAME` still wins. Agents in separate worktrees already differ
by name; several agents in the **same** directory take
`karr agent-name --unique` (`karr-8fa`).

## Read the board

```bash
karr list --compact                      # open cards, one line each
karr board                               # per-column summary; --done shows the final column too
karr show 12                             # one card in full, body included
karr list --unclaimed --status todo      # what is free to take
karr list --blocked                      # what is stuck, and why
karr show --me                           # the card you last touched (re-orient)
```

`list` hides the final column (`done`) and the archive unless asked for by
name (`--status done`, `--archived`).

## Work a card

```bash
karr pick --status todo --move in-progress       # most urgent free card, claimed as $KARR_CLAIM
karr move 12 in-progress                         # or take a specific one
karr move 12 in-progress --claim NAME            # explicit claim, wins over KARR_CLAIM
karr edit 12 -a "Cause is in Foo.pm, fix pending" -t   # timestamped note while working
karr edit 12 --block "needs the API change first"      # stuck: say why, keep the claim …
karr edit 12 --block "needs k7 first" --release        # … or let it go for someone else
karr edit 12 --unblock
karr handoff 12 --note "Implemented, needs QA" -t      # to the review column, claim refreshed
karr edit 12 --release && karr move 12 done            # or close it directly
```

Columns with `require_claim` (`in-progress`, `review` on a default board)
refuse a move without a claim. A claim expires after `claim_timeout` (default
1h) and the card is free again; `pick` skips blocked cards and live claims.
Put what you learned on the card (`-a`) before handing it off — the card is
the shared memory, your session is not.

## Create a card

```bash
karr create "Title" --priority high --tags cli,bug --body 'What is wrong, how to reproduce, what done looks like'
karr create "Start now" --status in-progress     # claimed as $KARR_CLAIM at creation
karr create "Ship it" --depends-on 2,3           # board-local dependency; ids must exist
karr create "New card" --json                    # the card as JSON: pipe the id onward
```

Bugs found on the way become cards, not silent fixes. A new card is unclaimed
unless `--status` puts it into a `require_claim` column (you are starting it)
or `--claim` says who holds it.

## Output flags

`--json` is taken by every board command, not by `backup`, `restore`,
`destroy`, `sync`, `set-refs`, `get-refs`. `--compact` exists on exactly nine:
`board`, `config`, `context`, `dashboard`, `list`, `log`, `metrics`, `pick`,
`show` — anywhere else it is `Unknown option: compact`, exit 2.

## When you need more

| Need | Read |
|---|---|
| Every option of `create`, `show`, `move`, `edit`, `delete`, `archive`; dependency rules | [references/cards.md](references/cards.md) |
| `list` filters and sorting, `board`, `dashboard`, `log`, `metrics`, `context --write-to` | [references/queries.md](references/queries.md) |
| `pick` ordering, `handoff` options, `unlock` for stale locks, timeouts, several agents on one board | [references/claims.md](references/claims.md) |
| A card waits on another repository: `--needs BOARD#ID`, `--escalated-from`, `karr needs --resolve` | [references/cross-board.md](references/cross-board.md) |
| `config get/set`, writable keys, the config YAML, `disable`/`enable` for karr-foundation | [references/config.md](references/config.md) |
| `sync`, fresh clones, stored card format, `materialize`/`import`, `repair`, `backup`/`restore`/`destroy`, `set-refs`/`get-refs` | [references/storage.md](references/storage.md) |
| `init`, `skill install/check/update`, `completion`, Docker | [references/setup.md](references/setup.md) |
