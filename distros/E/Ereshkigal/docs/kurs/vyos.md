# vyos — a VyOS firewall address-group

Blocks on a VyOS router by adding banned IPs to a firewall
address-group (and its `ipv6-address-group` twin) through the VyOS
HTTP API. Each ban is one `set`, each unban one `delete`, committed
automatically by the API. The groups and the rules referencing them
are yours to build.

```toml
[kur.sshd]
backend = "vyos"

[kur.sshd.options]
host = "10.0.0.1"
key  = "the-api-key"
```

## VyOS-side setup — required first

```
set service https api keys id kur key 'the-api-key'
set firewall group address-group kur_sshd
set firewall group ipv6-address-group kur_sshd
set firewall ipv4 input filter rule 10 action 'drop'
set firewall ipv4 input filter rule 10 source group address-group 'kur_sshd'
set firewall ipv6 input filter rule 10 action 'drop'
set firewall ipv6 input filter rule 10 source group ipv6-address-group 'kur_sshd'
commit ; save
```

(Adjust rule placement to your ruleset; the point is a rule per
family sourcing from the group.)

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping lives on the rules.
- `enable_cidr` — supported; the address-groups take networks as
  readily as hosts.
- `prefix` — builds the default group name.

## Options

| option     | default           | what                                                        |
|------------|-------------------|--------------------------------------------------------------|
| `host`     | *(required)*      | VyOS host, optionally `host:port`                           |
| `key`      | *(required)*      | HTTP API key                                                |
| `group`    | `<prefix>_<name>` | the address-group / ipv6-address-group name (same for both) |
| `timeout`  | `30`              | HTTP timeout in seconds                                     |
| `insecure` | `0`               | skip TLS certificate verification                           |

## What each operation does

All calls are form-encoded POSTs carrying a JSON `data` payload plus
the `key`; IPv4 goes to the `address-group` path, IPv6 to
`ipv6-address-group`:

| operation  | API traffic                                                              |
|------------|-------------------------------------------------------------------------------|
| `init`     | `POST /retrieve` with `{"op":"showConfig","path":["firewall","group","address-group","<group>"]}` |
| `ban`      | `POST /configure` with `{"op":"set","path":["firewall","group","<node>","<group>","address","<ip>"]}` |
| `unban`    | the same with `"op":"delete"`                                            |
| `list`     | no API call — the kur's own ban book                                     |
| `check`    | same probe as init                                                       |
| `flush`    | the delete per banned IP                                                 |
| `re_init`  | teardown (best effort), init, re-`set` every banned IP                   |
| `teardown` | the delete per banned IP (ban book kept)                                 |

Each `/configure` call is its own VyOS commit — there is no separate
apply step, and no `save`, so the group contents are running-config
only and vanish at a router reboot. That is fine: the kur re-adds
from its tablet, and stale bans should not outlive the router
anyway.

## self_heal

`check` verifies the API answers and can read the group's config —
not the group's contents nor the rules. Both init and check probe
only the IPv4 `address-group`; the `ipv6-address-group` is never
probed. Entries removed on the router by hand stay gone until
`re_init`.

## Gotchas

- Every mutation is a VyOS commit; commits are not instant. At
  interactive ban rates it is unnoticeable, under a flood the
  commits will queue.
- Do not run `commit ; save` on the router while heavily banned
  unless you want the current ban set baked into the saved config —
  harmless, but surprising after a reboot restores year-old bans the
  kur then has to reconcile.
- `insecure = 1` disables certificate verification.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `keyNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::vyos`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::vyos) has the full table.
