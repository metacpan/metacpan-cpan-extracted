# Architecture

## The words

The docs speak in the underworld's terms throughout. Each one means
exactly one thing, and this is all of them.

| the word                 | the machinery                                           |
|--------------------------|---------------------------------------------------------|
| the world above          | the CLI, your integrations, anything outside the daemon |
| a kur                    | one underworld: a `kur` process wrapping one backend    |
| a gate                   | a `fan_out` kur, one name opening onto several others   |
| Neti                     | the `enable_auth` identity check on the manager socket  |
| to banish, to send below | to ban                                                  |
| to call back             | to unban                                                |
| a sentence               | a ban's `ban_time`, in seconds                          |
| to cool a sentence       | to let one run out on its own, as the sweeper does      |
| eternal residence        | `ban_time = 0`, a ban that never expires                |
| the sweeper              | the once-a-second loop that releases served sentences   |
| the ban book             | a kur's in-memory record of who is below                |
| a clay tablet            | that record on disk, as CSV                             |
| the rolls                | what `banned` prints                                    |
| a debt                   | an unban the firewall would not take, still owed to it  |

## The shape of it

```
                 /usr/local/etc/ereshkigal.toml
                              |
                              v
  ereshkigal(1) ---- the manager daemon
   App::Cmd CLI       |  socket: /var/run/ereshkigal/socket
                      |  pid:    /var/run/ereshkigal/pid
                      |
                      |  spawns + supervises (POE::Wheel::Run)
          +-----------+-----------+
          v                       v
     kur --name sshd         kur --name smtp
          |                       |
     socket: .../kur/sshd.sock    .../kur/smtp.sock
     pid:    .../kur/sshd.pid     .../kur/smtp.pid
     tablets: /var/cache/ereshkigal/kur.sshd*.csv  kur.smtp*.csv
          |                       |
          v                       v
     Net::Firewall::         Net::Firewall::
     BlockerHelper           BlockerHelper
     (one of 37 backends:    (one of 37 backends:
      pf, iptables, ...)      pf, iptables, ...)
```

The manager reads the config, spawns one `kur` process per hash under
`kur`, and supervises them. Each kur owns exactly one
`Net::Firewall::BlockerHelper` instance (the module that actually
talks to the firewall) and serves it over its own unix socket. The
CLI — and anything else in the world above — speaks only to the
manager's socket; the manager relays each command down to the kurs
that need it and carries their replies back.

## What lives where

| path                                              | what                                             |
|---------------------------------------------------|--------------------------------------------------|
| `/usr/local/etc/ereshkigal.toml`                  | the config                                       |
| `/var/run/ereshkigal/socket`                      | the manager socket (mode 0660, configured group) |
| `/var/run/ereshkigal/pid`                         | the manager PID                                  |
| `/var/run/ereshkigal/kur/<name>.sock`             | a kur's socket (always 0600)                     |
| `/var/run/ereshkigal/kur/<name>.pid`              | a kur's PID                                      |
| `/var/cache/ereshkigal/kur.<name>.csv`            | a kur's ban tablet                               |
| `/var/cache/ereshkigal/kur.<name>.cidr.csv`       | its range ban tablet, when it carries any        |
| `/var/cache/ereshkigal/kur.<name>.retry.csv`      | unbans still owed to the firewall, when any      |
| `/var/cache/ereshkigal/kur.<name>.cidr.retry.csv` | the range equivalent                             |

The run and cache base dirs are configurable; the layout under them is
not.

## Supervision

Kurs are spawned via `POE::Wheel::Run` in foreground mode so the
manager can watch them. An underworld that collapses is raised again
on a doubling backoff — 1s, 2s, 4s... capped at 60s, reset after a
minute of healthy uptime — and on the way back up it restores its
residents from the tablets (see below). The `status` command shows
the restart count per kur.

## The protocol

