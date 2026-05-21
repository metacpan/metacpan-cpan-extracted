# Blank Environment Integration Test Plan

## Purpose

This plan validates that `Developer::Dashboard` can be built with `Dist::Zilla`
on the host, installed into a clean container from that built tarball, and
exercised there as an installed CLI and
web application rather than as a checkout-local script.

The goal is to prove that a new environment can:

- build the CPAN distribution tarball on the host from the repo
- install the built tarball with `cpanm --notest`
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
- installation: `cpanm --notest <tarball>`
- bootstrap: `dashboard init`, user-provided `dashboard update`
- help and prompt: `dashboard`, `dashboard help`, `dashboard ps1`, `dashboard shell bash`, `dashboard shell ps`
- helper staging: rerun a built-in helper command after install and verify the managed helper runtime converges on `~/.developer-dashboard/cli/dd/`; dashboard-managed flat helper files left directly under `~/.developer-dashboard/cli/` by older releases should be removed automatically on that staging pass
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
- when the Windows checkout bootstrap changes, `integration/windows/run-strawberry-smoke.ps1` must be rerun with `-UseInstallBootstrap` so the guest exercises `install.ps1` through the streamed `Invoke-Expression` path

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
The normal `prove -lr t` and explicit `Devel::Cover` gates are where the
Developer Dashboard distribution tests run in full. The later blank-container
tarball install is now an installation-verification gate, so it uses
`cpanm --notest` to verify packaged dependency resolution and installed
runtime behavior without rerunning the same distribution test suite a second
time. The Windows guest smoke follows the same rule for the tarball install
step, and the optional bootstrap path passes the tarball through the literal
`DD_INSTALL_CPAN_TARGET` environment variable so `install.ps1` still lets
`cpanm --notest` resolve the exact target literally. Outside that override,
the streamed Windows bootstrap defaults to cloning the GitHub `master`
checkout into a temporary local tree instead of relying on a potentially stale
CPAN release.

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
2. Run `prove -lv t/44-smart-router-two-stage.t` against that freshly built tarball so the extracted-dashboard smart-router contract is verified at the post-build stage. That guard retries one transient `cpanm` fetch or unpack failure inside its Docker container before treating the post-build install as a real repository regression.
3. Start the blank container with only that host-built tarball mounted into it.
4. Copy the mounted tarball to a versioned local path inside the container and
   install that staged tarball with `cpanm --notest`. The staged filename must keep the
   concrete `Developer-Dashboard-X.XX.tar.gz` version so `cpanm` cannot drift
   into a CPAN lookup because the bind-mounted filename is generic.
