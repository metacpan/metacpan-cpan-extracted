<!-- Generated from lib/Developer/Dashboard.pm POD by script/sync-readme-from-pod. Do not edit manually. -->

# NAME

Developer::Dashboard - a local home for development work

# VERSION
4.03

# INTRODUCTION

Developer::Dashboard gives a developer one place to organize the moving parts of day-to-day work.

Without it, local development usually ends up spread across shell history,
ad-hoc scripts, browser bookmarks, half-remembered file paths, one-off health
checks, and project-specific Docker commands. With it, those pieces can live
behind one entrypoint: a browser home, a prompt status layer, and a CLI
toolchain that all read from the same runtime.

It brings together browser pages, saved notes, helper actions, collectors,
prompt indicators, path aliases, open-file shortcuts, data query tools, and
Docker Compose helpers so local development can stay centered around one
consistent home instead of a pile of disconnected scripts and tabs.

When the current project contains `./.developer-dashboard`, that tree becomes
the first runtime lookup root for dashboard-managed files. The home runtime
under `~/.developer-dashboard` stays as the fallback base, so project-local
bookmarks, config, CLI hooks, helper users, sessions, and isolated docker
service folders can override home defaults without losing shared fallback data
that is not redefined locally.

The home runtime is now hardened to owner-only access by default. Directories
under `~/.developer-dashboard` are kept at `0700`, regular runtime files are
kept at `0600`, and owner-executable scripts stay owner-executable at
`0700`. Run `dashboard doctor` to audit the current home runtime plus any
older dashboard roots still living directly under `$HOME`, or
`dashboard doctor --fix` to tighten those permissions in place. The same
command also audits the staged helper namespace under
`~/.developer-dashboard/cli/dd/` for missing or stale dashboard-managed
helpers such as `_dashboard-core`, and `--fix` restages them from the
currently shipped helper assets when the runtime drift is repairable. It also
checks whether dashboard-managed bash bootstrap lines were appended after the
standard Debian-family non-interactive `return` guard in `~/.bashrc`; when
that drift is present, `dashboard doctor --fix` rewrites those lines above
the guard so tmux status commands and other non-interactive shells can still
resolve `dashboard` correctly. It also
reads optional hook results from
`~/.developer-dashboard/cli/doctor.d` so users can layer in more
site-specific checks later.

Frequently used built-in commands such as `jq`, `yq`, `tomq`, `propq`,
`iniq`, `csvq`, `xmlq`, `of`, `open-file`, `file`, `files`, and
`workspace` are staged
privately under `~/.developer-dashboard/cli/dd/` and dispatched by
`dashboard` without polluting the global PATH. That keeps dashboard-owned
built-ins separate from user commands and hooks under
`~/.developer-dashboard/cli/`. Compatibility aliases `pjq`, `pyq`,
`ptomq`, `pjp`, and `ticket` still normalize to the current commands when
they are invoked through `dashboard`. The public switchboard now keeps the
prompt path lighter as well: once the managed helper files are already staged,
`dashboard ps1` refreshes only the requested helper, reuses one path registry
for the whole invocation, and avoids loading the suggestion and skill dispatch
stack on the ordinary prompt fast path.

Dashboard also normalizes `PERL5LIB` for its own processes before the staged
helper runtime loads. Dashboard-owned libraries stay visible, but the active
Perl core, site, and vendor directories are forced ahead of inherited
user-local shadow copies. That keeps stale dual-life XS modules such as
`Encode` from breaking helper startup, collector child commands, saved Ajax
subprocesses, or skill hooks on hosts with older local-lib artefacts.
Dashboard-managed child commands also keep the current interpreter's bin
directory plus the active shell directory at the front of `PATH`, and
collector shell commands now run through a non-login shell so macOS
shell-session restore banners and similar startup chatter do not get prefixed
onto JSON collector output.

Explicit named collector stop and restart actions also pause the watchdog
supervisor for the targeted collector set while the lifecycle command is in
flight, then restore supervision for the remaining watched fleet afterwards.
That prevents the watchdog from racing a manual collector restart and spawning
another replacement loop underneath the CLI.

It provides a small ecosystem for:

- saved and transient dashboard pages built from the original bookmark-file shape
- bookmark-file syntax compatibility using the original
`:--------------------------------------------------------------------------------:` separator plus directives such as
`TITLE:`, `STASH:`, `HTML:`, and `CODE1:`
- Template Toolkit rendering for `HTML:`, with access to `stash`, `ENV`, and
`SYSTEM`
- bookmark `CODE*` execution with captured `STDOUT` rendered into the page and
captured `STDERR` rendered as visible errors
- per-page sandpit isolation so one bookmark run can share runtime
variables across `CODE*` blocks without leaking them into later page runs
- old-style root editor behavior with a free-form bookmark textarea when no path is provided
- file-backed collectors and indicators
- prompt rendering for `PS1` and the PowerShell `prompt` function
- project/path discovery helpers
- a lightweight local web interface
- action execution with trusted and safer page boundaries
- config-backed providers, path aliases, and compose overlays
- update scripts and installable runtime packaging

Managed runtime children are expected to clean up after themselves. Detached
web startup helpers, collector loops, the collector watchdog supervisor, the
SSL frontend connection workers, and background page actions now reap the
direct children they own instead of leaving zombie processes behind on hosts
such as macOS and WSL. Collector loops and the collector watchdog supervisor
also reap those children immediately on `SIGCHLD`, so long-interval
collectors and orphaned watchdogs do not leave visible `<defunct>`
dashboard processes behind until some later housekeeping pass. Managed
collectors are also watched after startup: an
unexpected exit triggers an automatic restart, while repeated crash loops are
raised as explicit `attention_required` collector state instead of silently
stopping or spinning forever.
Managed collector indicators also keep the collector array order declared in
`config/config.json` even after a live collector run rewrites its own status,
so the browser status board and `dashboard ps1` do not drift back to
alphabetical ordering after one collector refreshes.
Collector schedules now also support bounded overlap control. The default
collector `mode` is `singleton`, which means one long-running collector run
blocks the next scheduled start until the active run finishes. Set
`mode => "multiple"` to allow overlap, and use `multiple => N` to
bound how many concurrent runs of that same collector can exist at once. When
the field is omitted in `multiple` mode, the runtime defaults that bound to
`2`.

Developer Dashboard is meant to become the developer's working home:

- shared nav fragments from saved `nav/*.tt` bookmarks rendered between the top
chrome and the main page body on other saved pages
- a local dashboard page that can hold links, notes, forms, actions, and
rendered output
- a prompt layer that shows live status for the things you care about
- a command surface for opening files, jumping to known paths, querying data, and
running repeatable local tasks
- a configurable runtime that can adapt to each codebase without losing one
familiar entrypoint

## Shared Nav Fragments

If `nav/*.tt` files exist under the saved bookmark root, every non-nav page
render includes them between the top chrome and the main page body.

For the default runtime that means files such as:

- `~/.developer-dashboard/dashboards/nav/foo.tt`
- `~/.developer-dashboard/dashboards/nav/bar.tt`

And with route access such as:

- `/app/nav/foo.tt`
- `/app/nav/foo.tt/edit`
- `/app/nav/foo.tt/source`

The bookmark editor can save those nested ids directly, for example
`BOOKMARK: nav/foo.tt`. Raw TT/HTML fragment files under `nav/` also work
without bookmark wrappers, for example:

    [% index = '/app/index' %]
    <a href=[% index %]>[% index %]</a>

On a page like `/app/index`, the direct `nav/*.tt` files are loaded in
sorted filename order, rendered through the normal page runtime, and inserted
above the page body. Non-`.tt` files, subdirectories under `nav/`, and junk
files that do not look like TT or HTML fragments are ignored by that shared
nav renderer.

Under `DD-OOP-LAYERS`, the shared nav renderer now scans every inherited
`dashboards/nav/` layer from `~/.developer-dashboard` down to the current
directory, keeps parent-only fragments visible, and lets a deeper layer
replace the same `nav/<name>.tt` id without losing the rest of the
shared nav set. Template includes used by those bookmarks follow the same
layered bookmark lookup path. Installed skill nav also follows nested
`skills/<repo>/skills/<child>/...` trees now, so a nested
skill can contribute `dashboards/nav/index.tt` or other shared fragments
without being flattened back into only the first installed-skill level.

Shared nav fragments and normal bookmark pages both render through Template
Toolkit with `env.current_page` set to the active request path, such as
`/app/index`. The same path is also available as
`env.runtime_context.current_page`, alongside the rest of the request-time
runtime context. Token play renders for named bookmarks also reuse that saved
`/app/<id>` path for nav context, so shared `nav/*.tt` fragments do
not disappear just because the browser reached the page through a transient
`/?mode=render&token=...` URL.
Shared nav markup now wraps horizontally by default and inherits the page
theme through CSS variables such as `--panel`, `--line`, `--text`, and
`--accent`, so dark bookmark themes no longer force a pale nav box or hide
nav link text against the background.

## What You Get

- a browser interface on port `7890` for pages, status, editing, and helper
access
- a shell entrypoint for file navigation, page operations, collectors,
indicators, auth, and Docker Compose
- saved runtime state that lets the browser, prompt, and CLI all see the same
prepared information
- a place to collect project-specific shortcuts without rebuilding your daily
workflow for every repo

## Web Interface And Access Model

Run the web interface with:

    dashboard serve

By default it listens on `0.0.0.0:7890`, so you can open it in a browser at:

    http://127.0.0.1:7890/

Run `dashboard serve --ssl` to enable HTTPS with a generated self-signed
certificate under `~/.developer-dashboard/certs/`, then open:

    https://127.0.0.1:7890/

When SSL mode is on, plain HTTP requests on that same host and port are
redirected to the equivalent `https://...` URL before the dashboard route
runs. The generated certificate now carries browser-correct SAN coverage for
`localhost`, `127.0.0.1`, and `::1`, automatically includes the concrete
`--host HOST` bind target when that host is not a wildcard listen address, and
also includes any extra names or IPs listed under
`web.ssl_subject_alt_names` in `config/config.json`. Older dashboard certs are
rotated forward automatically when they no longer match that expected profile.
Browsers still show the normal self-signed certificate warning until you trust
the generated certificate locally.

Run `dashboard serve --no-editor` or `dashboard serve --no-endit` to keep
the browser in read-only mode. That hides the Share, Play, and View Source
links, blocks bookmark editor and source routes with `403`, blocks
bookmark-save POST requests even if someone tries to hit them directly, and
persists the mode so later `dashboard restart` runs stay read-only until you
switch it back with `dashboard serve --editor`.

Run `dashboard serve --no-indicators` or `dashboard serve --no-indicator` to
clear the whole top-right browser chrome area. That hides the browser-only
indicator strip, username, host or IP link, and live date-time line without
changing `/system/status` or terminal prompt output such as `dashboard ps1`,
and persists the mode until `dashboard serve --indicators` turns it back on.

For example, if you want the same dashboard cert to work for one local
`/etc/hosts` alias and one LAN IP, keep the runtime config like this:

    {
      "web": {
        "ssl_subject_alt_names": [
          "dashboard.local",
          "192.168.1.20",
          "fd00::20"
        ]
      }
    }

The access model is deliberate:

- numeric loopback and loopback-only hostnames such as `localhost` do not
require a password when the request still originates from loopback
- configured loopback aliases listed under `web.ssl_subject_alt_names` are also
treated as local-admin when they still arrive from loopback
- helper access is for everyone else, including non-loopback IPs and other
machines on the network
- helper logins let you share the dashboard safely without turning every browser
request into full local-admin access

In practice that means the developer at the machine gets friction-free local
admin access, while shared or forwarded access is forced through explicit
helper accounts.
If no helper user exists yet in the active dashboard runtime, outsider requests return
`401` with an empty body and do not render the login form at all.
When a saved `index` bookmark exists, opening `/` now redirects straight to
`/app/index` so the saved home page becomes the default browser entrypoint.
When no saved `index` bookmark exists yet, `/` still opens the free-form
bookmark editor.
If a user opens an unknown saved route such as `/app/foobar`, the browser now
opens the bookmark editor with a prefilled blank bookmark for that requested
path instead of showing a 404 error page.
When helper access is sent to `/login`, the login form now keeps the original
requested path and query string in a hidden redirect target. After a
successful helper login, the browser is sent back to that saved route, such as
`/app/index`, instead of being dropped at `/`.

## Collectors, Indicators, And PS1

Collectors are background or on-demand jobs that prepare state for the rest of
the dashboard. A collector can run a shell command or a Perl snippet, then
store stdout, stderr, exit code, and timestamps as file-backed runtime data.

That prepared state drives indicators. Indicators are the short status records
used by:

- the shell prompt rendered by `dashboard ps1`
- the top-right status strip in the web interface
- CLI inspection commands such as `dashboard indicator list`

This matters because prompt and browser status should be cheap to render.
Instead of re-running a Docker check, VPN probe, or project health command
every time the prompt draws, a collector prepares the answer once and the rest
of the system reads the cached result.
When the generated shell bootstrap runs inside a `dashboard workspace` tmux
session, those prompt indicators move out of the inline shell prompt and into
that session's tmux status area so the cursor line stays clean while the
indicator strip keeps updating between prompts. Workspace sessions use a
two-line bottom status block: the first row is the dashboard indicator strip
with the trailing date-time segment, and the second row keeps tmux's normal
session and indexed window list. Ordinary tmux sessions keep the normal
inline prompt. The
workspace workflow seeds a dedicated
`DEVELOPER_DASHBOARD_TMUX_STATUS=1` session flag for that behavior, and
Developer Dashboard also treats the older `TICKET_REF` session reference as a
fallback signal so older workspace sessions do not keep duplicating indicators in the
inline prompt. Developer Dashboard updates tmux through session-local runtime
commands instead of editing any user tmux config file or changing unrelated
tmux sessions on the same server.
Configured collector indicators now prefer the configured icon in both places,
and when a collector is renamed the old managed indicator is cleaned up
automatically so the prompt and top-right browser strip do not show both the
old and new names at the same time. Those managed indicator records now also
preserve a newer live collector status during restart/config-sync windows, so
a healthy collector does not flicker back to `missing` after it has already
reported `ok`.
If `indicator.icon` contains Template Toolkit syntax such as `[% a %]`, the
collector runner now treats collector `stdout` as JSON, decodes it through
`JSON::XS`, exposes hash keys as direct template variables plus `data`, and
persists the rendered icon as the live indicator value. Invalid JSON or TT
render failures are explicit collector errors: the collector `stderr` records
the template problem and the indicator stays red instead of silently falling
back.

## Why It Works As A Developer Home

The pieces are designed to reinforce each other:

- pages give you a browser home for links, notes, forms, and actions
- collectors prepare state for indicators and prompt rendering
- indicators summarize that state in both the browser and the shell
- path aliases, open-file helpers, and data query commands shorten the jump from
I know what I need to I am at the file or value now
- Docker Compose helpers keep recurring container workflows behind the same
`dashboard` entrypoint

That combination makes the dashboard useful as a real daily base instead of
just another utility script.

## Not Just For Perl

Developer Dashboard is implemented in Perl, but it is not only for Perl
developers.

It is useful anywhere a developer needs:

- a local browser home
- repeatable health checks and status indicators
- path shortcuts and file-opening helpers
- JSON, YAML, TOML, or properties inspection from the CLI
- a consistent Docker Compose wrapper

The toolchain already understands Perl module names, Java class names, direct
files, structured-data formats, and project-local compose flows, so it suits
mixed-language teams and polyglot repositories as well as Perl-heavy work.

Project-specific behavior is added through configuration, saved pages, and
user CLI extensions.

# MODULE NAMESPACING

All project modules are scoped under the `Developer::Dashboard::` namespace
to prevent pollution of the CPAN ecosystem. Core helper modules are available
under this namespace:

- Developer::Dashboard::File

    File I/O helpers with alias support for older bookmark compatibility.

- Developer::Dashboard::Folder

    Folder path resolution and discovery with runtime registry support.

- Developer::Dashboard::DataHelper

    JSON encoding and decoding helpers for older bookmark code.

- Developer::Dashboard::Zipper

    Token encoding and Ajax command building for transient URL construction.

- Developer::Dashboard::Runtime::Result

    Hook result environment variable decoding and access for command runners.

