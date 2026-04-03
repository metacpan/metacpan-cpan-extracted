# Update And Release

## Local Update

Run:

```bash
perl -Ilib bin/dashboard version
mkdir -p ~/.developer-dashboard/cli/update.d
printf '#!/usr/bin/env perl\nuse Runtime::Result;\nprint Runtime::Result::stdout(q{01-runtime});\nprint $ENV{RESULT} // q{}\n' > ~/.developer-dashboard/cli/update
chmod +x ~/.developer-dashboard/cli/update
printf '#!/bin/sh\necho runtime-update\n' > ~/.developer-dashboard/cli/update.d/01-runtime
chmod +x ~/.developer-dashboard/cli/update.d/01-runtime
perl -Ilib bin/dashboard update
```

This executes ordered scripts from either `~/.developer-dashboard/cli/update`
or `~/.developer-dashboard/cli/update.d`:

1. sorted by filename
2. running any regular executable file
3. skipping non-executable files
4. streaming each hook file's stdout and stderr live while still accumulating `RESULT` JSON
5. rewriting `RESULT` after each hook so later hook files can react to earlier output
6. passing the final `RESULT` JSON to the real command

`dashboard update` has no special built-in path. If you want it, provide it as
a normal user command and let its hook files run through the same top-level
command-hook path as every other dashboard subcommand.

Perl hook scripts can use `Runtime::Result` to decode `RESULT` and read
structured hook output without hand-parsing the JSON blob.

Use `dashboard version` to print the installed Developer Dashboard version.

The blank-container integration harness now installs the tarball first and then
builds a fake-project `./.developer-dashboard` tree so the shipped test suite
still starts from a clean runtime before exercising project-local overrides.

## Local Usage

Initialize runtime state:

```bash
perl -Ilib bin/dashboard init
```

Serve the local app in the background:

```bash
perl -Ilib bin/dashboard serve
```

The root path now redirects to `/app/index` when a saved `index` bookmark exists, and otherwise opens the free-form bookmark editor directly. `/apps` still redirects to `/app/index`.
Unknown saved routes such as `/app/foobar` must now open the bookmark editor with a prefilled blank bookmark for `/app/foobar` instead of returning a plain 404 page.
If the posted editor content includes `BOOKMARK: some-id`, that post now persists the bookmark document so `/app/some-id` works immediately after saving from `/`.
Saved bookmark editor routes such as `/app/some-id/edit` must keep posting back to that named route and keep their Play links on `/app/some-id`, even when transient `token=` URLs are disabled by default.
Edit and source routes must preserve raw Template Toolkit placeholders in bookmark source, so browser saves of `HTML:` or `FORM.TT:` content such as `[% title %]` should be verified as source-stable as well as render-correct.

Create a helper login user:

```bash
perl -Ilib bin/dashboard auth add-user <username> <password>
```

Remove a helper login user:

```bash
perl -Ilib bin/dashboard auth remove-user helper
```

Render shell bootstrap:

```bash
perl -Ilib bin/dashboard shell bash
```

Refresh generic built-in indicators:

```bash
perl -Ilib bin/dashboard indicator refresh-core
```

Inspect collector state:

```bash
perl -Ilib bin/dashboard collector inspect example.collector
```

Collector definitions may use either a shell `command` string or Perl `code`
string. If a collector defines an `indicator`, the collector name now supplies
the default indicator name and label automatically, so an icon-only indicator
block is enough for the common case. Collector indicators are also seeded
before the first run, so prompt and page status views show configured checks
immediately as missing until a collector reports a real exit code. Prompt
rendering prefixes the collector icon with `✅` for healthy checks and `🚨`
for failing or missing checks. Release validation should cover whichever
execution mode a new feature touches.

Render prompt in extended colored mode:

```bash
perl -Ilib bin/dashboard ps1 --jobs 1 --mode extended --color
```

Stop the web service and managed collector loops:

```bash
perl -Ilib bin/dashboard stop
```

Restart the web service and configured collector loops:

```bash
perl -Ilib bin/dashboard restart
```

Customize runtime locations:

```bash
export DEVELOPER_DASHBOARD_BOOKMARKS="$HOME/my-dd-pages"
export DEVELOPER_DASHBOARD_CONFIGS="$HOME/my-dd-config"
export DEVELOPER_DASHBOARD_CHECKERS="docker.health:repo.status"
```

Access semantics:

- `http://127.0.0.1:7890/` is trusted as local admin
- `http://localhost:7890/` is helper access and requires login
- remote or non-canonical host access also requires login

When helper access is redirected to `/login`, the login form must preserve the
original target path and query in a hidden redirect field so a successful
helper login returns the browser to the original route, such as `/app/index`,
instead of always sending it to `/`.

The default bind is `0.0.0.0:7890`, so the service is reachable on local and VPN interfaces unless the host firewall blocks it.
Run `dashboard serve --ssl` to enable HTTPS with the generated self-signed
certificate stored under `~/.developer-dashboard/certs/`, and verify the local
listener at `https://127.0.0.1:7890/`.
Shared `nav/*.tt` fragments now wrap horizontally and inherit bookmark theme
colors from CSS variables, so bookmark pages with dark panels do not force a
light nav strip or unreadable nav link text.

