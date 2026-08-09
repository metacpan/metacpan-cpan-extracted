# Usage

Everything goes through the `ereshkigal` CLI, which talks to the
manager socket. The global `-s <path>` option points it at a
non-default socket and works with every subcommand...

```shell
ereshkigal -s /var/run/ereshkigal/socket status
```

Data commands print their result as pretty JSON and exit 0; errors
print the server's error text and exit nonzero, so the CLI scripts
cleanly.

Every subcommand takes `--help` (or `-h`), which explains what it does,
what it will do to the firewall, and the shape of its options —
`ereshkigal help <command>` prints the same thing. Read
`ereshkigal unban --help` and `ereshkigal clear-retries --help` before
reaching for either; both can undo a lot of blocking in one go.

## Raising and quieting the underworlds

```shell
ereshkigal start                 # read the config, daemonize, raise every kur
ereshkigal start --foreground    # same, staying attached (supervisors, testing)
ereshkigal start --config /etc/e.toml
ereshkigal stop                  # stop every kur (tearing down their firewall
                                 # state) and then the manager
```

## A census of who dwells below

```shell
ereshkigal status           # manager uptime, each kur's up/down state and restarts
ereshkigal status --all     # the above plus every kur's full status block
ereshkigal status sshd      # one underworld in detail... uptime, stats, ban counts,
                            # sentence defaults, when the tablets were last copied
ereshkigal banned           # the rolls... every banned IP per kur, with the epoch
                            # each sentence ends (0 = eternal), plus any unbans
                            # still owed to the firewall (see below)
```

## Sending IPs below and calling them back

```shell
ereshkigal ban 1.2.3.4 5.6.7.8        # banish to EVERY kur
ereshkigal ban --kur sshd 1.2.3.4     # just the sshd underworld
ereshkigal ban --kur gate 1.2.3.4     # a gate (fan_out kur) sends it to
                                      # every member underworld
ereshkigal ban --ban-time 3600 1.2.3.4  # a one hour sentence
ereshkigal ban --ban-time 0 1.2.3.4     # eternal residence

ereshkigal unban 1.2.3.4    # each kur is checked and the IP released wherever it
                            # is actually held... the response reports was_banned
                            # per kur
ereshkigal unban --all      # empty every underworld (flush)
```

`ban` and `cidr-ban` take `--kur` to aim at one underworld; `unban`
and `cidr-unban` never needed the option — they ask every kur and
release the address wherever it is actually held. `ereshkigal unban
--kur sshd` is an error, not a narrower unban.

Sentences default per the config layering (request > kur > global >
600 seconds). Banning an IP already below just refreshes its sentence.
When a sentence is served, the kur's sweeper releases the IP on its
own — no cron jobs needed.

## Banishing whole ranges

Whole CIDR ranges can be banished too, once CIDR banning is enabled
(see [configuration](configuration.md)) and the kur's backend can
carry ranges.

```shell
ereshkigal cidr-ban 1.2.3.0/24 10.0.0.0/8   # banish ranges to EVERY kur
ereshkigal cidr-ban --kur sshd 1.2.3.0/24   # just the sshd underworld
ereshkigal cidr-ban --ban-time 3600 1.2.3.0/24  # a one hour sentence

ereshkigal cidr-unban 1.2.3.0/24            # each kur checked, the range
                                            # released wherever it is held
```

Ranges are reduced to their network address before being sent below,
so `1.2.3.4/24` and `1.2.3.0/24` are the same range and either spelling
finds it again for an unban. `cidr-ban` and its sentences behave exactly
like `ban`, sweeper and all.

There is no `cidr-unban --all` — `unban --all` already empties every
underworld, single IPs and ranges alike.

A kur without CIDR banning available for it (not enabled, or a backend
that cannot carry ranges) either answers a plain error or, when its
`cidr_silent_drop` is set, quietly drops the command with `dropped:1`.
That keeps a fan-out across a mix of range-capable and range-incapable
underworlds from being spoiled by the ones that cannot oblige.

## Raising and tearing down underworlds at runtime

```shell
ereshkigal add dns --backend pf --ports 53 --protocols tcp,udp \
    --option kill=1 --ban-time 300     # raise a new kur, now
ereshkigal add edge --backend xdp --interfaces eth0,eth1 \
    --enable-cidr 1                    # array valued options ride --interfaces
ereshkigal add gate --fan-out sshd,smtp  # raise a gate onto existing kurs
                                         # (see configuration.md)
ereshkigal remove dns                  # stop it, tear down its firewall state,
                                       # and deregister it
```

Neither touches the config file — a kur added at runtime vanishes on
the next restart unless you also add it to ereshkigal.toml, and a
removed one returns unless you delete it from there.

