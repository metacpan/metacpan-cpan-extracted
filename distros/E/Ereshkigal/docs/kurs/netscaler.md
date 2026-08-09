# netscaler — Citrix NetScaler/ADC

Blocks remotely by binding IPs into a policy dataset on a NetScaler
via the NITRO REST API — the equivalent of the fail2ban `netscaler`
action, done with `LWP::UserAgent` rather than curl. The dataset does
nothing by itself; responder (or similar) policies referencing it do
the actual blocking.

```toml
[kur.adc]
backend = "netscaler"

[kur.adc.options]
host    = "netscaler.example.com"
user    = "nsroot"
pass    = "hunter2"
dataset = "banned_ips"
```

## What it creates

One dataset value binding per banned IP:

```
PUT https://<host>/nitro/v1/config/policydataset_value_binding
{ "policydataset_value_binding": { "name": "<dataset>", "value": "1.2.3.4" } }
```

Unban is a DELETE on
`/nitro/v1/config/policydataset_value_binding/<dataset>?args=value:<ip>`.

## NetScaler-side setup — required before use

The policy dataset must already exist; init only verifies the API is
reachable and auth works, it does not create the dataset. On the
NetScaler:

```
add policy dataset banned_ips ipv4
```

(or type `ipv6` / one dataset per family as your policies need), then
wire it into enforcement, e.g. a responder policy dropping matching
clients:

```
add responder policy kur_block "CLIENT.IP.SRC.EQUALS_ANY(\"banned_ips\")" DROP
bind lb vserver my_vserver -policyName kur_block -priority 10 -type REQUEST
```

Exactly how the dataset is consumed — responder policy, ACL
expression, vserver or global binding — is your design; the kur only
manages the membership.

A dedicated API user with just the permissions to manage dataset
bindings is preferable to `nsroot`.

## Requirements

- `LWP::UserAgent` installed, plus `LWP::Protocol::https` when
  `scheme` is https (the default) — loaded only at runtime.
- Network reach to the appliance's NITRO endpoint.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping lives in the policies consuming
  the dataset.
- `enable_cidr` — this backend can **not** carry ranges (dataset
  values are single IPs); a kur with it set logs a warning at startup
  and answers range commands per `cidr_silent_drop`.
- `prefix` — only used in the default `dataset` name.

## Options

| option       | default           | what                                                             |
|--------------|-------------------|-------------------------------------------------------------------|
| `host`       | *(required)*      | hostname or IP of the appliance; `/^[a-zA-Z0-9.\-\[\]:]+$/`     |
| `user`       | *(unset)*         | username for basic auth                                          |
| `pass`       | *(unset)*         | password for basic auth                                          |
| `auth`       | *(unset)*         | pre-base64ed `user:pass`, in place of user/pass (fail2ban `ns_auth` parity) |
| `dataset`    | `<prefix>_<name>` | the policy dataset holding the IPs; `/^[a-zA-Z0-9_\-]+$/`       |
| `scheme`     | `https`           | `http` or `https`                                                |
| `ssl_verify` | `0`               | verify the TLS certificate                                       |
| `timeout`    | `30`              | HTTP timeout in seconds                                          |

`host` is required, as is either `auth` or both `user` and `pass`.
Auth is sent as `Authorization: Basic <base64>` — built from
user/pass at request time, or your `auth` value verbatim.

`ssl_verify` defaults **off**, matching the fail2ban action's
`curl -k` (appliances commonly wear self-signed certificates). Off
means `verify_hostname => 0` — the connection is encrypted but the
peer unauthenticated; anything that can MITM the path can harvest the
credentials. Set `ssl_verify = 1` if the appliance has a real
certificate, and consider giving it one if not.

## What each operation does

| operation  | API traffic                                                          |
|------------|--------------------------------------------------------------------------|
| `init`     | `GET <scheme>://<host>/nitro/v1/config` — verifies reachability and auth |
| `ban`      | the `PUT policydataset_value_binding` above                          |
| `unban`    | `DELETE .../policydataset_value_binding/<dataset>?args=value:<ip>`   |
| `list`     | no API call — the kur's own ban book                                 |
| `check`    | same probe as init                                                   |
| `flush`    | the DELETE per banned IP                                             |
| `re_init`  | teardown (best effort), init, re-PUT every banned IP                 |
| `teardown` | the DELETE per banned IP (ban book kept for re_init)                 |

HTTP-level failures die with the status and response body included —
but NITRO errors that arrive with HTTP 200 are not parsed, so a
misconfigured dataset name may only surface as a failed ban rather
than at init.

## self_heal and remote drift

`check` verifies the API answers and auth works — not that the
dataset exists or that individual bindings survive. A binding removed
on the appliance by hand stays removed until `re_init`; unlike the
cloudflare backend, unbanning an already-missing binding is an error
(the DELETE fails), which the kur logs and reports.

## Gotchas

- Every ban/unban is an API round trip; timed bans double that at
  expiry. Mind the appliance's management-plane appetite with very
  chatty ban sources.
- Both IPv4 and IPv6 values are accepted and passed through; make
  sure the dataset's type (and the policies) match what you feed it.
- IPv6 IPs are lowercased before use.
- Errors carry Error::Helper flags (`optionInvalid`, …) — [`Net::Firewall::BlockerHelper::backends::netscaler`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::netscaler) has the full
  table.
