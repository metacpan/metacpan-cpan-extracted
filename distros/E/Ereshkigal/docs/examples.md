# Examples

Worked scenarios to copy from. Paths assume the defaults; adjust to
taste.

## An sshd underworld on pf, hour-long sentences

`/usr/local/etc/ereshkigal.toml`...

```toml
socket_group = "wheel"

[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]
ban_time  = 3600

[kur.sshd.options]
kill = 1        # sever established sessions too... see security.md
```

```shell
ereshkigal start
ereshkigal ban --kur sshd 203.0.113.7
ereshkigal status sshd
```

The ban adds 203.0.113.7 to the kur's pf table and kills its existing
states. An hour later the sweeper releases it on its own.

## One underworld per service

```toml
ban_time = 600                  # the default sentence

[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]
ban_time  = 3600                # ssh abusers sit longer

[kur.sshd.options]
kill = 1

[kur.smtp]
backend   = "pf"
ports     = [ "25", "465", "587" ]
protocols = [ "tcp" ]

[kur.smtp.options]
kill = 1

[kur.web]
backend   = "pf"
ports     = [ "80", "443" ]
protocols = [ "tcp" ]
ban_time  = 300                 # web scanners come and go
```

`ereshkigal ban 198.51.100.9` banishes an IP to all three at once;
`--kur web` picks one.

## An eternal-residence blocklist

```toml
[kur.blocklist]
backend     = "pf"
ban_time    = 0                 # no one comes back on their own
enable_cidr = true              # whole ranges welcome too

[kur.blocklist.options]
kill = 1
```

Feeding it single IPs and whole ranges from files...

```shell
xargs ereshkigal ban      --kur blocklist < /usr/local/etc/blocklist.txt
xargs ereshkigal cidr-ban --kur blocklist < /usr/local/etc/blockranges.txt
```

Those IPs and ranges stay below across restarts (the tablets see to
that) until an explicit `ereshkigal unban` / `ereshkigal cidr-unban`.
A range is stored as its network address, so `ereshkigal cidr-unban
203.0.113.0/24` releases it however the ban was first spelled.

## An underworld on the edge router

OpenWrt ships no perl, so the kur lives on a host beside the router
and drives fw4 over ubus. Set the router up first — the packages, the
rpcd ACL, and a login pointed at it, all in [openwrt](kurs/openwrt.md)
— then:

```toml
[kur.wan-ssh]
backend     = "openwrt"
ports       = [ "22" ]
protocols   = [ "tcp" ]
enable_cidr = true

[kur.wan-ssh.options]
host     = "192.0.2.1"
user     = "blocker"
password = "hunter2"
zone     = "wan"        # '*', the default, is every zone
kill     = 1            # wants the conntrack package on the router
```

```shell
ereshkigal ban      --kur wan-ssh 203.0.113.7
ereshkigal cidr-ban --kur wan-ssh 203.0.113.0/24
```

Both land in the router's nftables sets at once, and neither is
written to its flash — the tablet is what carries them across a
restart of either end. Restarting the firewall or rebooting the router
empties those sets; `self_heal` catches that before the next ban and
rebuilds from the book, and `ereshkigal re-init wan-ssh` does the same
on demand.

## Raising and tearing down an underworld at runtime

```shell
# raise a dns kur right now
ereshkigal add dns --backend pf --ports 53 --protocols tcp,udp \
    --option kill=1 --ban-time 300

ereshkigal ban --kur dns 192.0.2.4

# tear it down... firewall state and all
ereshkigal remove dns
```

Neither command edits ereshkigal.toml — to keep the dns kur across
restarts, add its `[kur.dns]` hash to the config.

## Feeding an underworld from a log

The simplest possible integration, banning via the CLI...

```sh
#!/bin/sh
# banish repeat offenders in auth.log to the sshd underworld
tail -F /var/log/auth.log | while read line; do
    ip=$(printf '%s\n' "$line" \
        | sed -n 's/.*Failed password.*from \([0-9.]*\).*/\1/p')
    [ -n "$ip" ] && ereshkigal ban --kur sshd "$ip"
done
```

Or skipping the CLI and speaking JSON straight at the manager
socket...

```shell
printf '%s\n' \
  '{"command":"ban","args":{"ips":["203.0.113.7"],"kur":"sshd","ban_time":3600}}' \
  | nc -U /var/run/ereshkigal/socket
```

From perl, use `Ereshkigal::Client` — it also handles the
`enable_auth` gate transparently (see [usage](usage.md)).

## A monitoring user Neti admits to only one kur

```toml
enable_auth   = true
authed_groups = [ "wheel" ]     # admins may do anything

[kur.sshd]
backend      = "pf"
ports        = [ "22" ]
protocols    = [ "tcp" ]
authed_users = [ "sshd-mon" ]   # expands the global lists, for sshd only

[kur.sshd.options]
kill = 1
```

The `sshd-mon` user can `ereshkigal status sshd` and
`ereshkigal ban --kur sshd ...`, but `status`, a bare `ban`, `stop`,
and anything touching other kurs is refused at the gate. See
[security](security.md) for the full trust model.

## One gate onto many underworlds

Granting an integration each kur it should reach means editing every
one of them whenever the set changes. A [gate](kurs/gate.md) inverts
that: one name, authorized once, opening onto as many underworlds as
you like.

```toml
enable_auth   = true
authed_groups = [ "wheel" ]

[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.smtp]
backend   = "pf"
ports     = [ "25", "587" ]
protocols = [ "tcp" ]

[kur.edge]
backend = "cloudflare"

[kur.edge.options]
token = "someAPItoken"
zone  = "somezoneID"

# the gate... no process, no firewall of its own, just a name
[kur.baphomet]
fan_out      = [ "sshd", "smtp", "edge" ]
authed_users = [ "baphomet" ]
```

The `baphomet` user is on none of the three member kurs, yet:

```shell
ereshkigal ban --kur baphomet 1.2.3.4
```

lands that IP on pf twice over and at the Cloudflare edge, answering
per member. Adding a fourth underworld to the fan_out extends the
integration's reach without touching its authorization, and dropping
one narrows it — the integration never learns either happened.

Gates may not nest, and members must be real kurs. Untargeted
commands (a bare `ban`, `unban`, `banned`) never route through a gate;
they go to the real kurs directly.

## An underworld of pure imagination

The `dummy` backend remembers what it was told and touches no
firewall, so everything can be tried unprivileged...

```toml
run_base_dir   = "/tmp/ereshkigal-play/run"
cache_base_dir = "/tmp/ereshkigal-play/cache"
socket_group   = "wheel"        # any group you are in

[kur.testing]
backend = "dummy"
```

```shell
ereshkigal start --config ./play.toml
ereshkigal -s /tmp/ereshkigal-play/run/socket ban --ban-time 5 192.0.2.1
ereshkigal -s /tmp/ereshkigal-play/run/socket banned
sleep 6
ereshkigal -s /tmp/ereshkigal-play/run/socket banned   # released by the sweeper
ereshkigal -s /tmp/ereshkigal-play/run/socket stop
```
