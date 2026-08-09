# pfsense — a pfSense firewall alias

Blocks on a pfSense firewall by managing the contents of a host-type
alias through the [pfSense-API](https://pfrest.org/) package's REST
API (v2). One alias holds both IPv4 and IPv6; the alias and the rule
blocking on it are yours to create — the kur manages membership
only, rendering the alias wholesale from its own ban book on every
change and applying.

```toml
[kur.sshd]
backend = "pfsense"

[kur.sshd.options]
host = "fw.example.org"
key  = "the-api-key"
```

## pfSense-side setup — required first

- Install the **pfSense-API package** (it is not stock pfSense) and
  create an API key for a user whose privileges cover the firewall
  alias and apply endpoints.
- Create the host-type alias (*Firewall → Aliases*, type Host(s)),
  named per the `alias` option (default `<prefix>_<name>`).
- Create a firewall rule blocking traffic whose source is the alias.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping lives on the rule.
- `enable_cidr` — supported; the alias carries networks as readily
  as hosts.
- `prefix` — builds the default alias name.

## Options

| option     | default           | what                                        |
|------------|-------------------|----------------------------------------------|
| `host`     | *(required)*      | pfSense host, optionally `host:port`        |
| `key`      | *(required)*      | API key, sent as the `X-API-Key` header     |
| `alias`    | `<prefix>_<name>` | the pre-existing host alias to manage       |
| `timeout`  | `30`              | HTTP timeout in seconds                     |
| `insecure` | `0`               | skip TLS certificate verification           |

## What each operation does

Membership is **rendered wholesale**: each change PATCHes the full
sorted IP list, then applies:

| operation  | API traffic                                                              |
|------------|-------------------------------------------------------------------------------|
| `init`     | `GET /api/v2/firewall/alias?name=<alias>` — verifies auth and the alias |
| `ban`      | `PATCH /api/v2/firewall/alias` with `{"id":"<alias>","type":"host","address":[...all banned IPs...]}`, then `POST /api/v2/firewall/apply` |
| `unban`    | the same render-and-apply, minus the IP                                 |
| `list`     | no API call — the kur's own ban book                                    |
| `check`    | same probe as init                                                      |
| `flush`    | render with an empty list + apply                                       |
| `re_init`  | teardown (best effort), init, render the full book + apply              |
| `teardown` | render empty + apply (ban book kept for re_init)                        |

A failed PATCH rolls the kur's book back, so the book and the alias
stay agreed.

## self_heal

`check` verifies the API answers and the alias exists — not its
contents, and not the rule. But because every mutation re-renders
the whole membership from the book, hand-removed entries reappear at
the next ban/unban even without a re_init — wholesale rendering is
self-correcting in a way the per-entry backends are not.

## Gotchas

- **The kur owns the alias contents.** Whatever else was in the
  alias is replaced at the first mutation — give the kur its own
  alias, feed nothing else into it.
- Each mutation is two calls (render + apply) and pfSense reloads
  its filter on apply; fine at ban rates, worth knowing at flood
  rates.
- `insecure = 1` disables certificate verification — pfSense ships
  self-signed; give it a real cert if the path matters.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `keyNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::pfsense`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::pfsense) has the full
  table.
