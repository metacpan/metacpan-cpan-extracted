# Developer Dashboard

A local home for development work.

## Introduction

Developer Dashboard gives a developer one place to organize the moving parts of day-to-day work.

Without it, local development usually ends up spread across shell history, ad-hoc scripts, browser bookmarks, half-remembered file paths, one-off health checks, and project-specific Docker commands. With it, those pieces can live behind one entrypoint: a browser home, a prompt status layer, and a CLI toolchain that all read from the same runtime.

It brings together browser pages, saved notes, helper actions, collectors, prompt indicators, path aliases, open-file shortcuts, data query tools, and Docker Compose helpers so local development can stay centered around one consistent home instead of a pile of disconnected scripts and tabs.

When the current project contains `./.developer-dashboard`, that tree becomes the first runtime lookup root for dashboard-managed files. The home runtime under `~/.developer-dashboard` stays as the fallback base, so project-local bookmarks, config, CLI hooks, helper users, sessions, and isolated docker service folders can override home defaults without losing shared fallback data that is not redefined locally.

The home runtime is now hardened to owner-only access by default. Directories
under `~/.developer-dashboard` are kept at `0700`, regular runtime files are
kept at `0600`, and owner-executable scripts stay owner-executable at `0700`.
Run `dashboard doctor` to audit the current home runtime plus any older
dashboard roots still living directly under `$HOME`, or `dashboard doctor
--fix` to tighten those permissions in place. The same command also reads
optional hook results from `~/.developer-dashboard/cli/doctor.d` so users can
layer in more site-specific checks later.

Frequently used built-in helpers such as `jq`, `yq`, `tomq`, `propq`, `iniq`,
`csvq`, `xmlq`, `of`, and `open-file` are staged privately under
`~/.developer-dashboard/cli/dd/` and dispatched by `dashboard` without
polluting the global `PATH`. That keeps dashboard-owned built-ins separate from
user commands and hooks under `~/.developer-dashboard/cli/`. Compatibility
aliases `pjq`, `pyq`, `ptomq`, and `pjp` still map to the renamed commands when
they are invoked through `dashboard`.

It provides a small ecosystem for:

- saved and transient dashboard pages built from the original bookmark-file shape
- bookmark-file syntax compatibility using the original `:--------------------------------------------------------------------------------:` separator plus directives such as `TITLE:`, `STASH:`, `HTML:`, and `CODE1:`
- Template Toolkit rendering for `HTML:`, with access to `stash`, `ENV`, and `SYSTEM`
- bookmark `CODE*` execution with captured `STDOUT` rendered into the page and captured `STDERR` rendered as visible errors
- per-page sandpit isolation so one bookmark run can share runtime variables across `CODE*` blocks without leaking them into later page runs
- old-style root editor behavior with a free-form bookmark textarea when no path is provided
- file-backed collectors and indicators
- prompt rendering for `PS1` and the PowerShell `prompt` function
- project and path discovery helpers
- a lightweight local web interface
- action execution with trusted and safer page boundaries
- config-backed providers, path aliases, and compose overlays
- update scripts and installable runtime packaging

Developer Dashboard is meant to become the developer's working home:

- a local dashboard page that can hold links, notes, forms, actions, and rendered output
- a prompt layer that shows live status for the things you care about
- a command surface for opening files, jumping to known paths, querying data, and running repeatable local tasks
- a configurable runtime that can adapt to each codebase without losing one familiar entrypoint

### What You Get

- a browser interface on port `7890` for pages, status, editing, and helper access
- a shell entrypoint for file navigation, page operations, collectors, indicators, auth, and Docker Compose
- saved runtime state that lets the browser, prompt, and CLI all see the same prepared information
- a place to collect project-specific shortcuts without rebuilding your daily workflow for every repo

### Web Interface And Access Model

Run the web interface with:

```bash
dashboard serve
```

By default it listens on `0.0.0.0:7890`, so you can open it in a browser at:

```text
http://127.0.0.1:7890/
```

Run `dashboard serve --ssl` to enable HTTPS with a generated self-signed
certificate under `~/.developer-dashboard/certs/`, then open:

```text
https://127.0.0.1:7890/
```

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

Run `dashboard serve --no-editor` or `dashboard serve --no-endit` to keep the
browser in read-only mode. That hides the Share, Play, and View Source links,
blocks bookmark editor and source routes with `403`, blocks bookmark-save POST
requests even if someone tries to hit them directly, and persists the mode so
later `dashboard restart` runs stay read-only until you switch it back with
`dashboard serve --editor`.

Run `dashboard serve --no-indicators` or `dashboard serve --no-indicator` to
clear the whole top-right browser chrome area. That hides the browser-only
indicator strip, username, host or IP link, and live date-time line without
changing `/system/status` or terminal prompt output such as `dashboard ps1`,
and persists the mode until `dashboard serve --indicators` turns it back on.

For example, if you want the same dashboard cert to work for one local
`/etc/hosts` alias and one LAN IP, keep the runtime config like this:

```json
{
  "web": {
    "ssl_subject_alt_names": [
      "dashboard.local",
      "192.168.1.20",
      "fd00::20"
    ]
  }
}
```

The access model is deliberate:

- numeric loopback and loopback-only hostnames such as `localhost` do not require a password when the request still originates from loopback
- configured loopback aliases listed under `web.ssl_subject_alt_names` are also treated as local-admin when they still arrive from loopback
- helper access is for everyone else, including non-loopback IPs and other machines on the network
- helper logins let you share the dashboard safely without turning every browser request into full local-admin access

In practice that means the developer at the machine gets friction-free local admin access, while shared or forwarded access is forced through explicit helper accounts.
If no helper user exists yet in the active dashboard runtime, outsider requests return `401` with an empty body and do not render the login form at all.
When a saved `index` bookmark exists, opening `/` now redirects straight to
`/app/index` so the saved home page becomes the default browser entrypoint.
When no saved `index` bookmark exists yet, `/` still opens the free-form
bookmark editor.
If a user opens an unknown saved route such as `/app/foobar`, the browser now
opens the bookmark editor with a prefilled blank bookmark for that requested
path instead of showing a 404 error page.
When helper access is sent to `/login`, the login form now keeps the original
requested path and query string in a hidden redirect target. After a successful
helper login, the browser is sent back to that saved route, such as
`/app/index`, instead of being dropped at `/`.

### Collectors, Indicators, And PS1

Collectors are background or on-demand jobs that prepare state for the rest of the dashboard. A collector can run a shell command or a Perl snippet, then store stdout, stderr, exit code, and timestamps as file-backed runtime data.

That prepared state drives indicators. Indicators are the short status records used by:

- the shell prompt rendered by `dashboard ps1`
- the top-right status strip in the web interface
- CLI inspection commands such as `dashboard indicator list`

This matters because prompt and browser status should be cheap to render. Instead of re-running a Docker check, VPN probe, or project health command every time the prompt draws, a collector prepares the answer once and the rest of the system reads the cached result.
Configured collector indicators now prefer the configured icon in both places,
and when a collector is renamed the old managed indicator is cleaned up
automatically so the prompt and top-right browser strip do not show both the
old and new names at the same time. Those managed indicator records now also
preserve a newer live collector status during restart/config-sync windows, so a
healthy collector does not flicker back to `missing` after it has already
reported `ok`.
If `indicator.icon` contains Template Toolkit syntax such as `[% a %]`, the
collector runner now treats collector `stdout` as JSON, decodes it through
`JSON::XS`, exposes hash keys as direct template variables plus `data`, and
persists the rendered icon as the live indicator value. Invalid JSON or TT
render failures are explicit collector errors: the collector `stderr` records
the template problem and the indicator stays red instead of silently falling
back.

### Why It Works As A Developer Home

The pieces are designed to reinforce each other:

- pages give you a browser home for links, notes, forms, and actions
- collectors prepare state for indicators and prompt rendering
- indicators summarize that state in both the browser and the shell
- path aliases, open-file helpers, and data query commands shorten the jump from “I know what I need” to “I am at the file or value now”
- Docker Compose helpers keep recurring container workflows behind the same `dashboard` entrypoint

That combination makes the dashboard useful as a real daily base instead of just another utility script.

### Not Just For Perl

Developer Dashboard is implemented in Perl, but it is not only for Perl developers.

It is useful anywhere a developer needs:

- a local browser home
- repeatable health checks and status indicators
- path shortcuts and file-opening helpers
- JSON, YAML, TOML, or properties inspection from the CLI
- a consistent Docker Compose wrapper

The toolchain already understands Perl module names, Java class names, direct files, structured-data formats, and project-local compose flows, so it suits mixed-language teams and polyglot repositories as well as Perl-heavy work.

Project-specific behavior is added through configuration, saved pages, and user CLI extensions.

### Module Namespacing

All project modules are scoped under the `Developer::Dashboard::` namespace to prevent pollution of the CPAN ecosystem. Core helper modules are available under this namespace:

- `Developer::Dashboard::File` - file I/O helpers with alias support
- `Developer::Dashboard::Folder` - folder path resolution and discovery
- `Developer::Dashboard::DataHelper` - JSON encoding/decoding helpers
- `Developer::Dashboard::Zipper` - token encoding and Ajax command building
- `Developer::Dashboard::Runtime::Result` - hook result environment variable decoding

Project-owned modules now live only under the `Developer::Dashboard::`
namespace so the distribution does not pollute the CPAN ecosystem with
generic package names.

### Main Concepts

- `Developer::Dashboard::PathRegistry`
  Resolves the runtime roots that everything else depends on, such as dashboards, config, collectors, indicators, CLI hooks, logs, and cache.

- `Developer::Dashboard::FileRegistry`
  Resolves stable file locations on top of the path registry so the rest of the system can read and write well-known runtime files without duplicating path logic.

- `Developer::Dashboard::PageDocument` and `Developer::Dashboard::PageStore`
  Implement the saved and transient page model, including bookmark-style source documents, encoded transient pages, and persistent bookmark storage.

- `Developer::Dashboard::PageResolver`
  Resolves saved pages and provider pages so browser pages and actions can come from both built-in and config-backed sources.

- `Developer::Dashboard::ActionRunner`
  Executes built-in actions and trusted local command actions with cwd, env, timeout, background support, and encoded action transport, letting pages act as operational dashboards instead of static documents.

- `Developer::Dashboard::Collector` and `Developer::Dashboard::CollectorRunner`
  Implement file-backed prepared-data jobs with managed loop metadata, timeout/env handling, interval and cron-style scheduling, process-title validation, duplicate prevention, and collector inspection data. This is the prepared-state layer that feeds indicators, prompt status, and operational pages.

