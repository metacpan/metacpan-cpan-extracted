# routeros_api — MikroTik RouterOS over REST

Blocks on a MikroTik router via the RouterOS REST API (RouterOS
7.1+), managing membership in firewall address-lists. The filter (or
raw) rules that consume the lists are yours to build — the
npf/netscaler "membership only" model. If you want the rules created
for you, or are on RouterOS 6, use the ssh driven
[routeros](routeros.md) backend instead.

```toml
[kur.sshd]
backend = "routeros_api"

[kur.sshd.options]
host     = "192.0.2.1"
user     = "blocker"
password = "hunter2"
insecure = 1
```

## Router-side setup — required first

- RouterOS 7.1+ with the REST transport enabled: `/ip service`
  `www-ssl` (or `www` for plain http) active, ideally with a real
  certificate.
- An API user in a group with `read,write,rest-api` policy.
- The address-lists consumed by rules you write, e.g.:

```
/ip firewall filter add chain=input src-address-list=kur_sshd action=drop
/ipv6 firewall filter add chain=input src-address-list=kur_sshd action=drop
```

(The lists themselves spring into being on first entry; the rules
are the part that must exist for bans to bite.)

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https` for the default
  https) — loaded only at runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping belongs on your referencing
  rules.
- `enable_cidr` — supported; RouterOS address-lists take ranges as
  readily as single IPs.
- `prefix` — builds the default list names.

## Options

| option     | default           | what                                                   |
|------------|-------------------|---------------------------------------------------------|
| `host`     | *(required)*      | router, optionally `host:port`                         |
| `user`     | *(required)*      | REST API user (basic auth)                             |
| `password` | *(required)*      | REST API password                                      |
| `scheme`   | `https`           | `https` or `http`                                      |
| `insecure` | `0`               | skip TLS verification (RouterOS ships self-signed)     |
| `list4`    | `<prefix>_<name>` | IPv4 address-list name (`/ip` menu)                    |
| `list6`    | `<prefix>_<name>` | IPv6 address-list name (`/ipv6` menu)                  |
| `timeout`  | `30`              | HTTP timeout in seconds                                |

## What each operation does

IPv4 talks to `/rest/ip/firewall/address-list`, IPv6 to
`/rest/ipv6/firewall/address-list`:

| operation  | API traffic                                                          |
|------------|--------------------------------------------------------------------------|
| `init`     | `GET .../address-list?list=<list4>` — verifies reachability and auth |
| `ban`      | `PUT .../address-list` with `{"list":"<listN>","address":"<ip>"}`    |
| `unban`    | `GET .../address-list?list=<listN>&address=<ip>` to find the entry's `.id`, then `DELETE .../address-list/<id>` |
| `list`     | no API call — the kur's own ban book                                 |
| `check`    | same probe as init                                                   |
| `flush`    | the lookup+DELETE per banned IP                                      |
| `re_init`  | teardown (best effort), init, re-PUT every banned IP                 |
| `teardown` | the lookup+DELETE per banned IP (ban book kept)                      |

An entry already removed on the router by hand is treated as already
unbanned, not an error.

## self_heal

`check`/init probe only the IPv4 list endpoint — reachability and
credentials, not list contents, not the IPv6 side, and never whether
any rule consumes the lists. As with [npf](npf.md), the kur will
happily manage a list nothing reads; if bans don't bite, check the
rules first.

## Gotchas

- `insecure = 1` disables certificate verification — encrypted but
  unauthenticated, so credentials are exposed to an on-path
  attacker. Give the router a real cert if the path matters.
- Every ban is one HTTP round trip; an unban is two (a lookup, then
  the delete — or just the lookup when the entry is already gone), so
  a timed ban costs three calls over its lifetime. Fine for a
  router's management plane at normal rates.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `userNotDefined`, `passwordNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::routeros_api`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::routeros_api) has the full
  table.
