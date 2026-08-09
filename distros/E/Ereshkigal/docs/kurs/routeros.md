# routeros — MikroTik RouterOS over ssh

Blocks on a MikroTik router by driving its CLI over ssh: two
address-lists (IPv4 and IPv6) plus the input-chain filter rules
referencing them, all created by the kur itself. For the REST flavor
that manages only list membership, see
[routeros_api](routeros_api.md); this ssh one also works on RouterOS
6, which has no REST API.

```toml
[kur.sshd]
backend = "routeros"

[kur.sshd.options]
host     = "192.0.2.1"
user     = "blocker"
identity = "/usr/local/etc/ereshkigal/routeros_key"
```

## What it creates

At init, one filter rule per family:

```
/ip firewall filter add chain=input src-address-list=kur_sshd action=drop
/ipv6 firewall filter add chain=input src-address-list=kur_sshd action=drop
```

Bans then add to the matching list:

```
/ip firewall address-list add list=kur_sshd address=1.2.3.4
```

Every statement is delivered as
`ssh [-p <port>] [-i <identity>] <user>@<host> '<statement>'`.

## Requirements

- An ssh client in the `PATH` of the kur process.
- Key-based ssh access to the router as a user in a group with the
  `ssh`, `read`, and `write` policies. Interactive password
  prompts will hang the kur — use `identity` and an authorized key
  on the router (`/user ssh-keys import`).
- The router's host key already accepted (in `known_hosts` for the
  user the kur runs as) — the backend does nothing about host key
  prompts, and a prompt hangs the ban.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**. To
  scope the block, edit the filter rules the kur creates or use
  routeros_api against hand-built rules.
- `enable_cidr` — supported; RouterOS address-lists take ranges as
  readily as single IPs.
- `prefix` — builds the default list names.

## Options

| option     | default           | what                                             |
|------------|-------------------|---------------------------------------------------|
| `host`     | *(required)*      | router hostname or IP                            |
| `user`     | `admin`           | ssh user                                         |
| `ssh_cmd`  | `ssh`             | ssh binary plus any base arguments               |
| `ssh_port` | *(unset)*         | adds `-p <port>` when set                        |
| `identity` | *(unset)*         | adds `-i <identity>` when set                    |
| `list4`    | `<prefix>_<name>` | IPv4 address-list name                           |
| `list6`    | `<prefix>_<name>` | IPv6 address-list name                           |
| `action`   | `drop`            | filter rule action, e.g. `drop` or `reject`      |

## What each operation runs

All via ssh; `[find where ...]` is RouterOS's query-then-act idiom
and quietly matches nothing when the entry is already gone:

| operation  | statements                                                            |
|------------|---------------------------------------------------------------------------|
| `init`     | `/ip firewall filter add chain=input src-address-list=<list4> action=<action>` and the `/ipv6` twin |
| `ban`      | `/ip[v6] firewall address-list add list=<listN> address=<ip>`         |
| `unban`    | `/ip[v6] firewall address-list remove [find where list=<listN> address=<ip>]` |
| `list`     | no command — the kur's own ban book                                   |
| `check`    | `/ip firewall filter print where src-address-list=<list4>` exits 0    |
| `flush`    | `/ip[v6] firewall address-list remove [find where list=<listN>]`      |
| `re_init`  | teardown (best effort), init, re-add every banned IP                  |
| `teardown` | remove both filter rules, then both lists' entries (ban book kept)    |

## self_heal

`check` only confirms the IPv4 filter-rule query succeeds — and
RouterOS's `print where` exits 0 even when nothing matches, so in
practice it is an ssh-reachability probe. Only an ssh or auth
failure triggers self-heal; rules and list entries removed on the
router by hand stay gone until an explicit `re_init` (or a kur
restart).

## Gotchas

- Every ban is an ssh connection — fine for interactive-rate
  banning, sluggish under a flood. For high volume, routeros_api
  (still one request per ban, but HTTP rather than an ssh handshake)
  or a RouterOS address-list with its own timeout may suit better.
- teardown removes the filter rules the kur created by matching
  `src-address-list=<listN>` — any hand-added rules referencing the
  same list name will be removed with them.
- RouterOS address-list entries can carry their own timeouts; the
  kur does not use them — sentences are the kur sweeper's job.
- Errors carry Error::Helper flags (`hostNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::routeros`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::routeros) has the full
  table.
