# cloudflare — blocking at the edge

Blocks IPs remotely via the Cloudflare v4 API using IP access rules —
the equivalent of the fail2ban `cloudflare`/`cloudflare-token`
actions, done with `LWP::UserAgent` rather than curl. The ban never
touches the local host; Cloudflare stops the traffic before it
reaches you.

```toml
[kur.cf]
backend = "cloudflare"

[kur.cf.options]
token = "your-scoped-api-token"
zone  = "your-zone-id"
mode  = "block"
```

## What it creates

One IP access rule per banned IP, at the zone level when `zone` is
set and at the user (account-wide) level otherwise:

```
POST https://api.cloudflare.com/client/v4/zones/<zone>/firewall/access_rules/rules
{ "mode": "block",
  "configuration": { "target": "ip", "value": "1.2.3.4" },
  "notes": "kur_cf" }
```

IPv6 IPs use `"target": "ip6"`. The `notes` value is the rule's
identity: unban looks the rule ID up by mode + notes + target + value
and DELETEs it.

## Cloudflare-side setup — required first

- **Token auth (preferred):** create an API token with just what is
  needed — *Zone → Firewall Services → Edit* for zone level rules
  (scoped to the zone), or *Account → Account Firewall Access Rules →
  Edit* for user/account level.
- **Zone ID:** shown on the zone's Overview page in the dashboard, a
  hex string; the backend validates it as `/^[a-fA-F0-9]+$/`.
- Legacy auth (`email` + `key`, the global API key) also works, for
  parity with the old fail2ban action, but the global key is
  all-powerful — prefer a scoped token.

## Requirements

- `LWP::UserAgent` and `LWP::Protocol::https` — loaded only at
  runtime.
- Credentials (above), and outbound HTTPS to `api.cloudflare.com`.

## Settings

- `ports` / `protocols` — **not supported**; Cloudflare access rules
  are per-IP. Specifying either is a fatal error at kur startup.
- `enable_cidr` — supported; access rules take CIDR targets as well
  as single IPs.
- `prefix` — only used in the default `notes` value.

## Options

| option    | default           | what                                                             |
|-----------|-------------------|-------------------------------------------------------------------|
| `token`   | *(unset)*         | API token, sent as `Authorization: Bearer <token>`               |
| `email`   | *(unset)*         | account email for legacy auth, sent as `X-Auth-Email`            |
| `key`     | *(unset)*         | legacy global API key, sent as `X-Auth-Key`                      |
| `zone`    | *(unset)*         | zone ID (hex) to manage rules under; unset = user level          |
| `mode`    | `block`           | `block`, `challenge`, `js_challenge`, or `managed_challenge`     |
| `notes`   | `<prefix>_<name>` | note on created rules — also how they are found again            |
| `timeout` | `30`              | HTTP timeout in seconds                                          |

Either `token` or both `email` and `key` must be set; anything else
fails at kur startup.

`mode` is what Cloudflare does with matching requests — `block`
refuses outright, the challenge modes interpose a CAPTCHA / JS proof
/ managed challenge instead, useful when you would rather turn back than
banish.

## What each operation does

| operation  | API traffic                                                              |
|------------|------------------------------------------------------------------------------|
| `init`     | `GET <endpoint>?per_page=5` — verifies credentials and endpoint          |
| `ban`      | `POST <endpoint>` with mode/configuration/notes                          |
| `unban`    | `GET <endpoint>?mode=..&notes=..&configuration.target=..&configuration.value=..` to find the rule ID, then `DELETE <endpoint>/<id>` |
| `list`     | no API call — the kur's own ban book                                     |
| `check`    | same probe as init                                                       |
| `flush`    | the unban lookup+DELETE per banned IP                                    |
| `re_init`  | teardown (best effort), init, re-POST every banned IP                    |
| `teardown` | the unban lookup+DELETE per banned IP (ban book kept for re_init)        |

`<endpoint>` is
`.../zones/<zone>/firewall/access_rules/rules` or
`.../user/firewall/access_rules/rules`.

API-level failures die with the HTTP status and Cloudflare's error
codes/messages included, which is what lands in the kur's error
responses and log.

## self_heal and remote drift

`check` verifies the endpoint and credentials still answer — it does
**not** verify individual rules still exist, so a rule someone
deleted in the dashboard stays deleted until `re_init`. The converse
is handled: unbanning an IP whose rule is already gone is treated as
already-unbanned, not an error.

## Gotchas

- **Every kur ban is an API round trip**, and Cloudflare rate-limits
  the API (per-account request budgets). A hostile flood of
  ban-worthy IPs turns into a flood of API calls — consider longer
  `ban_time` values here, and note timed bans mean more calls
  (each expiry is a lookup + DELETE).
- The `notes` value is the lookup key. Two kurs (or anything else)
  sharing a notes string will find each other's rules; leave the
  default `<prefix>_<name>` alone unless you have a reason.
- User-level rules apply to every zone on the account; zone-level
  only to that zone. Pick deliberately via `zone`.
- IPv6 IPs are lowercased before use.
- Errors carry Error::Helper flags (`modeInvalid`, `optionInvalid`,
  …) — [`Net::Firewall::BlockerHelper::backends::cloudflare`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::cloudflare) has the full
  table.
