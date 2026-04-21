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
the final browser DOM. With no arguments it runs the built-in Ajax
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
`pagehide` cleanup beacons. For browser streaming checks, use `stream_data()`
or `stream_value()` against a finite saved Ajax handler and assert the final
DOM after incremental chunks land.

## Coverage

Install Devel::Cover in a local Perl library and generate the coverage report:

```bash
cpanm --local-lib-contained ./.perl5 Devel::Cover
export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
export PATH="$PWD/.perl5/bin:$PATH"
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
PERL5OPT=-MDevel::Cover prove -lr t
cover -report text -select_re '^lib/' -coverage statement -coverage subroutine
```

Developer Dashboard expects a reviewed `lib/` coverage report before release, and the current repository target is 100% statement and subroutine coverage for `lib/`.

The coverage-closure suite includes managed collector loop start/stop paths under `Devel::Cover`, including wrapped fork coverage in `t/14-coverage-closure-extra.t`, so the covered run stays green without breaking TAP from daemon-style child processes.
GitHub workflow coverage gates must match the `Devel::Cover` `Total` summary
line by regex rather than one fixed-width spacing layout, because runner or
module upgrades can change column padding without changing the real
`100.0 / 100.0 / 100.0` result.
The `t/07-core-units.t` collector loop guard treats both `HARNESS_PERL_SWITCHES` and `PERL5OPT` as valid `Devel::Cover` signals, because this machine uses both launch styles during verification.
The runtime-manager coverage cases also use bounded child reaping for stubborn process shutdown scenarios, so `Devel::Cover` runs do not stall indefinitely after the escalation path has already been exercised.
The focused skill regression in `t/19-skill-system.t` now also exercises `PathRegistry::installed_skill_docker_roots()` directly, including the default enabled-only view and the explicit `include_disabled => 1` path, so skill docker layering changes do not quietly drag the reviewed `lib/` total below `100.0 / 100.0 / 100.0`.
That same focused skill regression now also locks the same-repo
`DD-OOP-LAYERS` fallback contract inside one skill name, including inherited
fallback for missing `cli/<command>` files, missing bookmark files, missing
`dashboards/nav/` folders, and missing skill config keys.
The release-metadata checks also reject repeated FULL-POD-DOC template prose in shipped Perl assets, so contributors have to document the actual responsibility of each module or staged helper instead of pasting one generic block across the tree. The release gate also treats one-line or placeholder POD as a failure: shipped Perl docs must cover real inputs, outputs or side effects, command/runtime position, and multiple concrete examples.
The tarball release gate now also includes `t/36-release-kwalitee.t`, which
reads the built `Developer-Dashboard-X.XX.tar.gz` through
`Module::CPANTS::Analyse` and fails unless every kwalitee indicator passes.
Use that tarball-focused check for CPANTS drift; the source tree itself is not
the right surface for this analyzer.
The contributor contract now lives here plus `AGENTS.override.md` and
`agents.md`, not in the top-level product manual in `README.md` or
`Developer::Dashboard.pm`. Those two files stay synced as user-facing product
documentation instead of repeating repo-process rules.
When editing `Developer::Dashboard.pm`, audit the whole shipped manual, not
just the paragraph you touched. In particular, the FAQ wording must describe
real product behavior rather than contributor-only framing, and the `SEE ALSO`
section must use stable local section links instead of brittle private-module
targets that can degrade into broken rendered links. The rest of the top-level
manual should also stay self-contained: prefer plain code references such as
`Developer::Dashboard::PathRegistry` over POD links to private modules, so the
main product guide does not depend on MetaCPAN cross-linking to remain usable.
The same boundary applies to repo-internal Markdown filenames: user-facing
manuals and shipped Perl POD must not send readers to `*.md` files by name.
If a product guide needs to refer to one of those internal documents, describe
it conceptually instead of exposing the repository filename.
Markdown files themselves are also checkout-only documentation and must not be
released in the CPAN tarball. Keep the `dist.ini` Markdown exclusion in place,
and treat any shipped `*.md` file as a release-gate failure.
The built distribution should still ship a plain top-level `README`, so CPAN
and kwalitee consumers receive a readme without reopening the checkout-only
documentation set.
The repository root `LICENSE` should also stay a single canonical GPL text
that GitHub can classify, while the alternative Perl Artistic option remains
available in `LICENSE-Artistic-1.0-Perl`.
The same release boundary applies to repo-only verification and bootstrap
folders: `integration/` and the top-level `updates/` checkout helpers are not
installed runtime assets and must stay out of the release tarball. The shipped
runtime contract for `dashboard update` is the user-provided layered command
under `.developer-dashboard/cli/update` or `.developer-dashboard/cli/update.d`,
not the repository's checkout-only `updates/` folder.
Shipped library modules must also load correctly from an installed tarball.
Do not use `FindBin` or source-tree-relative `use lib` bootstrapping inside
repo-owned `.pm` files that are meant to run from the installed distribution.
Keep checkout-only bootstrap logic in entrypoints or tests, then prove the
built distribution with the packaged-tree and blank-environment gates.

