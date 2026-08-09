# ufw — Ubuntu's uncomplicated firewall

Blocks via `ufw(8)`. Unlike the table/set based backends there is no
container to create — each ban prepends one or more per-IP rules, and
each unban deletes them again.

```toml
[kur.sshd]
backend   = "ufw"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.sshd.options]
kill = "conntrack"
```

## What it creates

Per banned IP, one rule per blocked protocol, prepended so it sits
above ufw's allow rules:

```
ufw prepend deny proto tcp from 1.2.3.4 to any port 22
```

The rule specs, by configuration:

- nothing configured: `from <ip> to any`
- ports, no protocols (defaults tcp+udp): `proto tcp from <ip> to any
  port <p1,p2>` and the same for udp
- protocols with ports (tcp/udp only): `proto <proto> from <ip> to
  any port <p1,p2>`
- protocols without ports: `proto <proto> from <ip> to any`

Unban deletes the very same specs (`ufw delete deny proto tcp from
...`) — no comments or markers are used; the spec itself is the
identity.

## Requirements

- `ufw` in the `PATH` of the kur process, with privileges to use it —
  in practice, root.
- ufw **already enabled** (`ufw enable`). Both init and `check` run
  `ufw status` and require `Status: active`; the kur will not enable
  it for you.
- `kill = "ss"` needs `ss` (iproute2); `kill = "conntrack"` needs
  `conntrack` (conntrack-tools).

## Ports, protocols, and names

- `protocols` is limited to what ufw's rule syntax accepts: `tcp`,
  `udp`, `ah`, `esp`, `gre`, `igmp`, `ipv6` (each also validated
  against `/etc/protocols`). Default is everything from the IP, or
  `tcp`, `udp` when `ports` are given. Ports attach only to tcp/udp.
- `prefix` is accepted but unused — there is no named object to
  prefix; no combined length limit applies.
- `enable_cidr` — supported; a banned range becomes the same per-rule
  specs with the CIDR in place of the IP.

## Options

| option | default | what                                                                     |
|--------|---------|---------------------------------------------------------------------------|
| `type` | `deny`  | `deny` silently drops; `reject` sends a reject back                      |
| `kill` | `""`    | `""` nothing; `"ss"` uses `ss -K`; `"conntrack"` uses `conntrack -D`     |

### `kill`

A ufw rule only stops **new** connections (see
[security](../security.md)). The two kill flavors, both scoped to
the configured protocols and both covering IPv4 and IPv6:

- `"ss"` — `ss -K -tu dst "[<ip>]"`, with `-t`/`-u`/`-tu` chosen from
  the blocked protocols. ss can kill TCP connections and connected
  UDP sockets; if neither tcp nor udp is being blocked, nothing is
  killed.
- `"conntrack"` — `conntrack -D -s <ip>` (with `-f ipv6` for IPv6),
  scoped via `-p` per blocked protocol conntrack understands
  (tcp/udp/gre here); with nothing configured, every entry for the IP
  is dropped.

Exit codes are ignored — nothing matching is not an error.

## What each operation runs

| operation  | commands                                                                  |
|------------|------------------------------------------------------------------------------|
| `init`     | `ufw status \| grep -qiE "^Status:[[:space:]]*active"` (fatal if inactive) |
| `ban`      | `ufw prepend <type> <spec>` per spec, then the kill commands if enabled   |
| `unban`    | `ufw delete <type> <spec>` per spec                                       |
| `list`     | no command — the kur's own ban book                                       |
| `check`    | the same `ufw status` probe as init                                       |
| `flush`    | `ufw delete <type> <spec>` for every banned IP's specs                    |
| `re_init`  | teardown (best effort), init, re-add every banned IP's rules              |
| `teardown` | `ufw delete <type> <spec>` for every banned IP (ban book kept for re_init) |

## self_heal and reloads

`check` only verifies ufw is active — it does **not** verify the
individual per-IP rules still exist. `ufw disable`/`enable` cycles
are caught; a hand-deleted rule is not, and self_heal won't restore
it — the kur's book and `re_init` are the recovery path, see the
ban-time footnotes in [security](../security.md). (Some backends'
`check` does verify individual rules; ufw's is only the status
probe.)

## Gotchas

- Rules scale per IP × per protocol: banning 1000 IPs over tcp+udp
  means 2000 ufw rules. ufw is fine with that but `ufw status
  numbered` gets long; for very large ban volumes a set-based backend
  (or [linux_ip_route](linux_ip_route.md)) stays tidier.
- `ufw prepend` puts ban rules ahead of allow rules — that ordering
  is the point, and also means the bans show at the top of `ufw
  status`.
- Because ufw persists its rules, kur rules present at an unclean
  shutdown survive a reboot inside ufw's own state — and init is only
  the status probe, so nothing is cleaned at startup. Re-banning the
  same IP produces the identical spec (which ufw itself deduplicates),
  but rules for IPs no longer in the kur's book linger until a
  `re_init` or `teardown` deletes them spec by spec.
- IPv6 addresses are lowercased on ban.
- Errors carry Error::Helper flags (`typeInvalid`, `killInvalid`, …)
  — [`Net::Firewall::BlockerHelper::backends::ufw`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::ufw) has the
  full table.