5. Create the fake-project `./.developer-dashboard` tree only after that install step succeeds so the tarball's own tests still run against a clean runtime.
6. Extract the same tarball inside the container for the rest of the installed-command checks.
7. Verify the installed CLI responds to `dashboard help`.
8. Verify bare `dashboard` returns usage output.
9. Verify `dashboard version` reports the installed runtime version.
10. Create a fake project root with a local `./.developer-dashboard` runtime tree.
11. Exercise `dashboard cpan DBD::Driver` inside the fake project and confirm the requested driver plus `DBI` are installed into `./.developer-dashboard/local` and recorded in `./.developer-dashboard/cpanfile`.
12. Seed a user-provided fake-project `./.developer-dashboard/cli/update` command plus `update.d` hooks in the clean container, run `dashboard update`, and confirm the normal top-level command-hook pipeline completes, including later-hook reads through `Runtime::Result`.
13. Exercise path, prompt, shell, encode/decode, and indicator commands.
14. Exercise collector write/run/read/start/restart/stop flows, including fake-project config collector definitions, TT-backed collector indicator icons rendered from collector stdout JSON, `dashboard collector log`, `dashboard collector log <name>`, and housekeeper-driven collector log rotation from configured `rotation` or `rotations` rules.
15. Restart the installed runtime with one intentionally broken Perl config collector and one healthy config collector, then verify the broken collector reports an error without stopping the healthy collector or its green indicator state, even when prompt/browser status refreshes run during the restart window.
16. Kill one managed collector loop after startup, confirm the watchdog restarts it automatically, and verify `dashboard collector status <name>` records watchdog restart counters/timestamps. Kill it repeatedly until the watchdog limit is exceeded, then confirm the collector is marked `attention_required` instead of disappearing silently.
17. Exercise page create/save/show/encode/decode/render/source flows inside the fake bookmark directory.
18. Exercise builtin action execution.
19. For Windows-targeted changes, run `integration/windows/run-strawberry-smoke.ps1 -UseInstallBootstrap -BootstrapScript <checkout install.ps1>` so the guest validates the same streamed `Invoke-Expression` bootstrap shape that operators use with `irm .../install.ps1 | iex`, including successful `cpanm --notest .` checkout installation and a fresh PowerShell session that can load the generated profile without a `running scripts is disabled` failure, resolve `dashboard`, print `dashboard version`, and run `dashboard logs`.
20. Exercise docker compose dry-run resolution against a temporary project.
21. Start the installed web service.
22. Confirm exact-loopback access reaches the editor page in Chromium.
23. Confirm the browser can render a saved fake-project bookmark page from the fake project bookmark directory.
24. Confirm the browser inserts sorted rendered `nav/*.tt` bookmark fragments between the top chrome and the main page body.
25. Confirm the browser top-right status strip shows configured collector icons, not collector names, that UTF-8 icons such as `🐳` and `💰` are visibly rendered, and that renamed collectors no longer leave stale managed indicators behind.
26. Confirm an installed saved bookmark page can declare `var endpoints = {};`, then use `fetch_value()` and `stream_value()` from `$(document).ready(...)` against saved `/ajax/<file>` routes without inline-script ordering failures or browser console `ReferenceError`s.
27. Confirm an installed long-running saved `/ajax/<file>` route starts streaming the first output chunks promptly instead of buffering until the worker exits.
28. Confirm an installed skill page that ships `config/routes.json` emits the declared canonical custom ajax path, that the custom path resolves, that the smart `/ajax/<repo-name>/...` route still resolves for the same handler, and that a route-level default `type` such as `json`, `html`, or a raw mime type is honored when the request omits `?type=...`.
29. Confirm non-loopback self-access returns `401` with an empty body and without a login form before any helper user exists in the active runtime.
30. Add a helper user for the outsider browser flow, then confirm non-loopback self-access reaches the helper login page in Chromium.
31. Log in as a helper through the HTTP helper flow.
32. Confirm helper page chrome shows `Logout`.
33. Log out and confirm the helper account is removed.
34. Restart the installed runtime from the extracted tarball tree and confirm the web service comes back.
35. Stop the runtime and confirm the web service is gone.

## Expected Results

- every covered command exits successfully except bare `dashboard`, which should
  return usage with a non-zero status
