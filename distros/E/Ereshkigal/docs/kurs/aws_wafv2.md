# aws_wafv2 — AWS WAFv2 IP sets

Blocks at AWS WAF by managing WAFv2 IP sets through the `aws` CLI —
one set per address family, rendered wholesale from the kur's ban
book using WAF's get-then-update optimistic locking. The IP sets and
the WebACL rule blocking on them are yours to create.

```toml
[kur.web]
backend = "aws_wafv2"

[kur.web.options]
scope  = "REGIONAL"
region = "us-east-2"
name4  = "kur-web-v4"
id4    = "a1b2c3d4-..."
name6  = "kur-web-v6"
id6    = "e5f6a7b8-..."
```

## AWS-side setup — required first

- The IP set(s): `aws wafv2 create-ip-set --scope REGIONAL
  --ip-address-version IPV4 --name kur-web-v4 --addresses ...` (and
  an IPV6 twin if you feed it IPv6). Note the returned **Id** — the
  options take both name and id.
- A WebACL rule with a block action whose statement references the
  IP set(s), and the WebACL associated with the ALB/API
  Gateway/CloudFront distribution.
- CLI credentials for a principal with `wafv2:GetIPSet` and
  `wafv2:UpdateIPSet`.
- `scope = "CLOUDFRONT"` operates on the global (CloudFront) scope —
  the CLI must then talk to `us-east-1` (set `region` accordingly).

## Requirements

- The `aws` CLI in the `PATH` of the kur process (or `aws_cmd`),
  with working credentials — an instance/task role, or a profile the
  kur's environment resolves.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**;
  scoping lives on the WebACL rule.
- `enable_cidr` — supported; WAFv2 IP sets take real CIDRs, which
  render alongside the single IPs.
- `prefix` — unused; the IP sets are addressed by name and ID.
- At least one family must be fully configured (`name4`+`id4` or
  `name6`+`id6`); banning an IP of an unconfigured family is an
  error (`ipsetNotConfigured`).

## Options

| option    | default      | what                                        |
|-----------|--------------|----------------------------------------------|
| `scope`   | `REGIONAL`   | `REGIONAL` or `CLOUDFRONT`                  |
| `region`  | *(unset)*    | adds `--region <region>` when set           |
| `name4`   | *(unset)*    | IPv4 IP set name                            |
| `id4`     | *(unset)*    | IPv4 IP set ID                              |
| `name6`   | *(unset)*    | IPv6 IP set name                            |
| `id6`     | *(unset)*    | IPv6 IP set ID                              |
| `aws_cmd` | `aws`        | the aws CLI binary                          |

## What each operation runs

Every mutation is get-then-update per touched family — `get-ip-set`
supplies the **lock token** WAF's optimistic locking requires:

| operation  | commands                                                             |
|------------|--------------------------------------------------------------------------|
| `init`     | `aws wafv2 get-ip-set --scope <scope> --name <name> --id <id>` per configured family |
| `ban`      | `get-ip-set` for the IP's family, then `aws wafv2 update-ip-set ... --addresses <ip1>/32 <ip2>/32 ... --lock-token <token>` — the family's full book |
| `unban`    | the same, minus the IP                                               |
| `list`     | no command — the kur's own ban book                                  |
| `check`    | a `get-ip-set` per configured family                                 |
| `flush`    | `update-ip-set` with an empty address list per family                |
| `re_init`  | teardown (best effort), init, update with the full book per family   |
| `teardown` | update with empty addresses per family (ban book kept)               |

Single IPv4 addresses render as `/32`, IPv6 as `/128`; banned CIDR
ranges render as themselves.

## self_heal

`check` verifies the CLI can fetch each configured set — not their
contents or the WebACL. But as with the other wholesale-render
backends, hand-edits are overwritten at the next mutation.

## Gotchas

- The lock token is fetched fresh per mutation; if something else
  edits the same IP set between the get and the update, WAF rejects
  the update and the ban errors — the next mutation (or `re_init`)
  gets a fresh token and re-renders. Don't share the kur's IP sets
  with other writers.
- Every mutation shells out to the `aws` CLI twice; slow (a second
  or two each) but WAF IP sets hold 10,000 entries, so this scales
  in volume where [cloud_armor](cloud_armor.md) can't.
- WAF changes propagate in seconds but not instantly.
- Errors carry Error::Helper flags (`scopeInvalid`,
  `ipsetNotConfigured`, …) — [`Net::Firewall::BlockerHelper::backends::aws_wafv2`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::aws_wafv2) has the full
  table.
