# cloud_armor — a GCP Cloud Armor rule

Blocks at Google's edge by rewriting the source ranges of one Cloud
Armor security-policy rule via the `gcloud` CLI. The policy, the
deny rule, and the load balancer attachment are yours; the kur owns
that one rule's `--src-ip-ranges`, rendered wholesale from its ban
book on every change.

```toml
[kur.web]
backend = "cloud_armor"

[kur.web.options]
policy   = "kur-policy"
priority = 1000
project  = "my-project"
```

## The 10-range limit — read this first

Cloud Armor allows **at most 10 source IP ranges per rule**, and the
kur does not shard across rules — the 11th concurrently banned IP
makes the `gcloud` update fail and the ban error. A banned CIDR
range consumes a slot exactly like a single IP. The failed ban is
rolled back out of the ban set, so it does not wedge later updates —
but the limit is still the limit. This backend is for *small,
curated* ban sets at the edge (a handful of abusers on
`ban_time = 0`, say), not volume banning. For volume, block at the
instances or use a different edge.

## GCP-side setup — required first

- A Cloud Armor security policy attached to the backend
  service/load balancer.
- A **deny rule at the chosen priority already existing** in it —
  the kur updates the rule, never creates it:

```shell
gcloud compute security-policies rules create 1000 \
    --security-policy kur-policy --action deny-403 \
    --src-ip-ranges 192.0.2.255/32
```

  (the placeholder range gets overwritten at the first mutation).
- `gcloud` authenticated as an account with
  `compute.securityPolicies.get`/`.update` — a service account
  activated for the kur's user, since the kur runs headless.

## Requirements

- `gcloud` in the `PATH` of the kur process (or `gcloud_cmd`),
  pre-authenticated.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**; a
  Cloud Armor deny rule's scope is the rule's own business.
- `enable_cidr` — supported, but a range takes one of the 10 slots
  same as a single IP.
- `prefix` — unused.

## Options

| option       | default      | what                                     |
|--------------|--------------|-------------------------------------------|
| `policy`     | *(required)* | the security policy name                 |
| `priority`   | `1000`       | the rule (priority) the kur owns         |
| `project`    | *(unset)*    | adds `--project <project>` when set      |
| `gcloud_cmd` | `gcloud`     | the gcloud binary                        |

## What each operation runs

| operation  | command                                                              |
|------------|--------------------------------------------------------------------------|
| `init`     | `gcloud compute security-policies rules describe <priority> --security-policy <policy>` |
| `ban`      | `gcloud compute security-policies rules update <priority> --security-policy <policy> --src-ip-ranges <ip1>/32,<ip2>/128,...` — the full sorted book |
| `unban`    | the same render, minus the IP                                        |
| `list`     | no command — the kur's own ban book                                  |
| `check`    | the same describe as init                                            |
| `flush`    | the update with an empty range list                                  |
| `re_init`  | teardown (best effort), init, update with the full book              |
| `teardown` | update with empty ranges (ban book kept)                             |

## self_heal

`check` verifies the rule exists and gcloud auth works — not the
rule's contents. Hand-edits to the ranges are overwritten at the
next mutation, since every update ships the whole book.

## Gotchas

- The 10-range ceiling, again — it is the design constraint
  everything else here follows from.
- Each mutation is a full `gcloud` invocation (slow — seconds, not
  milliseconds) and Cloud Armor propagation adds more; sentences
  land at cloud pace.
- gcloud auth (service account tokens) can expire out from under a
  long-running kur; a failed ban with an auth error means
  re-activating credentials, not a kur bug.
- Errors carry Error::Helper flags (`policyNotDefined`, …) —
  [`Net::Firewall::BlockerHelper::backends::cloud_armor`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::cloud_armor) has
  the full table.
