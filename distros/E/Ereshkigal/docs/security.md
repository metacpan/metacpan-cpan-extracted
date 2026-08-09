# Security considerations

## Socket permissions are the first gate

The manager socket is created with the configured `socket_mode`
(default 0660) and chowned to `socket_group` (default: the root
user's default group — `wheel` on the BSDs, `root` on Linux). Group
membership on that socket is the base access control: whoever can
write to it can ban and unban. Pick the group accordingly.

The kur sockets are always mode 0600, owned by the user ereshkigal
runs as, and that is deliberately not configurable — read on.

## Neti at the gate: the enable_auth trust model

With `enable_auth = true`, the manager demands that every connection prove its identity
before any command is honored — Neti, the gatekeeper of the underworld, at the
door. Mechanically this is the POE::Component::Server::JSONUnix ownership challenge if the
kernel does not support peer cred on for unix sockets: the server hands the client a
random cookie and a directory; the client writes the cookie to a new file there; the
server stats the file. Since the kernel assigns file ownership from the writing process's
UID, a correctly-written cookie file proves which unix user is on the other
end. `Ereshkigal::Client` (and therefore the CLI) completes this transparently.

What it proves: the unix UID of the connecting process. What it does
not prove: anything about the process beyond that — any process of
that user passes.

Authorization then works from two pairs of lists:

- The top level `authed_users`/`authed_groups` grant **global**
  access — every command, every kur.
- Each kur's own `authed_users`/`authed_groups` **expand** the global
  lists for that kur only. They never replace them.
- A command must be authorized for **every underworld it touches**.
  `ban --kur sshd` touches one; a bare `ban`, `cidr-ban`, `unban`,
  `cidr-unban`, `banned`, `checkpoint`, `re-init`, or `clear-retries`
  touches all of them. Commands about the manager itself — `stop`,
  `add`, `remove`, and the whole-manager views `status`/`status --all`
  — require the global lists.
- UID 0 is always authorized.

Group membership is resolved at request time (the user's primary
group plus each listed group's member list), so user database changes
apply without a restart. Unknown group names simply never match.

**The boundary, stated plainly:** the kur backends do no checking at
all. Enforcement lives entirely in the manager, and that is only
sound because the kur sockets are 0600 — anything that CAN write to a
kur socket walks past Neti entirely. Protecting the kur sockets IS
the enforcement, which is why their mode is hardwired and why you
should never relax the run dir's permissions.

## The dead still speaking: established connections survive plain bans

The big one. Banishing an IP to Kur adds a firewall rule, and on
every real firewall that only bars NEW connections — sessions
established before the ban keep right on talking from the underworld.
An attacker whose brute-force succeeded before the ban landed keeps
their shell.

The packet-filter backends (`pf`, `ipfw`, `iptables`, `nftables`,
`firewalld`, `ufw`, `openwrt`) have a `kill` option that severs
those remaining ties to the world above, and for ban-on-abuse use you
almost certainly want it on where it exists:

```toml
[kur.sshd.options]
kill = 1
```

- **pf** — `kill = 1` runs `pfctl -k` to kill the existing states for
  the banned IP.
- **ipfw** — `kill = 1` uses tcpdrop(8) to tear down its established
  TCP connections.
- **iptables**, **nftables**, **firewalld** — `kill = 1` uses
  conntrack(8) to delete its connection-tracking state.
- **ufw** — `kill` names the tool rather than taking a flag:
  `"ss"` severs the sockets with `ss -K`, `"conntrack"` deletes the
  conntrack state as above.
- **openwrt** — `kill = 1` runs conntrack(8) on the router, which
  OpenWrt does not install by default. Its exit status is ignored, so
  a missing `conntrack` package (or, in remote mode, an ACL that does
  not allow it) is a silent no-op rather than an error — verify it
  rather than assume it.

All of them default to off, matching the underlying tools — so this
is an explicit choice you have to make per kur. Each kur's page under
[kurs/](kurs/) has the exact commands and how they are scoped to what
that kur blocks.

## Running as root

The pf/ipfw/iptables backends need root, so in practice the manager
and its kurs run as root. Consequences:

- `ereshkigal.toml` must be owned by root and not group or
  world-writable. It names `kur_bin`, the program the manager execs,
  so write access to the config is code execution as root.
- The same goes for the `kur_bin` itself and the directories on its path.
- The manager socket's group (`socket_group`) is effectively "may manipulate the
  firewall", with `enable_auth` off it is the full administrative access. Treat membership
  in that group accordingly.
  

## Where the gate leaves its cookies

The gate challenge writes its cookie files into a shared directory —
`auth_temp_dir`, defaulting to the system tmpdir. A sticky-bit `/tmp`
is fine, as the challenge only ever creates fresh files and checks
their ownership, but pointing `auth_temp_dir` at a directory of its
own — root-owned, world-writable, sticky bit set — avoids
pathological tmp setups and tmp-cleaner races on long-idle
connections.

## The tablets name names

The ban state CSVs under `/var/cache/ereshkigal/` list every banned
IP and when each sentence ends, and the retry tablets beside them
(`kur.<name>.retry.csv` and its CIDR sibling) name addresses too. If
revealing who you have banned (or when a ban lapses) matters in your
environment, keep the cache dir readable only by root.

## Ban-time footguns

- `ban_time = 0` is eternal residence — the IP stays banished until
  someone explicitly releases it, across restarts, forever. Make sure
  automation feeding a `ban_time = 0` kur is something you trust.
- `self_heal` (default on) re-establishes the firewall scaffolding
  (the anchor/table/chain/etc) if something outside removed it, before
  each ban or unban. It does not restore individual rules removed
  by hand behind the kur's back — the kur's book and the tablets are
  the source of truth, and `ereshkigal re-init` (or a kur restart)
  will re-ban from them.
- `clear-retries` forgives an unban the firewall would not take, and
  it does **not** touch the firewall. If the rule is in fact still
  there, forgiving it leaves that address blocked indefinitely with
  nothing tracking it — it will not appear in `banned` and no expiry
  will ever release it. Confirm the rule is really gone first, or
  settle the debt honestly with `unban` or `re-init`.
- The one-second sweeper means a sentence can run up to a second
  long. If that matters, your threat model is more interesting than
  this software.
