# juniper_srx — Juniper SRX

Blocks on a Juniper SRX by managing global address-book entries and
their membership in an address-set, via the Junos REST `/rpc` API —
each change loaded as `set`/`delete` configuration and **committed**
immediately, so unlike the FMC and Check Point kurs, enforcement is
live the moment the commit returns. The address-set and the security
policy referencing it are yours.

```toml
[kur.web]
backend = "juniper_srx"

[kur.web.options]
host     = "srx.example.org"
user     = "kur-api"
password = "hunter2"
```

## SRX-side setup — required first

- The REST API enabled:

```
set system services rest https
commit
```

- A login class/user allowed to change configuration under
  `security address-book` and to commit.
- The address-set (default `<prefix>_<name>`) referenced by a deny
  security policy, committed once, e.g.:

```
set security address-book global address kur_web_placeholder 192.0.2.255/32
set security address-book global address-set kur_web address kur_web_placeholder
set security policies from-zone untrust to-zone trust policy kur-web-deny \
    match source-address kur_web destination-address any application any
set security policies from-zone untrust to-zone trust policy kur-web-deny then deny
insert security policies from-zone untrust to-zone trust policy kur-web-deny before policy <your-first-allow>
commit
```

(The placeholder member is genuinely needed — Junos rejects an empty
address-set.)

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime. Auth is HTTP basic on every request; there is no session.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping lives on the policy.
- `enable_cidr` — supported; a banned range becomes its own address
  object (the `/` flattened to `-` in the object name) in the same
  address-set. Needs Net::Firewall::BlockerHelper newer than 0.1.0's
  2026-07-13 release, where CIDR object names were invalid Junos
  identifiers.
- `prefix` — builds the default address-set name and per-IP object
  names.

## Options

| option        | default           | what                                  |
|---------------|-------------------|----------------------------------------|
| `host`        | *(required)*      | SRX host, optionally `host:port`      |
| `user`        | *(required)*      | REST API user (basic auth)            |
| `password`    | *(required)*      | its password                          |
| `address_set` | `<prefix>_<name>` | the global address-set policies match |
| `timeout`     | `30`              | HTTP timeout in seconds               |
| `insecure`    | `0`               | skip TLS certificate verification     |

## What each operation does

Everything POSTs XML RPCs to `https://<host>/rpc`. Per-IP address
objects are named `<prefix>_<name>_<ip>` with dots/colons flattened
to dashes; IPv4 loads as `/32`, IPv6 as `/128`:

| operation  | RPCs                                                                |
|------------|--------------------------------------------------------------------------|
| `init`     | `<get-software-information/>` — verifies reachability and auth     |
| `ban`      | `<load-configuration action="set" format="text">` carrying `set security address-book global address <obj> <ip>/<mask>` and `set ... address-set <set> address <obj>`, then `<commit-configuration/>` |
| `unban`    | the load with `delete security address-book global address <obj>` (which also drops it from the set), then commit |
| `list`     | no API call — the kur's own ban book                                |
| `check`    | the same software-information probe as init                         |
| `flush`    | the delete-load + commit per banned IP                              |
| `re_init`  | teardown (best effort), init, re-load + commit per banned IP        |
| `teardown` | the delete-load + commit per banned IP (ban book kept)              |

## self_heal

`check` verifies reachability and credentials — not the address-book
contents, the set, or the policy. Hand-removed entries stay gone
until `re_init` (whose re-`set` of existing objects is harmlessly
idempotent, Junos being Junos).

## Gotchas

- **A commit per ban.** Junos commits take seconds on an SRX and
  serialize with any other configuration activity — an admin sitting
  in `configure exclusive` blocks the kur, and the kur's commits
  will sweep up any uncommitted candidate changes an admin left
  sitting. Give ops a heads-up that the ban system commits.
- The commit-per-change pace makes this kur wrong for high-churn ban
  sources; it shines for modest, longer sentences.
- Failed commits leave the kur's book ahead of the device until the
  next successful mutation or `re_init`.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `userNotDefined`, `passwordNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::juniper_srx`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::juniper_srx) has the full
  table.