Project-owned modules now live only under the `Developer::Dashboard::`
namespace so the distribution does not pollute the CPAN ecosystem with
generic package names.

## Main Concepts

- Path Registry

    `Developer::Dashboard::PathRegistry` resolves the runtime roots that
    everything else depends on, such as dashboards, config, collectors,
    indicators, CLI hooks, logs, and cache. The registry now keeps one
    invocation-scoped cwd plus memoized derived roots so thin-helper startup does
    not keep recomputing the same DD-OOP-LAYERS path chain during one command.

- File Registry

    `Developer::Dashboard::FileRegistry` resolves stable file locations on top of
    the path registry so the rest of the system can read and write well-known
    runtime files without duplicating path logic.

- Page Model

    `Developer::Dashboard::PageDocument` and `Developer::Dashboard::PageStore`
    implement the saved and transient page model, including bookmark-style source
    documents, encoded transient pages, and persistent bookmark storage.

- Page Resolver

    `Developer::Dashboard::PageResolver` resolves saved pages and provider pages
    so browser pages and actions can come from both built-in and config-backed
    sources.

- Actions

    `Developer::Dashboard::ActionRunner` executes built-in actions and trusted
    local command actions with cwd, env, timeout, background support, and encoded
    action transport, letting pages act as operational dashboards instead of static
    documents.

- Collectors

    `Developer::Dashboard::Collector` and
    `Developer::Dashboard::CollectorRunner` implement file-backed prepared-data
    jobs with managed loop metadata, timeout/env handling, interval and cron-style
    scheduling, process-title validation, duplicate prevention, and collector
    inspection data. This is the prepared-state layer that feeds indicators,
    prompt status, and operational pages.

- Indicators and Prompt

    `Developer::Dashboard::IndicatorStore` and `Developer::Dashboard::Prompt`
    expose cached state to shell prompts and dashboards, including compact versus
    extended prompt rendering, stale-state marking, generic built-in indicator
    refresh, and page-header status payloads for the web UI.

- Web Layer

    `Developer::Dashboard::Web::DancerApp`,
    `Developer::Dashboard::Web::App`, and
    `Developer::Dashboard::Web::Server` provide the browser interface on port
    `7890`, with Dancer2 owning the HTTP route table while the web-app service
    handles page rendering, login/logout, helper sessions, and the
    exact-loopback admin trust model.

- Open File Commands

    `dashboard of` and `dashboard open-file` resolve direct files, `file:line`
    references, Perl module names, Java class names, and recursive file-pattern
    matches under a resolved scope so the dashboard can shorten navigation work
    across different stacks.

- File Alias Commands

    `dashboard file` and `dashboard files` persist and inspect config-backed
    named file aliases, paralleling the existing path alias flow while targeting
    files instead of directories.

- Data Query Commands

    `dashboard jq`, `dashboard yq`, `dashboard tomq`, and `dashboard propq`
    parse JSON, YAML, TOML, and Java properties input, then optionally extract a
    dotted path and print a scalar or canonical JSON, giving the CLI a small
    data-inspection toolkit that fits naturally into shell workflows.
    `dashboard tomq` inflates TOML booleans into plain Perl `1` and `0`
    scalars, so CLI output and JSON-encoded query results stay stable instead of
    depending on backend-specific boolean objects.

- Private CLI Helper Assets

    Private `~/.developer-dashboard/cli/dd/` helper files provide the built-in
    command behaviour without installing generic command names into the global
    PATH. Query, open-file, workspace, path, file, and prompt commands keep
    dedicated helper bodies, while the remaining built-ins stage thin wrappers
    that hand off to a shared private `_dashboard-core` runtime.

    Only `dashboard` is intended to be the public CPAN-facing command-line
    entrypoint. The real built-in command bodies live outside `bin/dashboard`
    under `share/private-cli/`, then stage into `~/.developer-dashboard/cli/dd/`
    on demand. Generic helper names such as `workspace`, `of`, `open-file`,
    `jq`, `yq`, `tomq`, `propq`, `iniq`, `csvq`, `xmlq`, `path`,
    `paths`, `file`, and `files` are intentionally kept out of the installed
    global PATH to avoid
    polluting the wider Perl and shell ecosystem while still keeping
    dashboard-owned commands separate from user commands under
    `~/.developer-dashboard/cli/`. While those staged helpers run, their process
    title is normalized to the public `developer-dashboard ...` form so `ps`
    output shows the user-facing command instead of the staged helper path.

    `dashboard workspace` creates or reuses a tmux session for the requested
    workspace reference, seeds `WORKSPACE_REF`, keeps `TICKET_REF` for
    compatibility with older shells, refreshes plain-directory `.env` files from
    the highest ancestor down to the current directory when it creates or resumes a
    session, attaches through a dashboard-managed private helper instead of a
    public standalone binary, and completes already-open tmux session names when
    shell completion is enabled. The older `dashboard ticket` spelling remains as
    a compatibility alias.

- Runtime Manager

    `Developer::Dashboard::RuntimeManager` manages the background web service and
    collector lifecycle with process-title validation, numeric POSIX shutdown
    signals for Alpine/iSH compatibility, `pkill`-style fallback shutdown, and
    restart orchestration, tying the browser and prepared-state loops together as
    one runtime.

- Update Manager

    `Developer::Dashboard::UpdateManager` runs ordered update scripts and
    restarts validated collector loops when needed, giving the runtime a
    controlled bootstrap and upgrade path.

- Docker Compose Resolver

    `Developer::Dashboard::DockerCompose` resolves project-aware compose files,
    explicit overlay layers, services, addons, modes, env injection, and the
    final `docker compose` command so container workflows can live inside the
    same dashboard ecosystem instead of in separate wrapper scripts.

## Environment Variables

The distribution supports these compatibility-style customization variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`

    Override the saved page root.

- `DEVELOPER_DASHBOARD_CHECKERS`

    Filter enabled collector/checker names.

- `DEVELOPER_DASHBOARD_CONFIGS`

    Override the config root.

- `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS`

    Allow browser execution of transient `/?token=...`, `/action?atoken=...`,
    and older `/ajax?token=...` payloads. The default is off, so the web UI only
    executes saved bookmark files unless this is set to a truthy value such as
    `1`, `true`, `yes`, or `on`.

## Transient Web Token Policy

Transient page tokens still exist for CLI workflows such as `dashboard page encode`
and `dashboard page decode`, but browser routes that execute a transient payload
from `token=` or `atoken=` are disabled by default.

That means links such as:

- `http://127.0.0.1:7890/?token=...`
- `http://127.0.0.1:7890/action?atoken=...`
- `http://127.0.0.1:7890/ajax?token=...`

