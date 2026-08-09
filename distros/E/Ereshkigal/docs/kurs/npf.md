# npf — NetBSD

Blocks via `npfctl(8)` by adding IPs to an npf table. Unlike pf, npf
tables and the rules referencing them cannot be conjured on the fly —
both must already be declared in `npf.conf`. The kur only manages
table membership.

```toml
[kur.sshd]
backend = "npf"

[kur.sshd.options]
table = "kur_sshd"
```

## Host setup — the part you must do first

Declare the table and a rule using it in `/etc/npf.conf`, then
reload:

```
table <kur_sshd> type ipset    # type lpm instead if CIDR banning is enabled

group default {
    block in final from <kur_sshd>
    # ... the rest of your ruleset ...
}
```

```shell
npfctl reload
```

The rule is yours to shape — since ports and protocols live in
`npf.conf` rather than in the kur, scope the block there if you want
it narrower than everything, e.g.:

```
block in final proto tcp to any port ssh from <kur_sshd>
```

init verifies the table exists (`npfctl table <table> list`) and
fails if it does not.

## Requirements

- `npfctl` in the `PATH` of the kur process, with privileges to use
  it — in practice, root.
- npf enabled with the table and rule declared as above. Note the kur
  does not check that npf itself is active, only that the table
  answers.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup (`portsNotSupported` /
  `protocolsNotSupported`). They belong to the rule in `npf.conf`.
- `enable_cidr` — supported, but only against an `lpm`-type table:
  `ipset` tables hold exact addresses and reject prefixes, so a CIDR
  ban against one fails with `banCidrFailed`. Declare `type lpm` in
  `npf.conf` if this kur will banish ranges.
- `prefix` — only used to build the default table name.

## Options

| option  | default           | what                                                    |
|---------|-------------------|----------------------------------------------------------|
| `table` | `<prefix>_<name>` | the npf table to use; must match `/^[a-zA-Z0-9_\-]+$/`  |

The default with the default prefix is `kur_<name>`. The table named
here is exactly what must be declared in `npf.conf`.

## What each operation runs

| operation  | commands                                                       |
|------------|------------------------------------------------------------------|
| `init`     | `npfctl table <table> list` (fatal if it fails)                |
| `ban`      | `npfctl table <table> add <ip>`                                |
| `unban`    | `npfctl table <table> rem <ip>`                                |
| `list`     | no command — the kur's own ban book                            |
| `check`    | `npfctl table <table> list`                                    |
| `flush`    | `npfctl table <table> flush`                                   |
| `re_init`  | teardown (best effort), init, re-add every banned IP           |
| `teardown` | `npfctl table <table> flush` (the table itself cannot be removed; ban book kept for re_init) |

An `ipset`-type npf table holds both IPv4 and IPv6 addresses, so both
families work; ranges need `type lpm` (see Settings).

## self_heal and reloads

`check` verifies the table is still accessible. An `npfctl reload`
empties dynamic table contents, and the table still answering means
`check` passes — so a reload's damage is only healed when `re_init`
runs, either `ereshkigal re-init [<kur>]` or a kur restart, both of
which re-ban from the tablet. If you reload npf often, make
`ereshkigal re-init` part of that procedure.

## Gotchas

- Everything interesting is in `npf.conf`. If the block rule is
  missing or ordered after a pass rule that wins, the kur will hand
  down sentences and cool them happily while nothing is blocked — it
  can only see the table, not whether any rule consults it.
- Underscores are allowed in the table name (unlike kur names and
  prefixes), since npf allows them.
- IPv6 addresses are lowercased on ban.
- Errors carry Error::Helper flags (`tableInvalid`,
  `portsNotSupported`, …) — [`Net::Firewall::BlockerHelper::backends::npf`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::npf) has the full table.