- `Developer::Dashboard::IndicatorStore` and `Developer::Dashboard::Prompt`
  Expose cached state to shell prompts and dashboards, including compact versus extended prompt rendering, stale-state marking, generic built-in indicator refresh, and page-header status payloads for the web UI.

- `Developer::Dashboard::Web::DancerApp`, `Developer::Dashboard::Web::App`, and `Developer::Dashboard::Web::Server`
  Provide the browser interface on port `7890`, with Dancer2 owning the HTTP route table while the web-app service handles page rendering, login/logout, helper sessions, and the exact-loopback admin trust model.

- `dashboard of` and `dashboard open-file`
  Resolve direct files, `file:line` references, Perl module names, Java class names, and recursive file-pattern matches under a resolved scope so the dashboard can shorten navigation work across different stacks.

- `dashboard jq`, `dashboard yq`, `dashboard tomq`, and `dashboard propq`
  Parse JSON, YAML, TOML, and Java properties input, then optionally extract a dotted path and print a scalar or canonical JSON, giving the CLI a small data-inspection toolkit that fits naturally into shell workflows. Compatibility names `pjq`, `pyq`, `ptomq`, and `pjp` still normalize through `dashboard` for backward compatibility, but they are no longer shipped as standalone executables.

- `dashboard iniq`, `dashboard csvq`, and `dashboard xmlq`
  Parse INI, CSV, and XML file input with dotted path extraction.

- private `~/.developer-dashboard/cli/dd/*` built-in helpers plus `~/.developer-dashboard/cli/dd/_dashboard-core`
  Provide dashboard-managed helper assets without installing generic command names into the global PATH. Query/open-file/ticket/path/prompt helpers keep their own dedicated helper bodies, while the remaining built-in commands stage thin wrappers that hand off to the shared private `_dashboard-core` runtime.

Only `dashboard` is intended to be the public CPAN-facing command-line entrypoint. The real built-in command bodies now live outside `bin/dashboard` under `share/private-cli/`, then stage into `~/.developer-dashboard/cli/dd/` on demand. Generic helper names such as `ticket`, `of`, `open-file`, `jq`, `yq`, `tomq`, `propq`, `iniq`, `csvq`, `xmlq`, `path`, and `paths` are intentionally kept out of the installed global PATH to avoid polluting the wider Perl and shell ecosystem while still keeping dashboard-owned commands separate from user commands under `~/.developer-dashboard/cli/`.

- `dashboard ticket`
  Creates or reuses a tmux session for the requested ticket reference, seeds `TICKET_REF` plus dashboard-friendly branch aliases into that session environment, and attaches to it through a dashboard-managed private helper instead of a public standalone binary.

- `Developer::Dashboard::RuntimeManager`
  Manages the background web service and collector lifecycle with process-title validation, `pkill`-style fallback shutdown, and restart orchestration, tying the browser and prepared-state loops together as one runtime.

- `Developer::Dashboard::UpdateManager`
  Runs ordered update scripts and restarts validated collector loops when needed, giving the runtime a controlled bootstrap and upgrade path.

- `Developer::Dashboard::DockerCompose`
  Resolves project-aware compose files, explicit overlay layers, services, addons, modes, env injection, and the final `docker compose` command so container workflows can live inside the same dashboard ecosystem instead of in separate wrapper scripts.

### Environment Variables

The distribution supports these compatibility-style customization variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`
  Override the saved page root.

- `DEVELOPER_DASHBOARD_CHECKERS`
  Filter enabled collector or checker names.

- `DEVELOPER_DASHBOARD_CONFIGS`
  Override the config root.

- `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS`
  Allow browser execution of transient `/?token=...`, `/action?atoken=...`, and older `/ajax?token=...` payloads. The default is off, so the web UI only executes saved bookmark files unless this is set to a truthy value such as `1`, `true`, `yes`, or `on`.


### Transient Web Token Policy

Transient page tokens still exist for CLI workflows such as `dashboard page encode`
and `dashboard page decode`, but browser routes that execute a transient payload
from `token=` or `atoken=` are disabled by default.

That means links such as:

- `http://127.0.0.1:7890/?token=...`
- `http://127.0.0.1:7890/action?atoken=...`
- `http://127.0.0.1:7890/ajax?token=...`

return a `403` unless `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is enabled.
Saved bookmark-file routes such as `/app/index` and
`/app/index/action/...` continue to work without that flag.
Saved bookmark editor pages also stay on their named `/app/<id>/edit` and
`/app/<id>` routes when you save from the browser, so editing an existing
bookmark file does not fall back to transient `token=` URLs under the default
deny policy.

`Ajax` helper calls inside saved bookmark `CODE*` blocks should use an
explicit `file => 'name.json'` argument. When a saved page supplies that name,
the helper stores the Ajax Perl code under the saved dashboard ajax tree and emits a stable
saved-bookmark endpoint such as `/ajax/name.json?type=text`.
Those saved Ajax handlers run the stored file as a real process, defaulting to
Perl unless the file starts with a shebang, and stream both `stdout` and
`stderr` back to the browser as they happen. That keeps bookmark Ajax
workflows usable even while transient token URLs stay disabled by default, and
it means bookmark Ajax code can rely on normal `print`, `warn`, `die`,
`system`, and `exec` process behaviour instead of a buffered JSON wrapper.
Saved bookmark Ajax handlers also default to `text/plain` when no explicit
`type => ...` argument is supplied, and the generated Perl wrapper now enables
autoflush on both `STDOUT` and `STDERR` so long-running handlers show
incremental output in the browser instead of stalling behind process buffers.
If a saved handler also needs refresh-safe process reuse, pass
`singleton => 'NAME'` in the `Ajax` helper. The generated url then carries
that singleton name, the Perl worker runs as `dashboard ajax: NAME`, and the
runtime terminates any older matching Perl Ajax worker before starting the
replacement stream for the refreshed browser request. Singleton-managed Ajax
workers are also terminated by `dashboard stop` and `dashboard restart`, and
the bookmark page now registers a `pagehide` cleanup beacon against
`/ajax/singleton/stop?singleton=NAME` so closing the browser tab also tears
down the matching worker instead of leaving it behind.
If `code => ...` is omitted, `Ajax(file => 'name')` targets the existing
executable at `dashboards/ajax/name` instead of rewriting it.
Static files referenced by saved bookmarks are resolved from the effective
runtime public tree first and then from the saved bookmark root. The web layer
also provides a built-in `/js/jquery.js` compatibility shim, so bookmark pages
that expect a local jQuery-style helper still have `$`, `$(document).ready`,
`$.ajax`, jqXHR-style `.done(...)` / `.fail(...)` / `.always(...)` chaining,
the `method` alias used by modern callers, and selector `.text(...)` support
even when no runtime file has been copied into `dashboard/public/js` yet.

Saved bookmark editor and view-source routes also protect literal inline script
content from breaking the browser bootstrap. If a bookmark body contains HTML
such as `</script>`, the editor now escapes the inline JSON assignment used to
reload the source text, so the browser keeps the full bookmark source inside
the editor instead of spilling raw text below the page. Earlier bookmark
rendering now emits saved `set_chain_value()` bindings after the bookmark body
HTML, so pages that declare `var endpoints = {};` and then call helpers from
`$(document).ready(...)` receive their saved `/ajax/...` endpoint URLs without
throwing a play-route JavaScript `ReferenceError`.
Bookmark pages now also expose `fetch_value(url, target, options,
formatter)`, `stream_value(url, target, options, formatter)`, and
`stream_data(url, target, options, formatter)` helpers so a bookmark can bind
saved Ajax endpoints into DOM targets without hand-writing the fetch and
render boilerplate. `stream_data()` and `stream_value()` now use
`XMLHttpRequest` progress events for browser-visible incremental updates, so a
saved `/ajax/...` endpoint that prints early output updates the DOM before the
request finishes. Those helpers support plain text, JSON, and HTML output
modes, and the saved Ajax endpoint bindings now run after the page declares
its endpoint root object, so `$(document).ready(...)` callbacks can call
helpers such as `fetch_value(endpoints.foo, '#foo')` on first render.


### User CLI Extensions

Unknown top-level subcommands can be provided by executable files under
the current working directory's `./.developer-dashboard/cli` first, then the
nearest git-backed project runtime `./.developer-dashboard/cli` when it is a
different directory, and then `~/.developer-dashboard/cli`. For example,
`dashboard foobar a b` will exec the first matching
`cli/foobar` with `a b` as argv, while preserving stdin, stdout, and stderr.

`DD-OOP-LAYERS` is now the runtime contract for the whole local ecosystem.
Starting at `~/.developer-dashboard` and walking down through every parent
directory until the current working directory, every existing
`.developer-dashboard/` layer participates. The deepest layer stays the write
target and the first lookup hit, but bookmarks, `nav/*.tt`, config,
collectors, indicators, auth/session state lookups, runtime `local/lib/perl5`,
and custom CLI hooks are all inherited across the full chain instead of only a
single project-or-home split.

Dashboard-managed built-in helper extraction is the one explicit exception:
`dashboard init` and on-demand helper staging always write the built-in helper
scripts only to `~/.developer-dashboard/cli/dd/`. Layered lookup still applies
to user commands and hook directories under `./.developer-dashboard/cli/` plus
`~/.developer-dashboard/cli/`, but built-in helper offloading does not seed
duplicate copies into child project layers.

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
`/* ... */` block comments that can span multiple lines. Plain `.env` values
also support:

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

Perl code can inspect where a dashboard-managed env key came from with
`Developer::Dashboard::EnvAudit`.

Single-key lookup:

```perl
use Developer::Dashboard::EnvAudit;

