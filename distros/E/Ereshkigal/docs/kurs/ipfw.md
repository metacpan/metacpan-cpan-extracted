# ipfw — FreeBSD

Blocks via ipfw using a lookup table plus rules under a single rule
number. Banning an IP is one table add.

```toml
[kur.imap]
backend   = "ipfw"
ports     = [ "143", "993" ]
protocols = [ "tcp" ]

[kur.imap.options]
rule = 151
kill = 1
```

## What it creates

- The table `<prefix>_<name>` (e.g. `kur_imap`).
- One rule per (protocol, family) pair, all under the configured rule
  number:

```
ipfw add 151 deny tcp from "table(kur_imap)" to me 143,993
ipfw add 151 deny tcp from "table(kur_imap)" to me6 143,993
```

ipfw's `me` keyword matches only the host's IPv4 addresses and `me6`
only its IPv6 ones, so family-neutral protocols (tcp/udp/sctp) get
one rule per family, while family-specific ones get a single rule for
theirs: `ip4`, `ipv4`, `icmp`, `igmp` → `me`; `ip6`, `ipv6`, `icmp6`,
`ipv6-icmp`, `icmpv6` → `me6`.

## Requirements

- `ipfw` in the `PATH` of the kur process, with privileges to use it
  — in practice, root.
- ipfw enabled and running (`firewall_enable="YES"` in rc.conf, plus
  a `firewall_type` that leaves traffic flowing — the kur adds its
  rules to the live ruleset and does not enable the firewall for
  you). `kill = 1` additionally needs `tcpdrop` and `sockstat`, both
  in the base system.

## Ports, protocols, and names

- Default `protocols`: `ip4`, `ip6` (everything, both families) — or
  `tcp`, `udp` when `ports` are given. Note `ip4`/`ip6` are ipfw(8)
  rule keywords, not `/etc/protocols` names — the defaults bypass
  validation and cannot be requested explicitly in `protocols`.
  Port-capable protocols are tcp/udp/sctp; ports are appended to the
  rule as a comma list.
- `enable_cidr` — supported; ipfw tables carry prefixes as readily
  as addresses.
- `<prefix>_<name>` must be ≤ 63 characters, the ipfw table name
  limit.

## Options

| option     | default | what                                                                     |
|------------|---------|---------------------------------------------------------------------------|
| `rule`     | `150`   | the ipfw rule number all this kur's rules live under — **unique per kur** |
| `type`     | `deny`  | `deny` silently drops; `unreach`/`unreach6` reject                       |
| `unreach`  | `port`  | IPv4 unreach code when rejecting                                         |
| `unreach6` | `port`  | IPv6 unreach code when rejecting                                         |
| `kill`     | `0`     | tcpdrop existing TCP connections for a banned IP                         |

### `rule`

Must be a positive int. Both init and teardown run `ipfw delete
<rule>`, which removes **every** rule under that number — so two kurs
sharing a rule number will silently destroy each other's rules.
Give every ipfw kur its own number, and keep the numbers clear of
your hand-maintained ruleset. Placement matters, as it does
everywhere in ipfw: the number decides where in the ruleset the
block happens, so pick one that lands before your accept rules.

### `type`, `unreach`, `unreach6`

`deny` drops silently. `unreach` and `unreach6` are synonyms meaning
"reject": the family of each generated rule decides whether an IPv4
`unreach <code>` or an IPv6 `unreach6 <code>` is sent.

Valid `unreach` codes (per `ipfw(8)`): `net`, `host`, `protocol`,
`port`, `needfrag`, `srcfail`, `net-unknown`, `host-unknown`,
`isolated`, `net-prohib`, `host-prohib`, `tosnet`, `toshost`,
`filter-prohib`, `host-precedence`, `precedence-cutoff`.

Valid `unreach6` codes: `no-route`, `admin-prohib`, `address`,
`port`.

### `kill`

TCP only — FreeBSD has no tcpdrop equivalent for UDP, and since the
generated rules are stateless, UDP from a banned IP is cut off
immediately anyway. If protocols are configured and tcp is not among
them, nothing is killed.

The mechanism: `sockstat -nc4 -P tcp` (or `-nc6` per the banned IP's
family) is parsed for connections involving the IP and each is fed to
`tcpdrop`. IPv6 scope IDs (`fe80::1%em0`) are stripped first, as
tcpdrop does not accept them. Exit codes are ignored — no matching
connections is not an error.

## What each operation runs

With `T = <prefix>_<name>` and `R` the rule number:

| operation  | commands                                                                          |
|------------|-------------------------------------------------------------------------------------|
| `init`     | cleanup (failures ok): `ipfw table T destroy`, `ipfw delete R`; then (fatal): `ipfw table T create`, one `ipfw add R <action> <proto> from "table(T)" to me[6] [ports]` per (protocol, family) |
| `ban`      | `ipfw table T add <ip>`, then the tcpdrop pipeline if enabled                     |
| `unban`    | `ipfw table T delete <ip>`                                                        |
| `list`     | no command — the kur's own ban book                                               |
| `check`    | `ipfw table T info` and `ipfw list R`, both must exit 0                           |
| `flush`    | `ipfw table T flush`                                                              |
| `re_init`  | teardown (best effort), init, re-add every banned IP                              |
| `teardown` | `ipfw table T destroy`, `ipfw delete R`                                           |

## self_heal and reloads

`check` probes that the table exists and rule number `R` holds rules.
A ruleset reload (`service ipfw restart`) that does not recreate them
is noticed by the next ban/unban with `self_heal` on, which re-inits
and re-bans from the kur's book.

## Gotchas

- The rule-number collision above is the big one — `ipfw delete R` at
  init/teardown takes out anything else living at that number.
- All of a kur's rules share one number; that is normal ipfw practice
  and lets teardown be a single delete.
- IPv6 addresses are lowercased on ban.
- Errors carry Error::Helper flags (`ruleInvalid`, `typeInvalid`,
  `unreachInvalid`, `nameTooLong`, …) — [`Net::Firewall::BlockerHelper::backends::ipfw`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::ipfw) has the full table.
