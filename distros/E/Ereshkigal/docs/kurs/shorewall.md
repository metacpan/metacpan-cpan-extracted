# shorewall — Shorewall's dynamic blacklist

Blocks via Shorewall's dynamic blacklisting, driving the
`shorewall(8)` and `shorewall6(8)` commands. Nothing is created at
init — the dynamic blacklist is always there; banning is one command
per IP.

```toml
[kur.sshd]
backend = "shorewall"

[kur.sshd.options]
type = "drop"
```

## How it works

- ban: `shorewall drop <ip>` (or `reject`, per `type`)
- unban: `shorewall allow <ip>`

IPv4 IPs go through the `shorewall` command, IPv6 through
`shorewall6` — the kur dispatches per the banned IP's family.

## Requirements

- `shorewall` (and `shorewall6` for IPv6) in the `PATH` of the kur
  process, with privileges to run them — in practice, root.
- Shorewall running with dynamic blacklisting available
  (`DYNAMIC_BLACKLIST=Yes` in `shorewall.conf`, the default on
  current releases). The kur does not verify this — with it off,
  bans fail at ban time, not at startup.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**; the
  dynamic blacklist is whole-IP. Don't mistake a configured `ports`
  list for scoping.
- `enable_cidr` — supported; the dynamic blacklist takes ranges as
  readily as single IPs.
- `prefix` — unused; Shorewall's dynamic blacklist has no named
  containers.

## Options

| option           | default      | what                                          |
|------------------|--------------|------------------------------------------------|
| `type`           | `drop`       | `drop` silently drops; `reject` sends a reject |
| `shorewall_cmd`  | `shorewall`  | the shorewall binary, used for IPv4           |
| `shorewall6_cmd` | `shorewall6` | the shorewall6 binary, used for IPv6          |

## What each operation runs

| operation  | commands                                                        |
|------------|-------------------------------------------------------------------|
| `init`     | nothing — the dynamic blacklist needs no setup                  |
| `ban`      | `<shorewall[6]_cmd> <type> <ip>`                                |
| `unban`    | `<shorewall[6]_cmd> allow <ip>`                                 |
| `list`     | no command — the kur's own ban book                             |
| `check`    | `shorewall show dynamic` exits 0; plus `shorewall6 show dynamic` when any IPv6 ban exists |
| `flush`    | `allow` per banned IP                                           |
| `re_init`  | teardown (best effort), init, re-`drop` every banned IP         |
| `teardown` | `allow` per banned IP (ban book kept for re_init)               |

## self_heal and reloads

`check` only verifies the `shorewall` command answers — and
`shorewall6` too, but only while something IPv6 is actually banned,
so hosts without shorewall6 installed are not flagged unhealthy. A
`shorewall restart` clears the dynamic blacklist without failing
`check`, so the recovery path for a restart is
`ereshkigal re-init [<kur>]`, or a kur restart re-banning from the
tablet. If Shorewall restarts are part of your routine, pair them
with a `re-init`.

## Gotchas

- Shorewall's own `shorewall save`/`restore` also captures the
  dynamic blacklist; letting both Shorewall and the kur restore bans
  is harmless (re-drop of a dropped IP succeeds) but the kur's book
  is the authority on when sentences end.
- Errors carry Error::Helper flags (`typeInvalid`, …) — [`Net::Firewall::BlockerHelper::backends::shorewall`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::shorewall) has the full
  table.
