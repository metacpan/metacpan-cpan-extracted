# Claims: pick, handoff, unlock, several agents on one board

## The claim name

Claims are matched by name: `--claim` stamps it, `handoff` and `pick` check
it, `list --claimed-by` and `log --agent` select on it. Every command taking
`--claim` (`create`, `move`, `edit`, `pick`, `handoff`, `delete`, `archive`)
and `list --claimed-by` defaults to `KARR_CLAIM`; an explicit `--claim NAME`
wins over it. `create` is narrower: it takes `KARR_CLAIM` only when `--status`
names a `require_claim` column, so a card filed for others stays unclaimed.
karr writes the name nowhere — it is per process, so concurrent agents never
see each other's.

```bash
export KARR_CLAIM=$(karr agent-name)            # the worktree's root directory name, sanitised: "karr", "graphify-fix"
export KARR_CLAIM=$(karr agent-name --unique)   # several agents in ONE directory: "karr-8fa"
karr agent-name --json
```

`agent-name` is stable across calls (it is the checkout, not a random word),
so several agents on one board get **one worktree each** and differ by
directory name. Only agents started in the same directory need `--unique`. A
`require_claim` column refused without a claim names both ways to fix it.

Claims expire after `claim_timeout` (default 1h, board config); an expired
claim is free for `pick` and for anyone's `--claim`. `handoff` refuses a card
another live claim holds; `pick` skips it.

## pick

```bash
karr pick                                        # most urgent available card, claimed as $KARR_CLAIM
karr pick --status todo --move in-progress       # from these columns, then move
karr pick --tags backend                         # at least one of these tags
karr pick --claim NAME
karr pick --compact                              # stop after the "Picked task ... (claimed by NAME)" line
karr pick --json                                 # the full card either way
```

Atomic: finds and claims in one step, under a lock ref. Skips blocked cards
and live claims; warns about unfinished dependencies but hands the card over.
Order: class of service first (`expedite` > `fixed-date` > `standard` >
`intangible`; two `fixed-date` cards compare due dates before priority), then
priority.

## handoff

```bash
karr handoff 12 --note "Done, needs QA" -t       # to the review column, claim refreshed, note appended with timestamp
karr handoff 12 --block "waiting for feedback" --release
karr handoff 12 --claim NAME
```

The target is the board's `review` column; a board without one hands off to
its last non-terminal column instead of failing. The claim is refreshed
unless `--release` is given.

## unlock

```bash
karr unlock              # pick locks currently held
karr unlock 12           # break one
karr unlock --all
```

`pick` takes a lock ref and returns it inside the same command; an agent that
dies mid-pick leaves one behind. Locks expire after `lock_timeout` (default
5m, board config); `unlock` clears one now instead of waiting.

## Several agents on one board

```bash
# each agent, in its own worktree
export KARR_CLAIM=$(karr agent-name)
karr pick --status todo --move in-progress
# ... work; karr edit 12 -a "..." -t as you go ...
karr handoff 12 --note "Implementation complete" -t
# or close directly
karr edit 12 --release && karr move 12 done
```

Worktrees share the board (`refs/karr/*` lives in the common git dir), so
every agent sees the same cards while their claim names differ by directory.
karr-foundation exports `KARR_CLAIM` per run the same way.
