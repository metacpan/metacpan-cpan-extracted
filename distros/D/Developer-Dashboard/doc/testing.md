# Testing

## Test Suite

Run the full test suite with:

```bash
prove -lr t
```

Run the fast saved-bookmark browser smoke check with:

```bash
integration/browser/run-bookmark-browser-smoke.pl
```

That host-side smoke runner creates an isolated temporary runtime, starts the
checkout-local dashboard, loads one saved bookmark page through headless
Chromium, and can assert page-source fragments, saved `/ajax/...` output, and
the final browser DOM. With no arguments it runs the built-in legacy Ajax
`foo.bar` bookmark case.

For a real bookmark file, point it at the saved file and add the specific
browser assertions you care about:

```bash
integration/browser/run-bookmark-browser-smoke.pl \
  --bookmark-file ~/.developer-dashboard/dashboards/test \
  --expect-page-fragment "set_chain_value(foo,'bar','/ajax/foobar?type=text')" \
  --expect-ajax-path /ajax/foobar?type=text \
  --expect-ajax-body 123 \
  --expect-dom-fragment '<span class="display">123</span>'
```

For long-running saved bookmark Ajax handlers that would otherwise survive a
browser refresh, prefer `Ajax(..., singleton => 'NAME', ...)`. The runtime will
rename the Perl worker to `dashboard ajax: NAME`, terminate the older matching
Perl stream before it starts the refreshed one, and also tear down matching
singleton workers during `dashboard stop`, `dashboard restart`, and browser
`pagehide` cleanup beacons.

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

Frontend editor changes should also be checked in a real browser route, not just from HTML output. In particular, the bookmark editor overlay must keep the visible syntax-highlighted source aligned with the real textarea caret while typing, must not soft-wrap differently from the textarea, and exact saved `/app/<id>/edit` repros with multi-line `<script>` blocks must be checked in Chromium so the editor keeps its highlight spans without drifting onto the wrong line.

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
- `/proc` listener-pid fallback when minimal Linux containers do not provide `ss`
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
- posted instruction handling through `/`, including default denial of unsaved transient execution unless `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is enabled
- saved bookmark browser edits through `/app/<id>/edit`, including named-route saves and non-transient play links when transient URL execution stays disabled
- malformed legacy bookmark icon bytes are repaired into stable fallback glyphs on both `/app/<id>` and `/app/<id>/edit`, so browser verification should check for visible fallback icons instead of `�`
- nested saved bookmark ids such as `nav/foo.tt` through `/app/...`, `/app/.../edit`, and `/app/.../source`
- shared `nav/*.tt` bookmark rendering between top chrome and the main page body in sorted filename order
- Template Toolkit conditional rendering for shared nav fragments and saved pages using `env.current_page` and `env.runtime_context.current_page`
- `/apps -> /app/index` compatibility
- top chrome rendering on edit and legacy render pages
- denial of browser `token=` and `atoken=` execution for transient page and action payloads, plus legacy `/ajax?token=...`, when the transient URL opt-in env var is absent
- absence of accidental project-local `.developer-dashboard` creation when `dashboard restart` runs inside a git repo that has not opted into a local dashboard root
- saved bookmark `Ajax file => ...` handlers through `/ajax/<file>?type=...`, including `dashboards/ajax/...` storage, direct process-backed streamed ajax execution for both `stdout` and `stderr`, and blank-env verification under the default deny policy
- file-backed saved Ajax Perl wrappers with autoflushed `STDOUT` and `STDERR`, including a timing check that long-running `print` plus `sleep` handlers emit early chunks instead of buffering until exit

## Blank Environment Integration

Run the host-built tarball integration flow with:

```bash
integration/blank-env/run-host-integration.sh
```

This integration path builds the distribution tarball on the host with
`dzil build`, runs the prebuilt `dd-int-test:latest` container with only that
tarball mounted into it, installs the tarball with `cpanm`, and then
exercises the installed `dashboard` command inside the clean Perl container.

The shipped runtime-manager lifecycle checks now also fall back to `/proc`
socket ownership scans when that prebuilt image does not include `ss`, and
they re-probe the managed port for late listener pids before restart, so the
integration flow verifies the same stop/restart behavior that a minimal Linux
runtime will see in practice.
Those checks also cover the Starman master-worker split, where the recorded
managed pid can be the master while the bound listener pid is a separate
worker process on the same managed port.

The integration flow also:

- creates a fake project with its own `./.developer-dashboard` runtime tree
- creates that fake-project runtime tree only after `cpanm` completes, so the tarball's own test phase still runs against a clean runtime
- verifies installed CLI and saved bookmarks from that fake project's local runtime plus config collectors from that same runtime root
- verifies `dashboard version` reports the installed runtime version
- seeds a user-provided fake-project `./.developer-dashboard/cli/update` command plus `update.d` hooks inside the container and verifies `dashboard update` uses the same executable command-hook path as every other top-level subcommand, including later-hook reads through `Runtime::Result`
- verifies the installed web app denies `/?token=...` browser execution by default while saved bookmark routes still render
- uses headless Chromium to validate the editor, the saved fake-project bookmark page, and the helper login page
- verifies that an installed long-running saved `/ajax/...` route starts streaming visible output within the expected first seconds instead of buffering until process exit
