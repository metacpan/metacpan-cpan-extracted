# Multi-Raider Hall — Example Setup

A minimal but complete hall with three raiders, a cron job, and an ACP
port. Drop-in example — copy the files, change the API keys, run.

## What's in this example

- **Björn** — the git/release guy. OpenAI, `perl-hacker` + `git-guru`
  packs, caveman persona. Handles branch work, release notes, CI
  babysitting.
- **Lagertha** — the reviewer. Anthropic, `polite` persona, slower
  model. Reads diffs, flags issues, refuses when something's wrong.
- **Freya** — the scheduler's puppet. Singleton slot (`1freya`) so
  overlapping cron runs queue instead of stampeding. Posts a daily
  summary at 09:00.
- **Cron** — one scheduled job that spawns Freya every morning.
- **ACP** — port 38421 open on 127.0.0.1 so Zed (or `raider acp
  connect`) can treat the hall as a remote agent.

## Files

```
examples/multi-raider-hall/
├── README.md                  # this file
├── .raider-hall.yml           # hall config
└── .raider.md                 # shared persona note (optional)
```

Nothing else: at runtime the hall owns `.raider-hall/` (logs, state and,
with this config, the lib target its raiders install into) and keeps the
session journals in `.raider/sessions/`. Removing `.raider-hall/` between
runs drops the logs, the waiting queues, the session bindings and the
installed modules; the journals stay.

## Quick start

```bash
# 1. Copy the example somewhere writable
cp -r examples/multi-raider-hall ~/my-village
cd ~/my-village

# 2. Set the keys you need (raiders pick theirs from env)
export OPENAI_API_KEY=sk-...
export ANTHROPIC_API_KEY=sk-ant-...

# 3. Run the hall (foreground — omit --daemon to see the logs)
raider hall start

# 4. In another terminal:
raider hall ps
raider hall spawn bjorn "summarise the last 10 commits on main"
raider hall attach <id-from-spawn>
raider hall logs <id>
```

The first spawn also works against singletons:

```bash
raider hall spawn 1freya "report yesterday's merged PRs"
raider hall spawn 1freya "and the ones that got closed without merge"
# ↑ this one queues on Freya's slot and runs after the first finishes
```

## Talking to the hall over ACP

The hall exposes ACP on 127.0.0.1:38421. From the same machine:

```bash
# Handshake
raider acp ping 127.0.0.1:38421

# One-shot prompt to Björn
raider acp prompt 127.0.0.1:38421 --raider bjorn \
    "open the current git status and describe what's happening"

# Interactive REPL against Lagertha
raider acp connect 127.0.0.1:38421 --raider lagertha
acp> review the diff between main and the current branch
acp> /cancel                  # sends session/cancel
acp> /quit
```

Any client that speaks ACP over TCP can use the port the same way. An
editor that starts its agent as a local command over stdio (Zed does)
needs the stdio ACP server, which is not there yet (ADR 0010).

## Adding a raider

```bash
raider hall add-raider ivar --engine openai --persona teacher \
    --pack testing-fu --model gpt-4o-mini
```

This appends an entry to `.raider-hall.yml`. A running hall reads the
file once at start, so restart it (`raider hall stop`, then
`raider hall start`) before `raider hall spawn ivar "…"` uses the new
entry.

## Turning on Telegram

Uncomment the `telegram:` block in `.raider-hall.yml`, drop in your
bot token + allowlist, and restart the hall. `allowlist` lists the
Telegram user ids allowed to talk to the bot — empty means nobody;
group chats additionally need their chat id in `allowed_chats`.
Incoming messages emit `telegram.in` events on the hall bus, rejected
ones `telegram.rejected`. The raider spawned per
`routing:` mapping gets the message as its mission and can call the
`telegram_reply` MCP tool to answer back (wired automatically when the
child is spawned under a hall — `RAIDER_HALL_SOCKET` is the trigger).

## systemd

Once you're happy with the setup, install it as a systemd user unit so
it starts on login:

```bash
raider hall install --acp-port 38421
systemctl --user daemon-reload
systemctl --user enable --now raider-hall
journalctl --user -u raider-hall -f     # live logs
```

Inside a container? Add `--docker --image raudssus/raider:latest`; the
unit is dropped in `.raider-hall/systemd/raider-hall.service` (which
surfaces on the host via the bind-mount) and the output tells you to
`cp` it into `~/.config/systemd/user/`.

## Tuning knobs

A few things worth knowing:

- `longhouse: true` adds `longhouse/lib` of the hall to every
  raider's `PERL5LIB`.
- `coalesce: true` on a cron entry drops a run if the previous one is
  still running or waiting (the hall emits `cron.coalesced`). Default
  (off) queues the run behind the previous one, on the job's `cron:ID`
  binding — every occurrence runs, louder for pile-ups.
- `preferred_lib_target` in `.raider-hall.yml` is the `local::lib`
  every raider of the hall installs into with `perl_cpanm` (default
  `.raider/lib`); its `lib/perl5` is on each raider's `PERL5LIB`.
- `persona:` on a raider is a pack, passed as one more `--pack`.
- Event-bus subscribers (anyone who opens the unix socket and sends
  `{"type":"subscribe"}`) can filter by type prefix — `"raider."`
  gives you all raider lifecycle events without the cron/telegram
  noise.

## Next steps

- `raider hall spawn 1bjorn "…"` with the same name multiple times to
  see the queue in action (each mission runs after the previous).
- `raider acp connect …` while a cron job is running to see the event
  stream carry the scheduled raid's updates.
- Hook a second hall on another machine — ACP is TCP, so it's exactly
  the same wiring.