- `dashboard version` reports the installed release version
- `dashboard init` creates starter state without requiring manual setup
- `dashboard update` succeeds in the container from a user-provided fake-project `./.developer-dashboard/cli/update` command through the normal command-hook path
- the installed `dashboard` binary works without `perl -Ilib`
- the fake project's `./.developer-dashboard` tree becomes the active local runtime root with the home tree as fallback
- layered root-to-leaf `.env` and `.env.pl` files override in order, skill-local env files load only for skill execution paths, nested skill commands expand `foo -> foo.bar -> foo.bar.zzz` env files in order while preserving overwritten parent keys under aliases such as `foo_VERSION` and `foo_bar_VERSION`, and `dashboard docker compose` loads the same nested skill env chain plus both the leaf and cumulative `<skill>_DDDC` aliases for installed skills whose `config/docker/<service>/compose.yml` or `development.compose.yml` files actually participate in the resolved stack
- skill dependency installs follow `aptfile -> apkfile -> dnfile -> wingetfile -> brewfile -> package.json -> requirements.txt -> cpanfile -> cpanfile.local -> Makefile -> ddfile -> ddfile.local`, with `aptfile`, `apkfile`, and `dnfile` probing each listed package first and only escalating to `sudo apt-get install -y`, `sudo apk add --no-cache`, or `sudo dnf install -y` for packages that are still missing, `wingetfile` installing each listed package id only on Windows through `winget install --id ... --exact --accept-package-agreements --accept-source-agreements --disable-interactivity`, Node dependencies being staged through `npx --yes npm install` in a private dashboard workspace before landing in `$HOME/node_modules`, Python dependencies being installed through `python -m pip install --user --requirement requirements.txt` from the skill root, shared skill Perl dependencies landing in `~/perl5`, skill-local Perl dependencies landing in each skill's `./perl5`, optional skill `Makefile` flows running `make`, `make test` when a `test` or `tests` target exists unless `dashboard skills install --notest` is used, `make install`, and `make clean` when a `clean` target exists, and `ddfile.local` dependencies staying at the current skill install level
- long-running skill dependency steps keep the main epic checklist visible while streaming a Docker-style rolling ten-line detail window under the active task, collapse those detail lines when the task succeeds, and leave the captured detail visible when the task fails
- explicit `dashboard skills install --ddfile` runs process `ddfile` first into the active layered skills root and then `ddfile.local` into the current directory's nested `./skills/` tree
- explicit `dashboard skills install <source> ...` runs can install one or more sources in command-line order, append each exact source to the home root `~/.developer-dashboard/ddfile` without duplicating existing non-comment entries, `dashboard skills uninstall <repo-name>` removes matching source lines from that same root `ddfile` while preserving comments and unrelated entries, and bare `dashboard skills install` uses that root `ddfile` to reinstall every registered skill as an update-all pass with a visible source-level progress rundown and a default before/after `.env` `VERSION` table summary
- when the home runtime already has `.gitignore` or compatibility `.gitiignore`, explicit skill installs append `skills/<repo-name>/` without duplicates so cloned skill trees stay ignored by runtime Git checkouts
- `dashboard skill` is covered as the singular alias for `dashboard skills` management commands while installed command execution remains on the dotted `dashboard <skill>.<command>` path
- streamed `install.sh` runs such as `curl ... | sh` succeed without a local checkout by falling back to embedded `aptfile`, `apkfile`, `dnfile`, and `brewfile` manifests, shipping `tmux` in those bootstrap package sets because `dashboard workspace` is a first-party tmux workflow, cloning the current GitHub `master` checkout into a temporary local tree when no explicit `DD_INSTALL_CPAN_TARGET` override is set, and Debian-family or Alpine hosts bootstrap `App::perlbrew` automatically when the package manager path did not already provide `perlbrew`
- the old-system-Perl Alpine rescue path keeps the locally bootstrapped `perlbrew` and `patchperl` tools on the private `~/perl5/lib/perl5` include path so `curl ... | sh` can still build `perl-5.38.5` instead of dying with missing `App::perlbrew` or `Devel::PatchPerl` modules
- Debian-family streamed bootstrap also copes with third-party `nodejs` repositories that conflict with the distro `npm` package by installing `nodejs` first, checking whether `npm` and `npx` are already present, and only then attempting the distro `npm` package
- Alpine streamed bootstrap installs the repo-root `apkfile` package set through `apk add --no-cache` and then proves the same post-install shell finish line as Debian-family hosts
- Debian-family streamed bootstrap uses `perlbrew --notest install perl-5.38.5` for the old-system-Perl rescue path so blank-machine bootstrap does not fail on upstream Perl core test noise before Developer Dashboard itself is installed
- `install.sh` prints a full progress board before it changes the system, then emits only per-step transitions instead of redrawing the whole board, explains any upcoming `sudo` prompt as an operating-system package-manager password request before the prompt appears, suppresses perlbrew's generic `~/.profile` advice, updates the chosen rc file itself with the required `PERLBREW_HOME` and rescue-Perl `PATH` lines without sourcing perlbrew's bash-only startup file under generic `sh`, appends the matching `dashboard shell bash|zsh|sh` eval line so `d2`, prompt integration, and completion come up automatically, bridges bash login shells through `~/.profile` to `~/.bashrc`, seeds `File::ShareDir::Install` into the private `~/perl5` bootstrap before the checkout install, installs the local checkout directly with `cpanm --no-wget --notest .` when the installer is running from a checkout or extracted tarball, re-enters an activated shell automatically on a real terminal-backed `curl ... | sh` run, and for automated acceptance uses `DD_INSTALL_SHELL_COMMANDS` to prove `dashboard version`, `d2 version`, and `dashboard skills install browser` through that activated shell path
- blank macOS streamed bootstrap now also covers the no-Homebrew starting state, proving `install.sh` bootstraps Homebrew first, updates `PATH` from the discovered Homebrew prefix in the same run, and only then installs the repo `brewfile` package set
- `dashboard workspace` tmux sessions move prompt indicators into the first row of a session-local two-line bottom tmux status block, keep the normal indexed session/window row underneath it, keep the inline prompt free of duplicated indicators even for older sessions that only expose `TICKET_REF`, refresh the live indicator strip automatically through tmux status refresh, and do not change ordinary tmux sessions or any user tmux config file
- nested installed skill nav trees such as `skills/ho/skills/coverage/dashboards/nav/index.tt` render on the nested skill route itself and also join the shared nav strip above normal saved `/app/<page>` routes
- the staged home-runtime `shell` helper itself must emit that tmux-aware bootstrap after install, not just the repo checkout `bin/dashboard shell ...` path
- a broken config Perl collector reports an error without stopping other configured collectors
- a healthy config collector still reports `ok` and stays green in `dashboard indicator list`, `dashboard ps1`, and `/system/status`, without being clobbered back to `missing` by concurrent config-sync refreshes
- a killed managed collector loop is restarted automatically by the watchdog, and repeated crash loops eventually surface `watchdog_attention_required` in `dashboard collector status <name>` instead of going silent
- a live managed collector loop that stops updating its status or completion timestamps is treated as stalled, recycled automatically by the watchdog, and reported explicitly in `dashboard collector status <name>` instead of sitting silent forever
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
- skill pages that ship `config/routes.json` emit their declared canonical custom ajax paths, while the smart `/ajax/<repo-name>/...` route still works as the parent compatibility resolver and custom paths stay fallback-only before a normal `404`
- non-loopback access produces `401` with an empty body and without a login page until a helper user exists in the active runtime
- under `dashboard serve --ssl`, plain `http://HOST:PORT/...` requests on the public listener return a same-port `307` redirect to `https://HOST:PORT/...`, the generated cert advertises SAN coverage for `localhost`, `127.0.0.1`, and `::1`, and a browser then reaches the expected self-signed certificate warning instead of a reset connection
- after a helper user exists, non-loopback access produces the helper login page
- helper logout removes both the helper session and the helper account
- `dashboard stop` leaves no active listener on port `7890`
- `dashboard stop` and `dashboard restart` still control the real serving pid
  when the web process has renamed itself into a `starman master` listener
  shape, so container lifecycle checks stay attached to the active listener
