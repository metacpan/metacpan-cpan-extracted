# Housekeeper Temp Cleanup

## Purpose

Developer Dashboard now ships a built-in `housekeeper` collector and a matching
`dashboard housekeeper` command.

The cleanup target is the dashboard-owned shared temp area:

- `/tmp/<user>/developer-dashboard/state/<hash>/...`
- `/tmp/developer-dashboard-ajax-*`
- `/tmp/dashboard-result-*`

## What It Removes

- stale hashed runtime state roots whose recorded runtime root no longer exists
- stale hashed runtime state roots without live managed collector pid files
- stale oversized Ajax payload temp files created for saved Ajax requests
- stale runtime result temp files created for file-backed RESULT and LAST_RESULT payloads

## What It Keeps

- the active runtime state roots for the current DD-OOP-LAYERS chain
- state roots that still have live managed collector pid files
- newer temp files and directories that have not yet aged past the retention window

## Runtime Surface

Run it directly:

```bash
dashboard housekeeper
```

Run it through the managed collector surface:

```bash
dashboard collector run housekeeper
```

The built-in collector runs every `900` seconds by default. A user or project
config can override that default by defining another collector named
`housekeeper`.
