# pf — FreeBSD, OpenBSD, and friends

Blocks via pf using a table inside a dedicated anchor. Banning an IP
is one table add; the block rules referencing the table are loaded
once at init.

```toml
[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]
ban_time  = 3600

[kur.sshd.options]
kill = 1
```

## What it creates

- The table `<prefix>_<name>` (e.g. `kur_sshd`), declared
  `persist counters`, inside the anchor `<prefix>/<name>`
  (e.g. `kur/sshd`).
- One `block drop quick` rule per protocol (per port, for
  port-capable protocols) in that anchor:

```
block drop quick proto tcp from <kur_sshd> to any port 22
```

Rules take the form `block drop quick proto <protocol> from
<<table>> to any` with ` port <port>` appended once per port for
tcp/udp/sctp. Protocols that cannot take ports get one portless rule.

## Requirements

- `pfctl` in the `PATH` of the kur process, with privileges to use it
  — in practice, root.
- pf enabled (`pf_enable="YES"` in rc.conf on FreeBSD, `pfctl -e`).
- **The anchor must be called from the main ruleset.** The kur loads
  its rules into the anchor `<prefix>/<name>`, but pf only evaluates
  an anchor the main ruleset descends into. With the default prefix,
  add to `pf.conf`:

  ```
  anchor "kur/*"
  ```

  and reload (`pfctl -f /etc/pf.conf`). Without this the table and
  rules exist, `status` looks healthy, and **nothing is blocked** —
  neither init nor `check` can detect a missing anchor call, since
  both only look inside the anchor. This is the pf gotcha; check it
  first when bans don't bite.

## Ports, protocols, and names

- Default `protocols`: `tcp`, `udp`, `icmp`, `icmp6` — or `tcp`,
  `udp` when `ports` are given. Port-capable protocols are
  tcp/udp/sctp.
- The rules are family-neutral; one table holds both IPv4 and IPv6
  IPs.
- `enable_cidr` — supported; pf tables carry prefixes as readily as
  addresses.
- `<prefix>_<name>` must be ≤ 31 characters — the pf table name
  limit, enforced at kur startup rather than as a confusing pfctl
  error later.

## Options

| option | default | what                                    |
|--------|---------|------------------------------------------|
| `kill` | `0`     | kill existing states for a banned IP    |

### `kill`

Banishing an IP to the table only stops **new** connections —
established states keep talking (see
[security](../security.md); for ban-on-abuse you almost certainly
want `kill = 1`).

With it on, each ban also severs live states, scoped to what the kur
blocks:

- Nothing configured (blocking everything): `pfctl -k <ip>` — every
  state for the IP dies.
- Protocols and/or ports configured: the state table (`pfctl -s
  state -vv`) is searched, filtered to the blocked protocols and
  ports, and matching states are killed by ID via `pfctl -k id -k
  <id>`. Blocking only udp kills only udp states (pf keeps state for
  UDP too) and leaves tcp alone. The matching follows the family of
  the banned IP — pf prints IPv4 states as `addr:port` and IPv6 ones
  as `addr[port]`.

Kill commands are best effort; a failure (no matching states) is
ignored.

## What each operation runs

With `A = pfctl -a <prefix>/<name>` and `T = <prefix>_<name>`:

| operation  | commands                                                                                                                                                        |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `init`     | cleanup (failures ok): `A -t T -T flush`, `A -t T -T kill`, `A -F rules`; then (fatal): `echo 'table <T> persist counters' \| A -f-`, `echo '<rules>' \| A -f-` |
| `ban`      | `A -t T -T add <ip>`, then the kill commands if enabled                                                                                                         |
| `unban`    | `A -t T -T delete <ip>`                                                                                                                                         |
| `list`     | no command — the kur's own ban book                                                                                                                             |
| `check`    | `A -t T -T show` must exit 0, and `A -sr` must produce output                                                                                                   |
| `flush`    | `A -t T -T flush`                                                                                                                                               |
| `re_init`  | teardown (best effort), init, then re-add every banned IP                                                                                                       |
| `teardown` | `A -t T -T flush`, `A -t T -T kill`, `A -F rules`                                                                                                               |

Everything is scoped to the anchor — `-F rules` here flushes only the
anchor's rules, never the main ruleset.

## self_heal and reloads

`check` probes that the table exists and the anchor still holds
rules. A `pfctl -f /etc/pf.conf` reload wipes anchor contents that
are not in the file, so the next ban/unban with `self_heal` on
notices and re-inits, re-banning everything from the kur's book. What
`check` cannot notice is the missing `anchor "kur/*"` line — see
Requirements.

## Gotchas

- Two pf kurs sharing a prefix and name would fight over the same
  anchor; kur names are unique per manager, so this only bites if you
  run multiple managers with the default prefix.
- Banning an already banned IP is a no-op at the pf level (the kur
  just refreshes the sentence timer).
- IPv6 addresses are lowercased on ban so case variants can't
  duplicate.
- Errors carry Error::Helper flags (`banFailed`, `initFailed`,
  `nameTooLong`, …) — [`Net::Firewall::BlockerHelper::backends::pf`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::pf) has the full table.
