# Developer Dashboard

A local home for development work.

## Introduction

Developer Dashboard gives a developer one place to organize the moving parts of day-to-day work.

Without it, local development usually ends up spread across shell history, ad-hoc scripts, browser bookmarks, half-remembered file paths, one-off health checks, and project-specific Docker commands. With it, those pieces can live behind one entrypoint: a browser home, a prompt status layer, and a CLI toolchain that all read from the same runtime.

It brings together browser pages, saved notes, helper actions, collectors, prompt indicators, path aliases, open-file shortcuts, data query tools, and Docker Compose helpers so local development can stay centered around one consistent home instead of a pile of disconnected scripts and tabs.

Release tarballs contain installable runtime artifacts only; local Dist::Zilla release-builder configuration is kept out of the shipped archive.
Frequently used built-in commands such as `of`, `open-file`, `pjq`, `pyq`, `ptomq`, and `pjp` are also installed as standalone executables so they can run directly without loading the full `dashboard` runtime.
Before publishing a release, the built tarball should be smoke-tested with `cpanm` from the artifact itself so the shipped archive matches the fixed source tree.

It provides a small ecosystem for:

- saved and transient dashboard pages built from the original bookmark-file shape
- legacy bookmark syntax compatibility using the original `:--------------------------------------------------------------------------------:` separator plus directives such as `TITLE:`, `STASH:`, `HTML:`, `FORM.TT:`, `FORM:`, and `CODE1:`
- Template Toolkit rendering for `HTML:` and `FORM.TT:`, with access to `stash`, `ENV`, and `SYSTEM`
- legacy `CODE*` execution with captured `STDOUT` rendered into the page and captured `STDERR` rendered as visible errors
- legacy-style per-page sandpit isolation so one bookmark run can share runtime variables across `CODE*` blocks without leaking them into later page runs
- old-style root editor behavior with a free-form bookmark textarea when no path is provided
- file-backed collectors and indicators
- prompt rendering for `PS1`
- project and path discovery helpers
- a lightweight local web interface
- action execution with trusted and safer page boundaries
- plugin-loaded providers, path aliases, and compose overlays
- update scripts and release packaging for CPAN distribution

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

The access model is deliberate:

- exact numeric loopback admin access on `127.0.0.1` does not require a password
- helper access is for everyone else, including `localhost`, other hosts, and other machines on the network
- helper logins let you share the dashboard safely without turning every browser request into full local-admin access

In practice that means the developer at the machine gets friction-free local admin access, while shared or forwarded access is forced through explicit helper accounts.

### Collectors, Indicators, And PS1

Collectors are background or on-demand jobs that prepare state for the rest of the dashboard. A collector can run a shell command or a Perl snippet, then store stdout, stderr, exit code, and timestamps as file-backed runtime data.

That prepared state drives indicators. Indicators are the short status records used by:

- the shell prompt rendered by `dashboard ps1`
- the top-right status strip in the web interface
- CLI inspection commands such as `dashboard indicator list`

This matters because prompt and browser status should be cheap to render. Instead of re-running a Docker check, VPN probe, or project health command every time the prompt draws, a collector prepares the answer once and the rest of the system reads the cached result.

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

Project-specific behavior is added through configuration, startup collector definitions, saved pages, and optional plugins.

## Documentation

### Main Concepts

- `Developer::Dashboard::PathRegistry`
  Resolves the runtime roots that everything else depends on, such as dashboards, config, collectors, indicators, plugins, logs, cache, and startup files.

- `Developer::Dashboard::FileRegistry`
  Resolves stable file locations on top of the path registry so the rest of the system can read and write well-known runtime files without duplicating path logic.

- `Developer::Dashboard::PageDocument` and `Developer::Dashboard::PageStore`
  Implement the saved and transient page model, including bookmark-style source documents, encoded transient pages, and persistent bookmark storage.

- `Developer::Dashboard::PageResolver` and `Developer::Dashboard::PluginManager`
  Resolve saved pages, provider pages, plugin-defined aliases, and extension packs so browser pages and actions can come from both built-in and plugin-backed sources.

- `Developer::Dashboard::ActionRunner`
  Executes built-in actions and trusted local command actions with cwd, env, timeout, background support, and encoded action transport, letting pages act as operational dashboards instead of static documents.

- `Developer::Dashboard::Collector` and `Developer::Dashboard::CollectorRunner`
  Implement file-backed prepared-data jobs with managed loop metadata, timeout/env handling, interval and cron-style scheduling, process-title validation, duplicate prevention, and collector inspection data. This is the prepared-state layer that feeds indicators, prompt status, and operational pages.

- `Developer::Dashboard::IndicatorStore` and `Developer::Dashboard::Prompt`
  Expose cached state to shell prompts and dashboards, including compact versus extended prompt rendering, stale-state marking, generic built-in indicator refresh, and page-header status payloads for the web UI.

