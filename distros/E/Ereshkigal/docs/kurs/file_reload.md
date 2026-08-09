# file_reload — render bans to a file, run a reload hook

The generic backend for anything that reads a list of IPs from a
file and needs to be told when it changes: web servers, DNS RPZ
zones, hand rolled ipset restore files, Postfix access maps,
External Dynamic Lists served over HTTP. One backend, many recipes.

```toml
[kur.web]
backend = "file_reload"

[kur.web.options]
file   = "/etc/nginx/blocklist.conf"
format = "deny %%%BAN%%%;"
reload = "nginx -s reload"
blank_reload_error = 0
```

## How it works

On every change the **entire file** is re-rendered from the ban
book — header, one formatted line per banned IP (sorted), footer —
and written out, then the optional `reload` command runs. The file
is never parsed back; this kur is the sole author of its contents,
which makes every operation idempotent and leaves no partial state.

## Requirements

- Write access to `file`, and whatever the `reload` command needs.
  Nothing else — no firewall, no particular platform.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**;
  encode scoping into what consumes the file.
- `enable_cidr` — supported; banned ranges render into the file
  alongside the single IPs, so make sure the consumer can take a
  CIDR where it takes an IP.
- `prefix` — unused.

## Options

| option               | default      | what                                                          |
|----------------------|--------------|----------------------------------------------------------------|
| `file`               | *(required)* | path the ban list is rendered to                              |
| `format`             | `%%%BAN%%%`  | per-IP line template; `%%%BAN%%%` → the IP                    |
| `header`             | `""`         | emitted at the top, before the IP lines                       |
| `footer`             | `""`         | emitted at the bottom, after them                             |
| `reload`             | *(unset)*    | command run after each write; unset = just write the file     |
| `check`              | *(unset)*    | health probe command, exit 0 = healthy; unset = file-exists   |
| `remove_on_teardown` | `1`          | teardown unlinks the file; `0` = render it empty and leave it |
| `blank_reload_error` | `1`          | a reload producing no output is a failure even on exit 0; `0` for hooks silent on success |

## What each operation does

| operation  | effect                                                              |
|------------|----------------------------------------------------------------------|
| `init`     | render (empty book) + write + reload                                |
| `ban`      | render including the new IP + write + reload                        |
| `unban`    | render without it + write + reload                                  |
| `list`     | no file access — the kur's own ban book                             |
| `check`    | the `check` command, or bare file-exists if unset                   |
| `flush`    | render with an emptied book + write + reload                        |
| `re_init`  | re-render + write + reload from the current book                    |
| `teardown` | unlink + reload (or render empty, per `remove_on_teardown`); ban book kept |

A failing reload command fails the operation that triggered it, so a
broken hook surfaces as ban/unban errors rather than silently
leaving the consumer stale. By default a reload that produces **no
output at all** is also treated as a failure, even with a zero exit
(`blank_reload_error`) — most reload hooks that are silent are silent
because they never ran. For hooks genuinely quiet on success
(`nginx -s reload`, `postmap`, `systemctl reload ...`), set
`blank_reload_error = 0` as the recipes below do.

## Recipes

**nginx** (with `include /etc/nginx/blocklist.conf;` inside a
`server`/`http` block using `deny`):

```toml
file   = "/etc/nginx/blocklist.conf"
format = "deny %%%BAN%%%;"
reload = "nginx -s reload"
blank_reload_error = 0
```

**Postfix client access map:**

```toml
file   = "/usr/local/etc/postfix/client_access"
format = "%%%BAN%%% REJECT"
reload = "postmap /usr/local/etc/postfix/client_access"
blank_reload_error = 0
```

**ipset via restore file** (when you want the admin to own the
iptables rules and the kur only to feed a set):

```toml
file   = "/var/db/kur/web.ipset"
header = "flush kur_web"
format = "add kur_web %%%BAN%%%"
reload = "ipset restore -exist -f /var/db/kur/web.ipset"
blank_reload_error = 0
```

**External Dynamic List** for PAN-OS/FortiGate to poll — bare IPs,
served by your web server, no reload at all:

```toml
file   = "/usr/local/www/edl/banned.txt"
```

## self_heal

With no `check` command the probe is bare file-exists, so `self_heal`
notices the file being deleted and re-renders it on the next ban or
unban — but nothing more. A consumer that stopped reading the file, or
a reload hook that has been silently failing, looks perfectly healthy.

A `check` command closes that: point it at the consumer rather than
the file (`nginx -t`, a `postmap -q` lookup, `ipset list <name>`) and a
failure triggers a re-render plus reload on the next mutation.

## Gotchas

- `header`/`footer` are emitted as their own lines; include any
  further newlines yourself if a format wants blank separation.
- Reload runs on **every** mutation — a ban storm means a reload
  storm. Prefer cheap reloads (`nginx -s reload`, `postmap`) or no
  reload (EDL polling) for high-churn kurs.
- The write is direct, not tmp+rename; a crash mid-write can leave a
  truncated file until the next mutation rewrites it. Consumers that
  choke on partial files (rare for line-based lists) should check
  syntax in their own reload step.
- Without a real `check` command, self_heal only notices the file
  vanishing, not a consumer that stopped consuming.
- Errors carry Error::Helper flags (`fileNotDefined`,
  `fileWriteFailed`, …) — [`Net::Firewall::BlockerHelper::backends::file_reload`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::file_reload) has the full
  table.
