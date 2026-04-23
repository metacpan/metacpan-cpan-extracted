# Blank Environment Integration Test Plan

## Purpose

This plan validates that `Developer::Dashboard` can be built with `Dist::Zilla`
on the host, installed into a clean container from that built tarball, and
exercised there as an installed CLI and
web application rather than as a checkout-local script.

The goal is to prove that a new environment can:

- build the CPAN distribution tarball on the host from the repo
- install the built tarball with `cpanm`
- run the installed `dashboard` command successfully
- initialize runtime state in a fake project
- execute the major CLI surfaces through installed binaries against that fake project
- start and stop the web service
- exercise helper login and helper logout cleanup
- verify browser-facing editor and saved fake-project bookmark pages in a real headless browser
- verify the environment-variable project override flow works end to end
- verify layered `.env` and `.env.pl` loading from runtime roots and skill roots works end to end
- verify dotted skill commands that prompt on standard input still behave interactively after hook execution

## Scope

The integration run covers these command families:

- host packaging: `dzil build`
- installation: `cpanm <tarball>`
- bootstrap: `dashboard init`, user-provided `dashboard update`
- help and prompt: `dashboard`, `dashboard help`, `dashboard ps1`, `dashboard shell bash`, `dashboard shell ps`
- paths: `dashboard paths`, `dashboard path list`, `dashboard path resolve`, `dashboard path project-root`
- encoding: `dashboard encode`, `dashboard decode`
- indicators: `dashboard indicator set`, `dashboard indicator list`, `dashboard indicator refresh-core`
- collectors: `dashboard collector write-result`, `run`, `list`, `job`, `status`, `output`, `inspect`, `log`, `start`, `restart`, `stop`
- config: `dashboard config init`, `dashboard config show`
- auth: `dashboard auth add-user`, `list-users`, `remove-user`
- pages: `dashboard page new`, `save`, `list`, `show`, `encode`, `decode`, `urls`, `render`, `source`
- actions: `dashboard action run system-status paths`
- docker resolver: `dashboard docker compose --dry-run`
- web lifecycle: `dashboard serve`, `dashboard restart`, `dashboard stop`
- browser checks: headless Chromium editor, saved fake-project bookmark page, outsider bootstrap DOM verification, and helper-login DOM verification after helper-user enablement
- ajax streaming: installed long-running `/ajax/<file>` route timing, early-chunk verification, refresh-safe singleton replacement, `fetch_value()` / `stream_value()` DOM helper coverage, and browser pagehide cleanup coverage in unit tests
- windows verification assets: `integration/windows/run-strawberry-smoke.ps1` and `integration/windows/run-qemu-windows-smoke.sh`

When a release changes the skills runtime, also run the focused host-side
skill regressions outside the blank-container harness:

- `prove -lv t/19-skill-system.t`
- `prove -lv t/20-skill-web-routes.t`
- `prove -lv t/09-runtime-manager.t`

Those focused skill checks currently verify the installed-skill command and
page dispatch rules, the merged skill config behavior, repo-qualified skill
collectors joining the managed fleet used by `serve` / `restart` / `stop`,
shared nav rendering from every installed skill on both skill routes and
normal `/app/<page>` routes such as `/app/index`, the `dashboard skills list`
and `dashboard skills usage <repo>` inventory payloads, and the enable/disable
runtime boundary where disabled skills stay installed but stop contributing
commands, routes, collectors, and docker roots until they are re-enabled.
They also verify same-repo `DD-OOP-LAYERS` fallback inside one skill checkout,
including command-file fallback, bookmark-file fallback, nav-folder fallback,
and inherited skill config-key fallback from the base skill layer.

## Environment

The test container should be intentionally minimal:

- base image: official Perl runtime image
- no preinstalled Developer Dashboard
- only generic build, browser, and HTTP tooling added
- a temporary `HOME` so the installed app must bootstrap itself from scratch
- no requirement that `ss` or other iproute2 tools exist inside the image

The repo checkout is not mounted into the container as the app under test.
Only the host-built tarball is mounted into the blank container.

## Test Data

The integration run creates:

