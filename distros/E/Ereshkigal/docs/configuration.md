# Configuration

The config file is TOML, by default `/usr/local/etc/ereshkigal.toml`
(overridable with `ereshkigal start --config <path>`). Top level keys
are manager settings; each hash under `kur` defines one underworld,
named for the hash — the hash at `kur.sshd` is the kur instance
`sshd`. Names must match `/^[a-zA-Z0-9-]+$/`.

## Manager settings

| key                | default                 | what                                                           |
|--------------------|-------------------------|----------------------------------------------------------------|
| `socket_group`     | root's default group    | group ownership of the manager socket                          |
| `socket_mode`      | `"0660"`                | perms on the manager socket, as a string, processed via oct    |
| `run_base_dir`     | `/var/run/ereshkigal`   | sockets and PID files live under here                          |
| `cache_base_dir`   | `/var/cache/ereshkigal` | the clay tablets (ban state CSVs) live here                    |
| `kur_bin`          | `kur`                   | the kur bin the manager spawns                                 |
| `timeout`          | `30`                    | seconds the manager waits on a kur socket                      |
| `ban_time`         | `600`                   | seconds a ban lasts; `0` = eternal residence                   |
| `checkpoint`       | `60`                    | seconds between tablet recopies; `0` = mutations/stop only     |
| `enable_cidr`      | `false`                 | whether whole ranges may be banished — see below               |
| `cidr_silent_drop` | `false`                 | drop rather than error CIDR commands where CIDR is unavailable |
| `enable_auth`      | `false`                 | Neti at the gate — see [security](security.md)                 |
| `authed_users`     | `[]`                    | users with global access (with enable_auth)                    |
| `authed_groups`    | `[]`                    | groups with global access (with enable_auth)                   |
| `auth_temp_dir`    | system tmpdir           | where the auth challenge cookie files go                       |

Kur sockets are always mode 0600 — that is not configurable, and
[security](security.md) explains why it must stay that way.

## Kur settings

Inside a `[kur.<name>]` hash...

| key                | what                                                                              |
|--------------------|-----------------------------------------------------------------------------------|
| `backend`          | required unless `fan_out` is set; see [kurs](kurs.md) for more info               |
| `fan_out`          | array of other kur names, in place of `backend`; makes this a gate (see below)    |
| `ports`            | array of ports to block for; all if unset                                         |
| `protocols`        | array of protocols to block for; backend-dependent default if unset               |
| `prefix`           | rule/table/chain name prefix, default `kur`                                       |
| `self_heal`        | verify and re-init the firewall setup before each ban/unban, default 1            |
| `ban_time`         | this underworld's default sentence, overriding the top level one                  |
| `checkpoint`       | this underworld's tablet recopy interval, overriding the top level one            |
| `enable_cidr`      | whether this underworld banishes ranges, overriding the top level one             |
| `cidr_silent_drop` | this underworld's drop-vs-error handling for CIDR, overriding the top level one   |
| `options`          | a hash of backend specific options; see each backend's page under [kurs](kurs.md) |
| `authed_users`     | users granted access to this kur, expanding the global list                       |
| `authed_groups`    | groups granted access to this kur, expanding the global list                      |

## Gates — fan_out kurs

A kur hash may carry `fan_out`, an array of other kur names, in place
of `backend`:

```toml
[kur.baphomet]
fan_out      = [ "sshd", "smtp" ]
authed_users = [ "baphomet" ]
```

Such a kur is a gate — one name that opens onto several underworlds.
It has no process and no socket of its own; commands targeted at it
(`ban --kur`, `cidr-ban --kur`, `checkpoint <name>`, `re-init <name>`,
`clear-retries <name>`, `status <name>`) fan out to its members
instead, with results reported per member.

With `enable_auth` on, a command aimed at a gate is authorized
against the gate's own lists, not its members'. That is what a gate
buys: an outside integration — a log watcher, IDS glue — can be
granted the gate alone and reach a whole set of underworlds through
it, without being listed on any member, or knowing they exist.

Members must be real kurs (gates may not nest), and untargeted
commands (`ban`/`cidr-ban` with no `--kur`, `unban`, `cidr-unban`,
`banned`, and bare `checkpoint`, `re-init`, and `clear-retries`)
never touch gates, only real kurs. In `status`, a gate shows its
member list and counts as running when every member is.

## How ban_time layers

The most specific setting wins:

    per request --ban-time  >  kur ban_time  >  top level ban_time  >  600

`0` at any layer means the ban never expires. `checkpoint` layers the
same way, minus the per-request level.

## Banishing ranges

`enable_cidr` opens the `cidr-ban`/`cidr-unban` commands (see
[usage](usage.md)). It is off by default and layers per kur — a top
level `enable_cidr = true` turns it on everywhere, a `[kur.<name>]`
`enable_cidr` overrides it for that one underworld either way.

```toml
enable_cidr = true          # ranges may be banished everywhere...

[kur.sshd]
backend = "pf"

[kur.abuseipdb]
backend     = "abuseipdb"
enable_cidr = false         # ...but not through this one
```

Enabling it is only half the story — the backend has to be able to
carry ranges. Table and set based backends (`pf`, `ipfw`, `ufw`,
`npf`, `linux_ip_route`, `shorewall`, `openwrt`, and most of the
appliance and cloud backends) can; `iptables`, `nftables`,
`firewalld`, `xdp`, `hosts_deny`, `dns_rpz`, `nsupdate`, `abuseipdb`,
and `netscaler` can not. A kur that has `enable_cidr` set on a
backend that cannot carry ranges logs a warning at startup and
refuses range commands.

`cidr_silent_drop` decides how such a kur — CIDR off, or a backend that
cannot oblige — answers a range command. Off (the default), it returns
an error. On, it quietly drops the command, reporting `dropped:1`. The
point is fan-outs: with a gate spanning range-capable and
range-incapable underworlds, setting `cidr_silent_drop` on the
incapable ones lets a single `cidr-ban` land where it can without the
rest souring the response.

Single IP `ban`/`unban` are unaffected by either toggle, and
`unban --all` empties ranges alongside single IPs regardless.

## A complete example

```toml
# the world above
socket_group = "wheel"      # who may speak to the manager...
# 0660 would normally be better, but in this example
# involves multiple groups having access
socket_mode  = "0666"       # ...via group membership on the socket
ban_time     = 600          # ten minute sentences unless told otherwise
checkpoint   = 60           # recopy the tablets every minute

# Neti at the gate... identity checks on top of the socket perms
enable_auth   = true
# Neti allows the user admin to access everything
authed_users  = [ "admin" ]
# Neti allows all users of the group wheel to access everything
authed_groups = [ "wheel" ]

# the sshd underworld... hour long sentences, and sever the states of
# anyone sent below
[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]
ban_time  = 3600

[kur.sshd.options]
kill = 1

# the smtp underworld
[kur.smtp]
backend   = "pf"
ports     = [ "25", "465", "587" ]
protocols = [ "tcp" ]

# the web underworld
[kur.web]
backend   = "pf"
ports     = [ "80", "443" ]
protocols = [ "tcp" ]
# Neti allows all members of the www access to this underworld...
# meaning if your webapps can manage their own bans
authed_groups = [ "www" ]

[kur.web.options]
kill = 0


# eternal residence for the manually curated
[kur.blocklist]
backend  = "pf"
ban_time = 0

[kur.blocklist.options]
kill = 1
```

Config changes take effect on restart. Kurs added at runtime with
`ereshkigal add` are not written back to this file — to make one
permanent, add its hash here.