return a `403` unless `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is enabled.
Saved bookmark-file routes such as `/app/index` and
`/app/index/action/...` continue to work without that flag. Saved bookmark
editor pages also stay on their named `/app/<id>/edit` and
`/app/<id>` routes when you save from the browser, so editing an
existing bookmark file does not fall back to transient `token=` URLs under the
default deny policy.

`Ajax` helper calls inside saved bookmark `CODE*` blocks should use
an explicit `file => 'name.json'` argument. When a saved page supplies that
name, the helper stores the Ajax Perl code under the saved dashboard ajax tree and emits a
stable saved-bookmark endpoint such as
`/ajax/name.json?type=text`. Skill pages use the same helper contract. Without
extra skill route metadata the generated saved endpoint is namespaced under the
longest matching skill route, for example
`/ajax/example-skill/name.json?type=text` or
`/ajax/example-skill/sub-skill/name.json?type=text`. The runtime config tree
and installed skills can both ship `config/routes.json` to declare canonical
custom paths for normal saved app pages, skill-local app pages, Ajax handlers,
JavaScript assets, CSS assets, and other public assets. The schema is a JSON
object whose keys are the public custom paths and whose values are either one
smart local route string or an object with `to` plus an optional `type`, for
example

    {
       "/java" : "/app/learn.ai",
       "/v1/status" : {
          "to" : "/ajax/status",
          "type" : "json"
       },
       "/hello/world" : "/app/hello/world",
       "/main.css" : "/css/hello/world.css",
       "/hey.js" : "/js/hey/how/are/you.js",
       "/what/are/you" : "/others/hello/world/you.html"
    }

When that file is present, skill pages emit the declared canonical
`ajax` path such as `/v1/status` instead of the default `/ajax/...` url,
and runtime-level aliases such as `/java` can point at normal saved bookmark
ids such as `/app/learn.ai` without treating the dot as skill notation. The
same manifest also makes the declared custom `/app`, `/js`, `/css`, and
`/others` paths requestable. The smart longest-prefix routes remain the
parent resolvers:
`/app/example-skill/...`, `/ajax/example-skill/...`,
`/js/example-skill/...`, `/css/example-skill/...`, and
`/others/example-skill/...` are always checked first, and any declared custom
path is checked only after the normal smart route misses. Runtime-level custom
paths from the active `config/routes.json` layer chain follow the same
fallback rule against the built-in `/app`, `/ajax`, `/js`, `/css`, and
`/others` route handlers. If neither the smart route nor the custom path
resolves, the request falls through to the normal `404` response. Ajax custom
routes default to `json` when no explicit `type` is present, and the
optional `type` value can also be `html`,
`text`, or an arbitrary raw mime type such as
`application/vnd.example+json`. Those saved Ajax handlers run the stored file
as a real process, defaulting to Perl unless the file starts with a shebang,
and stream both `stdout` and `stderr` back to the browser as they happen.
That keeps bookmark Ajax workflows usable even while transient token URLs stay
disabled by default, and it means bookmark Ajax code can rely on normal
`print`, `warn`, `die`, `system`, and `exec` process behaviour instead of
a buffered JSON wrapper.
The same layered runtime config chain and installed-skill config trees can now
ship `config/api.json` files that authorize selected `/ajax/...` routes for
machine-to-machine callers without forcing a helper login form. The schema is a
JSON object keyed by API client name. Each entry must provide a stored SHA-256
hex digest under `secret` plus an `ajax` array of exact saved Ajax route
paths such as `/ajax/stream.txt` or
`/ajax/example-skill/status.json`. When a non-admin remote request targets one
of those registered `/ajax/...` paths, the caller can send
`X-DD-API-Key: NAME` and `X-DD-API-Secret: RAW-SECRET`. Developer Dashboard
hashes the raw secret with SHA-256, compares it to the stored digest, and
executes the saved Ajax handler when they match. Missing or wrong credentials
for a registered API route return `403` with the JSON body
`{"status":"forbidden"}`. Existing helper-session auth still works on the
same saved Ajax routes, so browser workflows and machine callers can coexist on
one handler without adding a second copy of the route. Like the rest of
`DD-OOP-LAYERS`, runtime `config/api.json` files merge from home to the
deepest active child layer, and installed skills contribute their own layered
`config/api.json` fragments for skill-local saved Ajax routes. The built-in
`dashboard api` command is the supported way to inspect or update the writable
runtime layer for that registry.
Saved bookmark Ajax handlers also default to `text/plain` when no explicit
`type => ...` argument is supplied, and the generated Perl wrapper now
enables autoflush on both `STDOUT` and `STDERR` so long-running handlers
show incremental output in the browser instead of stalling behind process
buffers.
If a saved handler also needs refresh-safe process reuse, pass
`singleton => 'NAME'` in the `Ajax` helper. The generated url then carries
that singleton name, the Perl worker runs as `dashboard ajax: NAME`, and the
runtime terminates any older matching Perl Ajax worker before starting the
replacement stream for the refreshed browser request. Singleton-managed Ajax
workers are also terminated by `dashboard stop` and `dashboard restart`, and
the bookmark page now registers a `pagehide` cleanup beacon against
`/ajax/singleton/stop?singleton=NAME` so closing the browser tab also tears
down the matching worker instead of leaving it behind.
If `code => ...` is omitted, `Ajax(file => 'name')` targets the
existing executable at `dashboards/ajax/name` instead of rewriting it.
Static files referenced by saved bookmarks are resolved from the effective
runtime public tree first and then from the saved bookmark root. The web layer
also provides a built-in bundled `/js/jquery.js` asset that serves the local
copy of jQuery 4.0.0, with `/js/jquery-4.0.0.min.js` kept as a compatibility
alias for the same shipped payload even when no runtime file has been copied
into `dashboard/public/js` yet. Skills can ship the same classes of assets
under their own dashboard tree: `dashboards/ajax/*` resolves at
`/ajax/<repo-name>/...` or
`/ajax/<repo-name>/<sub-skill>/...`, and
`dashboards/public/js/*`, `dashboards/public/css/*`, and
`dashboards/public/others/*` resolve at
`/js/<repo-name>/...`, `/css/<repo-name>/...`, and
`/others/<repo-name>/...` with the same nested-skill extension,
for example `/js/<repo-name>/<sub-skill>/path/file.js`. If a
request such as `/js/<repo-name>/foo/bar.js` or
`/js/<repo-name>/<sub-skill>/foo/bar.js` does not exist in the
skill-local public tree, the web layer falls back to the normal nested
saved-bookmark asset path `dashboards/public/js/...` or saved Ajax file path
`dashboards/ajax/...` instead of assuming the leading path segments must
belong to a skill.

Saved bookmark editor and view-source routes also protect literal inline
script content from breaking the browser bootstrap. If a bookmark body
contains HTML such as `/script`, the editor now escapes the inline JSON
assignment used to reload the source text, so the browser keeps the full
bookmark source inside the editor instead of spilling raw text below the page.
Saved browser workspaces can also show a request-specific token form above the
editor whenever the current request uses `{{token}}` placeholders, carrying
those token values across matching placeholders in the same workflow so later
requests can reuse the operator-supplied values without manual copy-and-paste.
Bookmark rendering now emits saved `set_chain_value()` bindings after
the bookmark body HTML, so pages that declare `var endpoints = {}` and then
call helpers from `$(document).ready(...)` receive their saved `/ajax/...`
endpoint URLs without throwing a play-route JavaScript `ReferenceError`.
Bookmark pages now also expose
`fetch_value(url, target, options, formatter)`,
`stream_value(url, target, options, formatter)`, and
`stream_data(url, target, options, formatter)` helpers so a bookmark can bind
saved Ajax endpoints into DOM targets without hand-writing the fetch and
render boilerplate. `stream_data()` and `stream_value()` now use
`XMLHttpRequest` progress events for browser-visible incremental updates, so
a saved `/ajax/...` endpoint that prints early output updates the DOM before
the request finishes. Those helpers support plain text, JSON, and HTML output
modes, and the saved Ajax endpoint bindings now run after the page declares
its endpoint root object, so `$(document).ready(...)` callbacks can call
helpers such as `fetch_value(endpoints.foo, '#foo')` on first render.
Saved browser workspaces that render response inspection panels should place
their Response Body and Response Headers tabs below the response `pre` box so
the main response payload stays visible while the tabbed details remain
reachable without jumping away from the current result.

## User CLI Extensions

Unknown top-level subcommands can be provided by executable files under
the current working directory's `./.developer-dashboard/cli` first, then the
nearest git-backed project runtime `./.developer-dashboard/cli` when it is a
different directory, and then `~/.developer-dashboard/cli`. For example,
`dashboard foobar a b` will exec the first matching
`cli/foobar` with `a b` as argv, while preserving stdin, stdout, and
stderr.

A direct custom command can also be stored as an executable
`cli/<command>.pl`, `cli/<command>.py`, `cli/<command>.js`, `cli/<command>.go`,
`cli/<command>.java`, `cli/<command>.sh`,
`cli/<command>.bash`, `cli/<command>.ps1`,
`cli/<command>.cmd`, or `cli/<command>.bat`, and
`dashboard <command>` resolves the same logical command name to
those files.

Concrete source-backed examples:

    dashboard hi
    dashboard foo

If `cli/hi.go` is executable, `dashboard hi` runs it through `go run`.
If `cli/report.py` is executable, `dashboard report` runs it through `python`.
If `cli/webhook.js` is executable, `dashboard webhook` runs it through `node`.
If `cli/foo.java` is executable, `dashboard foo` compiles it with `javac`
into an isolated temp directory and then runs the declared main class with
`java`.

If a user mistypes a command, dashboard now prints an explicit unknown-command
error together with the closest matching public command before the usual usage
summary. The same guidance also applies to dotted skill commands, so
`dashboard alpha-skill.run-tset` suggests the nearest installed dotted skill
command instead of only dumping generic help.

`DD-OOP-LAYERS` is now the runtime contract for the whole local ecosystem.
Starting at `~/.developer-dashboard` and walking down through every parent
directory until the current working directory, every existing
`.developer-dashboard/` layer participates. The deepest layer stays the write
target and the first lookup hit, but bookmarks, `nav/*.tt`, config,
collectors, indicators, auth/session state lookups, runtime
`local/lib/perl5`, and custom CLI hooks are all inherited across the full
chain instead of only a single project-or-home split.

Per-command hook files can live under either
`./.developer-dashboard/cli/<command>` or
`./.developer-dashboard/cli/<command>.d` in every inherited layer
from `~/.developer-dashboard` down to the current directory. Executable files
in those directories are run in sorted filename order within each layer, with
the layers themselves running top-down from home to the deepest current layer,
non-executable files are skipped, and each hook now streams its own
`stdout` and `stderr` live to the terminal while still accumulating those
channels into `RESULT` as JSON. If that JSON grows too large for a safe
`exec()` environment, `dashboard` spills it into `RESULT_FILE` and
`Developer::Dashboard::Runtime::Result` reads the same logical payload from
there so later hooks and the final command still see the same result set
without tripping `Argument list too long`. Built-in commands such as `dashboard jq`
use the same hook directory. A
directory-backed custom command can provide its real executable as
`~/.developer-dashboard/cli/<command>/run`, and that runner receives
the final `RESULT` plus `LAST_RESULT` environment variables. After each hook
finishes, the updated `RESULT` JSON is written back into the environment
before the next sorted hook starts, and `LAST_RESULT` is rewritten to the
structured result for the hook that just ran, so later hook scripts can react
to earlier hook output and also inspect the immediate previous hook in a stable
shape. `LAST_RESULT` carries `file`, `exit`, `STDOUT`, and `STDERR`.
Only an explicit `[[STOP]]` marker in one hook's `stderr` stops the
remaining hook files for that command. A non-zero exit code alone is still
recorded, but it does not skip later hooks. Executable `.py` hook files and
direct `.py` custom commands run through `python`. Executable `.js` hook files and
direct `.js` custom commands run through `node`. Executable `.go` hook files and
direct `.go` custom commands run through `go run`. Executable `.java`
hook files and direct `.java` custom commands are compiled with `javac`
into an isolated temp directory and then run through `java` using the
declared main class from the source file.

Perl hook code can use `Runtime::Result` to decode `RESULT` safely, read the
immediate `last_result`, and inspect per-hook `stdout`, `stderr`, exit
codes, or the last recorded hook entry.
If a Perl-backed command wants a compact final summary after its hook files
run, it can also call `Developer::Dashboard::Runtime::Result->report()` to print a simple
success/error report for each sorted hook file.

### Layered Env Files

Environment files are part of the same `DD-OOP-LAYERS` contract.
When `dashboard ...` runs, it loads every participating plain-directory env
file and runtime-layer env file from root to leaf before command hooks,
custom commands, or built-in helpers execute.

That ordered runtime pass loads, when present:

- `<root>/.env`
- `<root>/.env.pl`
- each deeper ancestor directory `.env`
- each deeper ancestor directory `.env.pl`
- each participating `.developer-dashboard/.env`
- each participating `.developer-dashboard/.env.pl`

Deeper files win because later layers overwrite earlier keys. Plain `.env`
files must contain explicit `KEY=VALUE` lines, and the load order at one
directory is always `.env` first and then `.env.pl`. Plain `.env` parsing
ignores blank lines, whole-line `#` comments, whole-line `//` comments, and
`/* ... */` block comments that can span multiple lines. Plain `.env`
values also support:

- leading `~` expansion to `$HOME`
- `$NAME` expansion from the current effective environment
- `${NAME:-default}` expansion with a fallback value
- `${Namespace::function():-default}` expansion through a static Perl function

Expansion can see system env keys, values loaded from earlier layers, and
values assigned by earlier lines in the same `.env` file. Missing functions,
malformed lines, malformed keys, and unterminated block comments fail
explicitly instead of being skipped silently. Executable logic can live in
`.env.pl`, which is run directly and may set `%ENV` programmatically.

Skill-local env files are loaded only when a skill command or skill hook is
actually running. A normal non-skill command inherits only the root-to-leaf
runtime env chain. A skill command inherits that same runtime chain first and
then loads each participating skill root from the base installed skill layer
to the deepest matching child skill layer, applying:

- `<skill-root>/.env`
- `<skill-root>/.env.pl`

This means a deeper skill env can override a shared runtime key, but that
override stays isolated to the skill execution path and does not leak into
unrelated commands.

For nested skill commands such as `dashboard foo.bar.zzz.show`, the skill env
chain expands from the root nested skill to the leaf skill before the command
runs:

- `skills/foo/.env`
- `skills/foo/skills/bar/.env`
- `skills/foo/skills/bar/skills/zzz/.env`

If a deeper nested skill overrides the same key, the parent value is preserved
under that parent skill alias before the deeper skill replaces the plain key.
For example, if all three nested skills assign `VERSION`, the leaf command
sees `VERSION` from `zzz`, `foo_VERSION` from `foo`, and
`foo_bar_VERSION` from `foo.bar`.

The Docker Compose resolver also loads `<skill-root>/.env` for each installed
skill whose `config/docker/<service>/compose.yml` or
`config/docker/<service>/development.compose.yml` file actually participates in
the resolved compose stack. That compose-only skill env layer stays isolated to
the compose resolver, respects disabled skills, and does not execute
`<skill-root>/.env.pl`. Nested skill compose services use that same
root-to-leaf env expansion, so a participating leaf service such as
`skills/foo/skills/bar/skills/zzz/config/docker/zzz/compose.yml` loads the
env chain from `foo` to `foo.bar` to `foo.bar.zzz` and preserves parent
overrides under aliases such as `foo_VERSION` and `foo_bar_VERSION`.

Perl code can inspect where a dashboard-managed env key came from with
`Developer::Dashboard::EnvAudit`.

Single-key lookup:

    use Developer::Dashboard::EnvAudit;

    my $entry = Developer::Dashboard::EnvAudit->key('FOO');

That returns either `undef` for normal system env keys or a hashref like:

    {
        value   => 'bar',
        envfile => '/full/path/to/.env',
    }

Full inventory lookup:

    my $all = Developer::Dashboard::EnvAudit->keys;

The audit records only dashboard-loaded env keys. System-provided keys that
did not come from a dashboard-managed `.env` or `.env.pl` file are left
untracked on purpose.

For example, a layered `.env` file can now look like:

    # root defaults
    ROOT_CACHE=~/cache
    API_BASE=https://example.test
    TOKEN=${ACCESS_TOKEN:-anonymous}
    MESSAGE=${Local::Env::Helper::message():-hello}

    /*
    child layers can still override
    any value later in the root-to-leaf chain
    */
    CHAINED=$ROOT_CACHE/$TOKEN

## Open File Commands

`dashboard of` is the shorthand name for `dashboard open-file`.

These commands support:

- direct file paths
- `file:line` references
- Perl module names such as `My::Module`
- Java class names such as `com.example.App` or `javax.jws.WebService`
- recursive regex searches inside a resolved directory alias or path

Without `--print`, `dashboard of` and `dashboard open-file` now behave like
the older picker workflow again: one unique match opens directly in
`--editor`, `VISUAL`, `EDITOR`, or `vim` as the final fallback, and
multiple matches render a numbered prompt. At that prompt you can press Enter
to open all matches with `vim -p`, type one number to open one file, type comma-separated
numbers such as `1,3`, or use a range such as `2-5`. Scoped searches also
rank exact helper/script names before broader regex hits, so
`dashboard of . jq` lists `jq` and `jq.js` ahead of `jquery.js`. Every
scoped search token is treated as a case-insensitive regex, so
`dashboard of . 'Ok\.js$'` matches `ok.js` but not `ok.json`.

Java class lookup first checks live `.java` files under the current project,
workspace roots, and `@INC`-adjacent source trees. If no live source file
exists, it also searches local source archives such as `-sources.jar`,
`-src.jar`, `src.zip`, `war`, and `jar` files under the current roots,
`~/.m2/repository`, Gradle caches, and `JAVA_HOME`. When a local archive
still does not provide the requested class, the helper can fetch a matching
Maven source jar, cache it under
`~/.developer-dashboard/cache/open-file/`, and then open the extracted Java
source.

## Data Query Commands

These built-in commands parse structured text and can then either extract a
dotted path or evaluate a Perl expression against the decoded document through
`$d`:

- `dashboard jq [path] [file]` for JSON
- `dashboard yq [path] [file]` for YAML
- `dashboard tomq [path] [file]` for TOML
- `dashboard propq [path] [file]` for Java properties

If the selected value is a hash or array, the command prints canonical JSON.
If the selected value is a scalar, it prints the scalar plus a trailing
newline.

The file path and query text are order-independent, and `$d` selects the
whole parsed document. For example, `cat file.json | dashboard jq '$d'` and
`dashboard jq file.json '$d'` return the same result. If the query text uses
`$d` inside a Perl expression, the command evaluates that expression against
the decoded document. For example, `echo '{"foo":[1],"bar":[2]}' | dashboard
jq 'sort keys %$d'` prints `["bar","foo"]`. The same contract applies to
`yq`, `tomq`, `propq`, `iniq`, `csvq`, and `xmlq`.

`xmlq` follows the same decoded-data model as the other query commands. XML
elements decode into nested hashes and arrays, repeated sibling tags become
arrays, attributes live under `_attributes`, and mixed text lives under
`_text`. That means `printf '<root`&lt;value>demo&lt;/value>&lt;/root>' | dashboard
xmlq root.value> prints `demo`, while `dashboard xmlq feed.xml '$d'` prints
the full decoded XML tree as canonical JSON.

# MANUAL

## Installation

Bootstrap a blank Alpine, Debian, Ubuntu, Fedora, or macOS machine from a checkout with:

    ./install.sh

Bootstrap a blank Windows PowerShell host from a checkout or the current shell with:

    powershell -ExecutionPolicy Bypass -File .\install.ps1
    irm https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.ps1 | iex

`install.sh` and `install.ps1` are checkout-only bootstrap helpers. They ship
in the source tree and release tarball so operators can run them explicitly
from a checkout, extracted tarball, or streamed bootstrap, but CPAN and
`cpanm` do not install them as global commands. When the Unix-like installer
is streamed through `sh` without a checkout, such as `curl ... | sh`, it
falls back to embedded Debian-family, Alpine, Fedora, and Homebrew package
manifests instead of assuming repo-local `aptfile`, `apkfile`, `dnfile`,
and `brewfile` files exist on disk, then clones the current GitHub
`master` checkout into a temporary local tree and installs that checkout so
the streamed bootstrap gets the same implementation snapshot that shipped the
installer instead of a stale CPAN release.

That installer reads the repo-root `aptfile` on Debian-family hosts and runs
`apt-get update` plus `apt-get install -y` for the listed packages, reads
the repo-root `apkfile` on Alpine hosts and runs
`apk add --no-cache` for the listed packages, reads the repo-root
`dnfile` on Fedora hosts and runs `dnf install -y` for the listed
packages, reads the repo-root
`brewfile` on macOS and runs `brew install` for the listed packages,
ships `tmux` in every one of those bootstrap package lists because
`dashboard workspace` is a first-party tmux workflow, verifies that `node`,
`npm`, and `npx` are available from those
bootstrap packages before finishing the install, or falls back to the embedded
copies of those package lists when the script is streamed without the checkout
files, installs Debian-family Node tooling in a conflict-aware order by
bringing in `nodejs` first and only attempting the distro `npm` package if
`npm` and `npx` are still missing, prints a visible install progress board
before doing any system changes, prints that full checklist once and then only
emits step transitions so the active pointer does not appear duplicated in
interactive terminals, explains that any upcoming `sudo` prompt is asking for
the user's operating-system account password only for package-manager work,
bootstraps Homebrew itself on blank macOS hosts before it tries to read the
repo-root `brewfile`, updates `PATH` from the discovered Homebrew prefix so
the same run can immediately install the listed macOS packages without asking
the operator to reopen the shell,
bootstraps user-space Perl
tooling under `~/perl5` with
`cpanm --no-wget --notest --local-lib-contained "$HOME/perl5" local::lib App::cpanminus File::ShareDir::Install`,
appends exactly one `local::lib` bootstrap line to `~/.bashrc`,
`~/.zshrc`, or `~/.profile` depending on the preferred login shell even
when the installer is run through plain `sh`, keeps bash login shells wired
by bridging `~/.profile` to `~/.bashrc`, prefers
Homebrew Perl on macOS when `brew --prefix perl` exposes a brewed
interpreter, bootstraps a user-space `perlbrew` Perl on Debian-family,
Alpine, or Fedora hosts when the system Perl is older than the required
`5.38`, installs `App::perlbrew` into `~/perl5/bin` first if the package manager did not
already put `perlbrew` on `PATH`, keeps that local `perlbrew` and
`patchperl` toolchain pinned to the private `~/perl5/lib/perl5` include path
while the rescue build runs, fetches the `App::perlbrew` tarball with
`curl` before the local install so Alpine does not emit the noisy
`IO::Socket::IP` warning during that bootstrap step, uses
`perlbrew --notest install perl-5.38.5` so blank-machine bootstrap does not
stall in upstream Perl core test failures, updates the selected shell rc file
itself with the needed `PERLBREW_HOME` and rescue-Perl `PATH` lines instead
of leaving a manual `~/.profile` editing step behind or sourcing perlbrew's
bash-only startup file under generic `sh`, appends the matching
`eval "$(".../dashboard" shell bash|zsh|sh)"` bootstrap so `d2`, prompt
integration, and completion come up automatically in future shells, re-enters
an activated shell automatically at the end of a terminal-backed streamed
install so `dashboard`, `d2`, prompt integration, and completion are live
immediately instead of leaving the user at a dead prompt, falls back to
printing the exact shell file it updated plus the exact `. "<rc-file`">
command the user should run only when the installer cannot safely take over a
terminal, never probes `/dev/tty` during a piped `curl ... | sh` run so
non-interactive installs stay quiet, installs Developer Dashboard into the user
account with `cpanm --no-wget --notest .` when the installer is running from a
checkout or extracted tarball, and uses that same `cpanm --no-wget --notest .`
flow against a temporary cloned checkout when the Unix-like bootstrap had to
clone GitHub `master` for a streamed install. That bootstrap now seeds
`File::ShareDir::Install` into `~/perl5` before the checkout install step so
`Makefile.PL` can refresh the shipped share tree even on a blank Ubuntu host,
and then runs `dashboard init` so the runtime exists immediately after
installation.

