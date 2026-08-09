# akamai — an Akamai network list

Blocks at the Akamai edge by managing a Network List via the Network
Lists v2 API, EdgeGrid-authenticated. Security policies referencing
the list do the blocking; the kur manages membership only — and,
crucially, **does not activate** the list (see below).

```toml
[kur.web]
backend = "akamai"

[kur.web.options]
host            = "akab-xxxx.luna.akamaiapis.net"
client_token    = "akab-..."
client_secret   = "..."
access_token    = "akab-..."
network_list_id = "12345_KURWEB"
```

## The activation caveat — read this first

Network list edits land in the API immediately but are **not live on
the edge until the list is activated** to the production network.
This kur appends and removes elements; it does not call the
activation endpoint. That makes it suitable for lists on
fast-activation setups or where something else handles activation
(automation, or lists configured to auto-activate via other
tooling) — and unsuitable as a standalone rapid-response ban path.
Know your activation story before relying on it.

## Akamai-side setup — required first

- An **IP-type network list**, created in Control Center or via the
  API; the option takes its ID.
- A security configuration (App & API Protector or similar) whose
  policy blocks clients matching the list.
- An **EdgeGrid API client** (Identity & Access Management) with
  read-write to the Network Lists API. The four credential options
  are the fields from its `.edgerc` — the kur takes them directly
  rather than reading the file.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime. The EdgeGrid signature is computed natively
  (HMAC-SHA256); no Akamai SDK needed.
- A reasonably accurate clock — EdgeGrid signatures embed a
  timestamp and skew breaks auth.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup.
- `enable_cidr` — supported; network lists carry ranges as readily
  as single IPs.
- `prefix` — unused; Akamai objects are addressed by
  `network_list_id`.

## Options

| option            | default      | what                                  |
|-------------------|--------------|----------------------------------------|
| `host`            | *(required)* | the API host from the credential set  |
| `client_token`    | *(required)* | EdgeGrid client token                 |
| `client_secret`   | *(required)* | EdgeGrid client secret                |
| `access_token`    | *(required)* | EdgeGrid access token                 |
| `network_list_id` | *(required)* | the network list to manage            |
| `timeout`         | `30`         | HTTP timeout in seconds               |
| `insecure`        | `0`          | skip TLS certificate verification     |

## What each operation does

Base URL:
`https://<host>/network-list/v2/network-lists/<network_list_id>`:

| operation  | API traffic                                                   |
|------------|--------------------------------------------------------------------|
| `init`     | `GET` the list — verifies credentials and the list            |
| `ban`      | `POST .../append` with `{"list":["<ip>"]}`                    |
| `unban`    | `DELETE .../elements?element=<ip>`                            |
| `list`     | no API call — the kur's own ban book                          |
| `check`    | same probe as init                                            |
| `flush`    | the DELETE per banned IP                                      |
| `re_init`  | teardown (best effort), init, re-append every banned IP       |
| `teardown` | the DELETE per banned IP (ban book kept)                      |

Deleting an element the list no longer has succeeds quietly.

## self_heal

`check` verifies the credentials still read the list — not its
membership, not the policies consuming it, and certainly not
activation state.

## Gotchas

- The activation caveat above is the whole ballgame.
- Akamai rate-limits the API; pace chatty ban sources.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `clientTokenNotDefined`, `clientSecretNotDefined`,
  `accessTokenNotDefined`, `networkListIdNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::akamai`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::akamai) has the full
  table.
