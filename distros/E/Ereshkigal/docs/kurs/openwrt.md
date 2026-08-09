# openwrt — OpenWrt fw4 via UCI

Blocks on an OpenWrt router by way of fw4, configured through UCI
rather than by writing firewall rules directly. Two `config ipset`
sections and the `config rule` sections that drop on them are added to
`/etc/config/firewall`; fw4 renders each ipset into an nftables set in
its own `inet fw4` table.

The kur drives either the machine it runs on or a router across the
network. Leave `host` unset and it runs `uci`, `fw4`, and `nft`
locally; set it and everything goes over ubus JSON-RPC instead. Remote
is the usual choice, since OpenWrt ships no perl and so cannot host a
kur of its own.

```toml
[kur.sshd]
backend   = "openwrt"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.sshd.options]
host     = "192.0.2.1"
user     = "blocker"
password = "hunter2"
zone     = "wan"
kill     = 1
```

## Router-side setup — required first for remote mode

Local mode needs none of this. Remote mode needs all of it, once per
router.

- Install the rpcd pieces. `uhttpd-mod-ubus` puts ubus on the web
  server; `rpcd-mod-file` provides the `file` object every `nft` and
  `fw4` call rides on.

```shell
apk add uhttpd-mod-ubus rpcd-mod-file

# on releases still using opkg
opkg update && opkg install uhttpd-mod-ubus rpcd-mod-file
```

- Confirm uhttpd serves the ubus endpoint, which is the path the kur
  posts to. Installing `uhttpd-mod-ubus` sets it, so this is a check
  rather than a step: `uci get uhttpd.main.ubus_prefix` should answer
  `/ubus`.

- Install the ACL as
  `/usr/share/rpcd/acl.d/net-firewall-blockerhelper.json`, then
  `/etc/init.d/rpcd reload`. Nothing grants `file` `exec` by default,
  so without it every `nft` and `fw4` call comes back as ubus
  permission denied.

```json
{
    "net-firewall-blockerhelper": {
        "description": "Net::Firewall::BlockerHelper openwrt backend",
        "read": {
            "ubus": { "uci": [ "get" ] },
            "uci": [ "firewall" ]
        },
        "write": {
            "ubus": {
                "uci": [ "add", "set", "delete", "order", "commit" ],
                "file": [ "exec" ]
            },
            "uci": [ "firewall" ],
            "file": {
                "/usr/sbin/nft": [ "exec" ],
                "/sbin/fw4": [ "exec" ]
            }
        }
    }
}
```

- Point a login at that ACL. The stock `root` entry in
  `/etc/config/rpcd` carries `list read '*'` and `list write '*'`, so
  it picks the new ACL up on its own and the default `user = "root"`
  needs nothing further. A dedicated account is the better idea and
  wants its own section, naming the ACL group — the top level key of
  the JSON above. `/etc/init.d/rpcd restart` afterwards.

```
config login
	option username 'blocker'
	option password '$p$blocker'
	list read 'net-firewall-blockerhelper'
	list write 'net-firewall-blockerhelper'
```

`$p$blocker` means the password of the system user of that name, out
of `/etc/shadow`; a crypt(3) hash or a plain string may be given
instead.

`/usr/share/rpcd/acl.d/` survives a reboot but is not carried across a
sysupgrade — add the file's path to `/etc/sysupgrade.conf`, or remote
mode starts answering permission denied after the next firmware
upgrade. `/etc/config/rpcd`, and so the login, is kept by default.

## What it creates

In `/etc/config/firewall`, with `S4`/`S6` being `<prefix>_<name>_4`
and `<prefix>_<name>_6`:

- one `config ipset` section per family, named after the set, with
  `family ipv4`/`ipv6`, `match src_net`, and `enabled 1`
- one `config rule` section per family per protocol, named
  `<prefix>_<name>_r<N>`, carrying `src <zone>`, `ipset S4`/`S6`,
  `proto`, `dest_port` where the protocol takes ports, and
  `target DROP`/`REJECT`
- unless `reorder = 0`, those rule sections are moved to the front of
  the config with `uci reorder`, so they are evaluated ahead of any
  accept rule already there

