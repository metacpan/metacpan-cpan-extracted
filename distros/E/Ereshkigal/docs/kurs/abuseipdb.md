# abuseipdb — report the banished

Not a blocker at all: reports banned IPs to
[AbuseIPDB](https://www.abuseipdb.com/) via its v2 REST API, the
equivalent of the fail2ban abuseipdb action. A ban files a report;
nothing is ever blocked by this kur itself.

Its natural home is inside a [gate](gate.md), next to a real
blocker — one command through the gate blocks locally *and* reports
upstream:

```toml
[kur.sshd]
backend   = "pf"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.sshd.options]
kill = 1

[kur.sshd-report]
backend = "abuseipdb"

[kur.sshd-report.options]
key        = "your-abuseipdb-api-key"
categories = [ "18", "22" ]
comment    = "ssh brute force"

[kur.baphomet]
fan_out = [ "sshd", "sshd-report" ]
```

## The reporting semantics — read this part

Reports cannot be withdrawn, so this backend's lifecycle is
deliberately lopsided:

- **ban** = report. Reporting an IP AbuseIPDB has seen from you
  within its rate-limit window (15 minutes at the time of writing)
  answers HTTP 429, which the kur treats as *already reported*, not
  an error.
- **unban / flush / teardown** = internal bookkeeping only. No API
  calls; a sentence ending changes nothing at AbuseIPDB.
- **re_init** re-inits but re-reports nothing — there is no remote
  state to restore.
- A kur **restart** replays the tablet through ban, so
  still-sentenced IPs get re-reported (or 429-swallowed if recent).
  With long sentences that means duplicate reports across restarts;
  AbuseIPDB treats a re-report after the window as a fresh report,
  which for a still-banned, still-abusive IP is usually fine — but
  know it happens.

## AbuseIPDB-side setup

An account and an API key (webmaster/user tier is fine). Free tier
allows 1,000 reports/day — pace your ban sources accordingly.

## Requirements

- `LWP::UserAgent` and `LWP::Protocol::https` (the API is https
  only) — loaded only at runtime.

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup.
- `enable_cidr` — this backend can **not** carry ranges (reports are
  per IP); a kur with it set logs a warning at startup and answers
  range commands per `cidr_silent_drop`.
- `prefix` — only appears in the default comment.
- Both IPv4 and IPv6 report fine.

## Options

| option       | default                     | what                                                    |
|--------------|-----------------------------|----------------------------------------------------------|
| `key`        | *(required)*                | AbuseIPDB API key                                       |
| `categories` | `18`                        | category numbers, array or comma string — see below     |
| `comment`    | `banned by <prefix>_<name>` | report comment; `%%%BAN%%%` → the IP; blank = none      |
| `timeout`    | `30`                        | HTTP timeout in seconds                                 |

Categories are AbuseIPDB's numeric taxonomy
(<https://www.abuseipdb.com/categories>) — 18 is Brute-Force, 22
SSH, 14 Port Scan, 21 Web App Attack. Pick per kur to match what the
ban source actually saw.

**Comments are public** on the reported IP's AbuseIPDB page. Do not
template in log lines, usernames, or anything else you would not
publish.

## What each operation does

| operation  | API traffic                                                              |
|------------|-------------------------------------------------------------------------------|
| `init`     | `GET /api/v2/check?ipAddress=127.0.0.2&maxAgeInDays=1` — verifies the key   |
| `ban`      | `POST /api/v2/report` with `ip`, `categories`, `comment` (429 tolerated)     |
| `unban`    | nothing                                                                      |
| `list`     | no API call — the kur's own ban book                                         |
| `check`    | same probe as init                                                           |
| `flush`    | nothing (ban book cleared)                                                   |
| `re_init`  | teardown (no-op) + init                                                      |
| `teardown` | nothing (ban book kept)                                                      |

## self_heal

There is nothing on the AbuseIPDB side to establish, so there is
nothing to repair — the re_init after a failed `check` just probes
again. `check` re-runs init's credential probe (catching a revoked or
expired key), so a kur stuck failing it has a credentials problem,
not a firewall one.

## Gotchas

- Because unban costs no API call, `ban_time` here only governs the
  kur's own book (and thus which IPs a restart re-reports). Matching
  the blocking kur's `ban_time` keeps gate members' books aligned.
- The already-banned check means one report per IP per sentence —
  the kur will not spam reports while an IP sits in the book, even
  if the ban source keeps firing (a refreshed sentence is not a new
  report).
- `check` costs one API call per self_heal probe; with `self_heal`
  on (the default) that is one extra call per ban. Harmless against
  the daily quota unless you are very chatty — set `self_heal = 0`
  on this kur if it matters, there is nothing to heal anyway.
- Errors carry Error::Helper flags (`keyNotDefined`,
  `categoriesInvalid`, …) — [`Net::Firewall::BlockerHelper::backends::abuseipdb`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::abuseipdb) has the full
  table.