On Windows PowerShell hosts, `install.ps1` uses `winget` to install missing
Git, Strawberry Perl, and Node.js LTS packages, pins those installs to the
community `winget` source so a broken `msstore` source does not block the
bootstrap, resets and refreshes the source catalog once before retrying when a
`winget` source failure still occurs, downloads `cpanm` from
`https://cpanmin.us/`, bootstraps `local::lib` into the private
`~/perl5` tree with that standalone script together with
`File::ShareDir::Install`, installs Developer Dashboard with `cpanm --notest`,
sets the CurrentUser PowerShell execution policy to
`RemoteSigned` when it is still too restrictive to load profile scripts,
updates the current-user PowerShell profile with a self-contained
private `~/perl5` PATH and Perl environment block plus
`dashboard shell ps`, runs `dashboard init` first so the home helper runtime
exists, and then activates that PowerShell bootstrap in the current shell when
possible. Future PowerShell sessions do not rely on installer-only helper
functions while loading that generated profile block. The generated bash, zsh,
POSIX sh, and PowerShell shell bootstraps all follow the same tmux-aware
prompt rule: when the shell starts inside a `dashboard workspace` tmux session
that carries `DEVELOPER_DASHBOARD_TMUX_STATUS=1`, indicator glyphs move to
the first row of that session's two-line bottom tmux status block, while the
second row keeps tmux's normal session and indexed window list. The inline
prompt suppresses indicator fragments with `dashboard ps1 --no-indicators`.
Ordinary tmux sessions keep the normal inline prompt. Developer Dashboard
does not edit the user's tmux config file to provide that behavior, and it
uses session-local tmux options
instead of changing the whole tmux server. Those dashboard-managed tmux
sessions also refresh the status block at a 15-second cadence instead of a
hot 2-second loop.
When helper staging reruns during upgrades, the managed home runtime also
removes dashboard-owned older flat helper files from
`~/.developer-dashboard/cli/` so the public command and shell bootstrap
always converge on the current `~/.developer-dashboard/cli/dd/` helper
generation instead of silently reusing stale wrappers from older releases.
The Windows bootstrap
does not try to self-install `App::cpanminus` while the downloaded
`cpanm` bootstrap script is still running, which avoids the Windows file
replacement failure that can break streamed `irm .../install.ps1 | iex`
installs. The shipped distribution metadata also keeps `Plack::Test` and
`Test::Pod` out of the end-user install prerequisite path so blank Windows
hosts do not have to pull the `Test::SharedFork` dependency chain during the
bootstrap. The Windows bootstrap target stays literal: when
`DD_INSTALL_CPAN_TARGET` is set, `install.ps1` passes that exact value
through to `cpanm --notest` instead of trying to reinterpret it. When that
override is unset in the streamed `irm .../install.ps1 | iex` path,
`install.ps1` clones the current GitHub `master` checkout into a temporary
local tree and installs that local checkout so the bootstrap installs the same
snapshot that shipped the installer instead of an older CPAN release. The
Windows smoke gate also proves that a brand-new profile-loaded PowerShell
session can resolve `dashboard`, print `dashboard version`, run
`dashboard logs`, run `dashboard restart`, and install at least one real
skill after that streamed bootstrap completes. The generated PowerShell shell
bootstrap now forces UTF-8 console input and output encoding before it returns
the multi-line prompt from `dashboard ps1`, so the prompt keeps the trailing
command marker on the next line and preserves indicator plus branch glyphs
such as heartbeat status and the trailing `🌿branch` fragment in normal
Windows terminals.

Useful bootstrap examples:

    ./install.sh
    SHELL=/bin/zsh ./install.sh
    DD_INSTALL_CPAN_TARGET=./Developer-Dashboard-X.XX.tar.gz ./install.sh
    curl https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.sh | sh
    powershell -ExecutionPolicy Bypass -File .\install.ps1
    $env:DD_INSTALL_CPAN_TARGET = '.\Developer-Dashboard-X.XX.tar.gz'; irm https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.ps1 | iex

Install from CPAN with:

    cpanm --no-wget --notest Developer::Dashboard

Or install from a checkout with:

    perl Makefile.PL
    make
    make test
    make install

## Local Development

Build the distribution:

    rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
    dzil build

The release gather rules exclude local coverage output such as `cover_db`, so
covered runs before `dzil build` do not leak Devel::Cover artifacts into the
shipped tarball.
Release hygiene now also requires that this cleanup leaves exactly one
unpacked `Developer-Dashboard-X.XX/` build directory and exactly one matching
`Developer-Dashboard-X.XX.tar.gz` artifact after the build.
The built distribution also ships a plain `README` companion so CPAN and
kwalitee consumers still receive a top-level readme without re-including the
checkout-only documentation set.

Run the CLI directly from the repository:

    perl -Ilib bin/dashboard init
    perl -Ilib bin/dashboard auth add-user <username> <password>
    perl -Ilib bin/dashboard version
    perl -Ilib bin/dashboard of --print My::Module
    perl -Ilib bin/dashboard open-file --print com.example.App
    printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard jq alpha.beta
    printf 'alpha:\n  beta: 3\n' | perl -Ilib bin/dashboard yq alpha.beta
    mkdir -p ~/.developer-dashboard/cli/update.d
    printf '#!/usr/bin/env perl\nuse Developer::Dashboard::Runtime::Result;\nprint Developer::Dashboard::Runtime::Result::stdout(q{01-runtime});\nprint $ENV{RESULT} // q{}\n' > ~/.developer-dashboard/cli/update
    chmod +x ~/.developer-dashboard/cli/update
    printf '#!/bin/sh\necho runtime-update\n' > ~/.developer-dashboard/cli/update.d/01-runtime
    chmod +x ~/.developer-dashboard/cli/update.d/01-runtime
    perl -Ilib bin/dashboard update
    perl -Ilib bin/dashboard serve
    perl -Ilib bin/dashboard stop
    perl -Ilib bin/dashboard restart

User CLI extensions can be tested from the repository too:

    mkdir -p ~/.developer-dashboard/cli
    printf '#!/bin/sh\ncat\n' > ~/.developer-dashboard/cli/foobar
    chmod +x ~/.developer-dashboard/cli/foobar
    printf 'hello\n' | perl -Ilib bin/dashboard foobar

    mkdir -p ~/.developer-dashboard/cli/jq.d
    printf '#!/usr/bin/env perl\nprint "seed\\n";\n' > ~/.developer-dashboard/cli/jq.d/00-seed.pl
    chmod +x ~/.developer-dashboard/cli/jq.d/00-seed.pl
    printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard jq alpha.beta

Dashboard-managed built-in helpers are different from user commands. All
built-in helper assets are always staged only under
`~/.developer-dashboard/cli/dd/`. Dedicated helper bodies are used for
`jq`, `yq`, `tomq`, `propq`, `iniq`, `csvq`, `xmlq`, `of`,
`open-file`, `ticket`, `path`, `paths`, and `ps1`, while the remaining
built-in commands stage thin wrappers that delegate into the shared private
`_dashboard-core` runtime. Under `DD-OOP-LAYERS`, layered lookup still
applies to user-provided commands and hook directories, but `dashboard init`
does not copy those built-in helpers into child project layers.

Each top-level dashboard command can also use an optional hook directory at
`~/.developer-dashboard/cli/<command>`. Executable files from that
directory run in sorted filename order before the real command starts,
non-executable files are skipped, and the captured stdout/stderr from the hook
files are accumulated into `$ENV{RESULT}` as JSON for later hooks and the
final command. Directory-backed custom commands can use
`~/.developer-dashboard/cli/<command>/run` as the actual executable.
If a subcommand does not have a built-in implementation, the real command can
be supplied as `~/.developer-dashboard/cli/<command>` or
`~/.developer-dashboard/cli/<command>/run`.

If you want `dashboard update`, provide it as a normal user command at
`~/.developer-dashboard/cli/update` or
`~/.developer-dashboard/cli/update/run` in any inherited layer, with the
deepest matching layer winning the final command path. Its hook files can live
under `update/` or `update.d`, and the real command receives the final
`RESULT` and `LAST_RESULT` payloads through the environment after those hook
files run. Each later hook also sees the latest rewritten `RESULT` from the
earlier hook set, the immediate previous hook through `LAST_RESULT`, and an
explicit `[[STOP]]` marker in one hook's `stderr` skips the remaining hook
files before control returns to the real update command. Perl code can read
those payloads through `Runtime::Result`.

Use `dashboard version` to print the installed Developer Dashboard version.

The blank-container integration harness applies fake-project dashboard override
environment variables only after `cpanm --notest` finishes installing the
tarball so the source-tree test and coverage gates stay responsible for full
distribution test execution while the later blank-container path verifies
packaged dependency resolution and installed runtime behavior.
That same blank-container path now also verifies web stop/restart behavior in a
minimal image where listener ownership may need to be discovered from `/proc`
instead of `ss`, including a late listener re-probe before
`dashboard restart` brings the web service back up.

## First Run

Initialize the runtime:

    dashboard init

Inspect resolved paths:

    dashboard paths
    dashboard path resolve bookmarks_root
    dashboard path add foobar /tmp/foobar
    dashboard path add .
    dashboard path del foobar
    dashboard path rm foobar
    dashboard files
    dashboard file add notes ~/notes.txt
    dashboard file resolve notes
    dashboard file del notes
    dashboard which jq
    dashboard which layered-tool
    dashboard which nest.level1.level2.here
    dashboard which --edit jq

Custom path aliases are stored in the effective dashboard config root so shell
helpers such as `cdr foobar` and `which_dir foobar` keep working across
sessions. When a project-local `./.developer-dashboard` tree exists, alias
writes go there first; otherwise they go to the home runtime. Under
`DD-OOP-LAYERS`, that write stays local to the deepest participating layer:
adding one child-layer alias does not copy inherited parent `config.json`
domains into the child file. The child layer keeps only its own new delta and
still inherits the rest from home and parent layers at read time. When an
alias points inside the current home directory, the stored config uses
`$HOME/...` instead of a hard-coded absolute home path so a shared fallback
runtime remains portable across different developer accounts. Re-adding an
existing alias updates it without error, and deleting a missing alias is also
safe.

`cdr` now follows a two-stage path flow instead of only jumping to one alias
or one top-level project name. If the first argument resolves as a saved alias
and there are no later arguments, `cdr alias` still goes straight there. If
the first argument resolves as a saved alias and more arguments remain,
`cdr` enters the alias root, then searches every directory under that root
with AND-matched regex keywords taken from the remaining arguments. One match
means `cd` into that directory; multiple matches mean print the full list and
stay at the alias root. If the first argument is not a saved alias, `cdr`
treats every argument as an AND-matched regex search beneath the current
directory. One match means `cd` there; multiple matches mean print the list
and leave the current directory unchanged. `which_dir` follows the same
selection logic but only prints the chosen target or match list instead of
changing directory. Unreadable subdirectories are skipped explicitly during
that search so one protected tree does not abort the whole lookup.

Both `cdr` and `which_dir` therefore use regex narrowing arguments, not
quoted substring tokens.

Examples:

    cdr foobar
    cdr foobar alpha foo bar
    cdr foobar 'alpha-foo$'
    cdr alpha red
    which_dir foobar alpha

Use `Developer::Dashboard::Folder` for runtime path helpers. It resolves the
same runtime, bookmark, config, and configured alias names exposed by
`dashboard paths`, and therefore backs the same folder-oriented flow that
`cdr` and `which_dir` use, including names such as `docker`, without relying on
unscoped CPAN-global module names.

`dashboard path add .` saves the current working directory under its basename.
`dashboard path add <name> .` uses the current working directory as the
target for an explicit alias. `dashboard path del .` and `dashboard path rm .`
remove the alias that points at the current working directory instead of
treating `.` as a literal error token.

Use `Developer::Dashboard::File` for runtime file helpers. It resolves the
same built-in and config-backed file aliases exposed by `dashboard files` and
`dashboard file list`, supports direct reads and writes through one public
wrapper, and keeps file alias behavior parallel with the folder/path contract.
It is the file-side twin of the existing Folder contract in the same way that
`dashboard of` and `dashboard open-file` are the file-side twins of
`cdr` and `which_dir`.

If you need the whole `dashboard paths` payload in Perl, call
`Developer::Dashboard::Folder->all` or
`Developer::Dashboard::PathRegistry->all_paths` instead of rebuilding the
hash by hand. If you need a fresh path registry object from that public Folder
inventory, call `Developer::Dashboard::PathRegistry->new_from_all_folders`.
If you need a collector store from the same Folder-derived runtime roots, call
`Developer::Dashboard::Collector->new_from_all_folders`.
If you need the whole `dashboard files` payload in Perl, call
`Developer::Dashboard::File->all` or
`Developer::Dashboard::FileRegistry->all_files` instead of rebuilding the
hash by hand.

File aliases follow the same effective-config write rules as path aliases.
`dashboard file add <name> <path>` writes to the deepest
participating config layer, keeps `$HOME/...` storage portable when the
target lives under the current home directory, updates existing aliases
idempotently, and lets `dashboard file resolve <name>`,
`dashboard of <name>`, or
`Developer::Dashboard::File->resolve($name)` read that alias back later.
When the alias name is a valid Perl method token,
`Developer::Dashboard::File->$name()` also works directly. When the alias
is numeric such as `123`, use a scalar method name like
`my $name = 123; Developer::Dashboard::File->$name()` because bare
`->123` is not valid Perl syntax. `dashboard files` prints the full
built-in plus configured file inventory, while `dashboard file list` prints
only the named configured file aliases.

`dashboard of` and `dashboard open-file` now treat configured file aliases
as direct file targets before they fall back to Perl-module, Java-class, or
regex search behavior. If the first token resolves as a saved path alias and
the remaining tokens join into one existing relative file path inside that
aliased directory, `dashboard of <path-alias> <relative-file>`
opens that exact file instead of treating the remaining tokens as regex
patterns. That means flows such as
`dashboard file add 123 /tmp/123.txt` followed by `dashboard of 123`, or
`dashboard path add foobar .` followed by `dashboard of foobar 456.txt`, now
resolve the exact configured or scoped file target directly.

The hashed `state_root`, `collectors_root`, `indicators_root`, and
`sessions_root` paths live under the shared temp state tree, not inside the
layered runtime config tree. If a reboot or temp cleanup removes one of those
hashed state roots, the path registry recreates it automatically the next time
dashboard code resolves the path and rewrites the matching `runtime.json`
metadata file before collectors, indicators, or sessions use it again.

Use `dashboard which <target>` to inspect what `dashboard` would
execute before you run it. The command prints one
`COMMAND /full/path` line for the resolved file and then one
`HOOK /full/path` line for each participating hook in runtime execution
order. That works for built-in helpers such as `jq`, layered custom commands
such as `layered-tool`, single-level skill commands such as
`example-skill.somecmd`, and multi-level nested skill commands such as
`nest.level1.level2.here`. If you add `--edit`, `dashboard which` skips the
inspection output and re-enters `dashboard open-file` with the resolved
command file path so the normal editor-selection behavior is reused.

Render shell bootstrap for bash, zsh, POSIX sh, or PowerShell:

    dashboard shell bash
    dashboard shell zsh
    dashboard shell sh
    dashboard shell ps

The generated zsh bootstrap now loads `compinit` before any `compdef`
registration, so a fresh macOS zsh shell can evaluate it without raising
`command not found: compdef`.

Audit runtime permissions:

    dashboard doctor
    dashboard doctor --fix

The doctor command also checks staged helper drift under
`~/.developer-dashboard/cli/dd/` and repairs dashboard-managed helper content
with `--fix` when the installed helper assets are current. On Debian-family
bash hosts it also repairs dashboard-managed shell bootstrap lines that were
previously appended after the non-interactive `return` guard in
`~/.bashrc`.

Resolve or open files from the CLI:

    dashboard of --print My::Module
    dashboard open-file --print com.example.App
    dashboard open-file --print javax.jws.WebService
    dashboard of --print notes
    dashboard of --print . 'Ok\.js$'
    dashboard of --print foobar 456.txt
    dashboard open-file --print path/to/file.txt
    dashboard open-file --print bookmarks index

Query structured files from the CLI:

    printf '{"alpha":{"beta":2}}' | dashboard jq alpha.beta
    printf 'alpha:\n  beta: 3\n' | dashboard yq alpha.beta
    printf '[alpha]\nbeta = 4\n' | dashboard tomq alpha.beta
    printf 'alpha.beta=5\n' | dashboard propq alpha.beta
    dashboard jq file.json '$d'

Start the local app:

    dashboard serve

Open the root path with no bookmark path to get the free-form bookmark editor directly. If you start the web service with `dashboard serve --no-editor` or `dashboard serve --no-endit`, the browser stays read-only instead and direct editor/source routes are blocked. If you start it with `dashboard serve --no-indicators` or `dashboard serve --no-indicator`, the right-top browser chrome is cleared while normal page rendering still works.

Stop the local app and collector loops:

    dashboard stop

Interactive terminal runs now print a task board on `stderr` first, then
mark each stop step as it finishes so the command does not appear hung while
the runtime waits for managed shutdown.

Restart the local app and configured collector loops:

    dashboard restart

Interactive terminal runs now print the full restart task board on `stderr`,
mark the active step with a blue `-`, stream active detail lines in blue,
mark completed steps with a green `[OK]`, mark failed steps with a red
`[X]` plus red failure detail lines, and keep the final JSON result on
`stdout`. Stop and restart shutdown paths send numeric POSIX signals instead
of named signal strings, so minimal Alpine/iSH Perl builds that reject `TERM`
by name still terminate managed web and collector processes correctly.

Create a helper login user:

    dashboard auth add-user <username> <password>