- `Developer::Dashboard::Web::App` and `Developer::Dashboard::Web::Server`
  Provide the browser interface on port `7890`, including the root editor, page rendering, login/logout, helper sessions, and the exact-loopback admin trust model.

- `dashboard of` and `dashboard open-file`
  Resolve direct files, `file:line` references, Perl module names, Java class names, and recursive file-pattern matches under a resolved scope so the dashboard can shorten navigation work across different stacks.

- `dashboard pjq`, `dashboard pyq`, `dashboard ptomq`, and `dashboard pjp`
  Parse JSON, YAML, TOML, and Java properties input, then optionally extract a dotted path and print a scalar or canonical JSON, giving the CLI a small data-inspection toolkit that fits naturally into shell workflows.

- standalone `of`, `open-file`, `pjq`, `pyq`, `ptomq`, and `pjp`
  Provide the same behavior directly, without proxying through the main `dashboard` command, for lighter-weight shell usage.

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

- `DEVELOPER_DASHBOARD_STARTUP`
  Override the startup collector-definition root.

### User CLI Extensions

Unknown top-level subcommands can be provided by executable files under
`~/.developer-dashboard/cli`. For example, `dashboard foobar a b` will exec
`~/.developer-dashboard/cli/foobar` with `a b` as argv, while preserving
stdin, stdout, and stderr.

### Open File Commands

`dashboard of` is the shorthand name for `dashboard open-file`.

These commands support:

- direct file paths
- `file:line` references
- Perl module names such as `My::Module`
- Java class names such as `com.example.App`
- recursive pattern searches inside a resolved directory alias or path

If `VISUAL` or `EDITOR` is set, `dashboard of` and `dashboard open-file` will exec that editor unless `--print` is used.

### Data Query Commands

These built-in commands parse structured text and optionally extract a dotted path:

- `dashboard pjq [path] [file]` for JSON
- `dashboard pyq [path] [file]` for YAML
- `dashboard ptomq [path] [file]` for TOML
- `dashboard pjp [path] [file]` for Java properties

If the selected value is a hash or array, the command prints canonical JSON. If the selected value is a scalar, it prints the scalar plus a trailing newline.

The file path and query path are order-independent, and `$d` selects the whole parsed document. For example, `cat file.json | dashboard pjq '$d'` and `dashboard pjq file.json '$d'` return the same result. The same contract applies to `pyq`, `ptomq`, and `pjp`.

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

Run the CLI directly from the repository:

```bash
perl -Ilib bin/dashboard init
perl -Ilib bin/dashboard auth add-user <username> <password>
perl -Ilib bin/dashboard of --print My::Module
perl -Ilib bin/dashboard open-file --print com.example.App
printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard pjq alpha.beta
printf 'alpha:\n  beta: 3\n' | perl -Ilib bin/dashboard pyq alpha.beta
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
```

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
```

Custom path aliases are stored in the global dashboard config so shell helpers such as `cdr foobar` and `which_dir foobar` keep working across sessions. When a saved alias points inside your home directory, the stored config uses `$HOME/...` instead of a hard-coded absolute home path so a shared `~/.developer-dashboard` folder remains portable across different developer accounts. Re-adding an existing alias updates it without error, and deleting a missing alias is also safe.

Render shell bootstrap:

```bash
dashboard shell bash
```

Resolve or open files from the CLI:

```bash
dashboard of --print My::Module
dashboard open-file --print com.example.App
dashboard open-file --print path/to/file.txt
dashboard open-file --print bookmarks welcome
```

Query structured files from the CLI:

```bash
printf '{"alpha":{"beta":2}}' | dashboard pjq alpha.beta
printf 'alpha:\n  beta: 3\n' | dashboard pyq alpha.beta
printf '[alpha]\nbeta = 4\n' | dashboard ptomq alpha.beta
printf 'alpha.beta=5\n' | dashboard pjp alpha.beta
dashboard pjq file.json '$d'
```

Start the local app:

```bash
dashboard serve
```

Open the root path with no bookmark path to get the free-form bookmark editor directly.

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

Encode and decode transient pages:

```bash
dashboard page show sample | dashboard page encode
dashboard page show sample | dashboard page encode | dashboard page decode
```

Run a page action:

```bash
dashboard action run system-status paths
```

Bookmark documents use the original separator-line format with directive headers such as `TITLE:`, `STASH:`, `HTML:`, `FORM.TT:`, `FORM:`, and `CODE1:`.
Posting a bookmark document with `BOOKMARK: some-id` back through the root editor now saves it to the bookmark store so `/app/some-id` resolves it immediately.

The browser editor highlights directive sections, HTML, CSS, JavaScript, and Perl `CODE*` content directly inside the editing surface rather than in a separate preview pane.
Edit and source views preserve raw Template Toolkit placeholders inside `HTML:` and `FORM.TT:` sections, so values such as `[% title %]` are kept in the bookmark source instead of being rewritten to rendered HTML after a browser save.

Template Toolkit rendering exposes the page title as `title`, so a bookmark
with `TITLE: Sample Dashboard` can reference it directly inside `HTML:` or
`FORM.TT:` with `[% title %]`. Transient play and view-source links are also
encoded from the raw bookmark instruction text when it is available, so
`[% stash.foo %]` stays in source views instead of being baked into the
rendered scalar value after a render pass.

Legacy `CODE*` blocks now run before Template Toolkit rendering during
`prepare_page`, so a block such as `CODE1: { a => 1 }` can feed
`[% stash.a %]` in the page body. Returned hash and array values are also
dumped into the runtime output area, so `CODE1: { a => 1 }` both populates
stash and shows the legacy-style dumped value below the rendered page body.
The `hide` helper no longer discards already-printed STDOUT, so
`CODE2: hide print $a` keeps the printed value while suppressing the Perl
return value from affecting later merge logic.

Page `TITLE:` values only populate the HTML `<title>` element. If a bookmark should show its title in the page body, add it explicitly inside `HTML:`, for example with `[% title %]`.

`/apps` redirects to `/app/index`, and `/app/<name>` can load either a saved bookmark document or a saved ajax/url bookmark file.

### Working With Collectors

Initialize example collector config:

```bash
dashboard config init
```

Run a collector once:

```bash
dashboard collector run example.collector
```

List collector status:

```bash
dashboard collector list
```

Collector jobs support two execution fields:

- `command` runs a shell command string through `sh -c`
- `code` runs Perl code directly inside the collector runtime

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
```

