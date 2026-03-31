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

- plugin file loading and path alias registration
- provider page resolution
- trusted versus transient action execution policy
- encoded action payload execution
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

- creates a fake project through `DEVELOPER_DASHBOARD_BOOKMARKS`, `DEVELOPER_DASHBOARD_CONFIGS`, and `DEVELOPER_DASHBOARD_STARTUP`
- verifies installed CLI and saved bookmarks from that fake project plus startup collectors from that fake project
- extracts the same tarball inside the container so `dashboard update` runs against built artifact contents
- uses headless Chromium to validate the editor, the saved fake-project bookmark page, and the helper login page
