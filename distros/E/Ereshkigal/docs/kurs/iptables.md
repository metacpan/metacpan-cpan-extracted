# iptables — Linux (iptables/ip6tables + ipset)

Blocks via ipset in combination with iptables and ip6tables. Banning
an IP is one ipset add. If the host runs firewalld, use the
[firewalld](firewalld.md) backend instead — driving iptables directly
fights the daemon and loses on reload.

```toml
[kur.web]
backend   = "iptables"
ports     = [ "80", "443" ]
protocols = [ "tcp" ]

[kur.web.options]
kill = 1
```

## What it creates

- Two ipsets: `<prefix>_<name>_4` (`hash:ip family inet`) and
  `<prefix>_<name>_6` (`hash:ip family inet6`).
- A dedicated chain `<prefix>_<name>` in the `filter` table of both
  iptables and ip6tables, populated with the block rules and jumped
  to from `INPUT`:

```
iptables -N kur_web
iptables -A kur_web -m set --match-set kur_web_4 src -p tcp -m multiport --dports 80,443 -j DROP
iptables -A INPUT -j kur_web
```

The jump is appended (`-A INPUT`), so it lands after existing INPUT
rules — an earlier ACCEPT wins. If your INPUT chain accepts by
protocol/port before falling through, consider whether the block
needs to come earlier; the [nftables](nftables.md) backend's priority
option gives finer control.

## Requirements

- `ipset`, `iptables`, and `ip6tables` in the `PATH` of the kur
  process, with privileges to use them — in practice, root (or
  `CAP_NET_ADMIN`).
- The `ip_set` kernel module (loaded on demand by ipset on any normal
  kernel). `kill = 1` additionally needs `conntrack` (the
  conntrack-tools package) and connection tracking enabled.
- `type = "tarpit"` / `"delude"` additionally need xtables-addons.
- Works with both iptables-legacy and iptables-nft, as it only ever
  talks through the `iptables`/`ip6tables` frontends.

## Ports, protocols, and names

- Default `protocols`: all traffic sourced from the sets — or `tcp`,
  `udp` when `ports` are given. Ports attach only to port-capable
  protocols (tcp/udp/sctp), via `-m multiport --dports` with a comma
  list.
- Family-inappropriate protocols are skipped per family: `icmp` gets
  no ip6tables rule; `ipv6-icmp`/`icmp6`/`icmpv6` get no iptables
  rule.