Remove a helper login user:

    dashboard auth remove-user helper

Helper sessions show a Logout link in the page chrome. Logging out removes both
the helper session and that helper account. Helper page views also show the
helper username in the top-right chrome instead of the local system account.
Exact-loopback admin requests do not show a Logout link.

## Managing API Keys For Saved Ajax Routes

List the effective machine-auth API registry:

    dashboard api
    dashboard api ls
    dashboard api ls --key helper-bot
    dashboard api ls --key helper-bot -o json

Create or update one API group from a raw secret:

    dashboard api add --key helper-bot --secret raw-secret
    dashboard api add --key helper-bot --secret rotated-secret
    dashboard api add --key helper-bot --secret raw-secret --route /ajax/health --route /ajax/healthz
    dashboard api add --key helper-bot --maybe-secret raw-secret --route /ajax/health --route /ajax/healthz

Add one exact saved Ajax route to an existing API group:

    dashboard api add --key helper-bot --route /ajax/health
    dashboard api add --key helper-bot --route /ajax/healthz

Remove one route or remove the whole API group:

    dashboard api rm --key helper-bot --route /ajax/healthz
    dashboard api rm --key helper-bot

The `dashboard api` command manages the deepest writable runtime
`config/api.json` layer under `DD-OOP-LAYERS`. Listing shows the effective
merged registry from home through the active child layer together with any
installed-skill API fragments that contribute saved Ajax machine auth. Updates
never rewrite installed skill files; they only change the writable runtime
layer for the current working context.

When you pass `--secret`, the raw secret is hashed to a SHA-256 hex digest
before it is stored. `--maybe-secret` is the route-friendly alias for the
same raw secret input: if the key is missing it creates the group, and if the
key already exists it overwrites the stored secret while the command updates
the requested routes. The saved JSON keeps the digest under `secret` plus the
exact allowed saved Ajax routes under `ajax`. `dashboard api add` accepts
one or more repeated `--route` flags, so one command can create the key,
hash the secret, and register multiple exact routes at once. Adding the same
route twice is a no-op. Removing an inherited API group from a deeper child
layer writes a child-layer tombstone so the parent definition is hidden
without editing the parent file.

## Working With Pages

Create a starter page document:

    dashboard page new sample "Sample Page"

Save a page:

    dashboard page new sample "Sample Page" | dashboard page save sample

List saved pages:

    dashboard page list

Render a saved page:

    dashboard page render sample

`dashboard page render` now uses the same page-runtime preparation path as
the browser route, so saved bookmark TT such as `[% title %]` and
`[% stash.foo %]` is rendered there too instead of only working under
`/app/<id>`.

Encode and decode transient pages:

    dashboard page show sample | dashboard page encode
    dashboard page show sample | dashboard page encode | dashboard page decode

Run a page action:

    dashboard action run system-status paths

Bookmark documents use the original separator-line format with directive
headers such as `TITLE:`, `STASH:`, `HTML:`, and `CODE1:`.

Posting a bookmark document with `BOOKMARK: some-id` back through the root
editor now saves it to the bookmark store so `/app/some-id` resolves it
immediately.

The browser editor now renders syntax-highlight markup again, but keeps that
highlight layer inside a clipped overlay viewport that follows the real
textarea scroll position by transform instead of via a second scrollbox.
That restores the visible highlighting while keeping long bookmark lines,
full-text selection, and caret placement aligned with the real textarea.
When you type `:---` on its own line, the editor also expands it to the full
separator line automatically and seeds the next sensible unique directive,
moving from `TITLE:` to `HTML:` and then on to the next available
`CODE<N>:` section so the common bookmark-writing flow stays fast and
brainless.

Edit and source views preserve raw Template Toolkit placeholders inside
`HTML:` sections, so values such as `[% title %]` are kept in the bookmark
source instead of being rewritten to rendered HTML after a browser save.
Template Toolkit rendering exposes the page title as `title`, so a bookmark
with `TITLE: Sample Dashboard` can reference it directly inside `HTML:`
with `[% title %]`. Transient play and view-source links are also encoded
from the raw bookmark instruction text when it is available, so
`[% stash.foo %]` stays in source views instead of being baked into the
rendered scalar value after a render pass.

Earlier `CODE*` blocks now run before Template Toolkit rendering during
`prepare_page`, so a block such as `CODE1: { a =` 1 }> can feed
`[% stash.a %]` in the page body. Returned hash and array values are also
dumped into the runtime output area, so `CODE1: { a =` 1 }> both populates
stash and shows the bookmark-style dumped value below the rendered page body.
The `hide` helper no longer discards already-printed STDOUT, so
`CODE2: hide print $a` keeps the printed value while suppressing the Perl
return value from affecting later merge logic.

Page `TITLE:` values only populate the HTML `<title>` element. If a
bookmark should show its title in the page body, add it explicitly inside
`HTML:`, for example with `[% title %]`.

`/apps` redirects to `/app/index`, and `/app/<name>` can load
either a saved bookmark document or a saved ajax/url bookmark file.

## Working With Collectors

Ensure the home config file exists without seeding collectors:

    dashboard config init

If `config/config.json` is missing, that command creates it as:

    {}

It does not inject an example collector, and if the file already exists it is
left untouched.

List collector status:

    dashboard collector list
    dashboard collector status shell.example

Inspect collector logs:

    dashboard collector log
    dashboard collector log shell.example

`dashboard collector log` prints the known collector log streams.
`dashboard collector log <name>` prints one collector transcript.
If a configured collector has not run yet, the command prints an explicit
no-log message instead of blank output.
`dashboard collector status <name>` now also exposes watchdog
metadata for managed loops, including `watchdog_restart_count`,
`watchdog_last_unexpected_stop_at`, `watchdog_last_restart_at`, and
`watchdog_attention_required`, so repeated collector crashes are visible
instead of looking like silent disappearance.
Collector status timestamps and collector log headers use the machine's local
system time with an explicit numeric timezone offset such as `+0100`, so the
visible timestamps line up with cron scheduling on the same machine instead of
looking one hour behind during daylight-saving transitions.

Collector jobs support two execution fields:

- `command` runs a shell command string through the native platform shell:
`sh -lc` on Unix-like systems and PowerShell on Windows
- `code` runs Perl code directly inside the collector runtime

The built-in `housekeeper` collector is always present even when
`config/config.json` is otherwise empty. It runs every `900` seconds with
Perl `code` instead of a shell command, so it does not depend on `PATH`
resolution. That collector removes stale hashed runtime state roots from the
shared temp tree under `/tmp/<user>/developer-dashboard/state/` and
removes older `developer-dashboard-ajax-*` temp files plus
`dashboard-result-*` runtime result temp files left behind in `/tmp/`. It
also rotates collector log transcripts when a collector defines `rotation`
or `rotations`. `lines` keeps the trailing line count, while `minute`,
`minutes`, `hour`, `hours`, `day`, `days`, `week`, `weeks`,
`month`, and `months` keep only log entries newer than the requested
retention window. Run it on demand with:

    dashboard housekeeper
    dashboard collector run housekeeper

If you need different cadence or behavior, define your own collector named
`housekeeper` in config. That override now inherits the built-in `code` and
`cwd` defaults, so changing only `interval` or adding `indicator`
metadata is enough:

    {
      "collectors": [
        {
          "name": "housekeeper",
          "interval": 60,
          "indicator": {
            "icon": "🧹"
          }
        }
      ]
    }

Example collector definitions:

    {
      "collectors": [
        {
          "name": "shell.example",
          "command": "printf 'shell collector\n'",
          "cwd": "home",
          "interval": 60
        },
        {
          "name": "perl.example",
          "code": "print qq(perl collector\n); return 0;",
          "cwd": "home",
          "interval": 60,
          "indicator": {
            "icon": "P"
          }
        },
        {
          "name": "foobar",
          "command": "./foobar",
          "cwd": "home",
          "interval": 10,
          "mode": "multiple",
          "multiple": 3,
          "rotation": {
            "lines": 100,
            "days": 1
          },
          "indicator": {
            "name": "foobar.indicator",
            "label": "Foobar",
            "icon": "[% a %]"
          }
        }
      ]
    }

Collector concurrency defaults are explicit:

- When `mode` is omitted, the collector runs in `singleton` mode.
- In `singleton` mode, the scheduler skips a due run while an older run of the
same collector is still active.
- In `multiple` mode, the scheduler still starts due runs while older runs are
active, but only until `multiple` active runs are already in flight.
- When `mode` is `multiple` and `multiple` is omitted, the runtime uses
`2`.
- Collectors whose `command` re-enters `dashboard` or `d2` through a shell
path now have a safety floor of `30` seconds even if config asks for a
smaller interval, because those recursive dashboard collectors are materially
heavier than direct shell probes. Set `allow_fast_poll` or
`allow_fast_dashboard_poll` on that collector, or set
`DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS`, when the faster
cadence is intentional and understood.
- When a collector sets `disable => 1` or `"disable": true`, dashboard
will not start that collector, explicit named starts reject it, and any
already-running managed loop for that collector is stopped during the next
collector lifecycle action. Managed indicator state for that collector is
also removed instead of lingering as if it were still active.
- Stopping a singleton collector loop also terminates the long-running command
currently owned by that loop, so `dashboard stop collector foo` does not leave
the old worker command alive behind the stopped dispatcher.

Collector indicators follow the collector exit code automatically: `0`
stores an `ok` indicator state and any non-zero exit code stores `error`.
When `indicator.name` is omitted, the collector name is reused
automatically. When `indicator.label` is omitted, it defaults to that same
name. Configured collector indicators are seeded immediately, so prompt and
page status strips show them before the first collector run. Before a
collector has produced real output it appears as missing. Prompt output
renders an explicit status glyph in front of the collector icon, so
successful checks show fragments such as `✅🔑` while failing or not-yet-run
checks show fragments such as `🚨🔑`.
Under `DD-OOP-LAYERS`, a deeper child layer no longer pins an inherited
collector indicator at that default `missing` placeholder just because the
child runtime has its own `.developer-dashboard/` folder. If the child layer
does not override that collector config and only has the placeholder state,
dashboard now falls back to the nearest inherited real collector state such
as a parent-layer `ok` result instead of turning the same indicator red.
The top-right browser status strip now uses that same configured icon instead
of falling back to the collector name, and stale managed indicators are
removed automatically if the collector config is renamed. The browser chrome
now uses an emoji-capable font stack there as well, so UTF-8 icons such as
`🐳` and `💰` remain visible instead of collapsing into fallback boxes.
For TT-backed collector icons, a collector such as `./foobar` can print
`{"a":123}` on `stdout`; the runner decodes that JSON into Perl data and
renders `[% a %]` into the live icon `123`. Later config-sync passes keep
the configured `icon_template` metadata and the already-rendered live
`icon`, so commands such as `dashboard indicator list` and `dashboard ps1`
do not revert the persisted icon back to raw `[% ... %]` text between runs.
The blank-environment integration flow also keeps a regression for mixed
collector health: one intentionally broken Perl collector must stay red
without stopping a second healthy collector from staying green in
`dashboard indicator list`, `dashboard ps1`, and `/system/status`.

## Docker Compose

Inspect the resolved compose stack without running Docker:

    dashboard docker compose --dry-run config

Include addons or modes:

    dashboard docker compose --addon mailhog --mode dev up -d
    dashboard docker compose config green
    dashboard docker compose config
    dashboard docker list
    dashboard docker list --disabled
    dashboard docker list --enabled
    dashboard docker disable green
    dashboard docker enable green

The resolver also supports old-style isolated service folders without adding
entries to dashboard JSON config. If
`./.developer-dashboard/docker/green/compose.yml` exists in the current
project it wins; otherwise the resolver falls back to
`~/.developer-dashboard/config/docker/green/compose.yml`.
`dashboard docker compose config green` or
`dashboard docker compose up green` will pick it up automatically by
inferring service names from the passthrough compose args before the real
`docker compose` command is assembled. If no service name is passed, the
resolver scans isolated service folders and preloads every non-disabled folder.
If a folder contains `disabled.yml` it is skipped. Each isolated folder
contributes `development.compose.yml` when present, otherwise `compose.yml`.
To toggle that marker without creating or deleting the file manually, use
`dashboard docker disable <service>` or
`dashboard docker enable <service>`. The toggle writes to the
deepest runtime docker root, so a child project layer can locally disable an
inherited home service by creating
`./.developer-dashboard/docker/<service>/disabled.yml` and can
re-enable it again by removing that same local marker.
To inspect the effective marker state without walking the folders manually,
use `dashboard docker list`. Add `--disabled` to show only disabled
services or `--enabled` to show only enabled services.

During compose execution the dashboard exports `DDDC` as the effective
config-root docker directory for the current runtime, so compose YAML can keep using
`${DDDC}` paths inside the YAML itself. Wrapper flags such as
`--service`, `--addon`, `--mode`, `--project`, and `--dry-run` are
consumed first, and all remaining docker compose flags such as `-d` and
`--build` pass straight through to the real `docker compose` command.
If one resolved service comes from an installed skill docker root, the
resolver also loads that skill's `<skill-root>/.env` file into the compose
environment before docker-config, addon, and mode env overlays are applied.
Only skills whose compose service files actually participate are included,
disabled skills are skipped, and `<skill-root>/.env.pl` is not executed from
this compose path. Nested skill services expand their env chain from the root
nested skill to the participating leaf service, preserving overwritten parent
keys under cumulative aliases such as `foo_VERSION` and
`foo_bar_VERSION` before the leaf value becomes the plain key. The resolver
also exports one skill-specific `<skill-name>_DDDC` variable for each
participating skill, using the leaf skill name with non-identifier characters
normalized to underscores and pointing that variable at the owning
`config/docker/` root. Nested skill services additionally export the full
cumulative skill path alias such as `foo_bar_zzz_DDDC` for the same compose
root, while the leaf alias stays available as `zzz_DDDC`.
When `--dry-run` is omitted, the dashboard hands off with `exec` so the
terminal sees the normal streaming output from `docker compose` itself
instead of a dashboard JSON wrapper.

## Prompt Integration

Render prompt text directly:

    dashboard ps1 --jobs 2

`dashboard ps1` now follows the original `~/bin/ps1` shape more closely: a
`(YYYY-MM-DD HH:MM:SS)` timestamp prefix, dashboard status and workspace info, a
bracketed working directory, an optional jobs suffix, and a trailing
`🌿branch` marker when git metadata is available. The prompt helper reads the
branch directly from on-disk git metadata instead of shelling out to
`git branch`, so repeated prompt renders stay lightweight on slower hosts such
as iSH. If the workspace workflow seeded `WORKSPACE_REF` or the older
`TICKET_REF` into the current tmux session, `dashboard ps1` also reads that
context from tmux when the shell environment does not already export it, but it
skips that tmux probe entirely when the shell is not inside tmux.

Generate shell bootstrap:

    dashboard shell bash
    dashboard shell zsh
    dashboard shell sh
    dashboard shell ps

The generated shell helper keeps the same bookmark-aware `cdr`, `dd_cdr`,
`d2`,
and `which_dir` functions across all supported shells. `cdr` first tries a
saved alias, then falls back to an AND-matched directory search beneath the
alias root or the current directory depending on whether that first argument
was a known alias. One match changes directory, multiple matches print the
list, and `which_dir` prints the same selected target or match list without
changing directory. Bash still uses `\j` for job counts, zsh refreshes
The shell-smoke regression coverage also compares those printed paths by
canonical identity, so macOS `/var/...` and `/private/var/...` aliases do
not fail equivalent `pwd` / `which_dir` checks. Bash still uses `\j` for
job counts, zsh refreshes
`PS1` through a `precmd` hook with `${#jobstates}`, POSIX `sh` falls back
to a prompt command that does not depend on bash-only prompt escapes, and
PowerShell installs a `prompt` function instead of using the POSIX `PS1`
variable.

`d2` is the short shell shortcut for `dashboard`, so after loading the
bootstrap you can run `d2 version`, `d2 doctor`, or
`d2 docker compose ps` without typing the full command name each time.