## The tablets

```shell
ereshkigal checkpoint          # every kur recopies its ban state CSV now
ereshkigal checkpoint sshd     # just the one
```

Normally you never need this — the tablets are rewritten on every
ban/unban, every `checkpoint` seconds, and at stop — but it is there
for taking a consistent snapshot before backups and the like.

## Unbans the firewall would not take

When a sentence runs out but the backend refuses the unban, the kur
releases the soul from its books and keeps owing the firewall the
removal, retrying with a backoff until it lands. Those debts survive
a restart, and `status` counts them while `banned` names them:

```shell
ereshkigal status --all        # unban_retries per kur, plus how long
                               # the longest owed has been outstanding
ereshkigal banned              # unban_retries names each one, with
                               # times_tried and when it is next due
```

A debt that will never be paid — the rule removed by hand, or a
backend that never had it — is forgiven with:

```shell
ereshkigal clear-retries                        # all of them, every kur
ereshkigal clear-retries sshd                   # just that kur's
ereshkigal clear-retries --ip 1.2.3.4           # just that one, everywhere
ereshkigal clear-retries blocklist --cidr 1.2.3.0/24
```

This only stops the kur asking. Nothing is sent to the firewall, so
anything genuinely still banished there stays banished — check before
forgiving, or you leave a rule nothing is tracking. If the backend is
healthy again, an ordinary `unban` settles the debt honestly instead,
and `re-init` settles the lot.

## Rebuilding a trampled setup

When something outside Ereshkigal drops the rules — a `shorewall
restart`, a `pf -F all`, a firewalld reload, an ipset flushed by hand,
an OpenWrt router rebooted — the kur's book still knows who should be
down there. `re-init` tears the setup down and rebuilds it from that
book:

```shell
ereshkigal re-init             # every kur rebuilds
ereshkigal re-init sshd        # just the one
```

Bans are not enforced during the rebuild. It is brief, but on a busy
edge pick your moment.

Mostly this is a manual convenience: with `self_heal` on (the default)
each kur already checks its setup before every ban and unban and
rebuilds it if it has gone missing. Reach for `re-init` when you want
that now rather than at the next ban, or when `self_heal` is off.

## Communing with Ereshkigal directly

Integrations (log watchers, IDS glue) do not need the CLI. The
manager socket speaks newline-delimited JSON: send one object, read
one back.

```
{"command":"ban","args":{"ips":["1.2.3.4"],"kur":"sshd","ban_time":3600}}
```

If `kur` names a gate (a `fan_out` kur), the ban fans out to its
members — handy for pointing an integration at one stable name and
managing which underworlds it reaches from the config side.

A shell one-liner...

```shell
printf '%s\n' '{"command":"ban","args":{"ips":["1.2.3.4"]}}' \
    | nc -U /var/run/ereshkigal/socket
```

From perl, `Ereshkigal::Client` handles the framing, timeouts, and —
when `enable_auth` is on — the gate challenge, transparently...

```perl
use Ereshkigal::Client;

my $client = Ereshkigal::Client->new(
    socket => '/var/run/ereshkigal/socket',
);

# dies on error responses, returns the result
my $result = $client->call_ok( 'ban',
    { ips => ['1.2.3.4'], kur => 'sshd', ban_time => 3600 } );

# or handle the envelope yourself
my $response = $client->call('status');
if ( $response->{status} eq 'ok' ) { ... }
```

The commands and their args mirror the CLI exactly:

| command         | args                                                    |
|-----------------|----------------------------------------------------------|
| `status`        | none                                                    |
| `status_all`    | none                                                    |
| `status_kur`    | `{"name":...}`                                          |
| `banned`        | none                                                    |
| `ban`           | `{"ips":[...]}`; `kur` and `ban_time` optional          |
| `unban`         | `{"ip":...}`, or `{"all":true}` to flush every kur      |
| `cidr_ban`      | `{"cidrs":[...]}`; `kur` and `ban_time` optional        |
| `cidr_unban`    | `{"cidr":...}`                                          |
| `add_kur`       | `{"name":..., "opts":{...}}`                            |
| `remove_kur`    | `{"name":...}`                                          |
| `checkpoint`    | `{"kur":...}`, or nothing for every kur                 |
| `re_init`       | `{"kur":...}`, or nothing for every kur                 |
| `clear_retries` | `{"kur":..., "ip":...}` or `{"kur":..., "cidr":...}`, all optional |
| `stop`          | none                                                    |

Every reply is either `{"status":"ok","result":...}` or
`{"status":"error","error":"..."}`.

With `enable_auth` on, a raw `nc` integration must complete the auth
challenge itself (see [security](security.md)) — using
Ereshkigal::Client is much less bother.
