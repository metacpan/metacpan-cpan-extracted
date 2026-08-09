# nftables — Linux (nft)

Blocks via nftables. Everything lives in one dedicated table, so
teardown is a single delete. Banning an IP is one set element add.

```toml
[kur.sshd]
backend   = "nftables"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.sshd.options]
kill = 1
```

## What it creates

A table `inet <prefix>_<name>` containing:

- a base chain `<prefix>_<name>`, hooked to input:
  `{ type filter hook input priority <priority> ; policy accept ; }`
- one set per family: `<prefix>_<name>_4` (`type ipv4_addr`) and
  `<prefix>_<name>_6` (`type ipv6_addr`)
- the block rules referencing them:

```
nft 'add rule inet kur_sshd kur_sshd tcp dport { 22 } ip saddr @kur_sshd_4 drop'
nft 'add rule inet kur_sshd kur_sshd tcp dport { 22 } ip6 saddr @kur_sshd_6 drop'
```

Because the whole setup is its own table with its own input hook, it
composes with whatever other nftables tables exist — nftables runs
every base chain hooked to input, in priority order. That includes
firewalld's own, on hosts where firewalld sits on nftables, though
the [firewalld](firewalld.md) backend is still the politer choice
there.

## Requirements

- `nft` in the `PATH` of the kur process, with privileges to use it —
  in practice, root (or `CAP_NET_ADMIN`).
- An nftables-capable kernel (any modern distro). `kill = 1`
  additionally needs `conntrack` (conntrack-tools).

## Ports, protocols, and names

- Default `protocols`: all traffic sourced from the sets — or `tcp`,
  `udp` when `ports` are given. Port-capable protocols (tcp/udp/sctp)
  get `<proto> dport { <ports> }`; other protocols are matched with
  `meta l4proto <proto>` and no port.
- Family-inappropriate protocols are skipped per family (`icmp` gets
  no IPv6 rule, `ipv6-icmp`/`icmp6`/`icmpv6` no IPv4 rule).
- No name length limit is imposed — nftables object names are long
  enough not to matter.
- `enable_cidr` — this backend can **not** carry ranges (the sets
  are plain `ipv4_addr`/`ipv6_addr`, no interval flag); a kur with it
  set logs a warning at startup and answers range commands per
  `cidr_silent_drop`.

## Options

| option     | default | what                                                        |
|------------|---------|--------------------------------------------------------------|
| `type`     | `drop`  | `drop` silently drops; `reject` sends ICMP port-unreachable |
| `priority` | `-1`    | priority of the base chain — see `nft(8)`                   |
| `kill`     | `0`     | drop existing conntrack entries for a banned IP             |

### `type`

With `reject`, nft itself picks the family-appropriate ICMP
port-unreachable — no per-family reject plumbing needed.

### `priority`

Any integer, negative allowed. The default `-1` runs the chain just
ahead of the conventional filter chains at priority 0, so bans are
decided before a distro firewall's accept rules get a look. Raise or
lower it to slot the kur relative to whatever else hooks input.

### `kill`

Identical mechanism and scoping to the [iptables](iptables.md)
backend: `conntrack -D -s <ip>` (`-f ipv6` for IPv6), scoped via `-p`
to the blocked protocols, everything dropped when nothing is
configured. Exit codes ignored.

## What each operation runs

With `T = <prefix>_<name>` (also the chain name) and `S4/S6` the
sets:

| operation  | commands                                                                      |
|------------|----------------------------------------------------------------------------------|
| `init`     | cleanup (failure ok): `nft 'delete table inet T'`; then (fatal): `add table`, `add chain ... hook input priority <p>`, `add set ... S4/S6`, one `add rule` per spec |
| `ban`      | `nft 'add element inet T <S4\|S6> { <ip> }'`, then the conntrack kills if enabled |
| `unban`    | `nft 'delete element inet T <S4\|S6> { <ip> }'`                               |
| `list`     | no command — the kur's own ban book                                           |
| `check`    | `nft 'list table inet T'`, and `nft 'list chain inet T T'` grepped for each `@set` reference |
| `flush`    | `nft 'flush set inet T S4'`, `nft 'flush set inet T S6'` (rules stay)         |
| `re_init`  | teardown (best effort), init, re-add every banned IP                          |
| `teardown` | `nft 'delete table inet T'`                                                   |

## self_heal and reloads

`check` verifies the table exists and that the chain's rules still
reference the sets. An `nft flush ruleset` or a distro firewall
restart that clobbers the table is noticed by the next ban/unban with
`self_heal` on, which re-inits and re-bans from the kur's book.

## Gotchas

- Like the iptables backend, everything is runtime state — nothing is
  written to `/etc/nftables.conf`. The kur recreates its table at
  startup; keep its prefix out of any `nft -f` rulesets you load by
  hand so a reload doesn't carry a stale copy.
- Set elements have no timeout flags — expiry is the kur sweeper's
  job, deliberately, so the tablet stays the single source of truth.
- IPv6 addresses are lowercased on ban.
- Errors carry Error::Helper flags (`typeInvalid`,
  `priorityInvalid`, …) — [`Net::Firewall::BlockerHelper::backends::nftables`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::nftables) has the full
  table.