- `<prefix>_<name>` must be ≤ 28 characters — the iptables chain name
  limit (the ipsets add `_4`/`_6` within ipset's 31-char limit).
- `enable_cidr` — this backend can **not** carry ranges (the sets are
  `hash:ip`); a kur with it set logs a warning at startup and answers
  range commands per `cidr_silent_drop`.

## Options

| option        | default  | what                                                        |
|---------------|----------|--------------------------------------------------------------|
| `type`        | `drop`   | `drop`, `reject`, `tarpit`, or `delude` — see below         |
| `tarpit_mode` | `tarpit` | TARPIT mode when `type = "tarpit"`: `tarpit`, `honeypot`, `reset` |
| `kill`        | `0`      | drop existing conntrack entries for a banned IP             |

### `type`

`reject` uses `-j REJECT --reject-with icmp-port-unreachable` on
IPv4 and `--reject-with icmp6-port-unreachable` on IPv6; `drop` is a
plain `-j DROP`.

`tarpit` and `delude` are the cruel options, backed by the
xtables-addons TARPIT and DELUDE targets. `tarpit` accepts the TCP
connection and holds it (zero window), tying the attacker's
resources up in the underworld rather than turning them away;
`tarpit_mode` picks the flavor (`tarpit` hold, `honeypot` accept
then hold, `reset` immediate RST). `delude` answers the SYN with a
SYN/ACK and everything after with RST — the port looks open to a
scanner but no session ever exists.

Both are **TCP only**: the generated rules always say `-p tcp`, and
non-tcp protocols (and the implicit udp when only ports are
configured) are skipped rather than emitted. `delude` is additionally
**IPv4 only** — xtables-addons provides no IPv6 DELUDE, so the
ip6tables rule falls back to plain DROP; banned IPv6 IPs are still
blocked, just silently dropped rather than deluded (TARPIT does
exist for IPv6 and is used as-is). Both also need their crafted
replies to escape connection tracking. With these types the backend
therefore builds a second chain in the **raw table**, jumped from
`PREROUTING` and holding `-j CT --notrack` rules that mirror the
block rules — set up at init, verified by `check`, torn down with
the rest. Without the notrack exemption the kernel stack would fight
the crafted packets and pin an INVALID conntrack entry per attacker
packet; the backend handles it, this is just why the raw table
suddenly has your prefix in it.

Requires xtables-addons installed (the `xt_TARPIT`/`xt_DELUDE`
modules); init fails cleanly if the target is missing. `kill = 1`
pairs well — sever the existing states, tarpit the reconnects.

### `kill`

A firewall rule only stops **new** connections — established flows
keep talking through their conntrack entries (see
[security](../security.md)). With `kill = 1`, each ban also runs
`conntrack -D -s <ip>` (with `-f ipv6` for IPv6 IPs), scoped to the
configured protocols via `-p`:

- No protocols configured — everything is blocked, so every entry for
  the IP is dropped.
- Ports but no protocols — scoped to tcp and udp.
- Protocols configured — one `conntrack -D -p <proto> -s <ip>` per
  blocked protocol conntrack can filter by (`tcp`, `udp`, `udplite`,
  `sctp`, `dccp`, `gre`, `icmp`, `icmpv6` — the icmp of the wrong
  family is skipped). Blocking only udp never drops tcp entries.

Exit codes are ignored — no matching entries is not an error.

## What each operation runs

With `C = <prefix>_<name>`, `S4/S6` the sets:

| operation  | commands                                                                            |
|------------|----------------------------------------------------------------------------------------|
| `init`     | cleanup (failures ok): `-D INPUT -j C`, `-F C`, `-X C` on both frontends, `ipset destroy S4/S6`; then (fatal): `ipset create S4 hash:ip family inet`, `ipset create S6 hash:ip family inet6`, `-N C` both frontends, the block rules, `-A INPUT -j C` both frontends |
| `ban`      | `ipset add <S4\|S6> <ip>` per the IP's family, then the conntrack kills if enabled  |
| `unban`    | `ipset del <S4\|S6> <ip>`                                                           |
| `list`     | no command — the kur's own ban book                                                 |
| `check`    | `ipset list S4`, `ipset list S6`, `iptables -C INPUT -j C`, `ip6tables -C INPUT -j C`, plus every block rule re-tested with `-C` |
| `flush`    | `ipset flush S4`, `ipset flush S6` (rules stay in place)                            |
| `re_init`  | teardown (best effort), init, re-add every banned IP                                |
| `teardown` | `-D INPUT -j C`, `-F C`, `-X C` on both frontends, then `ipset destroy S4`, `ipset destroy S6` |

With `type = "tarpit"`/`"delude"`, init, check, and teardown each
additionally cover the raw-table chain: init creates it (`-t raw -N
C`, the notrack rules, `-t raw -A PREROUTING -j C`), check re-tests
the PREROUTING jump and every notrack rule with `-C`, and teardown
removes it (`-D PREROUTING -j C`, `-F`, `-X`).

## self_heal and reloads

`check` is thorough here: both sets, both INPUT jumps, and every
individual block rule are verified. Anything an
`iptables-restore`/distro firewall restart swept away is noticed by
the next ban/unban with `self_heal` on, which re-inits and re-bans
from the kur's book. Ipsets survive an iptables flush — they are a
separate subsystem — so partial damage, rules gone and sets still
populated, is the common post-reload state, and re_init handles it.

## Gotchas

- Rules are runtime only. Nothing is written to
  `/etc/iptables/rules.v4` or the like — after a reboot the kur
  recreates everything at startup, which is the intended model.
  Conversely, if you use `iptables-save` for persistence, the kur's
  chain and jump will be captured; harmless, since the kur tears the
  captured copies down and recreates them at next start.
- IPv6 addresses are lowercased on ban so case variants can't
  duplicate.
- Errors carry Error::Helper flags (`typeInvalid`, `nameTooLong`, …)
  — [`Net::Firewall::BlockerHelper::backends::iptables`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::iptables) has
  the full table.