Branch and condition reports are still generated and should be used to drive new edge-case tests, especially when adding new runtime modules.

Frontend editor changes should also be checked in a real browser route, not just from HTML output. In particular, the bookmark editor overlay must keep the visible syntax-highlighted source aligned with the real textarea caret while typing, must not soft-wrap differently from the textarea, and exact saved `/app/<id>/edit` repros with multi-line `<script>` blocks must be checked in Chromium so the editor keeps its highlight spans without drifting onto the wrong line.

JSON behavior is exercised through the shared `Developer::Dashboard::JSON` wrapper, which now uses `JSON::XS`.
Release metadata checks also verify that built tarball runtime prerequisites
explicitly include `JSON::XS`.
When a code change introduces a new runtime Perl module, declare it in all
three release metadata sources in the same change: `Makefile.PL`, `cpanfile`,
and `dist.ini`. The release metadata guardrail fails if a required non-core
runtime module is missing from one of those files, so dependency drift is
caught before `dzil build`, blank-environment installs, or CI releases.
The shell bootstrap regression coverage also checks that the POSIX `cdr` and
`which_dir` helpers decode their JSON payloads through the same Perl
interpreter that generated the shell fragment, which prevents macOS
`JSON::XS` ABI mismatches when `/usr/bin/perl` and `~/perl5` belong to
different Perl builds.
Those shell-helper regression assertions also normalize printed path identity,
so macOS `/var/...` versus `/private/var/...` aliases do not fail otherwise
equivalent `pwd` or `which_dir` output checks.

Command execution paths are exercised through `Capture::Tiny` `capture` wrappers that return exit codes from the capture block itself rather than reading `$?` afterward.

## Process Management Checks

The test suite also covers collector loop management:

- managed loop reuse by matching process title
- stale pid cleanup
- foreign process protection
- updater detection of validated running loops

The runtime-manager tests also cover:

- background web startup handshake and web-state persistence
- `dashboard serve` collector startup and failure handling, including explicit startup errors and cleanup of already-started loops when a later collector fails
- DD-OOP-LAYERS canonical-path normalization, including a symlinked-home versus canonical-cwd regression that matches macOS `/var/...` and `/private/var/...` alias behaviour
- CLI `dashboard path project-root` assertions compare path identity instead of raw strings, so packaged installs stay green when macOS resolves the same temp repo through `/private/var/...`
- shell-helper `cdr` and `which_dir` assertions also normalize those `/var/...` versus `/private/var/...` aliases, so source-tree and packaged macOS runs do not fail on equivalent canonical paths
- `dashboard web: <host>:<port>` process-title detection
- `pkill` fallback when pid files are stale or missing
- `/proc` listener-pid fallback when minimal Linux containers do not provide `ss`
- packaged fallback assertions that stub `_find_web_processes`, so ambient live dashboard processes on the host cannot contaminate the recorded-pid branch during source-tree, tarball, or PAUSE install runs
- `dashboard stop` and `dashboard restart` lifecycle behavior

The extension tests also cover:

- config-backed path alias registration
- shell helper `cdr` and `which_dir` flows where the first argument may be a saved alias, remaining arguments narrow the alias root with AND-matched regex directory keywords, and non-alias arguments search beneath the current directory with the same regex contract
- `dashboard of` and `dashboard open-file` regex scope searches, including `Ok\.js$`-style exact suffix matches that must not drift into broader files such as `ok.json`
- Java class lookup through live `.java` files, local source archives such as source jars and `src.zip`, and cached Maven source-jar downloads when no local source file exists
- provider page resolution
- trusted versus transient action execution policy
- `dashboard doctor` audits of the current home runtime plus older `$HOME/bookmarks`, `$HOME/config`, `$HOME/cli`, and `$HOME/checkers` trees, including `--fix` permission repair and `cli/doctor.d` hook result capture
- encoded action payload execution
- CLI hook directories under `~/.developer-dashboard/cli/<command>` or `~/.developer-dashboard/cli/<command>.d` with sorted executable-only hook execution, live streamed hook progress, per-hook `RESULT` rewrites between hook runs, and `Runtime::Result` helper coverage
- explicit `[[STOP]]` hook-stop behavior, where only the stderr marker skips later hook files while control still returns to the main command path
- `LAST_RESULT` chaining through `Developer::Dashboard::Runtime::Result`, so each hook and the final command can inspect the immediate previous hook as `{ file, exit, STDOUT, STDERR }`
- oversized hook `RESULT` payloads spilling into `RESULT_FILE` before `exec()` would hit the kernel arg/env limit, while later hooks and final commands still read the same logical result set through `Runtime::Result`
- directory-backed custom commands through `~/.developer-dashboard/cli/<command>/run`
- non-destructive home helper staging, with dashboard-managed helpers isolated under `~/.developer-dashboard/cli/dd/` and user commands plus hooks preserved under `~/.developer-dashboard/cli/`
- MD5-aware `dashboard init` helper and seed refreshes, including unchanged mtimes when a dashboard-managed helper or seeded starter page already matches the shipped content
- stale managed `api-dashboard` / `sql-dashboard` saved copies refreshing to the current shipped seed when they still match the recorded managed digest, including known historical `sql-dashboard` digests from pre-manifest runtimes, while diverged user-edited saved pages stay untouched
- empty-object `config.json` bootstrapping when `dashboard init` or `dashboard config init` finds no existing config file, without seeding an example collector
- project-local `./.developer-dashboard` precedence over the home fallback for bookmarks, config, CLI commands and hooks, auth users, sessions, and isolated docker service folders
- seeded `dashboard init` starter pages for `api-dashboard` and `sql-dashboard`
- browser-check the seeded `api-dashboard` bookmark in a fresh runtime and verify the Postman-style shell renders the collection tabs, request tabs, request-token form for `{{token}}` placeholders, the hide/show request-credentials panel with the supported auth presets, import/export controls, file-backed collections loaded from `config/api-dashboard`, and that the `config/api-dashboard` directory plus saved collection files are tightened to `0700` / `0600`
- keep `t/22-api-dashboard-playwright.t` disk-backed by waiting for the saved collection JSON to contain the newly created request before later export/import/reload assertions, so the browser flow proves persisted collection state instead of only optimistic in-memory tabs
- when debugging `api-dashboard` import failures against a user-provided Postman file, run `API_DASHBOARD_IMPORT_FIXTURE=/path/to/collection.postman_collection.json prove -lv t/23-api-dashboard-import-fixture-playwright.t` to verify that the browser import control can load the fixture, render the collection in the Collections tab, and persist the Postman JSON to `config/api-dashboard`
- when changing `api-dashboard` import transport or large collection handling, run `prove -lv t/25-api-dashboard-large-import-playwright.t` to verify that an above-threshold Postman import still completes through the browser without tripping the saved-Ajax process argument limit
- when changing the `api-dashboard` layout, run `prove -lv t/24-api-dashboard-tabs-playwright.t` to keep the top-level Collections/Workspace tabs, the collection tab strip, and the inner Request Details/Response Body/Response Headers tabs below the response `pre` browser-verified
- browser-check the seeded `sql-dashboard` bookmark in a fresh runtime and verify the profile tabs, merged `SQL Workspace` tab, inner `Collection` and `Run SQL` workspace tabs, workspace left-nav collection tabs plus saved SQL list, visible active saved-SQL label, large auto-resizing editor, quiet action row beneath the editor, inline `[X]` delete affordances in the saved-SQL list, schema explorer, schema table filter box, schema copy/view-data actions, human type and length labels in the schema column list, shareable `connection` URL state, file-backed connection profiles loaded from `config/sql-dashboard`, file-backed SQL collections loaded from `config/sql-dashboard/collections`, both directory trees at `0700`, and saved profile/collection files at `0600`
- when debugging an upgraded SQL Dashboard runtime, check `dashboard page source sql-dashboard` first; a user-owned `~/.developer-dashboard/dashboards/sql-dashboard` override shadows the shipped seeded page, so stale browser behavior can come from that saved override instead of the current repo copy
- when changing starter-page refresh logic, run `prove -lv t/04-update-manager.t`, `prove -lv t/05-cli-smoke.t`, and `prove -lv t/27-sql-dashboard-playwright.t` so both the init/update seed refresh path and the real browser route stay covered against stale managed saved copies
- when changing bookmark rendering, verify both the browser route and the CLI render path with the same TT bookmark: run `prove -lv t/05-cli-smoke.t` for `dashboard page render <id>` coverage and `integration/browser/run-bookmark-browser-smoke.pl --bookmark-file /path/to/bookmark` for the browser route
- when changing Template Toolkit rendering or `nav/*.tt`, verify syntax-error handling too: broken TT must surface a visible `runtime-error` block and must not leak raw `[% ... %]` source in either the browser route or `dashboard page render`
- when changing `dashboard serve --ssl`, run `prove -lv t/17-web-server-ssl.t` and `prove -lv t/33-web-server-ssl-browser.t` so both the certificate profile and the real Chromium browser path stay covered; the generated cert must keep SAN coverage for `localhost`, `127.0.0.1`, `::1`, the concrete non-wildcard bind host, and any configured `web.ssl_subject_alt_names`, older dashboard certs must regenerate when stale or when the expected SAN list changes, plain HTTP must redirect on the public port, and Chromium must reach the privacy interstitial plus the real dashboard page when certificate trust is bypassed for the test browser, including one configured alias hostname
- when changing the bookmark-local SQL execution, collection, or schema browser flow, run `prove -lv t/26-sql-dashboard.t` for the metadata-handle regression, `prove -lv t/27-sql-dashboard-playwright.t` for the fake-driver browser route, `PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi prove -lv t/31-sql-dashboard-sqlite-playwright.t` for the 54-case real SQLite browser matrix, and `PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi prove -lv t/32-sql-dashboard-rdbms-playwright.t` when `DBD::mysql`, `DBD::Pg`, `DBD::ODBC`, and `DBD::Oracle` are installed so optional docker-backed MySQL/PostgreSQL/MSSQL/Oracle coverage stays healthy too; on this host MSSQL and Oracle also expect the user-space client libraries to be exposed through `LD_LIBRARY_PATH` and, for Oracle, `ORACLE_HOME`; schema browse must keep reading `table_info` / `column_info` rows directly and must not call `execute()` on those metadata handles
- when validating passwordless SQL flows, verify that SQLite profiles can save and reload with a blank user, that the portable `connection=dsn|user` route preserves that blank user, and that shared reloads do not invent a password warning for DSNs that do not need local credentials
- when changing runtime-local optional Perl dependency handling, run `prove -lv t/05-cli-smoke.t` and `prove -lv t/28-runtime-cpan-env.t` to verify `dashboard cpan DBD::Driver` still installs into `./.developer-dashboard/local`, appends the runtime `cpanfile`, records `DBI` automatically for requested `DBD::*` drivers, and keeps the runtime-local `PERL5LIB` wiring script-local instead of reintroducing a dedicated manager module
- Docker Compose file, project, service, addon, mode, and env resolution
- bookmark syntax parsing, placeholder rendering, `TITLE` head-only rendering, and sandpit-isolated `CODE*` execution

