# nsupdate — a DNS blocklist (RBL)

Maintains an RBL-style DNS blocklist by using `nsupdate(1)` to add
and remove TXT records under a BIND zone, authenticated with a TSIG
key — the equivalent of the fail2ban `nsupdate` action. Nothing is
blocked on any host; consumers of the RBL (MTAs, milters, other
tooling querying the zone) do their own refusing.

Banning `1.2.3.4` creates:

```
4.3.2.1.rbl.example.com. 60 IN TXT "banned"
```

— the classic reversed-octet RBL layout.

```toml
[kur.rbl]
backend = "nsupdate"

[kur.rbl.options]
domain  = "rbl.example.com"
keyfile = "/usr/local/etc/namedb/rbl.key"
```

## BIND-side setup — required before use

Generate a TSIG key and let it update the zone:

```shell
tsig-keygen -a hmac-sha256 kur-rbl > /usr/local/etc/namedb/rbl.key
chmod 400 /usr/local/etc/namedb/rbl.key
```

```
include "/usr/local/etc/namedb/rbl.key";

zone "rbl.example.com" {
    type master;
    file "dynamic/rbl.example.com.zone";
    update-policy { grant kur-rbl subdomain rbl.example.com. TXT; };
};
```

The `update-policy` grant above is scoped to TXT records under the
zone — all this backend ever writes. A plain
`allow-update { key kur-rbl; };` also works but grants more. The zone
file must be writable by named (dynamic zones usually live in a
directory of their own).

## Requirements

- `nsupdate` in the `PATH` of the kur process (BIND's, or a
  compatible one via the `nsupdate` option).
- The TSIG keyfile readable by the kur process; its existence is
  verified at init.
- DNS-update reachability to the zone's master (nsupdate speaks the
  DNS update protocol, not HTTP).

## Settings

- `ports` / `protocols` — **not supported**; specifying either is a
  fatal error at kur startup.
- **IPv4 only**, matching the fail2ban action — banning an IPv6 IP is
  an error (`ipv6NotSupported`); the reversed-octet name only makes
  sense for IPv4. Keep IPv6 sources pointed at other kurs.
- `enable_cidr` — this backend can **not** carry ranges (the
  reversed-octet owner name cannot express a prefix at all); a kur
  with it set logs a warning at startup and answers range commands
  per `cidr_silent_drop`.
- `prefix` — accepted, unused.

## Options

| option     | default      | what                                                            |
|------------|--------------|------------------------------------------------------------------|
| `domain`   | *(required)* | domain the records live under; `/^[a-zA-Z0-9.\-]+$/`           |
| `keyfile`  | *(required)* | full path to the TSIG key file; no whitespace or single quotes |
| `ttl`      | `60`         | TTL in seconds for created TXT records                          |
| `rdata`    | `banned`     | TXT record data; `/^[a-zA-Z0-9 .,:_\-]+$/`                     |
| `nsupdate` | `nsupdate`   | the nsupdate command to run                                     |

`rdata` is what RBL consumers see when they query; some tooling keys
off the text, so it is settable. Keep `ttl` low — it bounds how long
a lifted ban keeps resolving from caches.

## What each operation runs

Everything is `printf '<statements>' | nsupdate -k '<keyfile>'`, with
the record name built by reversing the IP's octets onto the domain:

| operation  | statements fed to nsupdate                                                     |
|------------|------------------------------------------------------------------------------------|
| `init`     | none — just verifies the keyfile exists as a regular file                      |
| `ban`      | `prereq nxrrset <rev>.<domain> TXT` ⏎ `update add <rev>.<domain> <ttl> IN TXT "<rdata>"` ⏎ `send` |
| `unban`    | `update delete <rev>.<domain> TXT` ⏎ `send`                                    |
| `list`     | no command — the kur's own ban book                                            |
| `check`    | nothing — always reports healthy                                               |
| `flush`    | the delete statements per banned IP                                            |
| `re_init`  | teardown (best effort), init, re-add every banned IP                           |
| `teardown` | the delete statements per banned IP (ban book kept for re_init)                |

The `prereq nxrrset` on ban makes the add conditional on the record
not already existing — a replayed ban (tablet reload after restart)
fails the prereq rather than stacking records. DNS deletes are
idempotent, so unbanning an already-gone record succeeds quietly.

## self_heal and remote drift

`check` has nothing it can probe cheaply and **always reports
healthy**, so `self_heal` is a no-op for this backend. A record
deleted on the server by hand stays gone until `re_init`; a
hand-added record is invisible to the kur. If the master is
unreachable, bans fail at ban time (nsupdate exits non-zero after its
own retry/timeout behavior — the kur imposes no timeout of its own).

## Gotchas

- The kur bans and cools sentences whether or not anything consults
  the RBL — enforcement is entirely on the consumers' side.
- Multiple kurs (or fail2ban jails) can share a zone as long as they
  manage disjoint IPs; they all write the same record shape. Two
  writers for the *same* IP will fight over one TXT record.
- Zone transfers/replication mean secondaries lag by NOTIFY/refresh;
  consumers querying a secondary see bans slightly late.
- Errors carry Error::Helper flags (`optionInvalid`,
  `ipv6NotSupported`, …) — [`Net::Firewall::BlockerHelper::backends::nsupdate`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::nsupdate) has the full
  table.
