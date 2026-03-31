# Update And Release

## Local Update

Run:

```bash
perl -Ilib bin/dashboard update
```

This executes ordered scripts from `updates/`:

1. bootstrap runtime config and starter pages
2. refresh Perl dependencies with `cpanm --installdeps .`
3. write shell bootstrap and append it to the user shell rc file if needed

The update manager also stops running collectors before updates and restarts them afterward.

## Local Usage

Initialize runtime state:

```bash
perl -Ilib bin/dashboard init
```

Serve the local app in the background:

```bash
perl -Ilib bin/dashboard serve
```

The root path now opens the free-form bookmark editor directly, and `/apps` redirects to `/app/index`.
If the posted editor content includes `BOOKMARK: some-id`, that post now persists the bookmark document so `/app/some-id` works immediately after saving from `/`.
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
export DEVELOPER_DASHBOARD_STARTUP="$HOME/my-dd-startup"
export DEVELOPER_DASHBOARD_CHECKERS="docker.health:repo.status"
```

Access semantics:

- `http://127.0.0.1:7890/` is trusted as local admin
- `http://localhost:7890/` is helper access and requires login
- remote or non-canonical host access also requires login

The default bind is `0.0.0.0:7890`, so the service is reachable on local and VPN interfaces unless the host firewall blocks it.

Process management does not trust pid files alone. The runtime validates managed web and collector processes by environment marker or process title, and uses a `pkill`-style scan fallback when pid state is stale.

Security baseline:

- helper passwords must be at least 8 characters long
- helper sessions are remote-bound and expire automatically
- the local server adds CSP, frame-deny, nosniff, no-referrer, and no-store headers

The extension layer now includes:

- JSON plugin packs in the global or repo-local plugins directory
- provider pages resolved through the page resolver
- action execution through the page action runner
- project-aware Docker Compose resolution through `dashboard docker compose`

Compose setup can now stay isolated in service folders under `~/.developer-dashboard/config/docker/<service>/compose.yml` without adding JSON config entries, and the wrapper infers service names from passthrough docker compose args such as `config green` before building the final `docker compose` command. When no service name is passed, the resolver scans isolated service folders and preloads every non-disabled folder. A folder containing `disabled.yml` is skipped. Each isolated folder contributes `development.compose.yml` when present, otherwise `compose.yml`. The compose runtime also exports `DDDC` as that global docker config root so YAML can continue to use `${DDDC}` paths internally. Wrapper-only flags are consumed first and remaining docker compose flags such as `-d` and `--build` pass through untouched.
Without `--dry-run`, the wrapper now hands off with `exec`, so terminal users see the normal streaming output from `docker compose` itself instead of a dashboard JSON wrapper.
Path aliases can now be managed from the CLI with `dashboard path add <name> <path>` and `dashboard path del <name>`. These commands persist user-defined aliases in the global config, and both repeated adds and repeated deletes are intentionally idempotent. When an added path lives under the current home directory, the stored config rewrites it to `$HOME/...` so a shared dashboard config directory does not hard-code one developer's absolute home path.

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
tar -tzf Developer-Dashboard-0.72.tar.gz | grep run-host-integration.sh
cpanm /tmp/Developer-Dashboard-0.72.tar.gz -v
```

and uploads the resulting tarball to PAUSE using:

- `PAUSE_USER`
- `PAUSE_PASS`

stored as GitHub Actions secrets.

The release workflow bootstraps the C<App::Cmd> dependency chain explicitly before C<Dist::Zilla>, including modules such as C<Module::Pluggable::Object>, C<Getopt::Long::Descriptive>, C<Class::Load>, and C<IO::TieCombine>, so fresh GitHub runners do not fail during release dependency installation when C<Dist::Zilla> pulls in the C<App::Cmd::*> stack.

Runtime JSON handling is implemented with `JSON::XS`, including the shell bootstrap helper used by `dashboard shell bash`.

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
