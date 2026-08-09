# The gate — `fan_out` kurs

Not a backend but a kind of kur all its own. A `[kur.<name>]` hash
carrying `fan_out` in place of `backend` is a gate: one name that
opens onto several underworlds. It has no process, no socket, and no
clay tablet — commands aimed at it fan out to its members, with
results reported per member.

```toml
[kur.baphomet]
fan_out      = [ "sshd", "smtp" ]
authed_users = [ "baphomet" ]
```

## Configuration

| key             | what                                                          |
|-----------------|----------------------------------------------------------------|
| `fan_out`       | array of one or more real kur names                           |
| `authed_users`  | users allowed through this gate (with `enable_auth`)          |
| `authed_groups` | groups allowed through this gate (with `enable_auth`)         |
| `ban_time`      | accepted by validation but unused — sentences belong to members |
| `checkpoint`    | accepted by validation but unused — tablets belong to members |

`backend`, `ports`, `protocols`, `prefix`, `options`, and `self_heal`
are meaningless on a gate; `backend` in particular may not coexist
with `fan_out`.

### Validation

Config validation happens in two passes. Per kur hash:

- The gate's name must match `/^[a-zA-Z0-9-]+$/`, like any kur.
- Exactly one of `backend` or `fan_out` must be present — carrying
  both is an error, and so is carrying neither.
- `fan_out` must be an array of **one or more** strings, each
  matching `/^[a-zA-Z0-9-]+$/`. An empty array is rejected.
- `authed_users`/`authed_groups`, if present, must be arrays of
  strings.

Then, once every kur is registered, memberships are checked:

- Every member named in `fan_out` must be a defined kur.
- No member may itself be a gate — **gates may not nest**. The error
  reads `fan_out kurs may not nest`.

All of this is checked both at config load and when a gate is created
at runtime via `ereshkigal add --fan-out`.

## Which commands fan out

Targeted commands, when their target is a gate, expand to the gate's
members and run against each:

- `ban --kur <gate>` — bans the IPs on every member.
- `cidr-ban --kur <gate>` — bans the ranges on every member; each
  member answers per its own CIDR capability and `cidr_silent_drop`.
- `checkpoint <gate>` — checkpoints every member.
- `status <gate>` — returns the gate's member list plus each member's
  full status.

Untargeted commands — a bare `ban` (no `--kur`), `unban`,
`cidr-unban`, `banned`, and a bare `checkpoint` — never touch gates.
They enumerate only real kurs; gates are skipped entirely. Naming a
gate's *member* directly (`ban --kur sshd`) works normally and is
authorized against the member's own lists, not the gate's.

## Response shape

A fanned-out command returns a hash keyed by member name. Each value
is either the member's own response, or an error entry:

```json
{ "kurs": {
    "sshd": { "ips": { "1.2.3.4": { "status": "ok" } } },
    "smtp": { "error": "not running" }
} }
```

A member that is down contributes `{ "error": "not running" }`; the
command still completes on the members that are up. A member whose
call fails contributes `{ "error": "<message>" }`. There is no
all-or-nothing semantic — read the per-member results.

The manager's `timeout` setting (default 30 seconds) bounds the whole
fan out as one deadline, not each member individually: all member
sockets share the same time budget, and any that has not answered
when it passes reports `timed out after <n> seconds`.

## Authorization — the point of gates

With `enable_auth` on, a command aimed at a gate is authorized
against the **gate's own** `authed_users`/`authed_groups` (plus the
global lists), not its members'. That is the reason gates exist: an
outside integration — a log watcher, IDS glue, [an external
client](../usage.md) — can be granted just the gate and drive
a whole set of kurs through a single point of contact, without being
listed on, or even knowing about, any member.

UID 0 is always authorized, and the per-gate lists *expand* the
global ones — they never replace them. See
[security](../security.md) for the full trust model.

## Gates in `status`

In the whole-manager census a gate shows its `fan_out` member list
and counts as `running` only when **every** member has a live
process. `status <gate>` goes further and includes each member's own
status response under `kurs`:

```json
{
  "name": "baphomet",
  "fan_out": ["sshd", "smtp"],
  "enabled": 1,
  "kurs": {
    "sshd": { "name": "sshd", "backend": "pf", "banned_count": 3, "...": "..." },
    "smtp": { "error": "not running" }
  }
}
```

## Runtime behavior and gotchas

- A gate's membership is frozen in its definition. `ereshkigal add`
  and `remove` raise and tear down real kurs, but do not edit
  existing gates — and removing a kur that is a gate's member is
  refused outright (`is a fan_out member of ...`), since config load
  would never have allowed the dangling membership it leaves behind.
  Remove the gate first if the member really has to go.
- Gates can themselves be added at runtime (`ereshkigal add <name>
  --fan-out a,b`); members must already exist at that moment.
- Since a gate has no process, there is nothing to restart, no PID,
  no socket under `run/kur/`, and no `kur.<name>.csv` tablet.
- A gate has no state of its own — `banned` and per-IP expiry always
  come from the members.

## Example — an integration granted one gate

```toml
enable_auth = true

[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.sshd.options]
kill = 1

[kur.smtp]
backend   = "pf"
ports     = [ "25", "465", "587" ]
protocols = [ "tcp" ]

[kur.smtp.options]
kill = 1

# baphomet the log watcher may speak only through its gate
[kur.baphomet]
fan_out      = [ "sshd", "smtp" ]
authed_users = [ "baphomet" ]
```

The `baphomet` user can `ban --kur baphomet` and `status baphomet`,
and nothing else — not `ban --kur sshd`, not a bare `ban`, not
`stop`.
