# fortigate — Fortinet FortiGate

Blocks on a FortiGate via the FortiOS REST API. Each ban creates a
firewall address object and adds it as a member of an address group;
a policy referencing the group drops the traffic. IPv4 uses
`firewall/address` + `firewall/addrgrp`, IPv6 their `address6` /
`addrgrp6` twins. The groups and the policy are yours to create; the
kur manages the objects and membership.

```toml
[kur.sshd]
backend = "fortigate"

[kur.sshd.options]
host  = "fw.example.org"
token = "the-rest-api-token"
```

## FortiGate-side setup — required first

- Create a REST API admin and token: *System → Administrators →
  Create New → REST API Admin*, with a profile scoped to firewall
  objects, and trusted-host restrictions pointing at the kur host.
- Create the address group(s) — IPv4 (`group4`, default
  `<prefix>_<name>`) and, if you feed it IPv6, the `group6` one.
  FortiGate refuses an empty static group, so seed each with a
  placeholder object (a `/32` from RFC 5737 space, say) that stays
  in it.
- Reference the group(s) as the source of a deny policy on the
  relevant interfaces.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https` for the default
  https) — loaded only at runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping belongs on the policy.
- `enable_cidr` — supported; a banned range becomes a subnet address
  object in the same groups.
- `prefix` — builds the default group names and the per-IP object
  names.

## Options

| option     | default           | what                                          |
|------------|-------------------|------------------------------------------------|
| `host`     | *(required)*      | FortiGate host, optionally `host:port`        |
| `token`    | *(required)*      | REST API token, sent as a bearer token        |
| `group4`   | `<prefix>_<name>` | IPv4 address group banned IPs are added to    |
| `group6`   | `<prefix>_<name>` | IPv6 address group                            |
| `vdom`     | *(unset)*         | virtual domain to scope the calls to          |
| `scheme`   | `https`           | `https` or `http`                             |
| `insecure` | `0`               | skip TLS certificate verification             |
| `timeout`  | `30`              | HTTP timeout in seconds                       |

## What each operation does

Auth is `Authorization: Bearer <token>`; `?vdom=<vdom>` is appended
when set. Per-IP address objects are named
`<prefix>_<name>_<ip>` with dots/colons flattened to hyphens
(`kur_sshd_1-2-3-4`, `kur_sshd_2001-db8--50`):

| operation  | API traffic                                                          |
|------------|--------------------------------------------------------------------------|
| `init`     | `GET /api/v2/cmdb/firewall/addrgrp/<group4>` — verifies token and the v4 group |
| `ban`      | `POST /api/v2/cmdb/firewall/address[6]` creating `{"name":"<obj>","subnet":"<ip>/32"}` (v6: `"ip6":"<ip>/128"`), then `POST .../addrgrp[6]/<group>/member` with `{"name":"<obj>"}` |
| `unban`    | `DELETE .../addrgrp[6]/<group>/member/<obj>`, then `DELETE .../address[6]/<obj>` |
| `list`     | no API call — the kur's own ban book                                 |
| `check`    | same probe as init                                                   |
| `flush`    | the two unban DELETEs per banned IP                                  |
| `re_init`  | teardown (best effort), init, re-create and re-add every banned IP   |
| `teardown` | the two unban DELETEs per banned IP (ban book kept)                  |

## self_heal

`check` verifies the token works and the IPv4 group exists — not the
IPv6 group, not the per-IP objects, not group membership, and not
the policy. Objects or members removed on the FortiGate by hand stay
gone until `re_init`.

## Gotchas

- **Two-step operations can fail halfway.** If the object creates
  but the group add fails, an orphaned address object is left on the
  FortiGate (created, referenced by nothing); likewise unban can
  remove membership but fail the object delete. Orphans are inert
  but accumulate — an occasional sweep of `<prefix>_<name>_*`
  objects not in the group tidies them.
- This is among the chattiest of the API backends: two calls per
  ban, two per unban, four per timed ban's lifetime. For high-churn bans,
  something set-based suits FortiGate better (an external EDL via
  [file_reload](file_reload.md), for instance — FortiGates can poll
  those as External Connectors).
- Removing a group member the group doesn't have errors (it is not
  tolerated the way whole-object hand-removal is elsewhere); after
  hand-cleanup on the FortiGate, expect some unban errors until the
  books agree — `re_init` squares them.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `tokenNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::fortigate`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::fortigate) has the full
  table.