- a temporary home directory under `/tmp`
- a fake project root under `/tmp/fake-project`
- a fake project `./.developer-dashboard` tree with `dashboards`, `config`, and `cli` directories
- a saved page named `sample`
- a saved bookmark page named `project-home`
- a saved stream regression bookmark page
- shared nav bookmark pages under `nav/*.tt`
- a helper user for explicit add/remove testing
- a second helper user for browser login/logout cleanup testing
- a temporary Compose project under `/tmp`

## Execution Flow

1. Build the distribution tarball on the host with `dzil build`.
2. Start the blank container with only that host-built tarball mounted into it.
3. Copy the mounted tarball to a versioned local path inside the container and
   install that staged tarball with `cpanm`. The staged filename must keep the
   concrete `Developer-Dashboard-X.XX.tar.gz` version so `cpanm` cannot drift
   into a CPAN lookup because the bind-mounted filename is generic.
4. Create the fake-project `./.developer-dashboard` tree only after that install step succeeds so the tarball's own tests still run against a clean runtime.
5. Extract the same tarball inside the container for the rest of the installed-command checks.
6. Verify the installed CLI responds to `dashboard help`.
7. Verify bare `dashboard` returns usage output.
8. Verify `dashboard version` reports the installed runtime version.
9. Create a fake project root with a local `./.developer-dashboard` runtime tree.
10. Run `dashboard init` from inside that fake project and confirm the project-local runtime roots plus `api-dashboard` and `sql-dashboard` starter pages exist.
11. Browser-check the seeded `api-dashboard` page from that fake project and confirm the Postman-style shell shows the collection tabs, request tabs, request-token form for `{{token}}` placeholders, the hide/show request-credentials panel with the supported auth presets, import/export controls, any `./.developer-dashboard/config/api-dashboard/*.json` collections loaded on startup, and the project-local `config/api-dashboard` directory plus saved collection files tightened to `0700` / `0600`.
11.1. When an `api-dashboard` import bug only reproduces with a real external Postman file, run `API_DASHBOARD_IMPORT_FIXTURE=/path/to/collection.postman_collection.json prove -lv t/23-api-dashboard-import-fixture-playwright.t` on the host to verify that the visible browser import control can load the fixture, render the collection in the Collections tab, and persist the Postman JSON under `config/api-dashboard`.
11.2. When changing the `api-dashboard` layout, run `prove -lv t/24-api-dashboard-tabs-playwright.t` on the host to verify the top-level Collections/Workspace tabs, the collection tab strip, and the inner Request Details/Response Body/Response Headers tabs below the response `pre` in a real browser.
11.3. When changing `api-dashboard` import transport or saved-Ajax payload handling, run `prove -lv t/25-api-dashboard-large-import-playwright.t` on the host to verify that a deliberately oversized Postman collection still imports through the visible browser control without tripping the saved-Ajax argument-size limit.
12. Browser-check the seeded `sql-dashboard` page from that fake project and confirm the profile tabs, merged `SQL Workspace` tab, workspace left-nav collection tabs plus the active collection's saved SQL list, visible active saved-SQL label, large auto-resizing editor, quiet action row beneath that editor, inline `[X]` delete affordances in the saved-SQL list, schema explorer reached through the top tab, shareable `connection` URL state, any `./.developer-dashboard/config/sql-dashboard/*.json` profiles loaded on startup, any `./.developer-dashboard/config/sql-dashboard/collections/*.json` SQL collections loaded on startup, both sql-dashboard directories tightened to `0700`, saved profile/collection files tightened to `0600`, the installed-driver dropdown rewrites only the `dbi:<Driver>:` DSN prefix, saving a second SQL name into one collection creates another saved SQL entry instead of overwriting the selected one, and a shared URL without a locally saved password rebuilds a draft connection profile instead of leaking a password.
12.1. When changing SQL dashboard browser UX or SQLite behavior, run `PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi prove -lv t/31-sql-dashboard-sqlite-playwright.t` on the host to exercise the 51-case real SQLite matrix, including blank-user connection profiles, collection UX, schema browsing, invalid SQL handling, shared-route restoration, and on-disk permission checks.
12.2. When `DBD::mysql`, `DBD::Pg`, `DBD::ODBC`, and `DBD::Oracle` are available locally, run `PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi prove -lv t/32-sql-dashboard-rdbms-playwright.t` on the host to verify the docker-backed MySQL, PostgreSQL, MSSQL, and Oracle browser flows as well. Those drivers are optional verification dependencies and are not shipped in the base runtime prerequisites. On this host MSSQL and Oracle also expect the user-space native libraries to be exposed through `LD_LIBRARY_PATH`, and Oracle additionally expects `ORACLE_HOME`.
13. Exercise `dashboard cpan DBD::Driver` inside the fake project and confirm the requested driver plus `DBI` are installed into `./.developer-dashboard/local` and recorded in `./.developer-dashboard/cpanfile`.
14. Seed a user-provided fake-project `./.developer-dashboard/cli/update` command plus `update.d` hooks in the clean container, run `dashboard update`, and confirm the normal top-level command-hook pipeline completes, including later-hook reads through `Runtime::Result`.
15. Exercise path, prompt, shell, encode/decode, and indicator commands.
16. Exercise collector write/run/read/start/restart/stop flows, including fake-project config collector definitions, TT-backed collector indicator icons rendered from collector stdout JSON, `dashboard collector log`, `dashboard collector log <name>`, and housekeeper-driven collector log rotation from configured `rotation` or `rotations` rules.
17. Restart the installed runtime with one intentionally broken Perl config collector and one healthy config collector, then verify the broken collector reports an error without stopping the healthy collector or its green indicator state, even when prompt/browser status refreshes run during the restart window.
18. Exercise page create/save/show/encode/decode/render/source flows inside the fake bookmark directory.
19. Exercise builtin action execution.
20. Exercise docker compose dry-run resolution against a temporary project.
21. Start the installed web service.
22. Confirm exact-loopback access reaches the editor page in Chromium.
23. Confirm the browser can render a saved fake-project bookmark page from the fake project bookmark directory.
24. Confirm the browser inserts sorted rendered `nav/*.tt` bookmark fragments between the top chrome and the main page body.
25. Confirm the browser top-right status strip shows configured collector icons, not collector names, that UTF-8 icons such as `🐳` and `💰` are visibly rendered, and that renamed collectors no longer leave stale managed indicators behind.
26. Confirm an installed saved bookmark page can declare `var endpoints = {};`, then use `fetch_value()` and `stream_value()` from `$(document).ready(...)` against saved `/ajax/<file>` routes without inline-script ordering failures or browser console `ReferenceError`s.
27. Confirm an installed long-running saved `/ajax/<file>` route starts streaming the first output chunks promptly instead of buffering until the worker exits.
28. Confirm non-loopback self-access returns `401` with an empty body and without a login form before any helper user exists in the active runtime.
29. Add a helper user for the outsider browser flow, then confirm non-loopback self-access reaches the helper login page in Chromium.
30. Log in as a helper through the HTTP helper flow.
31. Confirm helper page chrome shows `Logout`.
32. Log out and confirm the helper account is removed.
33. Restart the installed runtime from the extracted tarball tree and confirm the web service comes back.
34. Stop the runtime and confirm the web service is gone.

