# f5_bigip — an F5 BIG-IP address-list

Blocks on an F5 BIG-IP by managing an AFM firewall address-list via
iControl REST. One list holds both families; membership is rendered
wholesale from the kur's ban book on every change (a single PUT
replacing the `addresses` array). The list and the firewall
policy/rule consuming it are yours to build.

```toml
[kur.sshd]
backend = "f5_bigip"

[kur.sshd.options]
host     = "bigip.example.org"
user     = "kur-api"
password = "hunter2"
```

## BIG-IP-side setup — required first

- An AFM (Advanced Firewall Manager) provisioned BIG-IP — the
  address-list lives at `security firewall address-list`.
- Create the address-list, in the partition of your choice:
  `tmsh create security firewall address-list /Common/kur_sshd`
- Reference it from an AFM policy/rule that drops matching sources,
  attached where appropriate (global, route domain, or virtual
  server context).
- A user with permission to manage firewall address-lists — a
  dedicated role-scoped account rather than admin.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https`) — loaded only at
  runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping lives on the policy.
- `enable_cidr` — supported; the address-list carries ranges as
  readily as single IPs.
- `prefix` — builds the default list name.

## Options

| option      | default           | what                                     |
|-------------|-------------------|-------------------------------------------|
| `host`      | *(required)*      | BIG-IP host, optionally `host:port`      |
| `user`      | *(required)*      | iControl REST user (basic auth)          |
| `password`  | *(required)*      | its password                             |
| `name`      | `<prefix>_<name>` | the address-list object to manage        |
| `partition` | `Common`          | partition holding the address-list       |
| `timeout`   | `30`              | HTTP timeout in seconds                  |
| `insecure`  | `0`               | skip TLS certificate verification        |

## What each operation does

The object URL is
`/mgmt/tm/security/firewall/address-list/~<partition>~<name>`; auth
is HTTP basic:

| operation  | API traffic                                                            |
|------------|-----------------------------------------------------------------------------|
| `init`     | `GET` the object — verifies auth and that the list exists             |
| `ban`      | `PUT` the object with `{"addresses":[{"name":"<ip>"},...]}` — the full sorted book |
| `unban`    | the same render, minus the IP                                          |
| `list`     | no API call — the kur's own ban book                                   |
| `check`    | same probe as init                                                     |
| `flush`    | `PUT` with an empty `addresses` array                                  |
| `re_init`  | teardown (best effort), init, `PUT` the full book                      |
| `teardown` | `PUT` empty (ban book kept for re_init)                                |

A failed PUT rolls the kur's book back, keeping book and list
agreed.

## self_heal

`check` verifies auth and the list's existence — not its contents or
the policy. As with [pfsense](pfsense.md), wholesale rendering is
self-correcting: any hand-edit to the list is overwritten at the
next mutation.

## Gotchas

- **The kur owns the list contents** — the PUT replaces the entire
  `addresses` array. Anything else feeding the same list loses; give
  the kur its own.
- Very large books mean each mutation ships the whole list; BIG-IP
  handles thousands of entries fine, but the payload grows with the
  book.
- `insecure = 1` disables certificate verification; BIG-IP
  management certs are commonly self-signed.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `userNotDefined`, `passwordNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::f5_bigip`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::f5_bigip) has the full
  table.