Process management does not trust pid files alone. The runtime validates managed web and collector processes by environment marker or process title, and uses a `pkill`-style scan fallback when pid state is stale.

Security baseline:

- helper passwords must be at least 8 characters long
- helper sessions are remote-bound and expire automatically
- the local server adds CSP, frame-deny, nosniff, no-referrer, and no-store headers

The extension layer now includes:

- config-backed provider pages resolved through the page resolver
- action execution through the page action runner
- user CLI hook directories under `~/.developer-dashboard/cli`
- project-aware Docker Compose resolution through `dashboard docker compose`

Compose setup can now stay isolated in service folders under `./.developer-dashboard/docker/<service>/compose.yml` for the current project, with `~/.developer-dashboard/config/docker/<service>/compose.yml` as the fallback. The wrapper infers service names from passthrough docker compose args such as `config green` before building the final `docker compose` command. When no service name is passed, the resolver scans isolated service folders and preloads every non-disabled folder. A folder containing `disabled.yml` is skipped. Each isolated folder contributes `development.compose.yml` when present, otherwise `compose.yml`. The compose runtime also exports `DDDC` as the effective config-root docker directory for the current runtime so YAML can continue to use `${DDDC}` paths internally. Wrapper-only flags are consumed first and remaining docker compose flags such as `-d` and `--build` pass through untouched.
Without `--dry-run`, the wrapper now hands off with `exec`, so terminal users see the normal streaming output from `docker compose` itself instead of a dashboard JSON wrapper.
Path aliases can now be managed from the CLI with `dashboard path add <name> <path>` and `dashboard path del <name>`. These commands persist user-defined aliases in the effective config root, using a project-local `./.developer-dashboard` tree first when it exists and otherwise the home runtime. Both repeated adds and repeated deletes are intentionally idempotent. When an added path lives under the current home directory, the stored config rewrites it to `$HOME/...` so a shared dashboard config directory does not hard-code one developer's absolute home path.
Legacy `Folder` compatibility now also accepts the root-style names exposed by `dashboard paths`, so `Folder->runtime_root`, `Folder->bookmarks_root`, and `Folder->config_root` resolve through the existing legacy aliases without adding separate wrapper methods. Before `Folder->configure(...)` runs, those runtime-backed names now lazily bootstrap a default dashboard path registry from `HOME` instead of dying. Plain `Folder` calls also lazy-load config-backed path aliases from the active runtime, so direct compatibility calls such as `Folder->docker` match the aliases shown by `dashboard paths`.
`dashboard init` now seeds `welcome`, `api-dashboard`, and `db-dashboard` as editable saved bookmarks when those ids are missing.

## Release To PAUSE

The GitHub workflow:

- `.github/workflows/release-cpan.yml`

builds the release using Dist::Zilla:

```bash
rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
dzil build
```

Before publishing to PAUSE, remove older build directories and tarballs first so only the current release artifact remains, then validate the exact tarball that will ship:

```bash
rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
dzil build
tar -tzf Developer-Dashboard-1.33.tar.gz | grep run-host-integration.sh
cpanm /tmp/Developer-Dashboard-1.33.tar.gz -v
```

and uploads the resulting tarball to PAUSE using:

- `PAUSE_USER`
- `PAUSE_PASS`

stored as GitHub Actions secrets.

The release workflow bootstraps the C<App::Cmd> dependency chain explicitly before C<Dist::Zilla>, including modules such as C<Module::Pluggable::Object>, C<Getopt::Long::Descriptive>, C<Class::Load>, and C<IO::TieCombine>, so fresh GitHub runners do not fail during release dependency installation when C<Dist::Zilla> pulls in the C<App::Cmd::*> stack. It also installs C<Dist::Zilla::Plugin::MetaProvides::Package> so generated META files include an explicit C<provides> section.
Both shipped GitHub workflows now pin C<actions/checkout@v5> and set C<FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true> so hosted runners do not rely on the deprecated Node 20 JavaScript-action runtime.

Generated release metadata should also include repository resources plus an
explicit C<provides> section, and the repository root should ship
F<SECURITY.md> and F<CONTRIBUTING.md>.

Runtime JSON handling is implemented with `JSON::XS`, including the shell bootstrap helper used by `dashboard shell bash`.
The Dist::Zilla runtime prerequisite list pins `JSON::XS` explicitly so PAUSE
and other clean-install test environments always see that dependency in the
built tarball metadata.

Command-output capture is implemented with `Capture::Tiny` `capture`, with exit codes returned from the capture block. The core runtime does not currently make outbound HTTP client requests.

## Coverage Verification

Before release, verify the library coverage target:

```bash
eval "$(perl -I ~/perl5/lib/perl5 -Mlocal::lib=~/perl5)"
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
cover -report text -select_re '^lib/' -coverage statement -coverage subroutine
```

Release quality requires a reviewed coverage report for `lib/` alongside a green test suite.
