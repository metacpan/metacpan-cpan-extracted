# Stopping Collectors

`dashboard collector start <name>` starts two things: the collector **loop**
(the process titled `dashboard collector: <name>` that schedules and runs the
collector command) and a background **supervisor** (watchdog) that keeps the
collector alive by restarting the loop if it dies.

Because of that supervisor, stopping a collector is not just "kill the loop" —
the stop must also tell the supervisor to stop watching that collector, or the
supervisor immediately restarts it.

## The two stop commands (both supervisor-aware)

- `dashboard collector stop <name>` — the collector-subcommand form.
- `dashboard stop collector <name>` — the top-level runtime-control form.

Both now route through the same supervisor-aware stop:

1. deregister the collector from the supervisor (and stop the supervisor when no
   collectors remain under it), so the loop cannot be respawned;
2. terminate the loop, its workers, and each worker's command subtree;
3. reset the consumer-facing `status.json` so `dashboard collector status
   <name>`, the prompt strip (`dashboard ps1`), and the web status board all
   report the collector as stopped.

After a stop, the collector stays stopped: no new loop pid appears and
`dashboard collector status <name>` reports `running: 0`.

## What "stop everything" covers

- **The loop** is killed first so it stops spawning new workers; its own
  shutdown handler is given a grace period scaled to the number of active
  workers so it is not force-killed mid-cleanup.
- **Long-running command subtrees** are reaped by sending the worker's whole
  process group `SIGKILL`, so a command child that ignores `SIGTERM` is still
  terminated.
- **Orphaned workers** left behind by a crashed loop (a stale pid file) are
  swept as well.
- On hosts without `/proc` or `ps` (Windows), a managed loop is still
  recognized from its recorded runtime state so it can be terminated.

## Duplicate loops are prevented

`dashboard collector start` records the loop's identity in its state file
immediately. The supervisor recognizes an already-running loop from that
recorded state as well as from process identity, so it never creates a second
loop by racing a freshly started one before it has set its process title.
