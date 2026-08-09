# xdp — XDP/eBPF drops via xdp-filter

Drops packets in the NIC driver, before the kernel network stack
ever sees them, using `xdp-filter` from xdp-tools. The performance
option for very large ban books or packet floods on Linux.

```toml
[kur.edge]
backend = "xdp"

[kur.edge.options]
interfaces = [ "eth0" ]
```

## How it works

init loads the xdp-filter program onto each listed interface with a
default **allow** policy for both families:

```
xdp-filter load -f ipv4,ipv6 -p allow -m native eth0
```

Bans then add the IP to the program's BPF map blocklist
(`xdp-filter ip <ip> -m src`), unbans remove it (`... -r`). Because
every packet from the IP dies pre-stack, there is no `kill` option
and no need for one — established flows stop receiving anything the
moment the ban lands.

## Requirements

- `xdp-filter` (xdp-tools) in the `PATH` of the kur process, with
  privileges to load BPF programs — in practice, root.
- A kernel with XDP and the interface's driver supporting the chosen
  attach mode. `native` needs driver support; `skb` (generic mode)
  works everywhere at reduced speed — set `xdp_mode = "skb"` if
  `init` fails on your NIC.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**;
  xdp-filter's IP blocklist is whole-IP.
- `enable_cidr` — this backend can **not** carry ranges (the map
  holds single IPs); a kur with it set logs a warning at startup and
  answers range commands per `cidr_silent_drop`.
- `prefix` / `name` — accepted and unused by the backend; xdp-filter's
  map is global, not per-instance (which is also why `check` has to
  read the interface list out of `xdp-filter status` rather than
  probing an object of its own).

## Options

| option           | default      | what                                                        |
|------------------|--------------|--------------------------------------------------------------|
| `interfaces`     | *(required)* | array of interfaces to load the program onto, e.g. `["eth0"]` |
| `mode`           | `src`        | match direction for banned IPs — `src` or `dst`             |
| `xdp_mode`       | `native`     | attach mode: `native`, `skb`, `hw`, or `unspecified`        |
| `xdp_filter_cmd` | `xdp-filter` | the xdp-filter binary                                       |

`mode = "dst"` turns the kur into an outbound blocker (drop traffic
*to* the banned IPs) — occasionally useful, but `src` is the ban
semantics everything else in Ereshkigal assumes.

## What each operation runs

| operation  | commands                                                       |
|------------|------------------------------------------------------------------|
| `init`     | `xdp-filter load -f ipv4,ipv6 -p allow -m <xdp_mode> <iface>` per interface |
| `ban`      | `xdp-filter ip <ip> -m <mode>`                                 |
| `unban`    | `xdp-filter ip <ip> -m <mode> -r`                              |
| `list`     | no command — the kur's own ban book                            |
| `check`    | `xdp-filter status` exits 0 and lists every configured interface as loaded |
| `flush`    | `xdp-filter ip <ip> -m <mode> -r` per banned IP                |
| `re_init`  | teardown (best effort), init, re-add every banned IP           |
| `teardown` | `xdp-filter unload <iface>` per interface (ban book kept)      |

## self_heal

`check` runs the global `xdp-filter status` and requires each of
this kur's configured interfaces to show as loaded in its output —
the status exits 0 even with an interface unloaded, so the exit code
alone would miss it. An externally unloaded interface therefore
fails `check` and self_heal re_inits on the next ban/unban. What
`check` cannot see is the map's contents: IPs removed from the map
by hand stay gone until `re_init`.

## Gotchas

- **One XDP program per interface.** xdp-filter owns the interface's
  XDP hook while loaded: don't point two xdp kurs at the same
  interface, and don't run other XDP programs on it — teardown
  unloads the interface's program outright, taking any other
  xdp-filter user with it.
- The blocklist lives in a kernel BPF map; a crashed kur leaves the
  program loaded and the bans active (arguably a feature), cleaned
  up at the next init.
- `xdp-filter port` filtering exists upstream but is not exposed
  here; this kur is whole-IP.
- Errors carry Error::Helper flags (`interfacesInvalid`,
  `modeInvalid`, …) — [`Net::Firewall::BlockerHelper::backends::xdp`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::xdp) has the full table.