my $entry = Developer::Dashboard::EnvAudit->key('FOO');
```

That returns either `undef` for normal system env keys or a hashref like:

```perl
{
    value   => 'bar',
    envfile => '/full/path/to/.env',
}
```

Full inventory lookup:

```perl
my $all = Developer::Dashboard::EnvAudit->keys;
```

The audit records only dashboard-loaded env keys. System-provided keys that
did not come from a dashboard-managed `.env` or `.env.pl` file are left
untracked on purpose.

For example, a layered `.env` file can now look like:

```dotenv
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
```

### Shared Nav Fragments

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

```tt
[% index = '/app/index' %]
<a href=[% index %]>[% index %]</a>
```

On a page like `/app/index`, the direct `nav/*.tt` files are loaded in sorted
filename order, rendered through the normal page runtime, and inserted above
the page body. Non-`.tt` files, subdirectories under `nav/`, and junk files
that do not look like TT or HTML fragments are ignored by that shared-nav
renderer.

Under `DD-OOP-LAYERS`, the shared nav renderer now scans every inherited
`dashboards/nav/` layer from `~/.developer-dashboard` down to the current
directory, keeps parent-only fragments visible, and lets a deeper layer
replace the same `nav/<name>.tt` id without losing the rest of the shared nav
set. Template includes used by those bookmarks follow the same layered
bookmark lookup path.

Shared nav fragments and normal bookmark pages both render through Template
Toolkit with `env.current_page` set to the active request path, such as
`/app/index`. The same path is also available as
`env.runtime_context.current_page`, alongside the rest of the request-time
runtime context. Token play renders for named bookmarks also reuse that saved
`/app/<id>` path for nav context, so shared `nav/*.tt` fragments do not
disappear just because the browser reached the page through a transient
`/?mode=render&token=...` URL.
Shared nav markup now wraps horizontally by default and inherits the page
theme through CSS variables such as `--panel`, `--line`, `--text`, and
`--accent`, so dark bookmark themes no longer force a pale nav box or hide nav
link text against the background.

### Open File Commands

`dashboard of` is the shorthand name for `dashboard open-file`.

These commands support:

- direct file paths
- `file:line` references
- Perl module names such as `My::Module`
- Java class names such as `com.example.App` or `javax.jws.WebService`
- recursive regex searches inside a resolved directory alias or path

Without `--print`, `dashboard of` and `dashboard open-file` now behave like the
older picker workflow again: one unique match opens directly in `--editor`,
`VISUAL`, `EDITOR`, or `vim` as the final fallback, and multiple matches render
a numbered prompt. At that prompt you can press Enter to open all matches with
`vim -p`, type
one number to open one file, type comma-separated numbers such as `1,3`, or use
a range such as `2-5`. Scoped searches treat every later token as a
case-insensitive regex, so `dashboard of . 'Ok\.js$'` matches `ok.js` but not
`ok.json`. Scoped searches also rank exact helper/script names before broader
regex hits, so `dashboard of . jq` lists `jq` and `jq.js` ahead of
`jquery.js`.

Java class lookup first checks live `.java` files under the current project,
workspace roots, and `@INC`-adjacent source trees. If no live source file
exists, it also searches local source archives such as `-sources.jar`,
`-src.jar`, `src.zip`, `war`, and `jar` files under the current roots,
`~/.m2/repository`, Gradle caches, and `JAVA_HOME`. When a local archive still
does not provide the requested class, the helper can fetch a matching Maven
source jar, cache it under `~/.developer-dashboard/cache/open-file/`, and then
open the extracted Java source.

### Data Query Commands

These built-in commands parse structured text and can then either extract a
dotted path or evaluate a Perl expression against the decoded document through
`$d`:

- `dashboard jq [path] [file]` for JSON (also `pjq` for backward compatibility)
- `dashboard yq [path] [file]` for YAML (also `pyq` for backward compatibility)
- `dashboard tomq [path] [file]` for TOML (also `ptomq` for backward compatibility)
- `dashboard propq [path] [file]` for Java properties (also `pjp` for backward compatibility)
- `dashboard iniq [path] [file]` for INI files (new)
- `dashboard csvq [path] [file]` for CSV files (new)
- `dashboard xmlq [path] [file]` for XML files (new)

If the selected value is a hash or array, the command prints canonical JSON. If
the selected value is a scalar, it prints the scalar plus a trailing newline.

The file path and query text are order-independent, and `$d` selects the whole
parsed document. For example, `cat file.json | dashboard jq '$d'` and
`dashboard jq file.json '$d'` return the same result. If the query text uses
`$d` inside a Perl expression, the command evaluates that expression against the
decoded document. For example, `echo '{"foo":[1],"bar":[2]}' | dashboard jq
'sort keys %$d'` prints `["bar","foo"]`. The same contract applies to `yq`,
`tomq`, `propq`, `iniq`, `csvq`, and `xmlq` commands.

`xmlq` follows the same decoded-data model as the other query commands. XML
elements decode into nested hashes and arrays, repeated sibling tags become
arrays, attributes live under `_attributes`, and mixed text lives under `_text`.
That means `printf '<root><value>demo</value></root>' | dashboard xmlq
root.value` prints `demo`, while `dashboard xmlq feed.xml '$d'` prints the full
decoded XML tree as canonical JSON.

## Manual

### Installation

Install from CPAN with:

```bash
cpanm Developer::Dashboard
```

Or install from a checkout with:

```bash
perl Makefile.PL
make
make test
make install
```

### Local Development

Build the distribution:

```bash
rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
dzil build
```

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

```bash
perl -Ilib bin/dashboard init
perl -Ilib bin/dashboard auth add-user <username> <password>
perl -Ilib bin/dashboard version
perl -Ilib bin/dashboard of --print My::Module
perl -Ilib bin/dashboard open-file --print com.example.App
perl -Ilib bin/dashboard open-file --print javax.jws.WebService
perl -Ilib bin/dashboard of --print . 'Ok\.js$'
printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard jq alpha.beta
printf 'alpha:\n  beta: 3\n' | perl -Ilib bin/dashboard yq alpha.beta
mkdir -p ~/.developer-dashboard/cli/update
printf '#!/bin/sh\necho runtime-update\n' > ~/.developer-dashboard/cli/update/01-runtime
chmod +x ~/.developer-dashboard/cli/update/01-runtime
perl -Ilib bin/dashboard update
perl -Ilib bin/dashboard serve
perl -Ilib bin/dashboard stop
perl -Ilib bin/dashboard restart
```

User CLI extensions can be tested from the repository too:

```bash
mkdir -p ~/.developer-dashboard/cli
printf '#!/bin/sh\ncat\n' > ~/.developer-dashboard/cli/foobar
chmod +x ~/.developer-dashboard/cli/foobar
printf 'hello\n' | perl -Ilib bin/dashboard foobar

mkdir -p ~/.developer-dashboard/cli/jq
printf '#!/usr/bin/env perl\nprint "seed\\n";\n' > ~/.developer-dashboard/cli/jq/00-seed.pl
chmod +x ~/.developer-dashboard/cli/jq/00-seed.pl
printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard jq alpha.beta
```

A direct custom command can also be stored as an executable
`cli/<command>.pl`, `cli/<command>.go`, `cli/<command>.java`,
`cli/<command>.sh`, `cli/<command>.bash`, `cli/<command>.ps1`,
`cli/<command>.cmd`, or `cli/<command>.bat`, and `dashboard <command>`
resolves the same logical command name to those files.

Concrete source-backed examples:

```bash
dashboard hi
dashboard foo
```

If `cli/hi.go` is executable, `dashboard hi` runs it through `go run`.
If `cli/foo.java` is executable, `dashboard foo` compiles it with `javac`
into an isolated temp directory and then runs the declared main class with
`java`.

If a user mistypes a command, dashboard now prints an explicit unknown-command
error together with the closest matching public command before the usual usage
summary. The same guidance also applies to dotted skill commands, so
`dashboard alpha-skill.run-tset` suggests the nearest installed dotted skill
command instead of only dumping generic help.

Per-command hook files can live under either
`./.developer-dashboard/cli/<command>/` or
`./.developer-dashboard/cli/<command>.d/` in every inherited layer from
`~/.developer-dashboard` down to the current directory. Executable files in
those directories are run in sorted filename order within each layer, with the
layers themselves running top-down from home to the deepest current layer,
non-executable files are skipped, and each hook now streams its own `stdout`
and `stderr` live to the terminal while still accumulating those channels into
`RESULT` as JSON. If that JSON grows too large for a safe `exec()` environment,
`dashboard` spills it into `RESULT_FILE` and `Developer::Dashboard::Runtime::Result`
reads the same logical payload from there so later hooks and the final command
still see the same result set without tripping `Argument list too long`. Built-in
commands such as `dashboard jq` use the same hook directory. A directory-backed
custom command can provide its real executable as
`~/.developer-dashboard/cli/<command>/run`, and that runner receives the final
`RESULT` plus `LAST_RESULT` environment variables. After each hook finishes,
`dashboard` rewrites `RESULT` before the next sorted hook starts and also
rewrites `LAST_RESULT` to the structured result for the hook that just ran, so
later hook scripts can inspect both the full ordered set and the immediate
previous hook. `LAST_RESULT` carries `file`, `exit`, `STDOUT`, and `STDERR`.
Perl hook scripts can read both payloads through
`Developer::Dashboard::Runtime::Result`. A hook only stops the remaining
`<command>.d` chain when its `stderr` contains the explicit marker `[[STOP]]`;
a non-zero exit code by itself is still recorded in `RESULT` and `LAST_RESULT`
but does not skip the later hook files. If a Perl-backed command wants a
compact final summary after its hook files run, it can call
`Developer::Dashboard::Runtime::Result->report()` to print a simple
success/error report for each sorted hook file. Executable `.go` hook files and
direct `.go` custom commands run through `go run`. Executable `.java` hook
files and direct `.java` custom commands are compiled with `javac` into an
isolated temp directory and then run through `java` using the declared main
class from the source file.

If you want `dashboard update`, provide it as a normal user command at
`./.developer-dashboard/cli/update` or `./.developer-dashboard/cli/update/run`
in any inherited layer, with the deepest matching layer winning the final
command path. Its hook files can live under `update/` or `update.d/`, and the
real command receives the final `RESULT` and `LAST_RESULT` payloads through the
environment after those hook files run. If one of those hooks writes
`[[STOP]]` to `stderr`, later hook files are skipped and control returns
straight to the main `update` command.

Use `dashboard version` to print the installed Developer Dashboard version.

The blank-container integration harness now installs the tarball first and then
builds a fake-project `./.developer-dashboard` tree so the shipped test suite
still starts from a clean runtime before exercising project-local overrides.
That same blank-container path now also verifies web stop/restart behavior in a
minimal image where listener ownership may need to be discovered from `/proc`
instead of `ss`, including a late listener re-probe before `dashboard restart`
brings the web service back up.

### First Run

Initialize the runtime:

```bash
dashboard init
```

Inspect resolved paths:

```bash
dashboard paths
dashboard path resolve bookmarks_root
dashboard path add foobar /tmp/foobar
dashboard path del foobar
dashboard which jq
dashboard which layered-tool
dashboard which nest.level1.level2.here
dashboard which --edit jq
```

Custom path aliases are stored in the effective dashboard config root so shell helpers such as `cdr foobar` and `which_dir foobar` keep working across sessions. When a project-local `./.developer-dashboard` tree exists, alias writes go there first; otherwise they go to the home runtime. Under `DD-OOP-LAYERS`, that write stays local to the deepest participating layer: adding one child-layer alias does not copy inherited parent `config.json` domains into the child file. The child layer keeps only its own new delta and still inherits the rest from home and parent layers at read time. When a saved alias points inside your home directory, the stored config uses `$HOME/...` instead of a hard-coded absolute home path so a shared fallback runtime remains portable across different developer accounts. Re-adding an existing alias updates it without error, and deleting a missing alias is also safe.

`cdr` now follows a two-stage path flow instead of only jumping to one alias or one top-level project name. If the first argument resolves as a saved alias and there are no later arguments, `cdr alias` still goes straight there. If the first argument resolves as a saved alias and more arguments remain, `cdr` enters the alias root, then searches every directory under that root with AND-matched regex keywords taken from the remaining arguments. One match means `cd` into that directory; multiple matches mean print the full list and stay at the alias root. If the first argument is not a saved alias, `cdr` treats every argument as an AND-matched regex search beneath the current directory. One match means `cd` there; multiple matches mean print the list and leave the current directory unchanged. `which_dir` follows the same selection logic but only prints the chosen target or match list instead of changing directory. Unreadable subdirectories are skipped explicitly during that search so one protected tree does not abort the whole lookup.

Both `cdr` and `which_dir` therefore treat the narrowing arguments as regexes, not quoted substring tokens.

Examples:

```bash
cdr foobar
cdr foobar alpha foo bar
cdr foobar 'alpha-foo$'
cdr alpha red
which_dir foobar alpha
```

Use `Developer::Dashboard::Folder` for runtime path helpers. It resolves the
same runtime, bookmark, config, and configured alias names exposed by
`dashboard paths`, including names such as `docker`, without relying on
unscoped CPAN-global module names.

If you need the full `dashboard paths` payload in Perl, call
`Developer::Dashboard::Folder->all` or
`Developer::Dashboard::PathRegistry->all_paths` instead of rebuilding the hash
manually. If you want a fresh `PathRegistry` object from that public Folder
inventory, call `Developer::Dashboard::PathRegistry->new_from_all_folders`.
If you want a collector store that uses the same Folder-derived runtime roots,
call `Developer::Dashboard::Collector->new_from_all_folders`.

The hashed `state_root`, `collectors_root`, `indicators_root`, and
`sessions_root` paths live under the shared temp state tree, not inside the
layered runtime config tree. If a reboot or temp cleanup removes one of those
hashed state roots, the path registry recreates it automatically the next time
dashboard code resolves the path and rewrites the matching `runtime.json`
metadata file before collectors, indicators, or sessions use it again.

Use `dashboard which <target>` to inspect what `dashboard` would execute before
you run it. The command prints one `COMMAND /full/path` line for the resolved
file and then one `HOOK /full/path` line for each participating hook in
runtime execution order. That works for built-in helpers such as `jq`, layered
custom commands such as `layered-tool`, single-level skill commands such as
`example-skill.somecmd`, and multi-level nested skill commands such as
`nest.level1.level2.here`. If you add `--edit`, `dashboard which` skips the
inspection output and re-enters `dashboard open-file` with the resolved command
file path so the normal editor-selection behavior is reused.

Render shell bootstrap for bash, zsh, POSIX sh, or PowerShell:

```bash
dashboard shell bash
dashboard shell zsh
dashboard shell sh
dashboard shell ps
```

Audit runtime permissions:

```bash
dashboard doctor
dashboard doctor --fix
```

Resolve or open files from the CLI:

```bash
dashboard of --print My::Module
dashboard open-file --print com.example.App
dashboard open-file --print path/to/file.txt
dashboard open-file --print bookmarks api-dashboard
```

Query structured files from the CLI:

```bash
printf '{"alpha":{"beta":2}}' | dashboard jq alpha.beta
printf 'alpha:\n  beta: 3\n' | dashboard yq alpha.beta
printf '[alpha]\nbeta = 4\n' | dashboard tomq alpha.beta
printf 'alpha.beta=5\n' | dashboard propq alpha.beta
dashboard jq file.json '$d'
```

Start the local app:

```bash
dashboard serve
```

Open the root path with no bookmark path to get the free-form bookmark editor directly. If you start the web service with `dashboard serve --no-editor` or `dashboard serve --no-endit`, the browser stays read-only instead and direct editor/source routes are blocked. If you start it with `dashboard serve --no-indicators` or `dashboard serve --no-indicator`, the right-top browser chrome is cleared while normal page rendering still works.

Stop the local app and collector loops:

```bash
dashboard stop
```

Restart the local app and configured collector loops:

```bash
dashboard restart
```

Create a helper login user:

```bash
dashboard auth add-user <username> <password>
```

Remove a helper login user:

```bash
dashboard auth remove-user helper
```

Helper sessions show a Logout link in the page chrome. Logging out removes both
the helper session and that helper account. Helper page views also show the
helper username in the top-right chrome instead of the local system account.
Exact-loopback admin requests do not show a Logout link.

### Working With Pages

Create a starter page document:

```bash
dashboard page new sample "Sample Page"
```

Save a page:

```bash
dashboard page new sample "Sample Page" | dashboard page save sample
```

List saved pages:

```bash
dashboard page list
```

Render a saved page:

```bash
dashboard page render sample
```

`dashboard page render` now uses the same page-runtime preparation path as the
browser route, so saved bookmark TT such as `[% title %]` and `[% stash.foo %]`
is rendered there too instead of only working under `/app/<id>`.

Encode and decode transient pages:

```bash
dashboard page show sample | dashboard page encode
dashboard page show sample | dashboard page encode | dashboard page decode
```

Run a page action:

```bash
dashboard action run system-status paths
```

Bookmark documents use the original separator-line format with directive headers such as `TITLE:`, `STASH:`, `HTML:`, and `CODE1:`.
Posting a bookmark document with `BOOKMARK: some-id` back through the root editor now saves it to the bookmark store so `/app/some-id` resolves it immediately.

The browser editor now renders syntax-highlight markup again, but keeps that highlight layer inside a clipped overlay viewport that follows the real textarea scroll position by transform instead of via a second scrollbox. That restores the visible highlighting while keeping long bookmark lines, full-text selection, and caret placement aligned with the real textarea.
Edit and source views preserve raw Template Toolkit placeholders inside `HTML:` sections, so values such as `[% title %]` are kept in the bookmark source instead of being rewritten to rendered HTML after a browser save.

Template Toolkit rendering exposes the page title as `title`, so a bookmark
with `TITLE: Sample Dashboard` can reference it directly inside `HTML:` with
`[% title %]`. Transient play and view-source links are also
encoded from the raw bookmark instruction text when it is available, so
`[% stash.foo %]` stays in source views instead of being baked into the
rendered scalar value after a render pass.

Earlier `CODE*` blocks now run before Template Toolkit rendering during
`prepare_page`, so a block such as `CODE1: { a => 1 }` can feed
`[% stash.a %]` in the page body. Returned hash and array values are also
dumped into the runtime output area, so `CODE1: { a => 1 }` both populates
stash and shows the bookmark-style dumped value below the rendered page body.
The `hide` helper no longer discards already-printed STDOUT, so
`CODE2: hide print $a` keeps the printed value while suppressing the Perl
return value from affecting later merge logic.

Page `TITLE:` values only populate the HTML `<title>` element. If a bookmark should show its title in the page body, add it explicitly inside `HTML:`, for example with `[% title %]`.

`/apps` redirects to `/app/index`, and `/app/<name>` can load either a saved bookmark document or a saved ajax/url bookmark file.

### Working With Collectors

Ensure the home config file exists without seeding collectors:

```bash
dashboard config init
```

If `config/config.json` is missing, that command creates it as:

```bash
{}
```

It does not inject an example collector, and if the file already exists it is
left untouched.

List collector status:

```bash
dashboard collector list
```

Inspect collector logs:

```bash
dashboard collector log
dashboard collector log shell.example
```

`dashboard collector log` prints the known collector log streams.
`dashboard collector log <name>` prints one collector transcript.
If a configured collector has not run yet, the command prints an explicit
no-log message instead of blank output.
Collector status timestamps and collector log headers use the machine's local
system time with an explicit numeric timezone offset such as `+0100`, so the
visible timestamps line up with cron scheduling on the same machine instead of
looking one hour behind during daylight-saving transitions.

Collector jobs support two execution fields:

- `command` runs a shell command string through the native platform shell: `sh -lc` on Unix-like systems and PowerShell on Windows
- `code` runs Perl code directly inside the collector runtime

The built-in `housekeeper` collector is always present even when
`config/config.json` is otherwise empty. It runs every `900` seconds with
Perl `code` instead of a shell command, so it does not depend on `PATH`
resolution. That collector removes stale hashed runtime state roots from the
shared temp tree under `/tmp/<user>/developer-dashboard/state/` and removes
older `developer-dashboard-ajax-*` temp files plus `dashboard-result-*`
runtime result temp files left behind in `/tmp`. It also rotates collector
log transcripts when a collector defines `rotation` or `rotations`.
`lines` keeps the trailing line count, while `minute`, `minutes`, `hour`,
`hours`, `day`, `days`, `week`, `weeks`, `month`, and `months` keep only log
entries newer than the requested retention window. Run it on demand with:

```bash
dashboard housekeeper
dashboard collector run housekeeper
```

If you need different cadence or behavior, define your own collector named
`housekeeper` in config. That override now inherits the built-in `code` and
`cwd` defaults, so changing only `interval` or adding `indicator` metadata is
enough:

```json
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
```

Example collector definitions:

```json
{
  "collectors": [
    {
      "name": "shell.example",
      "command": "printf 'shell collector\\n'",
      "cwd": "home",
      "interval": 60
    },
    {
      "name": "perl.example",
      "code": "print qq(perl collector\\n); return 0;",
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
```

Collector indicators follow the collector exit code automatically: `0` stores
an `ok` indicator state and any non-zero exit code stores `error`.
When `indicator.name` is omitted, the collector name is reused automatically.
When `indicator.label` is omitted, it defaults to that same name.
Configured collector indicators are now seeded immediately, so prompt and page
status strips show them before the first collector run. Before a collector has
produced real output it appears as missing. Prompt output renders an explicit
status glyph in front of the collector icon, so successful checks show `✅🔑`
style fragments and failing or not-yet-run checks show `🚨🔑` style fragments.
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
renders `[% a %]` into the live icon `123`. Later config-sync passes keep the
configured `icon_template` metadata and the already-rendered live `icon`, so
commands such as `dashboard indicator list` and `dashboard ps1` do not revert
the persisted icon back to raw `[% ... %]` text between runs.
The blank-environment integration flow also keeps a regression for mixed
collector health isolation: one intentionally broken Perl collector must stay
red without stopping a second healthy collector from staying green in
`dashboard indicator list`, `dashboard ps1`, and `/system/status`.

### Docker Compose

Inspect the resolved compose stack without running Docker:

```bash
dashboard docker compose --dry-run config
```

Include addons or modes:

```bash
dashboard docker compose --addon mailhog --mode dev up -d
dashboard docker compose config green
dashboard docker compose config
dashboard docker list
dashboard docker list --disabled
dashboard docker list --enabled
dashboard docker disable green
dashboard docker enable green
```

The resolver also supports old-style isolated service folders without adding entries to dashboard JSON config. If `./.developer-dashboard/docker/green/compose.yml` exists in the current project it wins; otherwise the resolver falls back to `~/.developer-dashboard/config/docker/green/compose.yml`. `dashboard docker compose config green` or `dashboard docker compose up green` will pick it up automatically by inferring service names from the passthrough compose args before the real `docker compose` command is assembled. If no service name is passed, the resolver scans isolated service folders and preloads every non-disabled folder. If a folder contains `disabled.yml` it is skipped. Each isolated folder contributes `development.compose.yml` when present, otherwise `compose.yml`.
To toggle that marker without creating or deleting the file manually, use `dashboard docker disable <service>` or `dashboard docker enable <service>`. The toggle writes to the deepest runtime docker root, so a child project layer can locally disable an inherited home service by creating `./.developer-dashboard/docker/<service>/disabled.yml` and can re-enable it again by removing that same local marker.
To inspect the effective marker state without walking the folders manually, use `dashboard docker list`. Add `--disabled` to show only disabled services or `--enabled` to show only enabled services.

During compose execution the dashboard exports `DDDC` as the effective config-root docker directory for the current runtime, so compose YAML can keep using `${DDDC}` paths inside the YAML itself.
Wrapper flags such as `--service`, `--addon`, `--mode`, `--project`, and `--dry-run` are consumed first, and all remaining docker compose flags such as `-d` and `--build` pass straight through to the real `docker compose` command.
Without `--dry-run`, the dashboard hands off with `exec`, so you see the normal streaming output from `docker compose` itself instead of a dashboard JSON wrapper.

### Prompt Integration

Render prompt text directly:

```bash
dashboard ps1 --jobs 2
```

`dashboard ps1` now follows the original `~/bin/ps1` shape more closely: a
`(YYYY-MM-DD HH:MM:SS)` timestamp prefix, dashboard status and ticket info, a
bracketed working directory, an optional jobs suffix, and a trailing
`🌿branch` marker when git metadata is available. If the ticket workflow
seeded `TICKET_REF` into the current tmux session, `dashboard ps1` also reads
it from tmux when the shell environment does not already export it.

The path helpers also treat path identity canonically where the filesystem can
surface aliases. On macOS, `dashboard path project-root`, `cdr`, and
`which_dir` may report the same temp tree through `/private/var/...` even
when the shell entered it through `/var/...`, and the test/install contract
now treats those as the same real path instead of failing on a raw-string
mismatch.

Generate shell bootstrap:

```bash
dashboard shell bash
dashboard shell zsh
dashboard shell sh
dashboard shell ps
```

The generated shell helper keeps the same bookmark-aware `cdr`, `dd_cdr`, `d2`, and
`which_dir` functions across all supported shells. `cdr` first tries a saved
alias, then falls back to an AND-matched directory search beneath the alias
root or the current directory depending on whether that first argument was a
known alias. One match changes directory, multiple matches print the list, and
`which_dir` prints the same selected target or match list without changing
directory. The shell-smoke regression coverage also compares those printed
paths by canonical identity, so macOS `/var/...` and `/private/var/...`
aliases do not fail equivalent `pwd` / `which_dir` checks. Bash still uses `\j` for job counts, zsh refreshes `PS1` through a
`precmd` hook with `${#jobstates}`, POSIX `sh` falls back to a prompt command
that does not depend on bash-only prompt escapes, and PowerShell installs a
`prompt` function instead of using the POSIX `PS1` variable.

`d2` is the short shell shortcut for `dashboard`, so after loading the
bootstrap you can run `d2 version`, `d2 doctor`, or `d2 docker compose ps`
without typing the full command name each time.

The same generated bootstrap also wires live tab completion for `dashboard`
and `d2`. Bash registers `_dashboard_complete`, zsh registers
`_dashboard_complete_zsh`, and PowerShell registers `Register-ArgumentCompleter`
for both command names. Completion candidates come from the live runtime
instead of a hardcoded shell list, so built-in commands, layered custom CLI
commands, and installed dotted skill commands all show up in suggestions.
The generated bootstrap also wires `cdr`, `dd_cdr`, and `which_dir`
completion. The first argument suggests saved aliases plus matching directory
names beneath the current directory, and later arguments suggest matching
directory basenames beneath the resolved alias root or current directory
without crashing when one subtree is not readable.

For the POSIX shell bootstrap, the generated helper now decodes its JSON
payloads through the same Perl interpreter that generated the shell fragment
instead of a bare `perl -MJSON::XS ...` call. That keeps `cdr` and
`which_dir` stable on macOS installs where `/usr/bin/perl` and a user-local
`~/perl5` XS stack do not belong to the same Perl build. The generated `d2`
shortcut re-enters the `dashboard` script directly instead of hardcoding the
current Perl binary path, so the shortcut still works when the bootstrap is
loaded by a shell whose preferred Perl lives somewhere else.

On Windows, `dashboard shell` auto-selects PowerShell by default, and
interpreter-backed runtime entrypoints such as collector `command` strings,
trusted command actions, saved Ajax files, custom CLI commands, hook files,
and update scripts now resolve `.ps1`, `.cmd`, `.bat`, and `.pl` runners
without assuming `sh` or `bash`. That keeps Strawberry Perl installs usable
without requiring a Unix shell just to load the dashboard runtime.

The checked-in Windows verification assets follow the same layered approach:
fast forced-Windows unit coverage in `t/`, a real Strawberry Perl host smoke in
`integration/windows/run-strawberry-smoke.ps1`, and a host-side rerun helper in
`integration/windows/run-host-windows-smoke.sh` that delegates to
`integration/windows/run-qemu-windows-smoke.sh` for release-grade Windows
compatibility claims. The supported baseline on Windows is PowerShell plus
Strawberry Perl. Git Bash is optional. Scoop is optional. They are setup
helpers, not runtime requirements for the installed `dashboard` command. In
the Dockur-backed path, the launcher stages the Strawberry Perl MSI from the
Linux host into the OEM bundle and can keep multiple retained Windows guests
alive on configurable host web/RDP ports while it reruns the same smoke.

### Browser Access Model

The browser security model follows the original local-first trust concept:

- requests from loopback with a loopback host, such as `127.0.0.1`, `::1`, or `localhost`, are treated as local admin
- requests from loopback with a hostname listed under `web.ssl_subject_alt_names` are also treated as local admin
- requests from non-loopback IPs are treated as helper access
- outsider requests return `401` without a login page until at least one helper user exists
- after a helper user exists, outsider requests receive the helper login page
- helper sessions are file-backed, bound to the originating remote address, and expire automatically
- helper passwords must be at least 8 characters long

The editor and rendered pages also include a shared top chrome with share/source links on the left and the original status-plus-alias indicator strip on the right, refreshed from `/system/status`. That top-right area also includes the local username, the current host or IP link, and the current date/time in the same spirit as the old local dashboard chrome.
The displayed address is discovered from the machine interfaces, preferring a VPN-style address when one is active, and the date/time is refreshed in the browser with JavaScript.
`dashboard serve --no-indicators` and `dashboard serve --no-indicator` clear that whole top-right browser-only area without changing the terminal prompt or `/system/status`.
The bookmark editor also follows the old auto-submit flow, so the form submits when the textarea changes and loses focus instead of showing a manual update button.
For saved bookmark files, that browser save posts back to the named
`/app/<id>/edit` route and keeps the Play link on `/app/<id>` instead of a
transient `token=` URL, so updates still work while transient URLs are
disabled.
Bookmark parsing also treats a standalone `---` line as a section
break, preventing pasted prose after a code block from being compiled into the
saved `CODE*` body.
Saved bookmark loads now also normalize malformed bookmark icon bytes from older files before the
browser sees them. Broken section glyphs fall back to `◈`, broken item-icon
glyphs fall back to `🏷️`, and common damaged joined emoji sequences such as
`🧑‍💻` are repaired so edit and play routes stop showing Unicode replacement
boxes from older bookmark files.
- helper access requires a login backed by local file-based user and session records

This keeps the fast path for loopback-local access while making non-loopback or shared access explicit.

The default web bind is `0.0.0.0:7890`. Trust is still decided from the request origin and host header, not from the listen address.

`DD-OOP-LAYERS` comparisons normalize canonical path identities, so symlinked
aliases such as macOS `/var/...` versus `/private/var/...` do not break layer
discovery, deepest-layer writes, or layered bookmark/nav lookup.
The same portability rule now also applies to the shell-helper and
`locate_dirs_under` regression suites, so equivalent temp roots are compared
by real path identity instead of raw string spelling.

### Runtime Lifecycle

- `dashboard serve` starts the web service in the background by default
- `dashboard serve` starts the configured collector loops alongside the web service, so a plain serve keeps collectors and the web runtime under the same lifecycle action
- `dashboard serve --foreground` keeps the web service attached to the terminal
- `dashboard serve --ssl` enables HTTPS in Starman with the generated local certificate and key, keeps that certificate on a browser-correct SAN profile covering localhost, loopback IPs, the concrete non-wildcard bind host, and any configured `web.ssl_subject_alt_names`, regenerates older dashboard certs when they are stale, redirects non-HTTPS requests to the matching `https://...` URL, and reuses the saved SSL setting on later `dashboard restart` runs unless you override it
- `dashboard serve --no-editor` and `dashboard serve --no-endit` keep the browser in read-only mode by hiding Share, Play, and View Source chrome, denying `/app/<id>/edit`, `/app/<id>/source`, and bookmark-save POST routes with `403`, and persisting that read-only flag for later `dashboard restart` runs until `dashboard serve --editor` turns it back off
- `dashboard serve --no-indicators` and `dashboard serve --no-indicator` keep normal page rendering and left-side page chrome intact while clearing the whole top-right browser-only chrome area, including the status strip, username, host or IP link, and live date-time line, and persisting that flag for later `dashboard restart` runs until `dashboard serve --indicators` turns it back off
- `dashboard serve logs` prints the combined Dancer2 and Starman runtime log captured in the dashboard log file, `dashboard serve logs -n 100` starts from the last 100 lines, and `dashboard serve logs -f` follows appended output live
- `dashboard serve workers N` saves the default Starman worker count and starts the web service immediately when it is currently stopped; `--host HOST` and `--port PORT` can steer that auto-start path, and `dashboard serve --workers N` or `dashboard restart --workers N` can still override it for one run
- `dashboard stop` stops both the web service and managed collector loops
- `dashboard restart` stops both, starts configured collector loops again, then starts the web service, and only reports success after the replacement collector loops and web runtime both survive a short managed stability window, with the web side still holding a live managed pid and an accepting listener on the requested port
- web shutdown and duplicate detection do not trust pid files alone; they validate managed processes by environment marker or process title and use a `pkill`-style scan fallback when needed

### Environment Customization

After installing with `cpanm`, the runtime can be customized with these environment variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`
  Overrides the saved page or bookmark directory.

- `DEVELOPER_DASHBOARD_CHECKERS`
  Limits enabled collector or checker jobs to a colon-separated list of names.

- `DEVELOPER_DASHBOARD_CONFIGS`
  Overrides the config directory.

Collector definitions now come only from dashboard configuration JSON, so config remains the single source of truth for saved path aliases, providers, collectors, and Docker compose overlays.

### Updating Runtime State

Run your user-provided update command:

```bash
dashboard update
```

If `~/.developer-dashboard/cli/update` or `~/.developer-dashboard/cli/update/run`
exists, `dashboard update` runs that command after any sorted hook files from
`~/.developer-dashboard/cli/update/` or `~/.developer-dashboard/cli/update.d/`.

`dashboard init` seeds two editable starter bookmarks when they are missing:
`api-dashboard` and `sql-dashboard`.

Re-running `dashboard init` keeps an existing
`~/.developer-dashboard/config/config.json` intact. If the file is missing,
init creates it as `{}`. The command refreshes dashboard-managed helpers in
`~/.developer-dashboard/cli/dd/` and seeds starter bookmarks that are not
already present.

Starter bookmark refresh is also non-destructive. If a saved `api-dashboard`
or `sql-dashboard` page still matches the last dashboard-managed shipped copy,
`dashboard init` refreshes it to the current shipped seed. If the saved page
has diverged from the recorded managed digest, init treats it as a user edit
and leaves it alone. The refresh bridge also recognizes known older
dashboard-managed `sql-dashboard` digests from runtimes that predate the seed
manifest, so one stale shipped copy on an upgraded machine is refreshed
instead of looking stuck on older browser UI.

When `dashboard init` refreshes a dashboard-managed helper or shipped starter
file, it compares the existing content against the shipped content by MD5
inside Perl first. If the content already matches, init skips the copy
instead of rewriting the file unnecessarily.

When bookmark `HTML:` or shared `nav/*.tt` fragments hit a Template Toolkit
syntax error, render mode now shows a visible `runtime-error` block instead of
leaking the raw `[% ... %]` source into the browser or `dashboard page render`
output.

Home helper staging is non-destructive too. `dashboard init` may add or update
dashboard-managed built-in helpers only under `~/.developer-dashboard/cli/dd/`.
User commands and hook directories stay in `~/.developer-dashboard/cli/` and in
child-layer `./.developer-dashboard/cli/` roots, and init must not overwrite or
delete those user-space files while refreshing the home-only dd namespace.

The public `dashboard` entrypoint also stays thin for all built-in commands.
It only stages and execs helper assets from `share/private-cli/`: dedicated
helper bodies for `dashboard jq`, `dashboard yq`, `dashboard of`,
`dashboard open-file`, `dashboard ticket`, `dashboard path`, `dashboard
paths`, and `dashboard ps1`, plus thin wrappers for the remaining built-ins
that hand off to the shared private `_dashboard-core` runtime. The shipped
starter bookmark source lives under `share/seeded-pages/`, and the shipped
helper scripts live under `share/private-cli/`, so neither bookmark bodies nor
helper script bodies are embedded directly in the command script. Installed
copies resolve the same
seeded pages and helper assets from the distribution share directory, so
`dashboard init` works after `cpanm` installs and not just from a source
checkout.
When `dashboard` re-execs a Perl-backed helper or hook, it also forces the
same active dashboard `lib/` root into that child Perl process. That keeps
thin switchboard handoff on the current checkout code instead of drifting onto
an older installed `Developer::Dashboard` copy that may also be visible in
`PERL5LIB`.

The seeded `api-dashboard` bookmark now behaves like a local Postman-style
workspace. It keeps multiple request tabs in browser-local state, supports
import and export of Postman collection v2.1 JSON through the Collections tab,
saves created, updated, and imported collections as Postman collection JSON
under the runtime `config/api-dashboard/<collection-name>.json` path, reloads
every stored collection when the bookmark opens, keeps the active collection,
request, and tab reflected in the browser URL for direct-link and back/forward
navigation, renders Collections and Workspace as top-level tabs for narrower
browser layouts, renders stored collections as click-through tabs instead of
one long vertical stack, shows a request-specific token form above the editor
whenever the selected request uses `{{token}}` placeholders, carries those
token values across matching placeholders in other requests from the same
collection, resolves those token values into the visible request URL, headers,
and body fields, renders a hide/show `Request Credentials` section in the
workspace with Postman-compatible `Basic`, `API Token`, `API Key`, `OAuth2`,
`Apple Login`, `Amazon Login`, `Facebook Login`, and `Microsoft Login`
presets, hydrates imported Postman `request.auth` data back into that
credentials panel, exports saved request auth back into valid Postman JSON,
and applies the configured auth to outgoing headers or query strings when the
request is sent. The OAuth-style provider presets fill common authorize/token
URLs, but the actual access token and client details remain values the user
enters for that request. The bookmark also tightens project-local
`config/api-dashboard` to `0700` and each saved collection JSON file there to
`0600`, because saved request auth can include secrets inside the Postman
collection JSON. It renders Request Details, Response Body, and Response
Headers as inner workspace tabs below the response `pre` box, defaults
Response Body back to the active tab after each send, previews JSON, text,
PDF, image, and TIFF responses appropriately, and sends requests through its
saved Ajax endpoint backed by `LWP::UserAgent`. HTTPS endpoints also require
the packaged `LWP::Protocol::https` runtime prerequisite, so clean installs
can test normal TLS APIs without browser CORS rules. Oversized collection
saves now spill the saved Ajax request payload through temp files instead of
overflowing `execve` environment limits, and the bookmark rejects empty `200`
save/delete responses instead of claiming success when nothing was persisted.

`dashboard cpan <Module...>` installs optional Perl modules into the active
runtime-local `./.developer-dashboard/local` tree and appends matching
`requires 'Module';` lines to `./.developer-dashboard/cpanfile`. The command
stays implemented in the `dashboard` entrypoint rather than introducing a
separate SQL or CPAN manager product module, and saved Ajax workers infer the
same runtime-local `local/lib/perl5` path directly from the active runtime
root. When the requested modules include `DBD::*`, the command also installs
and records `DBI` automatically so generic database driver requests work with
a single command.

The seeded `sql-dashboard` bookmark is a file-backed SQL workspace built
inside the bookmark runtime itself rather than as a separate product module.
It stores connection profiles under
`config/sql-dashboard/<profile-name>.json`, keeps that
`config/sql-dashboard` directory owner-only at `0700`, writes each saved
profile JSON file owner-only at `0600`, stores saved SQL collections under
`config/sql-dashboard/collections/<collection-name>.json` with the same
owner-only `0700` / `0600` directory and file permissions, keeps the active
top-level tab, portable `connection` id, selected collection, selected saved
SQL item, selected schema table, and current SQL in the browser URL instead
of a saved SQL file, and treats SQL collections and connection profiles as
separate concepts so the same saved SQL can run against different
connections. Share URLs only carry the DSN-plus-user connection id without a
password; if another machine already has a matching saved profile with a
saved password, the bookmark reruns the shared SQL there, otherwise it opens
a draft connection profile built from that connection id so the other user
can add any required local credentials and run it. Passwordless profiles
such as SQLite may keep the user blank, and a matching blank-user shared
route auto-runs without inventing a password warning when the DSN does not
need one. The profile editor now renders the driver field as a dropdown of
installed `DBD::*` modules, shows driver-specific connection guidance beside
that dropdown, seeds a usable DSN template for SQLite, MySQL, PostgreSQL,
MSSQL/ODBC, and Oracle when the DSN is blank, and rewrites only the
`dbi:<Driver>:` DSN prefix when you switch drivers. The main browser flow
now merges collections and editing into one `SQL Workspace` tab with a
phpMyAdmin-style master-detail layout with two inner workspace tabs:
`Collection` and `Run SQL`. The `Collection` view keeps collection tabs and
the saved SQL list together in the left navigation rail, while `Run SQL`
keeps the editor plus results together on the right and leaves that runner
view active by default because it is the main operator path. The active
saved SQL name stays visible while you work, and saving a different SQL name
into the same collection adds a second saved SQL entry instead of
overwriting the selected one. The workspace editor now keeps the SQL
textarea as the primary focus with content-based auto-resize, uses one quiet
action row under the editor instead of a loud toolbar, removes the redundant
in-workspace schema button in favour of the top `Schema Explorer` tab, and
moves saved-SQL deletion to a compact inline `[X]` control beside each saved
query so the list stays visually tied to its collection. The bookmark still
renders profile tabs and schema tabs, executes SQL through generic `DBI`,
and uses DBI metadata calls such as `table_info` and `column_info` for the
schema browser. Schema Explorer now also gives the table list a live filter
box, renders human type labels and positive length labels from the DBI
metadata instead of leaking raw numeric type codes, lets the user copy a
table name directly, and adds a `View Data` action that jumps back to `Run
SQL` with a ready `select * from <table>` query for the selected table. The
core browser workflow is now live verified against SQLite, MySQL,
PostgreSQL, MSSQL via `DBD::ODBC`, and Oracle via `DBD::Oracle`. Schema
browse keeps reading `table_info` / `column_info` rows directly and must not
call `execute()` on those metadata handles, because ODBC drivers such as
MSSQL can fail with `SQL-HY010` on that misuse. Saved dashboard pages
override shipped seeded pages, so an
older `~/.developer-dashboard/dashboards/sql-dashboard` copy can still
shadow a newer shipped fix after upgrade; when SQL Dashboard behavior looks
stale, use `dashboard page source sql-dashboard` to confirm which page
source is live before debugging the browser route. It preserves programmable
statement blocks through `SQLS_SEP` and `INSTRUCTION_SEP`, including
`STASH`, `ROW`, `BEFORE`, and `AFTER` hooks, so result rows can still be
transformed locally before rendering into derived HTML, links, or button-like
actions. Its saved Ajax endpoints run through singleton workers. No `DBD::*`
driver ships in the base tarball by default; install only the one you need
with `dashboard cpan DBD::Driver` or user-space
`cpanm -L ~/perl5 DBD::Driver`, and the bookmark will return explicit install
guidance when a selected driver is missing. The repository also ships a
dedicated SQL dashboard support guide with the verification matrix and
per-database notes for that workspace.

### Skills System

Extend dashboard with isolated skill packages:

**Install a skill** from either a Git repository URL or a local checked-out
skill repository:

```bash
dashboard skills install git@github.com:user/example-skill.git
dashboard skills install https://github.com/user/example-skill.git
dashboard skills install /absolute/path/to/example-skill
```

Git sources are cloned. Direct local checked-out directories are synced in
place instead of recloned, using `rsync` when it is available and the built-in
Perl tree-copy fallback when it is not. That means `dashboard skills install`
also acts as reinstall and update for an already installed skill. A direct
local directory is only accepted when it is a checked-out Git repository with
a `.git/` directory plus a `.env` file that declares `VERSION=...`; otherwise
the install is rejected. The installed copy lives in its own isolated skill
root under the deepest participating `DD-OOP-LAYERS` runtime. In a home-only
session that is `~/.developer-dashboard/skills/<repo-name>/`. In a deeper
project layer that already has its own `.developer-dashboard/`, the install
target becomes `<that-layer>/.developer-dashboard/skills/<repo-name>/`.
Developer Dashboard does not merge the skill's `cli/`, `dashboards/`,
`config/`, `ddfile`, `aptfile`, `brewfile`, `cpanfile`, `cpanfile.local`, or
Docker files into the normal runtime folders.

Skill lookup also follows `DD-OOP-LAYERS`, but a same-named deeper skill is
now layered instead of flattening the whole repo. The home
`~/.developer-dashboard/skills/<repo-name>/` checkout is the base layer, and
any deeper `.developer-dashboard/skills/<repo-name>/` checkout becomes an
inherited layer for that same skill. Runtime lookup walks those participating
skill layers for `cli/<command>`, `cli/<command>.d`, `dashboards/*`,
`dashboards/nav/*`, `config/config.json`, and `perl5/lib/perl5`. If a child
layer omits a file, folder, or config key, lookup falls back to the base
layer. If multiple layers provide the same file or config key, the deepest
layer still wins that override.

**List installed skills:**

```bash
dashboard skills list
dashboard skills list -o json
```

The default output is a padded table with the columns `Repo`, `Enabled`,
`CLI`, `Pages`, `Docker`, `Collectors`, and `Indicators`. The `Enabled`
column prints the readable values `enabled` or `disabled` so the table stays
aligned and copied terminal output stays unambiguous.

Use `-o json` when you want structured output. It returns a `skills` array
where each item reports:
- repo name
- installed path
- `enabled` as a JSON boolean
- CLI command, page, docker service, collector, and indicator counts
- JSON booleans for `has_config`, `has_ddfile`, `has_aptfile`, `has_brewfile`,
  `has_cpanfile`, and `has_cpanfile_local`

**Inspect one installed skill:**

```bash
dashboard skills usage example-skill
dashboard skills usage example-skill -o table
```

The default output is JSON. It returns the installed skill state even when the
skill is disabled, including:
- CLI commands plus whether each command has hooks and how many
- bookmark pages and `dashboards/nav/*` entries
- docker service folders and the files inside each one
- the merged config key such as `_example-skill`
- declared collectors, their repo-qualified names, and indicator metadata

**Update a skill** to the latest version:

```bash
dashboard skills update example-skill
```

**Disable a skill** without uninstalling it:

```bash
dashboard skills disable example-skill
```

Disabling keeps the checkout in its current layered skills root but removes it
from normal runtime lookup. That means:
- `dashboard <repo-name>.<command>` stops dispatching into that skill
- `/app/<repo-name>` and `/app/<repo-name>/<page>` stop serving that skill's pages
- skill collectors, docker roots, config, and shared nav stop joining the active runtime
- `dashboard skills list` and `dashboard skills usage <repo-name>` still report the installed skill so it can be inspected and re-enabled later

**Enable a previously disabled skill:**

```bash
dashboard skills enable example-skill
```

Enabling removes the local disabled marker and restores the skill to command
dispatch, browser routes, collector loading, docker lookup, config merge, and
shared nav rendering.

**Execute a skill command:**

```bash
dashboard example-skill.somecmd arg1 arg2
```

The dotted form is the public route. If `example-skill` is installed and
ships `cli/somecmd`, `dashboard example-skill.somecmd` resolves the correct
layered skill command. If the active child layer for that same repo omits
`cli/somecmd`, the command falls back to the nearest inherited skill layer
that still provides it.

If the skill command itself lives below nested `skills/<repo>/.../skills/<repo>`
trees, the same dotted public form keeps walking those nested skill roots until
it resolves the final `cli/<cmd>` file. For example:

```bash
dashboard nest.level1.level2.here
dashboard which nest.level1.level2.here
```

The first command executes the nested skill command. The second prints the
resolved nested `cli/here` file plus any matching hook files that would run
before it.
Nested skill trees under `skills/<repo>/cli/` also stay reachable through the
same dotted public route, including multiple nested levels. For example, if
`example-skill` ships `skills/foo/skills/bar/cli/baz`, then
`dashboard example-skill.foo.bar.baz` resolves that nested command through the
installed skill tree.
isolated skill root, runs sorted hooks from `cli/somecmd.d/`, and then runs the
main command.

**Uninstall a skill:**

```bash
dashboard skills uninstall example-skill
```

Each installed skill lives under
`<participating-layer>/.developer-dashboard/skills/<repo-name>/` with:

- `cli/` - Skill commands (executable scripts, never installed to system PATH)
- `cli/<cmd>.d/` - Hook files for commands (sorted pre-command hooks)
- `dashboards/` - Skill-shipped pages, including `dashboards/index`
- `dashboards/nav/` - Skill nav fragments and bookmark pages loaded into `/app/<repo-name>` routes and into the shared nav strip rendered above normal saved `/app/<page>` routes such as `/app/index`
- `config/config.json` - Skill-local JSON config, merged into runtime config under `_<repo-name>`, with any declared `collectors` joining the managed fleet under repo-qualified names such as `example-skill.status`
- `config/docker/` - Skill-local Docker Compose roots that participate in layered docker service lookup
- `state/` - Persistent skill state and data
- `logs/` - Skill output logs
- `ddfile` - Optional dependent skill list installed before package managers run
- `aptfile` - Optional Debian-family system packages installed through `sudo apt-get install -y`
- `brewfile` - Optional macOS Homebrew packages installed through `brew install`
- `cpanfile` - Optional shared Perl dependencies installed into `~/perl5`
- `cpanfile.local` - Optional skill-local Perl dependencies installed into `<skill-root>/perl5`

Skills are completely isolated from the main dashboard runtime and from other
skills. Removing a skill is simple: `dashboard skills uninstall <repo-name>`
cleanly removes only that skill's directory.

Hook lifecycle details:

- hooks run in sorted filename order from `cli/<command>.d/`
- each hook result is appended to `RESULT`
- the immediately previous hook payload is exposed through `LAST_RESULT`
- oversized hook payloads spill into `RESULT_FILE` or `LAST_RESULT_FILE`
  before later skill hook or command execs would hit the kernel arg/env limit
- executable `.go` hooks run through `go run`
- executable `.java` hooks compile with `javac` and then run through `java`
- later hooks are skipped only when a hook writes the explicit marker `[[STOP]]`
  to `stderr`
- ordinary non-zero exit codes are recorded but do not act like an implicit
  stop request

Skill fleet integration:

- collectors declared in a skill `config/config.json` join the same managed fleet used by the system config
- `dashboard serve`, `dashboard restart`, and `dashboard stop` now manage those skill collectors together with the system-owned collectors
- skill collector names are normalized to `<repo-name>.<collector-name>` so collector process titles, status rows, and indicator state stay unambiguous
- indicator configuration attached to those skill collectors participates in the normal prompt and browser status flow
- disabled skills are excluded from that fleet until they are re-enabled

Skill browser routes:

- `/app/<repo-name>` renders `dashboards/index`
- `/app/<repo-name>/<page>` renders `dashboards/<page>`
- `dashboards/nav/*` is loaded into those skill app routes and into the shared nav strip above normal saved `/app/<page>` routes such as `/app/index`, so every installed skill can contribute top-level nav at once
- the older `/skill/<repo-name>/bookmarks/<id>` route still works for direct
  bookmark rendering
- disabled skills drop out of both the dedicated skill routes and the shared nav strip until they are re-enabled

Skill dependency and docker layering:

- if a `ddfile` exists, each listed dependency is installed first through
  `dashboard skills install <dependency>` while already-installed or in-flight
  skills are skipped to avoid loops
- if an `aptfile` exists on a Debian-family host, its package list is printed
  before the sudo prompt and then installed through `sudo apt-get install -y`
- if a `brewfile` exists on macOS, its package list is printed and then
  installed through `brew install`
- if a `cpanfile` exists, its Perl dependencies are installed into `~/perl5`
- if a `cpanfile.local` exists, its Perl dependencies are installed into the
  skill-local `perl5/` tree
- skill `config/docker/...` roots participate in docker service discovery after
  the home runtime docker config and before deeper project-layer overrides
- disabled skills are skipped by docker root discovery until they are re-enabled

### Skill Authoring

To build a new skill, start with a Git repository that contains `cli/`,
`config/config.json`, and optional `dashboards/`, `dashboards/nav/`, `state/`,
`logs/`, `ddfile`, `aptfile`, `brewfile`, `cpanfile`, and `cpanfile.local`
files under the skill root. Skill
commands are file-based commands run through the dotted
`dashboard <repo-name>.<command>` form. Skill hook files live under
`cli/<command>.d/`, skill app pages render from `/app/<repo-name>` and
`/app/<repo-name>/<id>`, and the older `/skill/<repo-name>/bookmarks/<id>`
route still resolves direct bookmark renders. If `config/config.json` declares
collectors, those collectors join the normal managed fleet under repo-qualified
names such as `example-skill.status`, which means `dashboard serve`,
`dashboard restart`, and `dashboard stop` treat them the same way they treat
system-owned collectors.

The repository also ships a dedicated skill authoring guide, and the installed
reference is available through the POD module
`Developer::Dashboard::SKILLS`. Together they cover the isolated skill layout,
environment variables such as `DEVELOPER_DASHBOARD_SKILL_ROOT`, bookmark
syntax like `TITLE:`, `BOOKMARK:`, `HTML:`, and `CODE1:`, bookmark browser
helpers such as `fetch_value()`, `stream_value()`, and `stream_data()`,
underscored config merge keys such as `_example-skill`, the
`ddfile -> aptfile -> brewfile -> cpanfile -> cpanfile.local` dependency
install order, the shared `~/perl5` versus skill-local `perl5/` split, skill
docker layering, and when to use
dashboard-wide custom CLI hook folders such as
`~/.developer-dashboard/cli/<command>.d` instead of a skill-local hook tree.

For operators rather than authors, `dashboard skills list`,
`dashboard skills usage <repo-name>`, `dashboard skills disable <repo-name>`,
and `dashboard skills enable <repo-name>` are the supported controls for
inventorying and toggling installed skills without deleting their isolated
runtime trees.

### Blank Environment Integration

## FAQ

### Is this tied to a specific company or codebase?

No. It is meant to give an individual developer one familiar working home that can travel across the projects they touch.

### Where should project-specific behavior live?

In configuration, saved pages, and user CLI extensions. That keeps the main dashboard experience stable while still letting each project add the local pages, checks, paths, and helpers it needs.

### Is the software spec implemented?

The current distribution implements the core runtime, page engine, action runner, provider loader, prompt and collector system, web lifecycle manager, and Docker Compose resolver described by the software spec.

What remains intentionally lightweight is breadth, not architecture:

- provider pages and action handlers are implemented in a compact v1 form
- bookmark-file pages are supported, with Template Toolkit rendering and one clean sandpit package per page run so `CODE*` blocks can share state within a bookmark render without leaking runtime globals into later requests

### How is the browser UI served?

The browser UI runs as the dashboard web service you start with
`dashboard serve`. Internally that service is a PSGI application served
through the shipped web runtime, while CLI-only commands continue to work
without keeping the browser service running.

### Why does a custom hostname sometimes require login?

Only loopback-origin requests with a loopback hostname such as `127.0.0.1`,
`::1`, or `localhost` receive automatic local-admin treatment. A custom alias
hostname also works as local admin when you list it under
`web.ssl_subject_alt_names` and the request still arrives from loopback.

### Why does a non-loopback host still get 401 without a login page?

Until at least one helper user exists, outsider access is disabled entirely.
That includes non-loopback IPs, forwarded hostnames, and any hostname that is
not loopback-local for the current request. Add a helper user first, then
outsider requests will receive the login page instead of the disabled-access
response.

### Why is the runtime file-backed?

Because prompt rendering, dashboards, and wrappers should consume prepared state quickly instead of re-running expensive checks inline.

### What JSON implementation does the project use?

The project uses `JSON::XS` for JSON encoding and decoding, including shell helper decoding paths.

### What does the project use for command capture and HTTP clients?

The project uses `Capture::Tiny` for command-output capture via `capture`, with
exit codes returned from the capture block rather than read separately. It
uses `LWP::UserAgent` for real outbound HTTP in active runtime paths such as
the saved `api-dashboard` request runner and the Java source lookup or mirror
path behind `dashboard of` and `dashboard open-file`.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The repository root `LICENSE` file carries a
canonical GPL text for GitHub and Scorecard detection, and the alternative
Artistic text lives in `LICENSE-Artistic-1.0-Perl`.

## Testing And Coverage

Run the test suite:

```bash
prove -lr t
```

Measure library coverage with Devel::Cover:

```bash
cpanm --local-lib-contained ./.perl5 Devel::Cover
export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
export PATH="$PWD/.perl5/bin:$PATH"
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
PERL5OPT=-MDevel::Cover prove -lr t
cover -report text -select_re '^lib/' -coverage statement -coverage subroutine
```

The repository target is 100% statement and subroutine coverage for `lib/`.
GitHub workflow coverage gates must match the `Devel::Cover` `Total` summary
line by regex rather than one fixed-width spacing layout, because runner or
module upgrades can change column padding without changing the real
`100.0 / 100.0 / 100.0` result.

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
default enabled-only view and the explicit `include_disabled => 1` path, so
skill docker layering changes do not silently pull the `lib/` total below the
required `100.0 / 100.0 / 100.0`.
The packaged `t/09-runtime-manager.t` fallback assertions also stub ambient
managed-web discovery explicitly, so tarball and PAUSE installs do not get
contaminated by unrelated live dashboard-shaped processes already running on
the host.
Release kwalitee is also a hard tarball-level gate. After `dzil build`, run:

```bash
prove -lv t/36-release-kwalitee.t
```

That gate analyzes the built `Developer-Dashboard-X.XX.tar.gz` with
`Module::CPANTS::Analyse` and fails unless every reported kwalitee indicator
passes. It also fails if stale unpacked `Developer-Dashboard-X.XX/` build
directories remain beside the current tarball, so artifact cleanup is now an
enforced release invariant instead of a manual habit. Do not trust source-tree
kwalitee probes for this repository; use the built tarball because that is the
artifact PAUSE and CPANTS actually inspect. The CPANTS modules used by this
gate stay release-only and must not leak into the generated install-time test
prerequisites for blank-environment `cpanm` verification.
Tests that depend on a missing or empty environment variable now establish that
state explicitly inside the test file, rather than assuming the parent shell
or install harness starts clean.

### Scorecard Timing

Run local repository gates first, then commit and push, and only then rerun
live Scorecard against the pushed repository state:

```bash
prove -lr t
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
dzil build
git commit -m "Meaningful change summary"
~/bin/git-push-mf origin master
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

Do not treat Scorecard as a pre-commit local gate on this machine. Several
checks are repository-hosted or history-based, so the meaningful enforcement
loop is `fix -> test -> commit -> push -> rerun scorecard`. If a Scorecard
check stays below `10 / 10`, record the exact blocker and whether it is
repo-side, GitHub-side, or historically impossible to change from the working
tree alone.
The license side of that gate expects the repository root `LICENSE` to stay a
single canonical GPL text that GitHub can classify, while the alternative
Perl Artistic option remains available in `LICENSE-Artistic-1.0-Perl`.

From a source checkout, for fast saved-bookmark browser regressions, run the
dedicated smoke script:

```bash
integration/browser/run-bookmark-browser-smoke.pl
```

That host-side smoke runner creates an isolated temporary runtime, starts the
checkout-local dashboard, loads one saved bookmark page through headless
Chromium, and can assert page-source fragments, saved `/ajax/...` output, and
the final browser DOM. With no arguments it runs the built-in Ajax
`foo.bar` bookmark case. For a real bookmark file, point it at the saved file
and add explicit expectations:

```bash
integration/browser/run-bookmark-browser-smoke.pl \
  --bookmark-file ~/.developer-dashboard/dashboards/test \
  --expect-page-fragment "set_chain_value(foo,'bar','/ajax/foobar?type=text')" \
  --expect-ajax-path /ajax/foobar?type=text \
  --expect-ajax-body 123 \
  --expect-dom-fragment '<span class="display">123</span>'
```

For `api-dashboard` import regressions against a real external Postman
collection, run the generic Playwright repro with an explicit fixture path:

```bash
API_DASHBOARD_IMPORT_FIXTURE=/path/to/collection.postman_collection.json \
prove -lv t/23-api-dashboard-import-fixture-playwright.t
```

That browser test injects the external fixture into the visible
`api-dashboard` import control and verifies that the collection appears in the
Collections tab, opens from the tree, and persists to
`config/api-dashboard/<collection-name>.json` without baking fixture-specific
branding into the repository.

For oversized `api-dashboard` imports that need to stay browser-verified above
the saved-Ajax inline payload threshold, run:

```bash
prove -lv t/25-api-dashboard-large-import-playwright.t
```

The main `t/22-api-dashboard-playwright.t` browser flow now also waits for the
saved collection JSON itself to contain the newly created request before it
drives the later export/import/reload path, so that coverage proves real
disk-backed collection persistence instead of only optimistic browser state.

That Playwright test imports a deliberately large Postman collection through
the visible browser file input and verifies that the browser still reports a
successful import instead of failing with an `Argument list too long` transport
error.

For the tabbed `api-dashboard` browser layout, run the dedicated Playwright
coverage:

```bash
prove -lv t/24-api-dashboard-tabs-playwright.t
```

That browser test verifies the top-level Collections and Workspace tabs, the
collection-to-collection tab strip inside the Collections view, and the inner
Request Details, Response Body, and Response Headers tabs below the response
`pre` box so the bookmark remains usable in constrained browser widths.

For `sql-dashboard` browser coverage, run:

```bash
prove -lv t/27-sql-dashboard-playwright.t
```

That browser test creates a profile through the visible bookmark UI, runs
programmable SQL through a fake runtime-local `DBI` stack under
`.developer-dashboard/local/lib/perl5`, verifies the shareable URL state, and
checks the schema table-tab browser.

For deep real SQLite browser coverage, run:

```bash
PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi \
prove -lv t/31-sql-dashboard-sqlite-playwright.t
```

That browser matrix runs 51 real SQLite cases against the visible SQL
workspace, including blank-user profile save and reload, merged workspace
layout, saved-SQL collection flow, schema browsing, invalid SQL and attrs
errors, shared-URL restoration, and file-permission checks.

For optional docker-backed MySQL, PostgreSQL, MSSQL, and Oracle browser
coverage, run:

```bash
PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi \
prove -lv t/32-sql-dashboard-rdbms-playwright.t
```

That browser file covers real MySQL, PostgreSQL, MSSQL, and Oracle services
through Docker using official `mysql:5.7`, `postgres:16`,
`mcr.microsoft.com/mssql/server:2022-latest`, and
`gvenzl/oracle-xe:21-slim-faststart` fixtures on this host. It intentionally
skips unless `DBI` plus the relevant `DBD::mysql`, `DBD::Pg`, `DBD::ODBC`, or
`DBD::Oracle` driver is already installed in the active Perl environment. For
MSSQL and Oracle on this host, the test also expects the user-space native
client libraries to be exposed through `PERL5LIB`, `LD_LIBRARY_PATH`, and, for
Oracle, `ORACLE_HOME`. Those drivers are not shipped as base runtime
prerequisites.

From a source checkout, for Windows-targeted changes, also run the Strawberry
Perl smoke on a Windows host:

```powershell
powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz
```

Before calling a release Windows-compatible from the source checkout, also run
the same smoke through the host-side Windows VM helper:

```bash
WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
integration/windows/run-host-windows-smoke.sh
```

That helper keeps the Windows VM path rerunnable by loading a reusable env
file, rebuilding the latest tarball when needed, and then delegating to the
checked-in QEMU launcher. The supported baseline on Windows is PowerShell plus
Strawberry Perl. Git Bash is optional. Scoop is optional. They are setup
helpers only. In the Dockur-backed path, the launcher can resolve the latest
64-bit Strawberry Perl MSI from Strawberry Perl's official `releases.json`
feed so the env file does not need a pinned installer URL for every rerun.
That same Windows guest smoke can install the tarball with `cpanm --notest`
for third-party dependency setup while still running the full Developer
Dashboard CLI, collector, Ajax, web, and browser smoke afterward.
