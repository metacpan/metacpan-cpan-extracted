# Architecture

Developer Dashboard is a local home for development work.

It is designed to give a developer one familiar place to keep pages, helpers,
status checks, prompt indicators, path shortcuts, and local automation close to
the code they work on every day.

Without it, the browser, shell prompt, collector scripts, Docker Compose
wrappers, and file-navigation shortcuts often drift into separate tools with
separate rules. The architecture here is meant to keep those surfaces tied to
one runtime so the browser, prompt, and CLI can behave like one developer home
instead of a loose pile of utilities.

## Core Services

- `Developer::Dashboard::PathRegistry`
  Resolves logical directories such as runtime, cache, logs, dashboards, collectors, and indicators.

- `Developer::Dashboard::FileRegistry`
  Resolves logical files such as config and logs on top of the path registry.

- `Developer::Dashboard::JSON`
  Centralizes JSON encoding and decoding through `JSON::XS`.

- `Capture::Tiny`
  Captures external command output for collectors, updater scripts, and smoke-test command execution.

- `Developer::Dashboard::ActionRunner`
  Executes built-in actions and trusted command actions with cwd, env, timeout, background support, and encoded action payload transport.

- `Developer::Dashboard::Collector`
  Stores collector output atomically as file-backed state.

- `Developer::Dashboard::CollectorRunner`
  Runs configured collector jobs once or in loops, persists outputs, records loop metadata, supports timeout/env and cron-style schedules, validates managed background processes by pid plus process title, and materializes TT-backed collector indicator icons from collector stdout JSON.

- `Developer::Dashboard::RuntimeManager`
  Starts the web service in the background, stops or restarts both web and collectors, and falls back to `pkill` plus process scanning instead of trusting pid files alone.

- `Developer::Dashboard::IndicatorStore`
  Stores prompt/dashboard indicators as file-backed state and can refresh generic built-in indicators.

- `Developer::Dashboard::Auth`
  Manages helper users and enforces the exact-loopback trust tier so local
  admin access on `127.0.0.1` stays friction-free while shared access still
  requires helper authentication.

- `Developer::Dashboard::SessionStore`
  Stores helper browser sessions as file-backed state.

- `Developer::Dashboard::Prompt`
  Renders `PS1` output from cached indicator state in compact or extended mode,
  with optional color and stale-state marking, so prompt redraws stay cheap and
  do not rerun expensive health checks.

- `dashboard`
  Canonical command-line entrypoint for runtime, page, collector, prompt, and user CLI extension operations.
  It is the only public executable the distribution installs into the global
  PATH, so generic helper names stay inside the dashboard runtime instead of
  leaking into the wider shell ecosystem.

- `dashboard of` / `dashboard open-file`
- open-file commands keep the interactive numbered chooser workflow for
  multi-match searches, support comma and range selections or blank-for-all,
  and fall back to `vim` when no editor is configured
  Resolve direct files, `file:line` references, Perl module names, Java class names, and recursive file-pattern matches below a resolved scope, then print or exec the configured editor.
  Scoped searches rank exact helper/script names ahead of broader substring matches, so `dashboard of . jq` prefers `jq` and `jq.js` before `jquery.js`.

- `dashboard jq` / `dashboard yq` / `dashboard tomq` / `dashboard propq` / `dashboard iniq` / `dashboard csvq` / `dashboard xmlq`
  Parse JSON, YAML, TOML, Java properties, INI, CSV, and XML input and optionally traverse a dotted path before printing a scalar or canonical JSON. File-path and query-path argument order is interchangeable, and `$d` selects the full parsed document.

- private `~/.developer-dashboard/cli/dd/jq` / `yq` / `tomq` / `propq` / `iniq` / `csvq` / `xmlq` / `of` / `open-file` / `ticket`
  Are staged into the dashboard runtime and used for private helper dispatch without installing generic command names into the system PATH.

- no public standalone `of`, `open-file`, or `ticket` executable
  The distribution keeps file-opening and ticket-session behaviour behind
  `dashboard` subcommands plus private runtime helpers instead of shipping more
  generic top-level binaries into the CPAN-installed PATH.

- `Developer::Dashboard::PageDocument`
  Canonical page model for saved, transient, and older bookmark pages.

- `Developer::Dashboard::PageStore`
  Persists saved pages and encodes/decodes transient page payloads.

- `Developer::Dashboard::PageResolver`
  Resolves saved pages and generated provider pages into one page-document model.

- `Developer::Dashboard::PageRuntime`
  Applies Template Toolkit rendering for `HTML`, then executes older `CODE*` sections inside one throwaway sandpit package per page run and captures their output for page rendering.

