# hosts_deny — TCP wrappers

Blocks via TCP wrappers by maintaining a marked region in
`/etc/hosts.deny`. Not a packet filter: only libwrap-aware daemons —
those linked against libwrap or run under `tcpd` — honor it, and the
connection is refused at accept time, after the TCP handshake.

```toml
[kur.sshd]
backend = "hosts_deny"

[kur.sshd.options]
daemon = "sshd"
```

## How it works

The backend owns exactly one region of the file, delimited by

```
# BEGIN Net::Firewall::BlockerHelper kur_sshd
sshd : 1.2.3.4
sshd : 5.6.7.8
# END Net::Firewall::BlockerHelper kur_sshd
```

Everything outside the markers is preserved untouched, so hand
maintained rules and other kurs (which get their own
`<prefix>_<name>` tag) coexist in the same file. Each mutation
re-renders the whole region from the ban book, IPs sorted. No reload
is needed — libwrap re-reads the file on every connection. With no
IPs banned the region (markers included) is absent entirely.

## Requirements

- Write access to the file (root, for `/etc/hosts.deny`).
- Daemons that actually consult libwrap. **Check this first**: much
  of the modern world does not — OpenSSH is commonly built without
  tcpwrappers these days (FreeBSD's base sshd still supports it;
  most Linux distro sshd packages no longer do). A hosts_deny kur
  protecting a daemon that never looks at the file bans no one.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**; the
  `daemon` option is this backend's scoping mechanism.
- `enable_cidr` — this backend can **not** carry ranges; a kur with
  it set logs a warning at startup and answers range commands per
  `cidr_silent_drop`.
- `prefix` — combined with the kur name to tag the marked region.

## Options

| option   | default           | what                                                       |
|----------|-------------------|-------------------------------------------------------------|
| `file`   | `/etc/hosts.deny` | the hosts.deny file to maintain                            |
| `daemon` | `ALL`             | the daemon_list of each rule; `ALL` or a daemon name like `sshd` |

## What each operation does

Every mutating operation is the same mechanic — strip this kur's
region, re-render it from the ban book, write the file back:

| operation  | effect                                                            |
|------------|--------------------------------------------------------------------|
| `init`     | rewrites the file with any stale region from a prior run removed |
| `ban`      | region re-rendered including the new IP                          |
| `unban`    | region re-rendered without it                                     |
| `list`     | no file access — the kur's own ban book                           |
| `check`    | with ≥1 ban: file contains the BEGIN marker and a `"<daemon> : <ip>"` line per banned IP; with none, passes without touching the file |
| `flush`    | region emptied (removed)                                          |
| `re_init`  | region re-rendered from the ban book                              |
| `teardown` | region removed; ban book kept for re_init                         |

Both IPv4 and IPv6 render the same way (`<daemon> : <ip>`), which
libwrap accepts for both families.

## self_heal

`check` verifies the region marker and every banned IP's line are
still present, so a hand-edit or restored file that lost the region
is noticed and healed on the next ban/unban. With no bans there is
nothing to verify and check always passes.

## Gotchas

- The rewrite is atomic: new contents go to a temp file in the same
  directory and are renamed into place (mode preserved), so a partial
  file can never be seen. Updates serialize under an exclusive flock
  on `<file>.lock` — created if needed and left in place, so don't be
  surprised by a `hosts.deny.lock` living next to the file.
- Because refusal happens post-handshake in the daemon, this blocks
  logins, not packets — no protection against floods, and nothing
  like `kill` exists (established sessions are untouched).
- Best regarded as a belt-and-suspenders or last-resort backend on
  systems where you cannot touch the packet filter.
- Errors carry Error::Helper flags (`fileWriteFailed`, …) — [`Net::Firewall::BlockerHelper::backends::hosts_deny`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::hosts_deny) has the full
  table.
