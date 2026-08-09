# firewalld — Linux hosts firewalld manages

Blocks on hosts where firewalld owns the firewall — where driving
iptables directly fights the daemon and loses on reload. Uses
ipset for the IP sets and the firewalld **direct interface** for the
block rules, so the daemon and the bans coexist.

```toml
[kur.sshd]
backend   = "firewalld"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.sshd.options]
kill = 1
```

## What it creates

- Two ipsets, created with `ipset(8)` directly (not firewalld's own
  ipset support): `<prefix>_<name>_4` (`hash:ip family inet`) and
  `<prefix>_<name>_6` (`hash:ip family inet6`).
- Block rules inserted through the direct interface into the
  configured chain (default `INPUT_direct`), priority 0:

```
firewall-cmd --direct --add-rule ipv4 filter INPUT_direct 0 \
    -m set --match-set kur_sshd_4 src -p tcp -m multiport --dports 22 -j DROP
firewall-cmd --direct --add-rule ipv6 filter INPUT_direct 0 \
    -m set --match-set kur_sshd_6 src -p tcp -m multiport --dports 22 -j DROP
```

The rule bodies are iptables argument strings — the direct interface
passes them through to iptables/ip6tables underneath.

## Requirements

- `firewall-cmd` and `ipset` in the `PATH` of the kur process, with
  privileges to use them — in practice, root.
- firewalld **running** — init fails and `check` reports unhealthy
  when `firewall-cmd --state` says otherwise.
- The direct interface available (it is, on any stock firewalld;
  it is deprecated upstream in favor of policies but still present).
- `kill = 1` additionally needs `conntrack` (conntrack-tools).

## Ports, protocols, and names

- Default `protocols`: all traffic sourced from the sets — or `tcp`,
  `udp` when `ports` are given. Ports attach to tcp/udp/sctp via
  `-m multiport --dports`; family-inappropriate icmp variants are
  skipped per family.
- `<prefix>_<name>` must be ≤ 29 characters — leaving room for the
  `_4`/`_6` suffix within ipset's 31-character set name limit.
- `enable_cidr` — this backend can **not** carry ranges (the sets are
  `hash:ip`); a kur with it set logs a warning at startup and answers
  range commands per `cidr_silent_drop`.

## Options

| option  | default        | what                                                         |
|---------|----------------|---------------------------------------------------------------|
| `type`  | `drop`         | `drop` silently drops; `reject` sends ICMP port-unreachable  |
| `chain` | `INPUT_direct` | direct interface chain for the rules; `/^[a-zA-Z0-9_\-]+$/`  |
| `kill`  | `0`            | drop existing conntrack entries for a banned IP              |

### `chain`

`INPUT_direct` is evaluated by firewalld ahead of its zone rules for
incoming traffic, which is what you want for bans. Point it elsewhere
(e.g. `FORWARD_direct`) if the host is routing for the machines you
are protecting.

### `type` / `kill`

Same semantics as the [iptables](iptables.md) backend — `reject` is
`REJECT --reject-with icmp-port-unreachable` / `icmp6-port-unreachable`
per family, and `kill` runs the same protocol-scoped
`conntrack -D -s <ip>` commands, exit codes ignored.

## What each operation runs

With `S4/S6` the sets and one `<rule>` per generated rule body:

| operation  | commands                                                                          |
|------------|--------------------------------------------------------------------------------------|
| `init`     | cleanup (failures ok): `firewall-cmd --direct --remove-rule <fam> filter <chain> 0 <rule>` for each, `ipset destroy S4/S6`; then (fatal): `ipset create S4/S6`, `firewall-cmd --direct --add-rule <fam> filter <chain> 0 <rule>` for each |
| `ban`      | `ipset add <S4\|S6> <ip>`, then the conntrack kills if enabled                    |
| `unban`    | `ipset del <S4\|S6> <ip>`                                                         |
| `list`     | no command — the kur's own ban book                                               |
| `check`    | `firewall-cmd --state`, `ipset list S4`, `ipset list S6`, and `firewall-cmd --direct --query-rule ...` per rule |
| `flush`    | `ipset flush S4`, `ipset flush S6` (rules stay)                                   |
| `re_init`  | teardown (best effort), init, re-add every banned IP                              |
| `teardown` | `--remove-rule` per rule, then `ipset destroy S4`, `ipset destroy S6`             |

## self_heal and reloads — the firewalld-specific point

Direct rules added this way are **runtime only**: `firewall-cmd
--reload` or a daemon restart wipes them. The ipsets survive (ipset
is its own kernel subsystem firewalld doesn't own), so the
post-reload state is sets full, rules gone — every banned IP still
listed, none of them actually blocked.

This is exactly what `self_heal` (on by default) exists for: `check`
queries each rule individually, the next ban/unban notices the loss
and re-inits, restoring the rules and re-banning from the kur's book.
If reloads are frequent and bans are sparse, note the window between
a reload and the next ban/unban — `ereshkigal re-init [<kur>]` closes
it on demand.

## Gotchas

- Query/remove of direct rules matches the argument string
  character-for-character; the backend always regenerates identical
  strings, but hand-added variants of its rules won't be recognized
  as its own.
- The `0` in the commands is the direct interface's own priority
  argument (ordering among direct rules in the same chain); it is
  fixed.
- IPv6 addresses are lowercased on ban.
- Errors carry Error::Helper flags (`chainInvalid`, `typeInvalid`,
  `nameTooLong`, …) — [`Net::Firewall::BlockerHelper::backends::firewalld`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::firewalld) has the full
  table.