Both the manager socket and the kur sockets speak the
newline-delimited JSON of
[POE::Component::Server::JSONUnix](https://metacpan.org/pod/POE::Component::Server::JSONUnix):
one JSON object per line in each direction.

```
-> {"command":"ban","args":{"ips":["1.2.3.4"],"kur":"sshd","ban_time":3600}}
<- {"status":"ok","result":{"kurs":{"sshd":{"ips":{"1.2.3.4":{"status":"ok"}}}}}}

-> {"command":"status_kur","args":{"name":"nope"}}
<- {"status":"error","error":"No such kur instance, \"nope\""}
```

The manager commands are `status`, `status_all`, `status_kur`,
`banned`, `ban`, `unban`, `cidr_ban`, `cidr_unban`, `add_kur`,
`remove_kur`, `checkpoint`, `re_init`, `clear_retries`, and `stop`.
The kur commands are `ban`, `unban`, `cidr_ban`, `cidr_unban`,
`banned`, `status`, `flush`, `re_init`, `checkpoint`,
`clear_retries`, and `stop`. The kur sockets are 0600 and only
Ereshkigal is expected to speak to them. See [usage](usage.md) for
driving the socket from your own integrations.

## Sentences and the sweeper

Every ban carries a term, the resolved `ban_time`; `0` means eternal
residence. Each kur runs a sweeper, a once-a-second check
that releases any soul whose sentence has been served: the IP is
unbanned from the backend, dropped from the books, and counted in the
`expired` stat (`cidr_expired` for ranges). Re-banning an IP that is
already below just refreshes its sentence.

Should the backend refuse the release — a remote API briefly
unreachable, say — the soul still leaves the books, but the firewall
side is remembered in a retry list rather than left banished forever.
The sweeper retries it, backing off by doubling from one second to a
cap of sixty, until the backend takes it. Nothing else will clear it
while the backend is still refusing: a hand `unban` goes to that same
backend and fails the same way, leaving the retry pending.

An entry leaves the list only once its rule is genuinely gone: the
retry lands, or a `flush`/`re_init` succeeds. It also leaves if the
address is wanted below again — a re-ban cancels the debt without
touching the backend, the rule never having left in the first place.
The list is written to its own tablet, so a debt survives a restart
with its count and backoff intact; restarting settles nothing the
firewall is owed.

A debt that can never be paid — the rule removed by hand, or a
backend that never carried it — would otherwise be retried forever at
the sixty second cap. `status` counts what is owed and how long the
longest has been outstanding, `banned` names each one, and
`clear-retries` forgives them, individually or in bulk. Forgiving one
tells the kur to stop asking and nothing more; the firewall is not
touched, so a rule that really is still there is left with nothing
tracking it.

## The clay tablets

Sumer's tablets were mostly accounts, and so are these — who is held,
what is owed, and since when.

Each kur checkpoints its banishments to
`/var/cache/ereshkigal/kur.<name>.csv`, a CSV of
`ip,time,ban_time_left` — who is below, when the row was written, and
how many seconds of their sentence remained at that moment (`0` for
eternal). Range bans, when a kur carries any, keep to a sibling
`kur.<name>.cidr.csv` of the same shape, so the single IP tablet is
untouched by them.

Unbans still owed to the firewall keep their own pair, `kur.<name>.retry.csv` and
`kur.<name>.cidr.retry.csv`, of `ip,first_tried,last_tried,times_tried,next_try,delay` —
what is owed, since when, how many times it has been asked for, when it is next due, and
where the backoff had got to. These carry absolute times rather than a remaining figure,
as a debt has no sentence to re-anchor and a `next_try` left in the past means it is due
at once. A kur owing nothing has no retry tablet at all, not even a header-only one.

A tablet is re-written:

- on every arrival and departure (ban/unban/flush/expiry)
- every `checkpoint` seconds (default 60) even without changes, so
  the time-left figures never go stale
- at `stop`, right before the firewall teardown
- on demand via the `checkpoint` command

The retry tablets follow the same triggers, plus whenever a debt is
taken on, retried, paid, or forgiven — and they are emptied once more
after a successful teardown at `stop`, since tearing down takes any
rule the kur failed to remove with it.

Every write is atomic: the new tablet is written beside the old one
and renamed over it, so a reader never sees a half-written file, and a
write that fails leaves the last good tablet in place.

On the way back up a tablet is read row by row, and anything that does
not parse — a bad field count, a non-numeric time, or an address that
is not a valid IP or range — is logged and skipped rather than
restored. Addresses are normalized before being booked, exactly as a
live ban is, so the ban book only ever holds canonical spellings and
every restored ban can be named by a later `unban`. A row whose
sentence ran out while the kur was down is unbanned rather than
re-banned, in case the firewall still carries the rule.
