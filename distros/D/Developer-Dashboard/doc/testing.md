# Testing

## Test Suite

Run the full test suite with:

```bash
prove -lr t
```

## Coverage

Install Devel::Cover in a local Perl library and generate the coverage report:

```bash
cpanm --local-lib-contained ./.perl5 Devel::Cover
export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
export PATH="$PWD/.perl5/bin:$PATH"
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
cover -report text -select_re '^lib/' -coverage statement -coverage subroutine
```

Developer Dashboard expects a reviewed `lib/` coverage report before release, and the current repository target is 100% statement and subroutine coverage for `lib/`.

The coverage-closure suite includes managed collector loop start/stop paths under `Devel::Cover`, including wrapped fork coverage in `t/14-coverage-closure-extra.t`, so the covered run stays green without breaking TAP from daemon-style child processes.

Branch and condition reports are still generated and should be used to drive new edge-case tests, especially when adding new runtime modules.

JSON behavior is exercised through the shared `Developer::Dashboard::JSON` wrapper, which now uses `JSON::XS`.
Release metadata checks also verify that built tarball runtime prerequisites
explicitly include `JSON::XS`.

Command execution paths are exercised through `Capture::Tiny` `capture` wrappers that return exit codes from the capture block itself rather than reading `$?` afterward.

## Process Management Checks

The test suite also covers collector loop management:

- managed loop reuse by matching process title
- stale pid cleanup
- foreign process protection
- updater detection of validated running loops

The runtime-manager tests also cover:

- background web startup handshake and web-state persistence
- `dashboard web: <host>:<port>` process-title detection
- `pkill` fallback when pid files are stale or missing
- `dashboard stop` and `dashboard restart` lifecycle behavior

The extension tests also cover:

- config-backed path alias registration
- provider page resolution
- trusted versus transient action execution policy
- encoded action payload execution
- CLI hook directories under `~/.developer-dashboard/cli/<command>` or `~/.developer-dashboard/cli/<command>.d` with sorted executable-only hook execution, live streamed hook progress, per-hook `RESULT` rewrites between hook runs, and `Runtime::Result` helper coverage
- directory-backed custom commands through `~/.developer-dashboard/cli/<command>/run`
- project-local `./.developer-dashboard` precedence over the home fallback for bookmarks, config, CLI commands and hooks, auth users, sessions, and isolated docker service folders
- seeded `dashboard init` starter pages for `welcome`, `api-dashboard`, and `db-dashboard`
- Docker Compose file, project, service, addon, mode, and env resolution
- legacy bookmark syntax parsing, placeholder rendering, `TITLE` head-only rendering, and sandpit-isolated `CODE*` execution

The repository also now enforces:

- function-level purpose/input/output comments across the Perl codebase
- POD trailers under `__END__` for modules, scripts, update scripts, and tests

The web tests also cover the access model:

- exact `127.0.0.1` admin bypass
- `localhost` helper login requirement
- helper login session creation and logout
- helper session remote-address binding and expiry validation paths
- forwarding of response headers such as `Location` and `Set-Cookie`
- root free-form editor behavior at `/`
- posted instruction handling through `/`
- nested saved bookmark ids such as `nav/foo.tt` through `/app/...` and `/page/...`
- shared `nav/*.tt` bookmark rendering between top chrome and the main page body in sorted filename order
- Template Toolkit conditional rendering for shared nav fragments and saved pages using `env.current_page` and `env.runtime_context.current_page`
- `/apps -> /app/index` compatibility
- top chrome rendering on edit and legacy render pages

## Blank Environment Integration

Run the host-built tarball integration flow with:

```bash
integration/blank-env/run-host-integration.sh
```

This integration path builds the distribution tarball on the host with
`dzil build`, starts a blank container with only that tarball mounted into it,
installs the tarball with `cpanm`, and then exercises the installed
`dashboard` command inside the clean Perl container.

The integration flow also:

- creates a fake project with its own `./.developer-dashboard` runtime tree
- creates that fake-project runtime tree only after `cpanm` completes, so the tarball's own test phase still runs against a clean runtime
- verifies installed CLI and saved bookmarks from that fake project's local runtime plus config collectors from that same runtime root
- verifies `dashboard version` reports the installed runtime version
- seeds a user-provided fake-project `./.developer-dashboard/cli/update` command plus `update.d` hooks inside the container and verifies `dashboard update` uses the same executable command-hook path as every other top-level subcommand, including later-hook reads through `Runtime::Result`
- uses headless Chromium to validate the editor, the saved fake-project bookmark page, and the helper login page