The same generated bootstrap also wires live tab completion for `dashboard`
and `d2`. Bash registers `_dashboard_complete`, zsh registers
`_dashboard_complete_zsh`, and PowerShell registers
`Register-ArgumentCompleter` for both command names. Completion candidates
come from the live runtime instead of a hardcoded shell list, so built-in
commands, layered custom CLI commands, and installed dotted skill commands
all show up in suggestions. For bash, the generated helper captures
completion payloads first instead of relying on process substitution, which
keeps completion responsive on macOS and inside packaged install-test shells.
The generated bootstrap also wires `cdr`,
`dd_cdr`, and `which_dir` completion. The first argument suggests saved
aliases plus matching directory names beneath the current directory, and later
arguments suggest matching directory basenames beneath the resolved alias root
or current directory without crashing when one subtree is not readable.

For the POSIX shell bootstrap, the generated helper now decodes its JSON
payloads through the same Perl interpreter that generated the shell fragment
instead of a bare `perl -MJSON::XS ...` call. That keeps `cdr` and
`which_dir` stable on macOS installs where `/usr/bin/perl` and a user-local
`~/perl5` XS stack do not belong to the same Perl build. The generated
`d2` shortcut re-enters the `dashboard` script directly instead of
hardcoding the current Perl binary path, so the shortcut still works when the
bootstrap is loaded by a shell whose preferred Perl lives somewhere else.

On Windows, `dashboard shell` auto-selects PowerShell by default, and
interpreter-backed runtime entrypoints such as collector `command` strings,
trusted command actions, saved Ajax files, custom CLI commands, hook files,
and update scripts now resolve `.ps1`, `.cmd`, `.bat`, and `.pl`
runners without assuming `sh` or `bash`. That keeps Strawberry Perl installs
usable without requiring a Unix shell just to load the dashboard runtime.
The Windows command launcher also normalizes extensionless local `cmd` shims
back to `cmd.exe` so Linux, WSL, and packaging hosts that happen to expose a
helper named `cmd` do not break the expected Windows `.cmd` and `.bat`
dispatch contract during cross-platform tests or tarball installs.

The repository-only Windows verification assets follow the same layered
approach: fast forced-Windows unit coverage in `t/`, a real Strawberry Perl
host smoke in the source checkout, and a host-side rerun helper that delegates
to the QEMU launcher for release-grade Windows compatibility claims. The
supported baseline on Windows is PowerShell plus Strawberry Perl. Git Bash is
optional. Scoop is optional. They are setup helpers, not runtime requirements
for the installed `dashboard` command. In the Dockur-backed path, the launcher
stages the Strawberry Perl MSI from the Linux host into the OEM bundle and can
keep multiple retained Windows guests alive on configurable host web/RDP ports
while it reruns the same smoke.

## Browser Access Model

The browser security model follows the original local-first trust concept:

- requests from loopback with a loopback host, such as `127.0.0.1`, `::1`, or `localhost`, are treated as local admin
- requests from loopback with a hostname listed under `web.ssl_subject_alt_names` are also treated as local admin
- requests from non-loopback IPs are treated as helper access
- outsider requests return `401` without a login page until at least one helper user exists
- after a helper user exists, outsider requests receive the helper login page
- helper access requires a login backed by local file-based user and session records
- helper sessions are file-backed, bound to the originating remote address, and expire automatically
- helper passwords must be at least 8 characters long

This keeps the fast path for loopback-local access while making non-loopback or shared access explicit.

The editor and rendered pages also include a shared top chrome with share and
source links on the left and the original status-plus-alias indicator strip on
the right, refreshed from `/system/status`.
That top-right area also includes the local username, the current host or IP
link, and the current date/time in the same spirit as the old local dashboard chrome.
The displayed address is discovered from the machine interfaces, preferring a VPN-style address when one is active, and the date/time is refreshed in the browser with JavaScript.
`dashboard serve --no-indicators` and `dashboard serve --no-indicator` clear that whole top-right browser-only area without changing the terminal prompt or `/system/status`.
The bookmark editor also follows the old auto-submit flow, so the form submits when the textarea changes and loses focus instead of showing a manual update button.
For saved bookmark files, that browser save posts back to the named
`/app/<id>/edit` route and keeps the Play link on
`/app/<id>` instead of a transient `token=` URL, so updates still
work while transient URLs are disabled.
Bookmark parsing also treats a standalone `---` line as a section
break, preventing pasted prose after a code block from being compiled into the
saved `CODE*` body.
Saved bookmark loads now also normalize malformed bookmark icon bytes from older files before the
browser sees them. Broken section glyphs fall back to `◈`, broken item-icon
glyphs fall back to `🏷️`, and common damaged joined emoji sequences such as
`🧑‍💻` are repaired so edit and play routes stop showing Unicode replacement
boxes from older bookmark files.

The default web bind is `0.0.0.0:7890`. Trust is still decided from the request origin and host header, not from the listen address.

`DD-OOP-LAYERS` comparisons normalize canonical path identities, so symlinked
aliases such as macOS `/var/...` versus `/private/var/...` do not break
layer discovery, deepest-layer writes, or layered bookmark/nav lookup.
The CLI path helpers follow the same portability rule: commands such as
`dashboard path project-root` may surface the canonical filesystem path, and
the supported contract treats macOS aliases such as `/var/...` and
`/private/var/...` as the same project root instead of different repos.
The same portability rule now also applies to the shell-helper and
`locate_dirs_under` regression suites, so equivalent temp roots are compared
by real path identity instead of raw string spelling.

## Runtime Lifecycle

The runtime manager follows the older local-service pattern:

- `dashboard serve` starts the web service in the background by default
- `dashboard serve` starts the configured collector loops alongside the web
service, so a plain serve keeps collectors and the web runtime under the same
lifecycle action
- `dashboard serve --foreground` keeps the web service attached to the terminal
- `dashboard serve --ssl` enables HTTPS in Starman with the generated local
certificate and key, keeps that certificate on a browser-correct SAN profile
covering localhost, loopback IPs, the concrete non-wildcard bind host, and any
configured `web.ssl_subject_alt_names`, regenerates older dashboard certs when
they are stale, redirects non-HTTPS requests to the matching `https://...`
URL, and reuses the saved SSL setting on later `dashboard restart` runs unless
you override it
- `dashboard serve --no-editor` and `dashboard serve --no-endit` keep the
browser in read-only mode by hiding Share, Play, and View Source chrome,
denying `/app/<id>/edit`, `/app/<id>/source`, and
bookmark-save POST routes with `403`, and persisting that read-only flag for
later `dashboard restart` runs until `dashboard serve --editor` turns it back
off
- `dashboard serve --no-indicators` and `dashboard serve --no-indicator` keep
normal page rendering and left-side page chrome intact while clearing the
whole top-right browser-only chrome area, including the status strip,
username, host or IP link, and live date-time line, and persisting that flag
for later `dashboard restart` runs until `dashboard serve --indicators`
turns it back off
- `dashboard serve logs` prints the combined Dancer2 and Starman runtime log
captured in the dashboard log file, `dashboard serve logs -n 100` starts from
the last 100 lines, and `dashboard serve logs -f` follows appended output live
- `dashboard serve workers N` saves the default Starman worker count and starts
the web service immediately when it is currently stopped; `--host HOST` and
`--port PORT` can steer that auto-start path, and both
`dashboard serve --workers N` and `dashboard restart --workers N` can still
override the worker count for one run
- `dashboard stop` stops both the web service and managed collector loops and,
prints the final lifecycle summary as a terminal table by default or JSON with
`-o json`; on an interactive terminal it also prints the full stop task board
on `stderr` before work starts so each shutdown step becomes visible instead
of silent waiting. The shutdown path now also follows the saved managed
listener port back to the real listener pid when the live web process has
renamed itself into a `starman master` shape, so minimal Docker runs still
stop the actual serving process instead of leaving the listener behind.
Managed collector stop and restart flows also wait for the previous loop to
really die before accepting a replacement, so a slow shutdown does not leave a
stale collector process rewriting loop state while the next restart is proving
the new pid.
- `dashboard stop web` only stops the managed web service
- `dashboard stop collector` only stops managed collector loops
- `dashboard stop collector <name>` only stops the requested managed
collector loop, and collector-name shell completion suggests registered
collector names
- `dashboard restart` stops both, starts configured collector loops again, then
starts the web service, prints the final lifecycle summary as a terminal table
by default or JSON with `-o json`, and only reports success after the
replacement collector loops and web runtime become visible and survive a short
post-ready confirmation window, with the web side still holding a live managed
pid and an accepting listener on the requested port. Restart now also reuses
the saved listener port to recover the real serving pid when the web process
has renamed itself into the underlying `starman master` form, so container
restarts still own and replace the active listener instead of losing control
after startup. On Linux hosts that are also running Developer Dashboard inside
Docker containers, managed stop and restart paths now reject sibling runtime
pids that live in a different Linux pid namespace, so a host-side restart does
not accidentally kill or adopt a container-owned web listener or collector
loop
- `dashboard restart web` only restarts the managed web service
- `dashboard restart collector` only restarts managed collector loops
- `dashboard restart collector <name>` only restarts the requested
collector loop, including an on-demand manual collector by converting it into
a managed interval loop, and collector-name shell completion suggests
registered collector names
- managed collector loops also run under a watchdog supervisor; if a loop dies
unexpectedly after startup, the watchdog restarts it automatically, records
the restart attempt in collector status/logs, and after too many crashes
inside the watchdog window marks the collector `attention_required` so the
operator sees an explicit problem instead of infinite silent restart churn
- `dashboard log` and `dashboard logs` print the combined dashboard web log
plus collector logs
- `dashboard log web` prints only the dashboard web log and still supports
`-n` and `-f`
- `dashboard log collector` prints only collector logs
- `dashboard log collector <name>` prints only the requested collector
log, and collector-name shell completion suggests registered collector names
- interactive restart and stop task boards mark the active step with a blue
`-`, stream active detail lines in blue, mark completed steps with a green
`[OK]`, mark failed steps with a red `[X]` plus red failure detail lines,
keep the final table or JSON summary on `stdout`, and use numeric POSIX
shutdown signals so minimal Alpine/iSH Perl builds that reject `TERM` by
name still terminate managed web and collector processes correctly
- web shutdown and duplicate detection do not trust pid files alone; they validate managed processes by environment marker or process title and use a `pkill`-style scan fallback when needed

## Environment Customization

