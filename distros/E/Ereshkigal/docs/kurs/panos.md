# panos — Palo Alto Networks PAN-OS

Blocks on a PAN-OS firewall by registering banned IPs to a tag
through the User-ID XML API. A Dynamic Address Group (DAG) matching
that tag, referenced by a security policy, does the enforcement —
and DAG membership updates **without a commit**, which is what makes
this the right PAN-OS mechanism for dynamic bans. The kur manages
only the registrations.

```toml
[kur.sshd]
backend = "panos"

[kur.sshd.options]
host = "fw.example.org"
key  = "the-api-key"
```

## PAN-OS-side setup — required first

- Generate an API key out of band (`type=keygen` API call or the web
  UI), ideally for a dedicated admin role restricted to the User-ID
  XML API.
- Create the Dynamic Address Group with a match condition on the
  tag (default `<prefix>_<name>`, e.g. `kur_sshd`):
  *Objects → Address Groups → Add*, type Dynamic, match
  `'kur_sshd'`.
- Reference the DAG as the source of a deny security policy, and
  commit that once — after which registrations flow into enforcement
  commit-free.

## Requirements

- `LWP::UserAgent` (plus `LWP::Protocol::https` for the default
  https) — loaded only at runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup. Scoping belongs on the security
  policy.
- `enable_cidr` — supported; a range registers against the tag the
  same way a single IP does.
- `prefix` — builds the default tag.

## Options

| option     | default           | what                                             |
|------------|-------------------|---------------------------------------------------|
| `host`     | *(required)*      | PAN-OS host, optionally `host:port`              |
| `key`      | *(required)*      | PAN-OS API key                                   |
| `tag`      | `<prefix>_<name>` | the tag registered IPs get, matched by the DAG   |
| `vsys`     | *(unset)*         | vsys to scope registrations to, e.g. `vsys1`     |
| `scheme`   | `https`           | `https` or `http`                                |
| `insecure` | `0`               | skip TLS certificate verification                |
| `timeout`  | `30`              | HTTP timeout in seconds                          |

## What each operation does

Everything is a `POST` to `<scheme>://<host>/api/` with form-encoded
`type`/`key`/`cmd` (plus `vsys` when set); success requires
`status="success"` in the XML reply:

| operation  | payload                                                             |
|------------|-------------------------------------------------------------------------|
| `init`     | `type=op`, `cmd=<show><system><info></info></system></show>` — verifies reachability and the key |
| `ban`      | `type=user-id`, a uid-message registering the IP to the tag         |
| `unban`    | `type=user-id`, the same message with `<unregister>`               |
| `list`     | no API call — the kur's own ban book                                |
| `check`    | the same op probe as init                                           |
| `flush`    | the unregister per banned IP                                        |
| `re_init`  | teardown (best effort), init, re-register every banned IP           |
| `teardown` | the unregister per banned IP (ban book kept)                        |

The register payload, for the curious:

```xml
<uid-message><version>2.0</version><type>update</type><payload>
  <register><entry ip="1.2.3.4"><tag><member>kur_sshd</member></tag></entry></register>
</payload></uid-message>
```

One tag holds both IPv4 and IPv6 registrations; registering an
already-registered IP is idempotent on PAN-OS.

## self_heal

`check` probes reachability and key validity — not that the tag's
DAG exists, that registrations are still in the User-ID cache, or
that any policy enforces them. Two consequences worth knowing:

- Registered-IP mappings are runtime state. A firewall reboot (or a
  User-ID cache clear) silently drops them while `check` stays
  green — pair such events with a `re_init`.
- A missing or mis-matched DAG means registrations succeed and
  nothing is blocked; as with [npf](npf.md), the kur cannot see
  whether anything consumes its work.

## Gotchas

- `vsys` must match where the DAG and policy live — registrations in
  the wrong vsys enforce nothing, successfully.
- Registrations can also carry timeouts on PAN-OS; the kur does not
  use them — sentences are the sweeper's job, and a PAN-side timeout
  would fight the tablet.
- `insecure = 1` disables certificate verification; the API key
  rides in every request body, so prefer a real certificate.
- Errors carry Error::Helper flags (`hostNotDefined`,
  `keyNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::panos`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::panos) has the full table.
