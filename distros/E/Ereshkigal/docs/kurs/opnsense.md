# opnsense — an OPNsense firewall alias

Blocks on an OPNsense firewall by adding IPs to a firewall alias via
the `alias_util` REST API, driven with
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent). One alias holds
both IPv4 and IPv6 — OPNsense host aliases are family agnostic. The
alias and the rule that blocks on it are yours to create; the kur
manages membership only.

```toml
[kur.sshd]
backend = "opnsense"

[kur.sshd.options]
host   = "fw.example.org"
key    = "someAPIkey"
secret = "someAPIsecret"
```

## OPNsense-side setup — required first

- Create the alias: *Firewall → Aliases*, type Host(s), name matching
  the `alias` option (default `<prefix>_<name>`, e.g. `kur_sshd`).
- Create a firewall rule blocking traffic whose source is that
  alias, on the interfaces that matter.
- Create an API key pair: *System → Access → Users*, the key/secret
  pair lands in a download. A dedicated user whose privileges cover
  just the firewall API is better than root's keys.

## Requirements

- [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent), plus
  [LWP::Protocol::https](https://metacpan.org/pod/LWP::Protocol::https)
  for the default https scheme — loaded only at runtime.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**;
  scoping lives on the referencing rule.
- `enable_cidr` — supported; the alias carries networks as readily
  as hosts.
- `prefix` — builds the default alias name.

## Options

| option     | default           | what                                                  |
|------------|-------------------|--------------------------------------------------------|
| `host`     | *(required)*      | OPNsense host, optionally `host:port`                 |
| `key`      | *(required)*      | API key (basic auth user)                             |
| `secret`   | *(required)*      | API secret (basic auth password)                      |
| `alias`    | `<prefix>_<name>` | the pre-existing alias the IPs are added to           |
| `scheme`   | `https`           | `https` or `http`                                     |
| `insecure` | `0`               | disables certificate verification, accepting self-signed certificates |
| `timeout`  | `30`              | HTTP timeout in seconds                               |

## What each operation runs

All calls are HTTP requests authenticated via basic auth with
`<key>:<secret>`, bodies sent as `Content-Type: application/json`:

| operation  | call                                                                  |
|------------|---------------------------------------------------------------------------|
| `init`     | `GET .../api/firewall/alias_util/list/<alias>` — verifies reachability, auth, and the alias |
| `ban`      | `POST .../api/firewall/alias_util/add/<alias>` with `{"address":"<ip>"}` |
| `unban`    | `POST .../api/firewall/alias_util/delete/<alias>` with `{"address":"<ip>"}` |
| `list`     | no API call — the kur's own ban book                                  |
| `check`    | same list call as init                                                |
| `flush`    | `POST .../api/firewall/alias_util/flush/<alias>` with `{}`            |
| `re_init`  | teardown (best effort), init, re-add every banned IP                  |
| `teardown` | the same alias flush (ban book kept for re_init)                      |

Deleting an address already gone from the alias succeeds quietly —
a hand-removal on the firewall won't make a later unban error.

## self_heal

`check` verifies the API answers and the alias exists — not that any
rule consumes the alias, nor the alias's contents. Contents removed
by hand stay removed until `re_init`.

## Gotchas

- **teardown and flush empty the whole alias.** If anything besides
  this kur feeds the same alias (another kur, hand-curated entries),
  those entries are flushed too — give each kur its own alias.
- `insecure = 1` skips certificate verification: encrypted,
  unauthenticated. Give the firewall a real certificate if the path
  matters.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `apiKeyNotDefined`, `apiSecretNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::opnsense`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::opnsense) has the full
  table.
