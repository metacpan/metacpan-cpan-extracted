# cisco_fmc — Cisco Firepower (FMC)

Blocks on Cisco Firepower by rewriting the literals of a network
group object on the FMC via its REST API. An access control policy
referencing the group does the blocking. The group, the policy, and
— critically — **deployment to the sensors** are yours; the kur
rewrites the group's membership wholesale from its ban book.

```toml
[kur.web]
backend = "cisco_fmc"

[kur.web.options]
host     = "fmc.example.org"
user     = "kur-api"
password = "hunter2"
group_id = "005056A7-2BEA-0ed3-0000-012884902213"
```

## The deployment caveat — read this first

FMC config changes do **nothing** on the firewalls until deployed.
The kur updates the network group in the FMC database; it does not
(and deliberately does not) trigger a deployment. On its own, that
makes bans "pending" until the next deploy. Workable setups pair it
with FMC's auto-deploy, scheduled deployments, or your own
deployment automation — without one of those, this kur bans on
paper.

## FMC-side setup — required first

- A dedicated REST API user (FMC enforces one login per user for
  API access — don't share an account with humans).
- A **network group object**, pre-created; the option takes its
  **UUID** (fetch it via
  `GET /api/fmc_config/v1/domain/<domain>/object/networkgroups`),
  not its name.
- An access control policy rule blocking sources matching the
  group, deployed once so the reference exists on the sensors.
- Non-default domains need the `domain` UUID; the default is FMC's
  stock global domain.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping lives on the policy rule.
- `enable_cidr` — supported; ranges land as network literals in the
  same group.
- `prefix` — builds the default `group_name`.

## Options

| option       | default             | what                                        |
|--------------|---------------------|----------------------------------------------|
| `host`       | *(required)*        | FMC host, optionally `host:port`            |
| `user`       | *(required)*        | API user (basic auth for token generation)  |
| `password`   | *(required)*        | its password                                |
| `group_id`   | *(required)*        | UUID of the network group to manage         |
| `group_name` | `<prefix>_<name>`   | name carried in the PUT payload             |
| `domain`     | `e276abec-e0f2-11e3-8169-6d9ed49b625f` | FMC domain UUID; the default is the stock Global domain |
| `timeout`    | `30`                | HTTP timeout in seconds                     |
| `insecure`   | `0`                 | skip TLS certificate verification           |

## What each operation does

init POSTs `/api/fmc_platform/v1/auth/generatetoken` (basic auth)
and keeps the returned `X-auth-access-token` for everything after:

| operation  | API traffic                                                          |
|------------|--------------------------------------------------------------------------|
| `init`     | the token generation                                                 |
| `ban`      | `PUT /api/fmc_config/v1/domain/<domain>/object/networkgroups/<group_id>` with `{"name":...,"id":...,"literals":[{"type":"Host","value":"<ip>"},...]}` — the full sorted book |
| `unban`    | the same render, minus the IP                                        |
| `list`     | no API call — the kur's own ban book                                 |
| `check`    | `GET` the group object                                               |
| `flush`    | `PUT` with an empty literals array                                   |
| `re_init`  | teardown (best effort), init (fresh token), `PUT` the full book      |
| `teardown` | `PUT` empty literals (ban book kept)                                 |

## self_heal

`check` verifies the token still reads the group — not its literals,
the policy, or deployment state. FMC tokens expire (30 minutes,
refreshable a few times); an expired token surfaces as failing
bans/checks, and the resulting `re_init` via self_heal generates a
fresh token — so token expiry is, unusually, self-healing here.

## Gotchas

- The deployment caveat, again — it dominates everything else.
- Wholesale PUTs mean the kur owns the group's literals; anything
  else editing the same group gets overwritten.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `userNotDefined`, `passwordNotDefined`, `groupIdNotDefined`, …) —
  [`Net::Firewall::BlockerHelper::backends::cisco_fmc`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::cisco_fmc) has
  the full table.