fw4 turns that into interval sets in the `inet fw4` table, which is
what lets one pair of sets hold single addresses and ranges alike.

## Requirements

- **Local mode** — `uci`, `fw4`, and `nft` in the kur process's
  `PATH`, with the privileges to use them. This means the kur runs on
  the router, which in turn means perl on the router.
- **Remote mode** — [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
  and [JSON](https://metacpan.org/pod/JSON) where the kur runs, plus
  [LWP::Protocol::https](https://metacpan.org/pod/LWP::Protocol::https)
  when `http_proto = "https"`; all loaded only at runtime. On the
  router, the setup above.
- `kill = 1` additionally needs the `conntrack` package on the router
  (`apk add conntrack` — the tool is packaged under that name, not
  `conntrack-tools`), and in remote mode its path added to the `file`
  section of the ACL.

## Ports, protocols, and names

- Default `protocols`: with no ports either, one rule per family with
  `proto all` — spelled out, because fw4 reads an absent `proto` as
  `tcp udp` and would block far less than asked. With `ports` given
  and no protocols, `tcp` and `udp`.
- Ports attach only to port-capable protocols (tcp/udp/sctp); others
  get a rule with no port.
- Family-inappropriate protocols are skipped per family (`icmp` gets
  no IPv6 rule, `ipv6-icmp`/`icmp6`/`icmpv6` no IPv4 rule).
- `prefix` and `name` joined must come to 250 characters or fewer,
  leaving the nftables identifier limit room for the `_4`/`_6` and
  `_r<N>` suffixes.
- `enable_cidr` — supported. Ranges share the sets the single IPs use,
  and host bits need no zeroing.

## Options

| option       | default          | what                                                        |
|--------------|------------------|--------------------------------------------------------------|
| `type`       | `drop`           | `drop` silently drops; `reject` sends ICMP unreachable      |
| `zone`       | `*`              | the firewall zone the rules apply to, becoming their `src`  |
| `reorder`    | `1`              | move the rules to the front of the firewall config          |
| `kill`       | `0`              | conntrack(8) away existing connections for a banned IP      |
| `host`       | *(unset)*        | the router to drive over ubus; unset means run locally      |
| `user`       | `root`           | the ubus login (remote only)                                |
| `password`   | *(required with `host`)* | that login's password (remote only)                 |
| `http_proto` | `http`           | `http` or `https` (remote only)                             |
| `http_port`  | `80`, or `443` with https | the port uhttpd listens on (remote only)           |
| `timeout`    | `30`             | HTTP timeout in seconds (remote only)                       |
| `insecure`   | `0`              | skip certificate verification, for a self-signed router     |

### `zone`

`*` — the default — is every zone, which is rarely what is wanted on
a router. `wan` is the usual answer.

### `kill`

Severs the connections a ban alone leaves talking (see
[security](../security.md)). `conntrack -D -s <ip>`, one call per
configured protocol via `-p`, everything for the address when no
protocols are configured. conntrack's exit status is deliberately
ignored, since it is non-zero whenever there was nothing to delete —
which also means a missing package or a denying ACL is a silent no-op
rather than an error. Ban an address with a connection open and watch
`conntrack -L -s <ip>` empty out if you want to know it works.

## What each operation runs

Shown as the local commands. Remote mode does the same work as ubus
calls: `uci` `add`/`set`/`delete`/`order`/`commit` and `file` `exec`.

| operation    | commands                                                                     |
|--------------|---------------------------------------------------------------------------------|
| `init`       | cleanup (failure ok): `uci -q delete` each section; then `uci set`/`add_list` per section, `uci reorder` unless off, the ban list written into the ipset `entry` lists, `uci commit firewall`, `fw4 reload` |
| `ban`        | `nft add element inet fw4 <S4\|S6> { <ip> }`, then the conntrack kills if enabled — a range ban is the same call |
| `unban`      | `nft delete element inet fw4 <S4\|S6> { <ip> }` — likewise for a range, and an already absent element is tolerated |
| `list`       | no command — the kur's own ban book                                          |
| `check`      | `uci -q get firewall.<section>` for each set and rule section, plus `nft list table inet fw4` |
| `flush`      | `nft flush set inet fw4 S4`, then `S6` — config and rules stay               |
| `re_init`    | teardown (best effort), init, re-add every banned IP and range               |
| `teardown`   | `uci -q delete` each rule and ipset section, `uci commit firewall`, `fw4 reload`, then `nft delete set inet fw4 S4`/`S6` |

The sets are deleted by name at teardown because `fw4 reload` is
incremental: it drops rules that left the config but strands a set
whose section is gone. `fw4 restart` would clear them, along with
every other set in the table — including any other kur's.

## Where the bans actually live

Banning touches the live nftables set and nothing else. That is the
whole point: `uci commit` writes the overlay filesystem, which on most
routers is flash with a finite erase budget, so a commit per ban would
wear it out.

Persistence is therefore the kur's job rather than the router's. The
clay tablet is the source of truth, and a kur restart re-bans every
row of it through the backend. What does reach `/etc/config/firewall`,
and so flash, is one commit at `init`, at `re-init`, and at
`teardown` — and since a re-init commits the ban book into the ipset
`entry` lists on its way through init, a re-init is what writes the
current residents to flash. Ereshkigal never commits on its own beyond
that.

An `fw4 reload` keeps set contents. An `fw4 restart`, an
`/etc/init.d/firewall restart`, and a reboot all empty them, and what
comes back is whatever was committed last, seeded by fw4 from the
`entry` lists.

## self_heal

`check` asks three things: that every UCI section is still there, that
`nft list table inet fw4` shows each set defined and referenced by a
rule, and that a set whose family currently has residents is not
empty. That last one is what catches a firewall restart or a reboot,
which leave the config pristine and only the sets empty.

Contents are checked for emptiness only, never against the book —
nftables merges and splits intervals in an interval set, so what comes
back is often not what went in.

In remote mode each probe is several HTTP round trips (one per
section, one for the table listing), paid on every ban and unban with
`self_heal` on. On a slow or distant router, `self_heal = 0` plus a
periodic [`ereshkigal re-init`](../usage.md) trades prompt healing for
a much cheaper ban path.

## Gotchas

- **A partly-stale set is invisible to `check`.** After a reboot, fw4
  seeds the sets from the last commit. If that snapshot is non-empty,
  the emptiness test passes while every ban made since is missing.
  `ereshkigal re-init` puts the book back; nothing notices on its own.
- **The first commit rewrites `/etc/config/firewall`.** `uci commit`
  canonicalizes the whole file and drops every comment in it,
  including the commented-out examples a stock config ships with. The
  configuration is unchanged, but the comments are gone — copy the
  file first if you want them.
- **Overlapping ranges do not round trip.** fw4 gives the sets the
  `auto-merge` flag, so nftables folds overlapping and adjacent ranges
  together. Ban `10.0.0.0/8` then `10.1.0.0/16` and one interval
  remains; a later `cidr-unban` of the `/16` punches a hole in the
  `/8`, while the kur's book still reads `/8`. Banish ranges that do
  not overlap and it cannot arise.
- **`reorder = 1` puts the rules ahead of the zone sections too.** fw4
  parses the whole config before emitting anything, so this is
  harmless, but it is worth knowing if you read the config by hand.
- With plain `http`, the router password crosses the network in the
  clear on every login. `http_proto = "https"` with `insecure = 1`
  encrypts it against a self-signed certificate; drop `insecure` once
  the router has a real one.
- ubus sessions expire after five idle minutes. The backend notices
  the resulting permission denied, logs in again, and retries once, so
  this costs a round trip rather than an error.
- Several kurs may share a router — sections and sets are named from
  `<prefix>_<name>` and each teardown removes only its own.
- Errors carry Error::Helper flags (`invalidHost`, `noPassword`,
  `invalidZone`, `invalidHttpPort`, `invalidHttpProto`, …) —
  [`Net::Firewall::BlockerHelper::backends::openwrt`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::openwrt)
  has the full table, along with the backend's own account of the
  router-side setup.
</content>
</invoke>
