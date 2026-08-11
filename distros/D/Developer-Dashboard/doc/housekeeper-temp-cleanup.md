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

## How Candidates Are Found

The temp-file candidates are found by **listing the system temp directory** and
keeping the entries whose names carry a dashboard-owned prefix
(`developer-dashboard-ajax-` or `dashboard-result-`).

That listing is the containment boundary, and it is a boundary by construction:
a candidate is always an entry of the temp directory, so no candidate can name a
path outside it, whatever characters the temp path itself contains.

A shell-glob pattern built from the temp path is deliberately **not** used.
Perl's built-in `glob` is `csh_glob`: it splits its argument on whitespace and
honours backslash escapes. A temp path shaped like an ordinary Windows one --
`C:\Users\John Smith\AppData\Local\Temp`, or any account whose name contains a
space -- therefore produced fragments rather than the intended pattern, with two
consequences:

- the genuine temp files were never matched, so the cleanup reclaimed nothing
  while still reporting success; and
- the trailing fragment was a *relative* pattern, so it resolved against the
  housekeeper process's working directory and offered unrelated files up for
  deletion.

Two failure modes are also distinguished on purpose, because "could not look"
must never be reported as "there was nothing there":

- a temp directory that is **absent** yields an empty scan; but
- a temp directory that **exists and cannot be read** raises an error rather
  than quietly reporting an empty scan.

The `scanned` counters reported by a run therefore count exactly the entries
actually considered in the temp directory, so a zero only ever means the
directory genuinely held nothing.

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