## Expected Results

- every covered command exits successfully except bare `dashboard`, which should
  return usage with a non-zero status
- `dashboard version` reports the installed release version
- `dashboard init` creates starter state without requiring manual setup
- `dashboard update` succeeds in the container from a user-provided fake-project `./.developer-dashboard/cli/update` command through the normal command-hook path
- the installed `dashboard` binary works without `perl -Ilib`
- the fake project's `./.developer-dashboard` tree becomes the active local runtime root with the home tree as fallback
- layered root-to-leaf `.env` and `.env.pl` files override in order, and skill-local env files load only for skill execution paths
- skill dependency installs follow `aptfile -> apkfile -> dnfile -> brewfile -> package.json -> cpanfile -> cpanfile.local -> ddfile -> ddfile.local`, with `aptfile`, `apkfile`, and `dnfile` probing each listed package first and only escalating to `sudo apt-get install -y`, `sudo apk add --no-cache`, or `sudo dnf install -y` for packages that are still missing, `ddfile.local` dependencies staying at the current skill install level, Node dependencies being staged through `npx --yes npm install` in a private dashboard workspace before landing in `$HOME/node_modules`, shared skill Perl dependencies landing in `~/perl5`, and skill-local Perl dependencies landing in each skill's `./perl5`
- explicit `dashboard skills install --ddfile` runs process `ddfile` first into the active layered skills root and then `ddfile.local` into the current directory's nested `./skills/` tree
- streamed `install.sh` runs such as `curl ... | sh` succeed without a local checkout by falling back to embedded `aptfile`, `apkfile`, `dnfile`, and `brewfile` manifests, and Debian-family or Alpine hosts bootstrap `App::perlbrew` automatically when the package manager path did not already provide `perlbrew`
- the old-system-Perl Alpine rescue path keeps the locally bootstrapped `perlbrew` and `patchperl` tools on the private `~/perl5/lib/perl5` include path so `curl ... | sh` can still build `perl-5.38.5` instead of dying with missing `App::perlbrew` or `Devel::PatchPerl` modules
- Debian-family streamed bootstrap also copes with third-party `nodejs` repositories that conflict with the distro `npm` package by installing `nodejs` first, checking whether `npm` and `npx` are already present, and only then attempting the distro `npm` package
- Alpine streamed bootstrap installs the repo-root `apkfile` package set through `apk add --no-cache` and then proves the same post-install shell finish line as Debian-family hosts
- Debian-family streamed bootstrap uses `perlbrew --notest install perl-5.38.5` for the old-system-Perl rescue path so blank-machine bootstrap does not fail on upstream Perl core test noise before Developer Dashboard itself is installed
- `install.sh` prints a full progress board before it changes the system, then emits only per-step transitions instead of redrawing the whole board, explains any upcoming `sudo` prompt as an operating-system package-manager password request before the prompt appears, suppresses perlbrew's generic `~/.profile` advice, updates the chosen rc file itself with the required `PERLBREW_HOME` and rescue-Perl `PATH` lines without sourcing perlbrew's bash-only startup file under generic `sh`, appends the matching `dashboard shell bash|zsh|sh` eval line so `d2`, prompt integration, and completion come up automatically, bridges bash login shells through `~/.profile` to `~/.bashrc`, re-enters an activated shell automatically on a real terminal-backed `curl ... | sh` run, and for automated acceptance uses `DD_INSTALL_SHELL_COMMANDS` to prove `dashboard version`, `d2 version`, and `dashboard skills install browser` through that activated shell path
- a broken config Perl collector reports an error without stopping other configured collectors
- a healthy config collector still reports `ok` and stays green in `dashboard indicator list`, `dashboard ps1`, and `/system/status`, without being clobbered back to `missing` by concurrent config-sync refreshes
- `dashboard collector log` prints aggregated collector transcripts, `dashboard collector log <name>` prints the named collector transcript, and configured collectors that have not run yet report an explicit no-log message instead of blank output
- TT-backed collector icons render from stdout JSON and stay rendered through later config-sync reads instead of reverting to raw `[% ... %]` text
- the web service serves the root editor on `127.0.0.1:7890`
- the browser can load both the editor and a saved fake-project bookmark page from the fake project bookmark directory
- the browser sees sorted shared `nav/*.tt` fragments above the main page body on that fake-project bookmark page
- the browser top-right status strip shows configured collector icons and does not leave stale renamed collector indicators behind
- nested `DD-OOP-LAYERS` collector prompts do not let a child-layer placeholder `missing` state override a healthy inherited parent-layer collector indicator when the child config adds no collector override
- under `DD-OOP-LAYERS`, `dashboard path add` writes only the new child-layer alias delta into the deepest child `config/config.json` instead of copying inherited parent config domains into that file
- bookmark pages can use `fetch_value()`, `stream_value()`, and `stream_data()` helpers against saved `/ajax/...` endpoints on first render
- the installed `/ajax/<file>` route streams early output chunks promptly enough to prove browser-visible progress instead of silent buffering
- non-loopback access produces `401` with an empty body and without a login page until a helper user exists in the active runtime
- under `dashboard serve --ssl`, plain `http://HOST:PORT/...` requests on the public listener return a same-port `307` redirect to `https://HOST:PORT/...`, the generated cert advertises SAN coverage for `localhost`, `127.0.0.1`, and `::1`, and a browser then reaches the expected self-signed certificate warning instead of a reset connection
- after a helper user exists, non-loopback access produces the helper login page
- helper logout removes both the helper session and the helper account
- `dashboard stop` leaves no active listener on port `7890`
- interactive `dashboard stop` and `dashboard restart` runs print the full lifecycle task board on `stderr` before work begins, so managed shutdown and startup waits stay visible instead of looking hung
- runtime stop/restart behavior still works when listener ownership must be
  discovered through `/proc` instead of `ss`