The resolver also supports old-style isolated service folders without adding entries to dashboard JSON config. If `~/.developer-dashboard/config/docker/green/compose.yml` exists, `dashboard docker compose config green` or `dashboard docker compose up green` will pick it up automatically by inferring service names from the passthrough compose args before the real `docker compose` command is assembled. If no service name is passed, the resolver scans isolated service folders and preloads every non-disabled folder. If a folder contains `disabled.yml` it is skipped. Each isolated folder contributes `development.compose.yml` when present, otherwise `compose.yml`.

During compose execution the dashboard exports `DDDC` as `~/.developer-dashboard/config/docker`, so compose YAML can keep using `${DDDC}` paths inside the YAML itself.
Wrapper flags such as `--service`, `--addon`, `--mode`, `--project`, and `--dry-run` are consumed first, and all remaining docker compose flags such as `-d` and `--build` pass straight through to the real `docker compose` command.
Without `--dry-run`, the dashboard hands off with `exec`, so you see the normal streaming output from `docker compose` itself instead of a dashboard JSON wrapper.

### Prompt Integration

Render prompt text directly:

```bash
dashboard ps1 --jobs 2
```

Generate bash bootstrap:

```bash
dashboard shell bash
```

### Browser Access Model

The browser security model follows the legacy local-first trust concept:

- requests from exact `127.0.0.1` with a numeric `Host` of `127.0.0.1` are treated as local admin
- requests from other IPs or from hostnames such as `localhost` are treated as helper access
- helper sessions are file-backed, bound to the originating remote address, and expire automatically
- helper passwords must be at least 8 characters long

The editor and rendered pages also include a shared top chrome with share/source links on the left and the original status-plus-alias indicator strip on the right, refreshed from `/system/status`. That top-right area also includes the local username, the current host or IP link, and the current date/time in the same spirit as the old local dashboard chrome.
The displayed address is discovered from the machine interfaces, preferring a VPN-style address when one is active, and the date/time is refreshed in the browser with JavaScript.
The bookmark editor also follows the old auto-submit flow, so the form submits when the textarea changes and loses focus instead of showing a manual update button.
- helper access requires a login backed by local file-based user and session records

This keeps the fast path for exact loopback access while making non-canonical or remote access explicit.

The default web bind is `0.0.0.0:7890`. Trust is still decided from the request origin and host header, not from the listen address.

### Runtime Lifecycle

- `dashboard serve` starts the web service in the background by default
- `dashboard serve --foreground` keeps the web service attached to the terminal
- `dashboard stop` stops both the web service and managed collector loops
- `dashboard restart` stops both, starts configured collector loops again, then starts the web service
- web shutdown and duplicate detection do not trust pid files alone; they validate managed processes by environment marker or process title and use a `pkill`-style scan fallback when needed

### Environment Customization

