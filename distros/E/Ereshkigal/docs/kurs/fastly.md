# fastly — an edge ACL at Fastly

Blocks at the Fastly edge by managing entries in an Edge ACL via the
Fastly API. The service's VCL decides what happens to matching
clients; the kur manages ACL membership only, one entry per banned
IP, effective as soon as the API call lands (edge ACL updates do not
need a service deploy).

```toml
[kur.web]
backend = "fastly"

[kur.web.options]
token   = "the-api-token"
service = "SU1Z0isxPaozGVKXdv0eY"
acl     = "6tUXdegLTf5BCig0zGFrU3"
```

## Fastly-side setup — required first

- Create the ACL on the service (via UI or API) and note the
  **service ID** and **ACL ID** — the options take IDs, not names.
- VCL that consults the ACL and acts (referencing the ACL by
  whatever *name* you created it under — the kur only ever sees the
  ID), e.g.:

```vcl
if (client.ip ~ my_banned_acl) {
  error 403 "banished";
}
```

- An API token scoped to the service with engineer/ACL permissions.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup.
- `enable_cidr` — supported; ACL entries carry a subnet as readily
  as a single IP.
- `prefix` — bookkeeping only; Fastly objects are addressed by ID.

## Options

| option     | default      | what                                    |
|------------|--------------|------------------------------------------|
| `token`    | *(required)* | API token, sent as the `Fastly-Key` header |
| `service`  | *(required)* | the service ID                          |
| `acl`      | *(required)* | the ACL ID                              |
| `timeout`  | `30`         | HTTP timeout in seconds                 |
| `insecure` | `0`          | skip TLS certificate verification       |

## What each operation does

Base URL: `https://api.fastly.com/service/<service>/acl/<acl>`:

| operation  | API traffic                                                          |
|------------|--------------------------------------------------------------------------|
| `init`     | `GET .../entries?per_page=1` — verifies token, service, and ACL      |
| `ban`      | `POST .../entry` with `{"ip":"<ip>","subnet":32}` (128 for IPv6)     |
| `unban`    | `GET .../entries` to find the entry's ID, then `DELETE .../entry/<id>` |
| `list`     | no API call — the kur's own ban book                                 |
| `check`    | same probe as init                                                   |
| `flush`    | the lookup+DELETE per banned IP                                      |
| `re_init`  | teardown (best effort), init, re-POST every banned IP                |
| `teardown` | the lookup+DELETE per banned IP (ban book kept)                      |

An entry already removed at Fastly by hand is treated as already
unbanned.

## self_heal

`check` verifies the token still reads the ACL — not the entries,
and not that any VCL consults it. Hand-removed entries stay gone
until `re_init`.

## Gotchas

- The unban lookup fetches the entry list to find the ID — with very
  large ACLs that is a heavy read per unban, and mass expiries
  multiply it. Fastly ACLs also cap at 10,000 entries by default;
  keep ban volumes inside that.
- Fastly rate-limits API writes account-wide; pace chatty ban
  sources.
- Errors carry Error::Helper flags (`serviceNotDefined`,
  `tokenNotDefined`, `aclNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::fastly`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::fastly) has the full
  table.