- `dashboard restart` also succeeds when a listener pid survives the first stop
  sweep and must be discovered by a late port re-probe
- `dashboard restart` only reports success after the replacement runtime still
  has a live managed pid and an accepting listener on the requested port, and
  after that ready state survives a short confirmation window instead of
  trusting an acknowledged pid that dies immediately afterwards

## Optional macOS Brewfile Verification

End-to-end `brewfile` verification on macOS is optional manual coverage, not a
required release gate. Use a real macOS host or a disposable macOS guest only
when you need to investigate a Homebrew-specific regression.

One practical route is the `dockur/macos` project:
https://github.com/dockur/macos

The upstream README documents a compose flow using `dockurr/macos`,
`/dev/kvm`, `/dev/net/tun`, `NET_ADMIN`, and the web installer on port `8006`.
Once the guest is installed and reachable, copy the built tarball in, install
Developer Dashboard with `cpanm`, create a skill that ships a `brewfile`, and
confirm `dashboard skills install <skill>` prints the requested Homebrew
packages before running `brew install ...`. When the fixture directory also
contains `ddfile` and `ddfile.local`, run `dashboard skills install --ddfile`
from that directory and confirm the global entries land under the active
layered skills root while the local entries land under `./skills/`.

## Out Of Scope

These are not treated as failures for this blank-environment run:

