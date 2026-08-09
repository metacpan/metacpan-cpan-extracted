# dummy — an underworld of pure imagination

Remembers what it was told and does nothing else. No commands are
run, no rules are created; bans live in the kur process's memory (and
its clay tablet) and nowhere else. For testing Ereshkigal itself,
protocol glue, and integrations without touching a firewall.

```toml
[kur.pretend]
backend = "dummy"
```

## Requirements

None. No binaries, no privileges, no firewall. This is the one
backend that works as an unprivileged user, provided `run_base_dir`
and `cache_base_dir` point somewhere that user can write.

## Settings

- `ports` / `protocols` — accepted and validated (ports must be
  1–65535 or `getservbyname`-resolvable names, protocols must resolve
  via `getprotobyname` — the same validation every backend gets),
  then ignored. So it stays a drop-in stand-in for a real backend: a
  config that validates against dummy will validate against iptables
  or pf.
- `enable_cidr` — supported; range bans are remembered just like
  single IPs, so CIDR flows can be tested here too.
- `prefix` — accepted, unused.
- `options` — takes none; any keys passed are ignored, though the
  value must still be a hash (anything else is a fatal
  `optionsNotHash`).

## What each operation does

| operation  | effect                                                        |
|------------|----------------------------------------------------------------|
| `init`     | marks the backend inited; nothing else                        |
| `ban`      | adds the IP to the in-memory ban hash                         |
| `unban`    | removes the IP from the hash                                  |
| `list`     | returns the hash keys                                         |
| `check`    | always reports healthy — it cannot fail                       |
| `flush`    | clears the hash                                               |
| `re_init`  | clears and re-marks inited                                    |
| `teardown` | clears the inited flag                                        |

IPv6 addresses are lowercased on the way in, matching every other
backend, so `2001:DB8::1` and `2001:db8::1` are one ban.

## self_heal

Never fires. `check` cannot fail, so the probe before each ban/unban
always passes and there is never a re_init — which is the point: a
dummy kur costs the same one no-op probe a real one costs, without
any of the healing being exercised. If you are testing self_heal
itself, you want a real backend or the `shell` one.

## Behavior worth knowing

- The kur-level machinery all still works for real: sentences expire
  via the sweeper, the tablet is written and reloaded across
  restarts, `banned`/`status`/`flush`/`re_init` behave exactly as
  they would over a real firewall — the whole manager/kur/client
  stack, exercised with zero risk.
- It is also handy as a gate member while wiring up an integration:
  point the integration at a gate whose members are dummies, watch
  `banned` to confirm the right IPs arrive, then swap the members'
  backends for real ones.

## Errors

Only the shared validation errors apply (bad port, bad protocol, bad
prefix/name, options not a hash); the operations themselves cannot
fail. See [`Net::Firewall::BlockerHelper::backends::dummy`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::dummy) for
the flag list.
