# linux_ip_route — null routes via iproute2

Blocks whole IPs by adding unreachable/blackhole routes with `ip(8)`.
No firewall is required at all: traffic dies in the routing decision,
before it would reach any firewall chain, and it stays fast with very
large numbers of banned IPs — a good fallback, and a good "block
everything from this IP everywhere" hammer.

```toml
[kur.blocklist]
backend  = "linux_ip_route"
ban_time = 0

[kur.blocklist.options]
blocktype = "blackhole"
```

## What it creates

One route per banned IP, of whichever `blocktype` is configured. With
the default `unreachable`:

```
ip route add unreachable 1.2.3.4
ip -6 route add unreachable 2001:db8::bad
```

The IP's family picks the command (`ip` vs `ip -6`) automatically.

Note the asymmetry with the firewall backends: a route affects
traffic **to** the banned IP, replies from the host included, which
in practice kills the conversation both ways for anything the host
itself terminates. It is not a filter on the interface, though, and
it cannot be scoped to a port or protocol.

## Requirements

- `ip` (iproute2) in the `PATH` of the kur process, with privileges
  to change routes — in practice, root (or `CAP_NET_ADMIN`).
- Nothing else. No firewall, no kernel modules beyond normal
  networking.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. A route blocks the whole IP or nothing.
- `enable_cidr` — supported; a banned range is one route for the
  whole prefix.
- `prefix` — accepted, unused; routes carry no names.

## Options

| option      | default       | what                                          |
|-------------|---------------|------------------------------------------------|
| `blocktype` | `unreachable` | the route type — see below                    |

Valid values, matching `ip-route(8)`:

- `unreachable` — sends ICMP host-unreachable back.
- `blackhole` — silently drops; nothing is sent back.
- `prohibit` — sends ICMP administratively-prohibited back.

`blackhole` gives an attacker the least information;
`unreachable`/`prohibit` fail faster and more honestly for anything
legitimate caught in the net.

## What each operation runs

With `CMD = ip` or `ip -6` per the IP's family and `BT` the
blocktype:

| operation  | commands                                                                 |
|------------|-----------------------------------------------------------------------------|
| `init`     | nothing — routes need no scaffolding                                     |
| `ban`      | `CMD route add BT <ip>`                                                  |
| `unban`    | `CMD route del BT <ip>`                                                  |
| `list`     | no command — the kur's own ban book                                      |
| `check`    | `CMD route show type BT <ip>` per banned IP; missing = unhealthy         |
| `flush`    | `CMD route del BT <ip>` for every banned IP                              |
| `re_init`  | teardown (best effort), init, re-add every route                         |
| `teardown` | `CMD route del BT <ip>` per IP, failures tolerated (ban book kept)       |

A subtlety in `check`: `ip route show` exits 0 even when nothing
matches, so the probe treats **empty output** as the route being
gone. And since it probes each banned IP's route individually, this
is the rare backend where `check` cost grows with the number of bans
— with tens of thousands of eternal residents, each self_heal probe
walks them all.

## self_heal and reloads

An externally flushed routing table (`ip route flush`, a network
manager restart that rebuilds routes) is caught: `check` notices any
missing route and re_init re-adds them all. Teardown tolerating
already-removed routes exists for exactly this — cleaning up after an
external wipe should not error.

## Gotchas

- Routes are per-IP host routes; they do not aggregate. A million
  bans is a million routing table entries — the kernel handles that
  fine, but `ip route` output becomes archaeology.
- The block is host-wide and direction-agnostic in effect: the banned
  IP cannot reach any service, and the host cannot initiate anything
  to it either. If you need "block them from ssh but let them fetch
  the website", this is the wrong kur.
- On the plus side, this backend coexists with anything — pf-oriented
  hosts, firewalld hosts, hosts with no firewall at all.
- IPv6 addresses are lowercased on ban.
- Banned ranges must have the host bits zeroed (`192.0.2.0/24`, not
  `192.0.2.4/24`) — iproute2 rejects the latter with "Invalid prefix
  for given prefix length", surfacing as a `banCidrFailed` error.
- Errors carry Error::Helper flags (`blocktypeInvalid`,
  `portsNotSupported`, …) — [`Net::Firewall::BlockerHelper::backends::linux_ip_route`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::linux_ip_route) has the full table.