The repository also now enforces:

- function-level purpose/input/output comments across the Perl codebase
- POD trailers under `__END__` for modules, scripts, update scripts, and tests
- `FULL-POD-DOC` sections in every repo-owned Perl file, covering purpose, why
  the file exists, when to use it, how to use it, what uses it, and multiple
  concrete examples that include the common path plus at least one meaningful
  edge or debugging path when the file owns one, with
  `t/15-release-metadata.t` acting as the release gate for that documentation
  floor
- a full-manual audit whenever `Developer::Dashboard.pm` changes, including
  FAQ wording, `SEE ALSO` target validation, and rejection of brittle
  `L<Developer::Dashboard::...>` private-module links in
  `t/15-release-metadata.t`
- rejection of repo-internal `*.md` filename references in the synced
  top-level product manuals and in shipped Perl POD, enforced through
  `t/15-release-metadata.t`
- explicit setup for env-sensitive tests, so checks that depend on blank
  variables such as `RESULT` clear or localize that state instead of assuming
  the parent shell or packaging harness starts empty

The web tests also cover the access model:

- exact `127.0.0.1` admin bypass
- `localhost` helper login requirement
- helper login session creation and logout
- helper session remote-address binding and expiry validation paths
- forwarding of response headers such as `Location` and `Set-Cookie`
- root free-form editor behavior at `/`
- posted instruction handling through `/`, including default denial of unsaved transient execution unless `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is enabled
- saved bookmark browser edits through `/app/<id>/edit`, including named-route saves and non-transient play links when transient URL execution stays disabled
- malformed bookmark icon bytes from older files are repaired into stable fallback glyphs on both `/app/<id>` and `/app/<id>/edit`, so browser verification should check for visible fallback icons instead of `�`
- nested saved bookmark ids such as `nav/foo.tt` through `/app/...`, `/app/.../edit`, and `/app/.../source`
- shared `nav/*.tt` bookmark rendering between top chrome and the main page body in sorted filename order
- raw `nav/*.tt` TT/HTML fragment rendering between top chrome and the main page body, plus direct `/app/nav/<name>.tt` and `/source` coverage for those raw fragment files
- Template Toolkit conditional rendering for shared nav fragments and saved pages using `env.current_page` and `env.runtime_context.current_page`
- `/apps -> /app/index` compatibility
- top chrome rendering on edit and saved render pages
- denial of browser `token=` and `atoken=` execution for transient page and action payloads, plus transient `/ajax?token=...`, when the transient URL opt-in env var is absent
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
The release gather rules also exclude local `cover_db` output so a covered
host run does not contaminate the tarball under test.
The release gather rules must also exclude local scratch and dependency trees
such as `node_modules/` and `test_by_michael/`. Those paths are source-tree
implementation details, not distributable runtime assets, so release metadata
must fail before build or release if they are gathered into the tarball.

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
- should be interpreted together with the tracked source-tree integration assets in `doc/integration-test-plan.md`, `doc/windows-testing.md`, and `integration/browser/run-bookmark-browser-smoke.pl`; source-tree tests now fail if those release/support assets are missing from git even when they still exist locally

## Windows Verification

For Windows-targeted changes, keep the verification layered:

- run the fast forced-Windows unit coverage in `t/`
- run the real Strawberry Perl smoke on a Windows host with `integration/windows/run-strawberry-smoke.ps1`
- run the full-system QEMU guest smoke with `integration/windows/run-host-windows-smoke.sh` before making a release-grade Windows compatibility claim

The Strawberry smoke verifies `dashboard shell ps`, `dashboard ps1`, one
PowerShell-backed collector command, one saved Ajax PowerShell handler through
`Invoke-WebRequest`, and a browser DOM dump through Edge or Chrome when either
browser is present in the Windows environment.
In the Dockur-backed guest path, the launcher stages the Strawberry Perl MSI
from the Linux host and the Windows tarball install currently uses
`cpanm --notest` for third-party dependency setup before the real dashboard
runtime smoke runs.
The supported Windows runtime baseline is PowerShell plus Strawberry Perl.
Git Bash is optional. Scoop is optional. They remain setup helpers, not
runtime requirements for Developer Dashboard itself.