- outbound integrations not implemented by the current core
- actual privileged Docker daemon execution inside the container

The docker command family is validated through `--dry-run`, which is enough to
prove that the installed CLI resolves the compose stack correctly in a clean
environment.

## Invocation

For a quick host-side bookmark browser repro before the full blank-environment
container cycle, run:

```bash
integration/browser/run-bookmark-browser-smoke.pl
```

That script is the fast path for saved bookmark browser issues such as static
asset loading, bookmark Ajax binding, and final DOM rendering checks.

For Windows verification outside the Linux container flow, run the checked-in
Strawberry Perl smoke on a Windows host:

```powershell
powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz
```

For release-grade Windows compatibility claims, run the same smoke through the
host-side Windows VM helper:

```bash
WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
integration/windows/run-host-windows-smoke.sh
```

That helper loads reusable env-file settings, builds a fresh tarball when
needed, and then delegates to `integration/windows/run-qemu-windows-smoke.sh`.
The supported runtime baseline inside Windows is PowerShell plus Strawberry
Perl. Git Bash is optional. Scoop is optional. They are setup helpers only.
In the Dockur-backed path, the host launcher stages the Strawberry Perl MSI
into the OEM bundle and the Windows guest currently installs the tarball with
`cpanm --notest` before running the real dashboard smoke checks.

Build the tarball on the host and run the integration harness with:

```bash
integration/blank-env/run-host-integration.sh
```

The harness expects the prebuilt integration image `dd-int-test:latest` to
exist locally and mounts the host-built tarball into that container.

## Pass Criteria

The run passes when:

- the container exits `0`
- the app under test comes only from the host-built tarball
- the installed `dashboard` CLI completes the scripted fake-project flow from the mounted tarball install
- Chromium verifies the editor, saved bookmark page, outsider disabled-access page, and helper login page
- the web lifecycle and helper browser flow behave as expected
