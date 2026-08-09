# checkpoint — Check Point Management API

Blocks on Check Point by creating a host object per banned IP,
membered into a group, via the Management API (login → command →
publish). A security policy referencing the group does the blocking.
The group and policy are yours — as is **policy installation**, the
Check Point equivalent of Firepower's deployment caveat.

(No relation to Ereshkigal's own `checkpoint` command, which recopies
the clay tablets — an unfortunate collision of vendor and metaphor.)

```toml
[kur.web]
backend = "checkpoint"

[kur.web.options]
host     = "mgmt.example.org"
user     = "kur-api"
password = "hunter2"
```

## The install-policy caveat — read this first

The Management API's `publish` saves changes to the management
database; gateways enforce them only after **install-policy** (or,
on newer setups, updatable-object style automation). The kur
publishes after every change but never installs policy. Pair it with
scheduled policy pushes or automation that installs on publish —
without that, bans accumulate in SmartConsole and block nothing.

## Check Point-side setup — required first

- Management API enabled and reachable
  (`https://<host>/web_api/...`).
- A dedicated API user with permissions for host objects, group
  edits, and publish. Mind the **session limits** — Check Point caps
  concurrent sessions per user, so don't share the account.
- A **group object**, pre-created, named per the `group` option
  (default `<prefix>_<name>`).
- A policy rule dropping sources matching the group, installed once
  so the reference is live.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup.
- `enable_cidr` — supported; a banned range becomes a network object
  in the same group.
- `prefix` — builds the default group name and the per-IP object
  names.

## Options

| option     | default           | what                                    |
|------------|-------------------|------------------------------------------|
| `host`     | *(required)*      | management server host                  |
| `user`     | *(required)*      | Management API user                     |
| `password` | *(required)*      | its password                            |
| `group`    | `<prefix>_<name>` | the pre-existing group that objects join |
| `timeout`  | `30`              | HTTP timeout in seconds                 |
| `insecure` | `0`               | skip TLS certificate verification       |

## What each operation does

init POSTs `/web_api/login` and carries the returned session id as
`X-chkp-sid` thereafter. Per-IP host objects are named
`<prefix>_<name>_<ip>` with dots/colons flattened to dashes:

| operation  | API traffic                                                            |
|------------|-----------------------------------------------------------------------------|
| `init`     | `POST /web_api/login`                                                  |
| `ban`      | `POST /web_api/add-host` with `{"name":"<obj>","ip-address":"<ip>","groups":["<group>"]}`, then `POST /web_api/publish` |
| `unban`    | `POST /web_api/delete-host` with `{"name":"<obj>"}`, then publish      |
| `list`     | no API call — the kur's own ban book                                   |
| `check`    | `POST /web_api/keepalive` — session still valid (and refreshed)        |
| `flush`    | delete-host + publish per banned IP                                    |
| `re_init`  | teardown (best effort), init (fresh login), re-add + publish per IP    |
| `teardown` | delete-host + publish per banned IP (ban book kept)                    |

## self_heal

`check` is a session keepalive — it validates (and refreshes) the
session, nothing about objects, group, policy, or installation. A
timed-out session fails checks and bans; the `re_init` that
self_heal then triggers performs a fresh login, so session expiry
heals itself at the next ban/unban. With `self_heal` on, every ban's
keepalive also keeps the session alive.

## Gotchas

- The install-policy caveat dominates — publish ≠ enforce.
- Two API calls per ban and unban (change + publish); publishes are
  not cheap on busy management servers. High-churn ban sources will
  make SmartConsole's audit log very talkative.
- The kur never logs out; sessions die by server-side timeout.
  Combined with per-user session caps, give the kur its own API user
  and don't restart it in a tight loop.
- Hand-deleted host objects make later unbans error (deleting a
  missing object fails); `re_init` squares the books.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `userNotDefined`, `passwordNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::checkpoint`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::checkpoint) has the full
  table.
