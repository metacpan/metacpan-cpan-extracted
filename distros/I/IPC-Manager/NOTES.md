# Maintainer notes

Informal todo list for codebase-wide cleanups that fall outside any
single feature branch.

## Audit: count-when-bool-suffices methods

The streaming_deadlock branch grew a `have_pending_sends` boolean fast
path next to `pending_sends` because the service event loop only ever
needed "is there anything queued?" but `pending_sends` walks every
peer summing queue depths. Same shape may exist elsewhere — accessor
that loops to compute a count, callers that use the result only as
truthy/falsy.

### Audit results (2026-04-26)

Reviewed:

- `pending_messages` — already short-circuits via `return 1 if ...`
  in every implementation. Boolean already.
- `peers`, `connections`, `listening_peers`, `messages`, `all_stats`,
  `workers` — return lists/hashes for iteration; no production
  boolean call sites found.
- `handles_for_select` — paired with `have_handles_for_select`
  (constant per-driver) since long before this audit. Done.
- `pending_responses` family — `have_pending_responses` exists.
- `pending_sends` — `have_pending_sends` added in
  streaming_deadlock work.
- `_gone_pending_peers` (Service::Handle) — found one boolean caller
  in `await_all_responses` that used the list only to check `if
  (@gone)` and called the method again later for the names.
  `_have_gone_pending_peers` short-circuits on first hit; matters
  here because each iteration calls `_pending_peer_active` which
  can hit the FS / DB.

### Remaining

None known. Re-audit when adding new loop-shaped accessors.