- interactive `dashboard stop` and `dashboard restart` runs print the full lifecycle task board on `stderr` before work begins, so managed shutdown and startup waits stay visible instead of looking hung
- `dashboard stop` and `dashboard restart` default to a final terminal table summary, while `-o json` keeps the machine-readable payload
- `dashboard stop web`, `dashboard stop collector`, `dashboard stop collector <name>`, `dashboard restart web`, `dashboard restart collector`, `dashboard restart collector <name>`, `dashboard log`, `dashboard logs`, `dashboard log web`, `dashboard log collector`, and `dashboard log collector <name>` all behave as documented, with collector-name completion feeding the scoped collector commands
- runtime stop/restart behavior still works when listener ownership must be
  discovered through `/proc` instead of `ss`
- Linux host lifecycle runs ignore web and collector pids that belong to a
  different pid namespace, so a host-side runtime does not kill or adopt a
  sibling Docker runtime during `dashboard stop` or `dashboard restart`
- `dashboard restart` also succeeds when a listener pid survives the first stop
  sweep and must be discovered by a late port re-probe
- `dashboard restart` only reports success after the replacement runtime still
  has a live managed pid and an accepting listener on the requested port, and
  after that ready state survives a short confirmation window instead of
  trusting an acknowledged pid that dies immediately afterwards
- runtime shutdown uses numeric POSIX signals for managed stop/restart paths so
  Alpine/iSH Perl builds that reject named signal strings still stop web and
  collector processes correctly

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
into the OEM bundle and the Windows guest installs the tarball with
`cpanm --notest` before running the real dashboard smoke checks.

Build the tarball on the host, rebuild the blank-environment image from the
current Dockerfile, and run the integration harness with:

```bash
integration/blank-env/run-host-integration.sh
```

The harness rebuilds the `dd-int-test:latest` integration image from the
current `integration/blank-env/Dockerfile` and mounts the host-built tarball
into that fresh container run.
That image must include the native CPAN build baseline needed by packaged
installs, including `libexpat1-dev`, `libssl-dev`, `pkg-config`, and
`zlib1g-dev`, so `XML::Parser`, `Net::SSLeay`, and related transitive
dependencies can compile before the installed dashboard smoke begins.
It must also provide a real Chromium binary, not a snap-wrapper launcher, so
the in-container browser verification can dump DOM output directly without a
side-channel browser install step.

## Pass Criteria

The run passes when:

- the container exits `0`
- the app under test comes only from the host-built tarball
- the installed `dashboard` CLI completes the scripted fake-project flow from the mounted tarball install
- Chromium verifies the editor, saved bookmark page, outsider disabled-access page, and helper login page
- the web lifecycle and helper browser flow behave as expected