After installing with `cpanm`, the runtime can be customized with these environment variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`

    Overrides the saved page or bookmark directory.

- `DEVELOPER_DASHBOARD_CHECKERS`

    Limits enabled collector or checker jobs to a colon-separated list of names.

- `DEVELOPER_DASHBOARD_CONFIGS`

    Overrides the config directory.

- `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS`

    Allows browser execution of transient `/?token=...`, `/action?atoken=...`,
    and older `/ajax?token=...` payloads. The default is off, so the web UI only
    executes saved bookmark files unless this is set to a truthy value such as
    `1`, `true`, `yes`, or `on`.

Collector definitions come only from dashboard configuration JSON, so config
remains the single source of truth for path aliases, providers, collectors,
and Docker compose overlays.

## Testing And Coverage

Run the test suite:

    prove -lr t

Measure library coverage with Devel::Cover:

    cpanm --no-wget --notest --local-lib-contained ./.perl5 Devel::Cover
    export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
    export PATH="$PWD/.perl5/bin:$PATH"
    cover -delete
    HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
    PERL5OPT=-MDevel::Cover prove -lr t
    cover -report text -select_re '^lib/' -coverage statement -coverage subroutine

The repository target is 100% statement and subroutine coverage for `lib/`.
This is a standing QA gate for every change, not only releases. After the
normal `prove -lr t` test gate passes, run the numeric `Devel::Cover` gate
and do not treat the work as done until the `cover` summary still reports
100% statement and 100% subroutine coverage for `lib/`.
GitHub workflow coverage gates must match the `Devel::Cover` `Total` summary
line by regex rather than one fixed-width spacing layout, because runner or
module upgrades can change column padding without changing the real
`100.0 / 100.0 / 100.0` result.
The tag-driven GitHub release workflow must also install `Devel::Cover`
before it runs that numeric coverage gate, or the signed-release path can
fail before any release assets are published.

The coverage-closure suite includes managed collector loop start/stop paths
under `Devel::Cover`, including wrapped fork coverage in
`t/14-coverage-closure-extra.t`, so the covered run stays green without
breaking TAP from daemon-style child processes.
The `t/07-core-units.t` collector loop guard treats both
`HARNESS_PERL_SWITCHES` and `PERL5OPT` as valid `Devel::Cover` signals,
because this machine uses both launch styles during verification.
The runtime-manager coverage cases also use bounded child reaping for stubborn
process shutdown scenarios, so `Devel::Cover` runs do not stall indefinitely
after the escalation path has already been exercised.
The focused skill regression in `t/19-skill-system.t` now also exercises
`PathRegistry::installed_skill_docker_roots()` directly, including the
default enabled-only view and the explicit `include_disabled => 1` path,
so skill docker layering changes do not silently pull the `lib/` total below
the required `100.0 / 100.0 / 100.0`.
The packaged `t/09-runtime-manager.t` fallback assertions also stub ambient
managed-web discovery explicitly, so tarball and PAUSE installs do not get
contaminated by unrelated live dashboard-shaped processes already running on
the host.
Release kwalitee is also a hard tarball-level gate. After `dzil build`, run:

    prove -lv t/36-release-kwalitee.t

That gate analyzes the built `Developer-Dashboard-X.XX.tar.gz` with
`Module::CPANTS::Analyse` and fails unless every reported kwalitee indicator
passes. It also fails if stale unpacked `Developer-Dashboard-X.XX/` build
directories remain beside the current tarball, so artifact cleanup is now an
enforced release invariant instead of a manual habit. Do not trust
source-tree kwalitee probes for this repository; use the built tarball
because that is the artifact PAUSE and CPANTS actually inspect. The CPANTS
modules used by this gate stay release-only and must not leak into the
generated install-time test prerequisites for blank-environment `cpanm`
verification.
The post-build smart-router two-stage Docker guard also retries one transient
`cpanm` fetch or unpack failure inside its container, so one corrupt upstream
download does not masquerade as a deterministic packaging regression in the
repository itself.
Tests that depend on a missing or empty environment variable now establish that
state explicitly inside the test file, rather than assuming the parent shell
or install harness starts clean.
The JavaScript fast-check wrapper is a source-tree fuzz gate: it runs when
`node`, `npm`, `package.json`, and `package-lock.json` are all present, and
it skips in packaged install-test trees that do not ship those checkout-only
JavaScript manifests.

Security review is also a hard verification gate. This repository now treats
OWASP as a full gate rather than a baseline-only spot check: every
security-sensitive change must complete an OWASP ASVS 5.0.0 applicability
review across V1 through V14, use ASVS Level 2 rigor as the default floor,
and escalate to Level 3 review when the change touches higher-trust surfaces
such as authentication, session handling, cryptographic handling, release
signing, or externally callable API routes. The same review must also map the
change against the OWASP Top 10 2021 categories, with explicit attention to
`A01 Broken Access Control`, `A02 Cryptographic Failures`,
`A03 Injection`, `A04 Insecure Design`,
`A05 Security Misconfiguration`, `A06 Vulnerable and Outdated Components`,
`A07 Identification and Authentication Failures`,
`A08 Software and Data Integrity Failures`,
`A09 Security Logging and Monitoring Failures`, and
`A10 Server-Side Request Forgery`.

The shipped security review now also keeps a dedicated OWASP compliance SOW
and evidence matrix. That record exists so the project can distinguish
between the currently safe public wording, which is OWASP-aligned or
OWASP-gated, and the stronger blanket phrase `OWASP compliant`. Do not use
the stronger phrase until the chapter-by-chapter evidence record, repo-side
audit set, and remaining governance gates are all closed together.

For the local repo-side evidence, run the grep-based auth/session, redirect,
traversal, command-execution, header, and raw-SQL checks from the shipped
security verification guidance, then keep the focused web and SSL regressions
green:

    rg -n "LWP::Simple|HTTP::Tiny|JSON::PP|capture_merged" bin lib t
    rg -n "companies house|ewf|xmlgw|chips|tuxedo|chs|grover|cidev|pbs|password=|dsn=" bin lib README doc t
    rg -n "X-Content-Type-Options|nosniff|Content-Security-Policy|X-Frame-Options|Referrer-Policy|SameSite=Strict|HttpOnly" lib doc SECURITY
    rg -n "Transient token URLs are disabled|_transient_url_tokens_allowed|verify_user|login_response|_session_cookie" lib/Developer/Dashboard/Web lib/Developer/Dashboard/Auth.pm
    rg -n "DBI->connect|\\$dbh->prepare\\(\\$sql\\)|table_info|column_info" bin/dashboard lib t
    rg -n "_sanitize_redirect_target|Location|redirect" lib/Developer/Dashboard/Web lib t
    rg -n "\\.\\./|rel2abs|dashboards/public|dashboards/ajax|skills/.+/dashboards" lib/Developer/Dashboard/Web lib t
    rg -n "system\\(|exec\\(|open STDOUT|open STDERR|timeout_ms|alarm\\(" lib/Developer/Dashboard/ActionRunner.pm lib/Developer/Dashboard/CollectorRunner.pm lib/Developer/Dashboard/Web/Server.pm t
    prove -lv t/08-web-update-coverage.t t/web_app_static_files.t t/17-web-server-ssl.t

From a source checkout, for fast saved-bookmark browser regressions, run the
dedicated smoke script:

    integration/browser/run-bookmark-browser-smoke.pl

That host-side smoke runner creates an isolated temporary runtime, starts the
checkout-local dashboard, loads one saved bookmark page through headless
Chromium, and can assert page-source fragments, saved `/ajax/...` output, and
the final browser DOM. With no arguments it runs the built-in Ajax
`foo.bar` bookmark case. For a real bookmark file, point it at the saved file
and add explicit expectations:

    integration/browser/run-bookmark-browser-smoke.pl \
      --bookmark-file ~/.developer-dashboard/dashboards/test \
      --expect-page-fragment "set_chain_value(foo,'bar','/ajax/foobar?type=text')" \
      --expect-ajax-path /ajax/foobar?type=text \
    --expect-ajax-body 123 \
    --expect-dom-fragment '<span class="display">123</span>'

From a source checkout, for Windows-targeted changes, also run the Strawberry
Perl smoke on a Windows host:

    powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz
    powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz -UseInstallBootstrap -BootstrapScript C:\path\install.ps1

Before calling a release Windows-compatible from the source checkout, also run
the same smoke through the host-side Windows VM helper:

    WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
    integration/windows/run-host-windows-smoke.sh

That helper keeps the Windows VM path rerunnable by loading a reusable env
file, rebuilding the latest tarball when needed, and then delegating to the
checked-in QEMU launcher. The supported baseline on Windows is PowerShell plus
Strawberry Perl. Git Bash is optional. Scoop is optional. They are setup
helpers only. In the Dockur-backed path, the launcher can resolve the latest
64-bit Strawberry Perl MSI from Strawberry Perl's official `releases.json`
feed so the env file does not need a pinned installer URL for every rerun.
That same Windows guest smoke can install the tarball with `cpanm --notest`
for third-party dependency setup while still running the full Developer
Dashboard CLI, collector, Ajax, web, and browser smoke afterward. When the
checkout bootstrap is part of the change, the Windows smoke also runs
`install.ps1` through a streamed `Invoke-Expression` wrapper with the staged
tarball passed through the literal `DD_INSTALL_CPAN_TARGET` environment
variable so the guest matches the operator flow of `irm .../install.ps1 | iex`
while still overriding the default GitHub `master` checkout clone with the
exact staged tarball under test.

## Updating Runtime State

Run your user-provided update command:

    dashboard update

If `./.developer-dashboard/cli/update` or
`./.developer-dashboard/cli/update/run` exists in the current project it is
used first; otherwise the home runtime fallback is used. `dashboard update`
runs that command after any sorted hook files from `update/` or `update.d`.

Re-running `dashboard init` keeps an existing
`~/.developer-dashboard/config/config.json` intact. If the file is missing,
init creates it as `{}`. The command refreshes dashboard-managed helpers in
`~/.developer-dashboard/cli/dd/` and preserves user-owned saved pages.

When `dashboard init` refreshes a dashboard-managed helper or shipped
starter file, it compares the existing content against the shipped content by
MD5 inside Perl first. If the content already matches, init skips the copy
instead of rewriting the file unnecessarily.

When bookmark `HTML:` or shared `nav/*.tt` fragments hit a Template Toolkit
syntax error, render mode now shows a visible `runtime-error` block instead
of leaking the raw `[% ... %]` source into the browser or
`dashboard page render` output.

Home helper staging is non-destructive too. `dashboard init` may add or
update dashboard-managed built-in helpers only under
`~/.developer-dashboard/cli/dd/`. User commands and hook directories stay in
`~/.developer-dashboard/cli/` and in child-layer
`./.developer-dashboard/cli/` roots, and init must not overwrite or delete
those user-space files while refreshing the home-only dd namespace.

The public `dashboard` entrypoint also stays thin for all built-in commands.
It only stages and execs helper assets from `share/private-cli/`: dedicated
helper bodies for `dashboard jq`, `dashboard yq`, `dashboard of`,
`dashboard open-file`, `dashboard workspace`, `dashboard path`,
`dashboard paths`, `dashboard file`, `dashboard files`, and
`dashboard ps1`, plus thin wrappers for the
remaining built-ins that hand off to the shared private
`_dashboard-core` runtime. The shipped starter bookmark source lives under
`share/seeded-pages/`, and the shipped helper scripts live under
`share/private-cli/`, so neither bookmark bodies nor helper script bodies
are embedded directly in the command script.
Installed copies resolve the same seeded pages and helper assets from the
distribution share directory, so `dashboard init` works after a `cpanm`
install and not just from a source checkout. Those helper-backed built-ins
also rewrite their live process title to `developer-dashboard ...`, so
process listings stay aligned with the public command names instead of
exposing the staged helper path.
When `dashboard` re-execs a Perl-backed helper or hook, it also forces the
same active dashboard `lib/` root into that child Perl process. That keeps
thin switchboard handoff on the current checkout code instead of drifting onto
an older installed `Developer::Dashboard` copy that may also be visible in
`PERL5LIB`.

`dashboard cpan <Module...>` installs optional Perl modules into the
active runtime-local `./.developer-dashboard/local` tree and appends matching
`requires 'Module';` lines to `./.developer-dashboard/cpanfile`. The command
stays implemented in the `dashboard` entrypoint rather than introducing a
separate CPAN manager product module, and saved Ajax workers infer the
same runtime-local `local/lib/perl5` path directly from the active runtime
root. When the requested modules include `DBD::*`, the command also installs
and records `DBI` automatically so generic database driver requests work with
a single command.
per-database notes for that workspace.

## Skills System

Extend dashboard with isolated skill packages:

Install a skill from either a Git repository URL or a local checked-out skill
repository:

    dashboard skills install browser
    dashboard skills install foo/bar
    dashboard skills install git@github.com:user/example-skill.git
    dashboard skills install https://github.com/user/example-skill.git
    dashboard skills install /absolute/path/to/example-skill
    dashboard skills install --notest browser
    dashboard skills install browser foo/bar git@github.com:user/example-skill.git
    dashboard skills install --ddfile
    dashboard skill list

Bare one-word skill names are expanded against the official
`https://github.com/manif3station/` GitHub base, so
`dashboard skills install browser` clones
`https://github.com/manif3station/browser`. Two-part `owner/repo`
shorthand is expanded against GitHub too, so
`dashboard skills install foo/bar` clones `https://github.com/foo/bar`.
Full URLs such as `https://github.com/user/example-skill.git` and
`git@github.com:user/example-skill.git` are used exactly as supplied.
Multiple explicit sources can be supplied to one install command. Developer
Dashboard installs them in the order given, prints a progress rundown before
work starts, and registers every source once.
The default install summary is a terminal table with each skill's `.env`
`VERSION` before and after the install. Use `-o json` when a script needs the
raw result payload. `dashboard skill` is
accepted as a singular alias for the `dashboard skills` management command
family, so `dashboard skill list` and `dashboard skill install browser` are
equivalent to the plural form. It does not replace dotted skill execution;
installed skill commands still run as `dashboard <skill>.<command>`.

Git sources are cloned. Direct local checked-out directories are synced in
place instead of recloned, using `rsync` when it is available and the
built-in Perl tree-copy fallback when it is not. That means
`dashboard skills install` also acts as reinstall and update for an already
installed skill. A direct local directory is only accepted when it is a
checked-out Git repository with a `.git/` directory plus a `.env` file that
declares `VERSION=...`; otherwise the install is rejected. The installed
copy lives in its own isolated skill root under the deepest participating
`DD-OOP-LAYERS` runtime. In a home-only session that is
`~/.developer-dashboard/skills/<repo-name>/`. In a deeper project
layer that already has its own `.developer-dashboard/`, the install target
becomes
`<that-layer>/.developer-dashboard/skills/<repo-name>/`.
Each explicit `dashboard skills install <source>`, including every
source in a multi-source command, also registers that exact source in
`~/.developer-dashboard/ddfile` unless it is already listed there. When
`~/.developer-dashboard/.gitignore` already exists, the install also adds
`skills/<repo-name>/` for each installed skill without duplicating
existing entries, so users who keep the dashboard runtime in Git do not
accidentally track cloned skill trees. The installer also honors an existing
`~/.developer-dashboard/.gitiignore` spelling as a compatibility safety net.
Calling bare `dashboard skills install` with no source reads that root
`ddfile` and reinstalls every listed skill as an update batch, showing the
same progress rundown and before/after version table. If no listed skill
changes version, the summary explicitly says `No update.`. First-time installs
from that root `ddfile` still report `installed` even when the skill ships no
`.env` `VERSION` metadata. If the root `ddfile` does not exist yet or has no
installable entries, the command returns an explicit error telling the user to
install a skill first or pass a skill source. When an operator later runs
`dashboard skills uninstall <repo-name>`, the home root
`ddfile` now drops any exact source lines that resolve back to that repo name
while leaving comments and unrelated entries untouched.
Long-running dependency manifests now show a Docker-build-style live detail
window under the active epic task. That rolling window keeps the newest ten
detail lines from tools such as `brew`, `npx npm install`, `cpanm`, and
`make`, collapses automatically when the task completes, and leaves the full
epic checklist visible while the active manifest streams.
Developer Dashboard does not merge the skill's `cli/`, `dashboards/`,
`config/`, `ddfile`, `ddfile.local`, `aptfile`, `apkfile`, `dnfile`,
`wingetfile`, `brewfile`, `Makefile`, `dockerfile`, `package.json`, `cpanfile`,
`cpanfile.local`, or Docker files into the
normal runtime folders.

`dashboard skills install --ddfile` reads dependency manifests from the
current directory instead of taking one explicit skill source. If `ddfile`
exists there, each listed source installs into the base home-layer skills root
at `~/.developer-dashboard/skills/<repo-name>/` even when the command
is run inside a deeper child `.developer-dashboard/` layer. If `ddfile.local`
exists there, each listed source installs into the current directory's nested
`skills/<repo-name>/` tree instead. When both manifests are present,
the command processes `ddfile` first and `ddfile.local` second. Repeated
`dashboard skills install --ddfile` runs also act as reinstall and refresh
for already-installed targets, just like repeated explicit
`dashboard skills install <source>` runs.
Interactive `dashboard skills install` runs also print a task board on
`stderr`; multi-source and bare update-all installs show one task for every
source before any clone or dependency step starts. For a single skill, the
board begins with fetch and layout only, then appends dependency tasks after
the fetched skill root has been inspected. A dependency row appears only when
the matching manifest file really exists, and operating-system-specific rows
such as `aptfile`, `apkfile`, `dnfile`, `wingetfile`, and `brewfile`
appear only on matching host families. When a single skill ships dependency
manifests such as `package.json` or `Makefile`, the matching task updates to
show the detected file path so a long-running `npm`, `make`, `cpanm`, or
package-manager step stays visible instead of looking blind, with a rolling
detail window that keeps the newest progress lines under the active task in
blue and leaves failure detail lines visible in red when a manifest step stops
with an error.

Installed dotted skill commands such as `dashboard demo-skill.foo` now hand
control to the real skill command after hook processing instead of wrapping
the main command in an extra capture layer. That keeps interactive prompting
behavior intact for commands that print a prompt and then read from standard
input.

Skill lookup also follows `DD-OOP-LAYERS`, but a same-named deeper skill is
now layered instead of flattening the whole repo. The home
`~/.developer-dashboard/skills/<repo-name>/` checkout is the base
layer, and any deeper
`.developer-dashboard/skills/<repo-name>/` checkout becomes an
inherited layer for that same skill. Runtime lookup walks those
participating skill layers for `cli/<command>`,
`cli/<command>.d`, `dashboards/*`, `dashboards/nav/*`,
`config/config.json`, and `perl5/lib/perl5`. If a child layer omits a file,
folder, or config key, lookup falls back to the base layer. If multiple
layers provide the same file or config key, the deepest layer still wins that
override.

List installed skills:

    dashboard skills list
    dashboard skills list -o json

The default output is a padded table with the columns `Repo`, `Enabled`,
`CLI`, `Pages`, `Docker`, `Collectors`, and `Indicators`. The
`Enabled` column prints the readable values `enabled` or `disabled` so the
table stays aligned and copied terminal output stays unambiguous.

Use `-o json` when you want structured output. It returns a `skills` array
where each item reports:

- repo name
- installed path
- `enabled` as a JSON boolean
- CLI command, page, docker service, collector, and indicator counts
- JSON booleans for `has_config`, `has_ddfile`, `has_aptfile`,
`has_apkfile`, `has_dnfile`, `has_brewfile`, `has_cpanfile`,
`has_cpanfile_local`, `has_makefile`, and `has_dockerfile`

Inspect one installed skill:

    dashboard skills usage example-skill
    dashboard skills usage example-skill -o table

The default output is JSON. It returns the installed skill state even when the
skill is disabled, including:

- CLI commands plus whether each command has hooks and how many
- bookmark pages and `dashboards/nav/*` entries
- docker service folders and the files inside each one
- the merged config key such as `_example-skill`
- declared collectors, their repo-qualified names, and indicator metadata

Update registered skills to their latest versions:

    dashboard skills install

Disable a skill without uninstalling it:

    dashboard skills disable example-skill

Disabling keeps the checkout in its current layered skills root but removes it
from normal runtime lookup. That means:

- `dashboard <repo-name>.<command>` stop dispatching into that
skill
- `/app/<repo-name>` and `/app/<repo-name>/<page>`
stop serving that skill's pages
- skill collectors, docker roots, config, and shared nav stop joining the
active runtime
- `dashboard skills list` and
`dashboard skills usage <repo-name>` still report the installed skill
so it can be inspected and re-enabled later

Enable a previously disabled skill:

    dashboard skills enable example-skill

Enabling removes the local disabled marker and restores the skill to command
dispatch, browser routes, collector loading, docker lookup, config merge, and
shared nav rendering.

Execute a skill command:

    dashboard example-skill.somecmd arg1 arg2

The dotted form is the public route. If `example-skill` is installed and
ships `cli/somecmd`, `dashboard example-skill.somecmd` resolves the correct
layered skill command. If the active child layer for that same repo omits
`cli/somecmd`, the command falls back to the nearest inherited skill layer
that still provides it.

That same dotted dispatch also applies to runtime-backed command files such as
`cli/report.py` and `cli/webhook.js`. In those cases the resolved skill
command still runs through the same public `dashboard <skill>.<command>`
route, with Python-backed files launched through `python` and JavaScript-backed
files launched through `node`.

If the skill command itself lives below nested
`skills/<repo>/.../skills/<repo>` trees, the same dotted
public form keeps walking those nested skill roots until it resolves the final
`cli/<cmd>` file. For example:

    dashboard nest.level1.level2.here
    dashboard which nest.level1.level2.here

The first command executes the nested skill command. The second prints the
resolved nested `cli/here` file plus any matching hook files that would run
before it.
Nested skill trees under `skills/<repo>/cli/` stay reachable through
that same public dotted route, including multiple nested levels. For example,
if `example-skill` ships `skills/foo/skills/bar/cli/baz`, then
`dashboard example-skill.foo.bar.baz` resolves the nested command through the
installed skill tree.
isolated skill root, runs sorted hooks from `cli/somecmd.d/`, and then runs the
main command.

Uninstall a skill:

    dashboard skills uninstall example-skill

Each installed skill lives under
`<participating-layer>/.developer-dashboard/skills/<repo-name>/`
with:

- **cli/**

    Skill commands (executable scripts, never installed to system PATH)

- **cli/&lt;cmd>.d/**

    Hook files for commands (sorted pre-command hooks)

- **dashboards/**

    Skill-shipped pages, including `dashboards/index`

- **dashboards/nav/**

    Skill nav fragments and bookmark pages loaded into
    `/app/<repo-name>` routes and into the shared nav strip rendered
    above normal saved `/app/<page>` routes such as `/app/index`

- **config/config.json**

    Skill-local JSON config, merged into runtime config under
    `_<repo-name>`. Any declared `collectors` join the managed fleet
    under repo-qualified names such as `example-skill.status`

- **config/api.json**

    Skill-local machine auth config for selected `/ajax/...` routes. Entries merge
    through the same skill-layer contract, keep SHA-256 secret digests plus exact
    saved Ajax route lists, and allow remote callers to send `X-DD-API-Key` plus
    `X-DD-API-Secret` instead of a helper session for those registered saved Ajax
    handlers.

- **config/docker/**

    Skill-local Docker Compose roots that participate in layered docker service lookup

- **state/**

    Persistent skill state and data

- **logs/**

    Skill output logs

- **ddfile**

    Optional dependent skill list installed after package managers run

- **ddfile.local**

    Optional local dependent skill list installed after `ddfile` into the same
    skills root as the current skill install target

- **aptfile**

    Optional Debian-family system packages installed through
    `sudo apt-get install -y` after Dashboard checks each listed package and
    keeps only the missing packages in the install request

- **brewfile**

    Optional macOS Homebrew packages installed through `brew install`

- **wingetfile**

    Optional Windows packages installed through `winget install --id ... --exact
    \--accept-package-agreements --accept-source-agreements --disable-interactivity`

- **Makefile**

    Optional skill install workflow run before `ddfile`, using `make`,
    `make test` when a `test` or `tests` target exists unless
    `dashboard skills install --notest` is used, `make install`, and
    `make clean` when a `clean` target exists

- **dnfile**

    Optional Fedora system packages installed through
    `sudo dnf install -y` after Dashboard checks each listed package and keeps
    only the missing packages in the install request

- **package.json**

    Optional Node dependencies installed into `$HOME/node_modules` by running
    `npx --yes npm install <dependency-spec...>` inside a private dashboard staging
    workspace and then merging the resulting packages into
    `$HOME/node_modules`

- **requirements.txt**

    Optional Python dependencies installed through
    `python -m pip install --user --requirement requirements.txt`

- **cpanfile**

    Optional shared Perl dependencies installed into `~/perl5`

- **cpanfile.local**

    Optional skill-local Perl dependencies installed into
    `<skill-root>/perl5`

Skills are completely isolated from the main dashboard runtime and from other
skills. Removing a skill is simple: `dashboard skills uninstall <repo-name>`
cleanly removes only that skill's directory and unregisters matching install
sources from the home root `ddfile`.

Hook lifecycle details:

- hooks run in sorted filename order from `cli/<command>.d/`
- each hook result is appended to `RESULT`
- the immediately previous hook payload is exposed through `LAST_RESULT`
- oversized hook payloads spill into `RESULT_FILE` or
`LAST_RESULT_FILE` before later skill hook or command execs would hit the
kernel arg/env limit
- executable `.py` hooks run through `python`
- executable `.js` hooks run through `node`
- executable `.go` hooks run through `go run`
- executable `.java` hooks compile with `javac` and then run through `java`
- later hooks are skipped only when a hook writes the explicit marker
`[[STOP]]` to `stderr`
- ordinary non-zero exit codes are recorded but do not act like an implicit stop
request

### Additional Release Notes

When `~/.developer-dashboard/.gitignore` exists, skill installs add
`skills/<repo-name`/> entries without duplication so cloned skill trees stay
out of the tracked runtime tree.

Skill-shipped pages mount under app-style routes such as
`/app/<repo-name`> and `/app/<repo-name`/&lt;page>>.

Under `DD-OOP-LAYERS`, same-name skills shadow by the deepest matching repo
name while missing files still fall back to the base skill layer.

For repository delivery on this machine, follow the loop:

    fix -> test -> commit -> push -> rerun scorecard

Use `~/bin/git-push-mf` for the authenticated push step.
Do not treat Scorecard as a pre-commit local gate; run it only after the local
gates, commit, and push are complete.

Skill fleet integration:

- collectors declared in a skill `config/config.json` join the same managed
fleet used by the system config
- `dashboard serve`, `dashboard restart`, and `dashboard stop` manage those
skill collectors together with the system-owned collectors
- skill collector names are normalized to
`<repo-name>.<collector-name>` so collector process titles,
status rows, and indicator state stay unambiguous
- indicator configuration attached to those skill collectors participates in the
normal prompt and browser status flow
- disabled skills are excluded from that fleet until they are re-enabled

Skill browser routes:

- `/app/<repo-name>` renders `dashboards/index`
- `/app/<repo-name>/<page>` renders `dashboards/<page>`
- nested child skills under `skills/<repo-name>/` extend those same
routes, so `/app/<repo-name>/<sub-skill>` renders that child
skill's `dashboards/index` and
`/app/<repo-name>/<sub-skill>/<page>` renders that
child skill's `dashboards/<page>`
- skill-local ajax handlers under `dashboards/ajax/*` resolve at
`/ajax/<repo-name>/...` and nested child skills extend that prefix as
`/ajax/<repo-name>/<sub-skill>/...`. Optional
`config/routes.json` metadata can also publish canonical custom ajax
paths such as `/v1/status`, but the smart
`/ajax/<repo-name>/...` resolver stays the parent route and custom
paths are fallback-only after smart route lookup misses
- runtime-level `config/routes.json` aliases can also point at normal saved
bookmark ids such as `/app/learn.ai` plus the built-in `/ajax/...`,
`/js/...`, `/css/...`, and `/others/...` route families, so one dashboard
runtime can expose shorter stable public paths like `/java` without changing
the underlying saved filename
- skill-local static assets under `dashboards/public/js/*`,
`dashboards/public/css/*`, and `dashboards/public/others/*` resolve at
`/js/<repo-name>/...`, `/css/<repo-name>/...`, and
`/others/<repo-name>/...`, with nested child skills extending those
same prefixes under `/js/.../<sub-skill>/...`,
`/css/.../<sub-skill>/...`, and `/others/.../<sub-skill>/...`.
Optional `config/routes.json` metadata can also publish canonical custom
`/js`, `/css`, and `/others` paths for those same assets, but the smart
`/js/...`, `/css/...`, and `/others/...` routes still stay the parent
resolvers and custom paths remain fallback-only after the smart lookup misses
- the installed web server uses the same smart longest-prefix dispatcher for
those `/app`, `/ajax`, `/js`, `/css`, and `/others` routes, so installed
skill-local pages, Ajax handlers, and public assets work through the shipped
PSGI route layer without being copied into the shared dashboard roots
- `dashboards/nav/*` is loaded into those skill app routes and into the shared
nav strip above normal saved `/app/<page>` routes such as
`/app/index`, so every installed skill can contribute top-level nav at once.
Nested installed skills under repeated `skills/<repo>` trees also
join that shared nav discovery path, which means a route such as
`/app/ho/coverage` can pick up nav fragments from
`skills/ho/skills/coverage/dashboards/nav/*` in addition to the top-level
skill nav
- the older `/skill/<repo-name>/bookmarks/<id>` route still works for direct bookmark rendering
- disabled skills drop out of both the dedicated skill routes and the shared nav
strip until they are re-enabled

Skill dependency and docker layering:

- if a `ddfile` exists, each listed dependency is installed after package and
language dependency manifests through
`dashboard skills install <dependency>` while already-installed or
in-flight skills are skipped to avoid loops
- if a `ddfile.local` exists under an installed skill, each listed dependency
is then installed through `dashboard skills install <dependency>`
into the same skills root that owns the current installed skill, so
child-layer skill installs stay in that child layer and home-layer installs
stay in the home layer
- if an operator runs `dashboard skills install --ddfile` inside a directory
that contains `ddfile`, every listed source is reinstalled or refreshed into
the base `~/.developer-dashboard/skills/` root
- if that same directory also contains `ddfile.local`, every listed source is
then reinstalled or refreshed into the current directory's nested
`skills/<repo-name>/` tree after the global `ddfile` pass completes
- if an `aptfile` exists on a Debian-family host, Dashboard checks each listed
package first and only prints and installs the packages that are still missing
through `sudo apt-get install -y`; interactive progress output only shows this
row when both the manifest exists and the host is Debian-family
- if an `apkfile` exists on an Alpine host, Dashboard checks each listed
package first and only prints and installs the packages that are still missing
through `sudo apk add --no-cache`; interactive progress output only shows this
row when both the manifest exists and the host is Alpine
- if a `dnfile` exists on a Fedora host, Dashboard checks each listed package
first and only prints and installs the packages that are still missing through
`sudo dnf install -y`; interactive progress output only shows this row when
both the manifest exists and the host is Fedora
- if a `wingetfile` exists on a Windows host, Dashboard installs each listed
package id through `winget install --id ... --exact
--accept-package-agreements --accept-source-agreements
--disable-interactivity`; interactive progress output only shows this row when
both the manifest exists and the host is Windows
- if a `brewfile` exists on macOS, its package list is printed and then
installed through `brew install`; interactive progress output only shows this
row when both the manifest exists and the host is macOS
- if a `Makefile` exists, Dashboard runs it after the Perl dependency
manifests and before any deferred `ddfile` processing, using `make`,
`make test` when a `test` or `tests` target exists unless
`dashboard skills install --notest` was requested, `make install`, and
`make clean` when a `clean` target exists; interactive progress output only
shows this row when the file exists
- if a `package.json` exists, its Node dependencies are installed into
`$HOME/node_modules` by running `npx --yes npm install <dependency-spec...>`
inside a private dashboard staging workspace and then merging the resulting
packages into `$HOME/node_modules`, so unrelated `$HOME/package.json` files
do not break skill installs; interactive progress output only shows this row
when the file exists
- if a `requirements.txt` exists, its Python dependencies are installed through
`python -m pip install --user --requirement requirements.txt` from the skill
root before the Perl dependency manifests run; interactive progress output only
shows this row when the file exists
- if a `cpanfile` exists, its Perl dependencies are installed into `~/perl5`;
interactive progress output only shows this row when the file exists
- if a `cpanfile.local` exists, its Perl dependencies are installed into the
skill-local `perl5/` tree; interactive progress output only shows this row
when the file exists
- skill `config/docker/...` roots participate in docker service discovery after
the home runtime docker config and before deeper project-layer overrides
- disabled skills are skipped by docker root discovery until they are
re-enabled

### Skill Authoring

To build a new skill, start with a Git repository that contains `cli/`,
`config/config.json`, optional `config/api.json`, and optional `dashboards/`, `dashboards/nav/`,
`state/`, `logs/`, `ddfile`, `ddfile.local`, `aptfile`, `apkfile`,
`dnfile`,
`brewfile`, `Makefile`, `package.json`, `requirements.txt`, `cpanfile`, and `cpanfile.local` files under the skill
root. Skill commands are file-based
commands run through the dotted
`dashboard <repo-name>.<command>` form. Skill hook files live
under `cli/<command>.d/`, skill app pages render from
`/app/<repo-name>` and `/app/<repo-name>/<id>`, and
the older `/skill/<repo-name>/bookmarks/<id>` route still
resolves direct bookmark renders. If `config/config.json` declares
collectors, those collectors join the normal managed fleet under
repo-qualified names such as `example-skill.status`, which means
`dashboard serve`, `dashboard restart`, and `dashboard stop` treat them the
same way they treat system-owned collectors. If `config/api.json` declares API
clients, those entries join the layered machine-auth allowlist for exact
saved `/ajax/...` route paths owned by that skill.

The repository also ships a dedicated skill authoring guide, and the installed
reference is available through the POD module
`Developer::Dashboard::SKILLS`. Together they cover the isolated skill
layout, environment variables such as `DEVELOPER_DASHBOARD_SKILL_ROOT`,
bookmark syntax like `TITLE:`, `BOOKMARK:`, `HTML:`, and `CODE1:`,
bookmark browser helpers such as `fetch_value()`, `stream_value()`, and
`stream_data()`, underscored config merge keys such as `_example-skill`,
`aptfile -` apkfile -> dnfile -> wingetfile -> brewfile -> package.json -> requirements.txt -> cpanfile -> cpanfile.local -> Makefile -> ddfile -> ddfile.local>
automatic dependency install order, the explicit
`dashboard skills install --ddfile` operator order of
the deferred `ddfile -` ddfile.local> pass, the shared `~/perl5` versus skill-local
`perl5/` split, the `$HOME/node_modules` Node install target used by
`package.json`, the `python -m pip install --user` path used by
`requirements.txt`, the optional `Makefile` command chain and `--notest` skip,
the same-install-level dependency target used by skill-local `ddfile.local`,
skill docker layering, and when to use dashboard-wide custom CLI hook folders such as
`~/.developer-dashboard/cli/<command>.d` instead of a skill-local
hook tree.

For operators rather than authors, `dashboard skills list`,
`dashboard skills usage <repo-name>`,
`dashboard skills disable <repo-name>`, and
`dashboard skills enable <repo-name>` are the supported controls for
inventorying and toggling installed skills without deleting their isolated
runtime trees.

# FAQ

## Is this tied to a specific company or codebase?

No. The core distribution is intended to be reusable for any project.

## Where should project-specific behavior live?

In configuration, saved pages, and user CLI extensions. The core should stay generic.

## Is the software spec implemented?

The current distribution implements the core runtime, page engine, action runner, provider loader, prompt and collector system, web lifecycle manager, and Docker Compose resolver described by the software spec.

What remains intentionally lightweight is breadth, not architecture:

\- provider pages and action handlers are implemented in a compact v1 form
\- bookmark-file pages are supported, with Template Toolkit rendering and one clean sandpit package per page run so `CODE*` blocks can share state within a bookmark render without leaking runtime globals into later requests

## How is the browser UI served?

The browser UI runs as the dashboard web service you start with
`dashboard serve`. Internally that service is a PSGI application served
through the shipped web runtime, while CLI-only commands continue to work
without keeping the browser service running.

## Why does a custom hostname sometimes require login?

Only loopback-origin requests with a loopback hostname such as `127.0.0.1`,
`::1`, or `localhost` receive automatic local-admin treatment. A custom alias
hostname also works as local admin when you list it under
`web.ssl_subject_alt_names` and the request still arrives from loopback.

## Why does a non-loopback host still get 401 without a login page?

Until at least one helper user exists, outsider access is disabled entirely.
That includes non-loopback IPs, forwarded hostnames, and any hostname that is
not loopback-local for the current request. Add a helper user first, then
outsider requests will receive the login page instead of the disabled-access
response.

## Why is the runtime file-backed?

Because prompt rendering, dashboards, and wrappers should consume prepared state quickly instead of re-running expensive checks inline.

## What JSON implementation does the project use?

The project uses `JSON::XS` for JSON encoding and decoding, including shell helper decoding paths.

## What does the project use for command capture and HTTP clients?

The project uses `Capture::Tiny` for command-output capture via `capture`,
with exit codes returned from the capture block rather than read separately.
It uses `LWP::UserAgent` for real outbound HTTP in active runtime paths such
as the Java source lookup or mirror path behind `dashboard of` and
`dashboard open-file`.

# SEE ALSO

["Main Concepts"](#main-concepts),
["Working With Collectors"](#working-with-collectors),
["Runtime Lifecycle"](#runtime-lifecycle),
["Skills System"](#skills-system)

# AUTHOR

Developer Dashboard Contributors

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. The repository root `LICENSE` file carries the
canonical MIT text used for repository metadata, GitHub license detection, and
distribution packaging.

Like most widely used open-source licenses, those license texts include strong
disclaimers. In practical terms the software is provided `"as is"`, no
warranty is given, and the authors are not accepting liability for damages
caused by somebody using the free software wrongly or suffering a problem on
their own side. That license disclaimer is the main baseline protection for
normal open-source distribution, although it is not unlimited and local law
can still matter.