After installing with `cpanm`, the runtime can be customized with these environment variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`
  Overrides the saved page or bookmark directory.

- `DEVELOPER_DASHBOARD_CHECKERS`
  Limits enabled collector or checker jobs to a colon-separated list of names.

- `DEVELOPER_DASHBOARD_CONFIGS`
  Overrides the config directory.

- `DEVELOPER_DASHBOARD_STARTUP`
  Overrides the startup collector-definition directory.

Startup collector definitions are read from `*.json` files in `DEVELOPER_DASHBOARD_STARTUP`. A startup file may contain either a single collector object or an array of collector objects.

Example:

```json
[
  {
    "name": "docker.health",
    "command": "docker ps",
    "cwd": "home",
    "interval": 30
  }
]
```

### Updating Runtime State

Run the ordered update pipeline:

```bash
dashboard update
```

This performs runtime bootstrap, dependency refresh, shell bootstrap generation, and collector restart orchestration.

### Blank Environment Integration

Run the host-built tarball integration flow with:

```bash
integration/blank-env/run-host-integration.sh
```

This integration path builds the distribution tarball on the host with
`dzil build`, starts a blank container with only that tarball mounted into it,
installs the tarball with `cpanm`, and then exercises the installed
`dashboard` command inside the clean Perl container.

Before uploading a release artifact, remove older build directories and tarballs first so only the current release artifact remains, then validate the exact tarball that will ship:

```bash
rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
dzil build
tar -tzf Developer-Dashboard-0.72.tar.gz | grep run-host-integration.sh
cpanm /tmp/Developer-Dashboard-0.72.tar.gz -v
```

The harness also:

- creates a fake project wired through `DEVELOPER_DASHBOARD_BOOKMARKS`, `DEVELOPER_DASHBOARD_CONFIGS`, and `DEVELOPER_DASHBOARD_STARTUP`
- verifies the installed CLI works against that fake project through the mounted tarball install
- extracts the same tarball inside the container so `dashboard update` runs from artifact contents instead of the live repo
- starts the installed web service
- uses headless Chromium to verify the root editor, a saved fake-project bookmark page from the fake project bookmark directory, and the helper login page
- verifies helper logout cleanup and runtime restart and stop behavior

## FAQ

### Is this tied to a specific company or codebase?

No. It is meant to give an individual developer one familiar working home that can travel across the projects they touch.

### Where should project-specific behavior live?

In configuration, startup collector definitions, saved pages, and optional extensions. That keeps the main dashboard experience stable while still letting each project add the local pages, checks, paths, and helpers it needs.

### Is the software spec implemented?

The current distribution implements the core runtime, page engine, action runner, plugin/provider loader, prompt and collector system, web lifecycle manager, and Docker Compose resolver described by the software spec.

What remains intentionally lightweight is breadth, not architecture:

- plugin packs are JSON-based rather than a larger CPAN plugin API
- provider pages and action handlers are implemented in a compact v1 form
- legacy bookmarks are supported, with Template Toolkit rendering and one clean sandpit package per page run so `CODE*` blocks can share state within a bookmark render without leaking runtime globals into later requests

### Does it require a web framework?

No. The current distribution includes a minimal HTTP layer implemented with core Perl-oriented modules.

### Why does localhost still require login?

This is intentional. The trust rule is exact and conservative: only numeric loopback on `127.0.0.1` receives local-admin treatment.

### Why is the runtime file-backed?

Because prompt rendering, dashboards, and wrappers should consume prepared state quickly instead of re-running expensive checks inline.

### How are CPAN releases built?

The repository is set up to build release artifacts with Dist::Zilla and upload them to PAUSE from GitHub Actions.

### What JSON implementation does the project use?

The project uses `JSON::XS` for JSON encoding and decoding, including shell helper decoding paths.

### What does the project use for command capture and HTTP clients?

The project uses `Capture::Tiny` for command-output capture via `capture`, with exit codes returned from the capture block rather than read separately. There is currently no outbound HTTP client in the core runtime, so `LWP::UserAgent` is not yet required by an active code path.

## GitHub Release To PAUSE

The repository includes a GitHub Actions workflow at:

- `.github/workflows/release-cpan.yml`

It expects these GitHub Actions secrets:

- `PAUSE_USER`
- `PAUSE_PASS`

The workflow:

1. checks out the repo
2. installs Perl, release dependencies, the explicit `App::Cmd` prerequisite chain, and Dist::Zilla
3. builds the CPAN distribution tarball with `dzil build`
4. uploads the tarball to PAUSE

It can be triggered by:

- pushing a tag like `v0.01`
- manual `workflow_dispatch`

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
cover -report text -select_re '^lib/' -coverage statement -coverage subroutine
```

The repository target is 100% statement and subroutine coverage for `lib/`.

The coverage-closure suite includes managed collector loop start/stop paths
under `Devel::Cover`, including wrapped fork coverage in
`t/14-coverage-closure-extra.t`, so the covered run stays green without
breaking TAP from daemon-style child processes.