- `Developer::Dashboard::Web::App`
  Implements the browser service layer for page rendering, page actions, helper
  login/logout, and older compatibility flows behind the HTTP route table.

- `Developer::Dashboard::Web::DancerApp`
  Owns the explicit Dancer2 HTTP route table, normalizes requests, enforces
  protected-route authorization, and forwards work into the web-app service.

- `Developer::Dashboard::Web::Server`
  PSGI web server wrapper for the Dancer2 app, defaulting to bind `0.0.0.0:7890`.

- `Developer::Dashboard::UpdateManager`
  Runs ordered update scripts, stops running collectors, and restarts them afterward.

- `Developer::Dashboard::DockerCompose`
  Resolves compose base files plus explicit project, service, addon, and mode overlays, env injection, and the final `docker compose` command.
  It also discovers isolated service folders under the dashboard docker config root and exports `DDDC` for compose-time path references inside YAML.

## Runtime Model

The architecture follows a producer/consumer pattern:

- collectors prepare data in the background
- indicators and pages read cached state
- prompt rendering reads cached state only
- update scripts bootstrap runtime state and shell integration

Collector-backed indicator config has one extra split when `indicator.icon`
uses Template Toolkit syntax:

- the configured TT source is persisted as `icon_template`
- the live rendered indicator value is persisted separately as `icon`
- collector runs render `icon_template` against stdout JSON data
- later config-sync passes keep the rendered `icon` instead of rewriting raw
  `[% ... %]` text back into prompt and browser state

That connection matters to the product story:

- collectors prepare the answer once
- indicators summarize it in the browser and prompt
- pages and actions give the browser a working home instead of a static note page
- CLI helpers move the developer directly to files, paths, and container commands

Collector loops are managed explicitly:

- each loop writes a pid file plus `loop.json` metadata
- the process title is set to `dashboard collector: <name>`
- duplicate prevention requires both a live pid and a matching process title
- stale or foreign pid files are cleaned up instead of being trusted blindly

Web service lifecycle is managed the same way:

- `dashboard serve` backgrounds the web service by default
- `dashboard serve` starts the configured collector loops alongside the web service, so `serve`, `stop`, and `restart` all act on the same managed runtime set
- `dashboard stop` stops both the web service and collector loops
- `dashboard restart` stops both, restarts configured collectors, then starts the web service again
- the web process title is set to `dashboard web: <host>:<port>`
- shutdown prefers managed-process validation, then falls back to `pkill -f` style matching and explicit process scans

Browser access is managed explicitly:

- exact `127.0.0.1` with numeric host `127.0.0.1` is trusted as local admin
- `localhost`, other hosts, and other client IPs are helper-tier requests
- helper-tier requests must authenticate through file-backed user and session records
- helper usernames are validated, passwords require at least 8 characters, and user/session files are written with `0600` permissions
- helper sessions are bound to the originating remote address and expire after 12 hours
- helper page views show a Logout link in the top chrome, display the helper username in the top-right user marker, and logging out removes both the helper session and that helper account
- exact-loopback admin page views do not show a Logout link
- HTTP responses add CSP, frame-deny, nosniff, no-referrer, and no-store headers

Page source compatibility is explicit:

- bookmark files serialize back to the original `KEY: ...` plus divider-line syntax
- older `KEY: ...` documents separated by the original divider line are supported directly
- `HTML` is rendered through Template Toolkit with access to `stash`, `ENV`, and `SYSTEM`
- `TITLE` populates the document `<title>` and is exposed to Template Toolkit as `title`, but it is not injected into the page body automatically
- `CODE*` blocks run through the older page runtime, merge returned hashes into stash, dump returned hash and array values into the runtime output area, append printed `STDOUT` to the page, and show `STDERR` as red error output
- one generated sandpit package is reused across `CODE*` blocks for a single render, then destroyed so package globals do not leak into later requests
- `/` with no bookmark path opens the free-form instruction editor directly
- posting a root-editor document with `BOOKMARK: some-id` persists it as a saved bookmark so `/app/some-id` can load it on the next request
- `/apps` redirects to `/app/index`
- transient browser execution from `/?token=...`, `/action?atoken=...`, and older `/ajax?token=...` is disabled by default and only re-enabled when `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is truthy
- saved bookmark `Ajax` helper calls can avoid transient tokens by supplying `file => 'name.json'`, which stores the code under `dashboards/ajax/...`, emits `/ajax/<name>?type=...`, and runs the stored file as a real process so live `stdout` and `stderr` stream back to the browser directly
- edit and render views include shared top chrome with share/source links plus the original status-plus-alias indicator strip, refreshed from `/system/status`, alongside the local user, a machine IP link chosen from the active interfaces, and a browser-updated date/time
- direct `nav/*.tt` saved bookmarks are treated as shared nav fragments, and raw TT/HTML fragment files under `nav/` are accepted too when they actually look like nav markup, so `/app/nav/foo.tt` remains editable like any other bookmark while non-nav pages insert the sorted rendered `nav/*.tt` outputs between the top chrome and the main page body
- bookmark Template Toolkit rendering exposes `env.current_page` and `env.runtime_context.current_page`, so saved pages and nav fragments can branch on the active request path without losing the rest of the runtime context
- `DD-OOP-LAYERS` is the cross-runtime contract: starting at `~/.developer-dashboard` and walking down through every parent directory until the current working directory, every existing `.developer-dashboard/` layer participates as one inherited runtime stack
- under `DD-OOP-LAYERS`, the deepest discovered layer stays the write target and first lookup hit, while bookmarks, shared `nav/*.tt`, config, collectors, indicators, auth/session stores, runtime `local/lib/perl5`, static assets, and custom CLI hooks are all inherited across the full layer chain instead of only one project-or-home split
- DD-OOP-LAYERS ancestry and dedupe checks normalize canonical path identities, so macOS path aliases such as `/var/...` and `/private/var/...` still resolve to the same inherited layer chain
- dashboard-managed built-in helper extraction is the explicit home-only exception to that write rule: `dashboard init` and on-demand helper staging always seed built-in helpers only under `~/.developer-dashboard/cli/dd/`, while layered lookup still applies to user commands and hook directories under the ordinary layered `cli/` roots
- home-runtime helper staging is non-destructive: `dashboard init` may add or update dashboard-managed built-in helpers under `~/.developer-dashboard/cli/dd/`, but it must preserve the separate user command and hook space under `~/.developer-dashboard/cli/` plus child-layer `./.developer-dashboard/cli/` roots instead of deleting or clobbering user files there
- dashboard-managed helper and starter-page refreshes are MD5-aware inside Perl, so `dashboard init` skips rewriting a dashboard-managed helper or shipped starter page when the existing file already matches the shipped content digest
- starter-page refreshes are safe across upgrades too: `dashboard init` records the md5 of the last dashboard-managed shipped `api-dashboard` / `sql-dashboard` copy under the active runtime config tree, refreshes only pages that still match that recorded or bridged historical managed digest, and preserves diverged user-edited saved pages instead of flattening them back to the shipped bookmark
- `dashboard init` seeds `api-dashboard` and `sql-dashboard` as normal editable saved bookmarks, but rerunning it preserves an existing `~/.developer-dashboard/config/config.json` instead of overwriting user config; if the file is missing, init creates it as `{}` without inventing an example collector
- the public `dashboard` entrypoint stays thin for all built-in commands: the shipped starter bookmark source plus helper script source live under `share/seeded-pages/` and `share/private-cli/`, dedicated helper bodies cover `jq`/`yq`/`of`/`open-file`/`ticket`/`path`/`paths`/`ps1`, and the remaining built-ins stage thin wrappers into the shared private `_dashboard-core` runtime so those bodies do not bloat the command script; installed copies resolve the same assets from the distribution share dir
- the seeded `api-dashboard` bookmark is a Postman-style workspace built inside the bookmark runtime, with local tab state, Postman collection import/export, file-backed collection persistence under `config/api-dashboard/<collection-name>.json`, owner-only `config/api-dashboard` and saved collection file permissions (`0700` / `0600`) because saved request auth can carry secrets, automatic reload of every stored collection on startup, browser URL restoration for active collection/request/tab navigation, request-token carry-over for `{{token}}` placeholders, a hide/show request-credentials panel with `Basic`, `API Token`, `API Key`, `OAuth2`, `Apple Login`, `Amazon Login`, `Facebook Login`, and `Microsoft Login` presets backed by Postman `request.auth` import/export, browser-side previews for JSON/text/PDF/image/TIFF responses, and a saved Ajax request sender backed by `LWP::UserAgent`
- the seeded `sql-dashboard` bookmark is also built entirely inside the bookmark runtime, with file-backed connection profiles under `config/sql-dashboard/<profile-name>.json`, file-backed SQL collections under `config/sql-dashboard/collections/<collection-name>.json`, owner-only `config/sql-dashboard` and `config/sql-dashboard/collections` directory/file permissions (`0700` / `0600`), a merged phpMyAdmin-style `SQL Workspace` tab with inner `Collection` and `Run SQL` subtabs so the collection rail can collapse when the user is focused on editing and results, a visible active saved-SQL label, a large auto-resizing SQL editor with one quiet action row below it, inline `[X]` deletion beside each saved SQL item, browser URL restoration for portable `connection` ids plus collection/item/table/sql state instead of saved SQL files, share-link draft-profile reconstruction when the receiving machine does not already have the saved connection, programmable `SQLS_SEP` / `INSTRUCTION_SEP` statement hooks, generic `DBI` execution, schema browsing through `table_info` / `column_info` without explicit `execute()` calls on those metadata handles, a live schema table filter, schema copy/view-data actions, human type/length labels derived from DBI metadata instead of raw numeric type codes, driver-specific DSN guidance for SQLite/MySQL/PostgreSQL/MSSQL/Oracle in the profile editor, live browser verification against SQLite, MySQL, PostgreSQL, MSSQL via `DBD::ODBC`, and Oracle via `DBD::Oracle`, and a runtime override model where `~/.developer-dashboard/dashboards/sql-dashboard` can shadow the shipped seeded page until the user updates or removes that saved override; use `dashboard page source sql-dashboard` to inspect the live source that the browser route is actually rendering, all while keeping those `DBD::*` drivers out of shipped base runtime prerequisites
- `dashboard cpan <Module...>` installs optional runtime modules into `./.developer-dashboard/local` and appends them to `./.developer-dashboard/cpanfile`, including automatic `DBI` installation when users request a `DBD::*` driver, while keeping that support in the `dashboard` entrypoint and having saved Ajax workers infer `local/lib/perl5` directly from the active runtime root
- `dashboard serve logs` exposes the combined Dancer2 and Starman runtime log stored in the dashboard log file, with `-n N` tailing and `-f` follow mode
- `dashboard serve workers N` persists the default Starman worker count in config and auto-starts the web service when it is currently stopped; `--host HOST` and `--port PORT` steer that auto-start path, while `dashboard serve --workers N` and `dashboard restart --workers N` still allow one-off overrides
- the editor view auto-submits the bookmark form on textarea change/blur instead of relying on a visible update button
- the editor keeps a plain escaped source overlay with wrapping disabled so the visible text geometry stays identical to the real textarea during long bookmark edits

## Environment Overrides

The core supports compatibility-style environment overrides for project customization:

- `DEVELOPER_DASHBOARD_BOOKMARKS`
  Saved page/bookmark root.

- `DEVELOPER_DASHBOARD_CHECKERS`
  Filter for enabled collector/checker names using colon-separated values.

- `DEVELOPER_DASHBOARD_CONFIGS`
  Config root.

- `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS`
  Opt-in flag for browser execution of transient `token=` and `atoken=` payloads.


The runtime also supports user CLI extensions:

- unknown top-level `dashboard` subcommands are resolved through the `DD-OOP-LAYERS` stack with the deepest matching `./.developer-dashboard/cli/<command>` winning over parent layers and finally `~/.developer-dashboard/cli`
- the matching executable receives the remaining argv unchanged
- stdin, stdout, and stderr are preserved through `exec`
- every top-level command also has optional hook directories at `./.developer-dashboard/cli/<command>` or `./.developer-dashboard/cli/<command>.d` in every inherited layer
- executable hook files run in sorted filename order within each layer, and the layers themselves execute from `~/.developer-dashboard` down to the deepest current layer
- non-executable files in the hook directory are skipped
- hook `stdout` and `stderr` stream live to the terminal while also being accumulated into `RESULT` JSON for later hooks and the final command
- after each hook exits, the updated `RESULT` JSON is written back into the environment before the next hook starts
- Perl hook scripts can use `Runtime::Result` to decode `RESULT` and inspect prior hook `stdout`, `stderr`, and exit codes
- there is no special built-in `update` path; `dashboard update` is just another user-provided command when `./.developer-dashboard/cli/update` or `./.developer-dashboard/cli/update/run` exists, with the same home fallback
- directory-backed custom commands can use `./.developer-dashboard/cli/<command>/run` as the final executable after hooks complete, with the same home fallback

## Packaging

- `dist.ini` controls Dist::Zilla packaging
- GitHub Actions builds with `dzil build`
- uploads to PAUSE use `PAUSE_USER` and `PAUSE_PASS`

## Quality Gates

- `prove -lr t` must pass
- library coverage is measured with Devel::Cover
- the coverage report should be reviewed before release, especially after adding new runtime modules
