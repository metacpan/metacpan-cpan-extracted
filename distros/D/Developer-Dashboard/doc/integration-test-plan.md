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

## Scope

The integration run covers these command families:

- host packaging: `dzil build`
- installation: `cpanm <tarball>`
- bootstrap: `dashboard init`, user-provided `dashboard update`
- help and prompt: `dashboard`, `dashboard help`, `dashboard ps1`, `dashboard shell bash`
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
- browser checks: headless Chromium editor, saved fake-project bookmark page, and helper-login DOM verification
- ajax streaming: installed long-running `/ajax/<file>` route timing, early-chunk verification, and refresh-safe singleton replacement plus browser pagehide cleanup coverage in unit tests

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
- a saved legacy bookmark page named `project-home`
- a saved legacy bookmark page named `legacy-ajax-stream`
- shared nav bookmark pages under `nav/*.tt`
- a helper user for explicit add/remove testing
- a second helper user for browser login/logout cleanup testing
- a temporary Compose project under `/tmp`

## Execution Flow

1. Build the distribution tarball on the host with `dzil build`.
2. Start the blank container with only that host-built tarball mounted into it.
3. Install the mounted tarball with `cpanm`.
4. Create the fake-project `./.developer-dashboard` tree only after that install step succeeds so the tarball's own tests still run against a clean runtime.
5. Extract the same tarball inside the container for the rest of the installed-command checks.
6. Verify the installed CLI responds to `dashboard help`.
7. Verify bare `dashboard` returns usage output.
8. Verify `dashboard version` reports the installed runtime version.
9. Create a fake project root with a local `./.developer-dashboard` runtime tree.
10. Run `dashboard init` from inside that fake project and confirm the project-local runtime roots plus `welcome`, `api-dashboard`, and `db-dashboard` starter pages exist.
11. Seed a user-provided fake-project `./.developer-dashboard/cli/update` command plus `update.d` hooks in the clean container, run `dashboard update`, and confirm the normal top-level command-hook pipeline completes, including later-hook reads through `Runtime::Result`.
12. Exercise path, prompt, shell, encode/decode, and indicator commands.
13. Exercise collector write/run/read/start/restart/stop flows, including fake-project config collector definitions.
14. Restart the installed runtime with one intentionally broken Perl config collector and one healthy config collector, then verify the broken collector reports an error without stopping the healthy collector or its green indicator state.
15. Exercise page create/save/show/encode/decode/render/source flows inside the fake bookmark directory.
16. Exercise builtin action execution.
17. Exercise docker compose dry-run resolution against a temporary project.
18. Start the installed web service.
19. Confirm exact-loopback access reaches the editor page in Chromium.
20. Confirm the browser can render a saved fake-project bookmark page from the fake project bookmark directory.
21. Confirm the browser inserts sorted rendered `nav/*.tt` bookmark fragments between the top chrome and the main page body.
22. Confirm an installed long-running saved `/ajax/<file>` route starts streaming the first output chunks promptly instead of buffering until the worker exits.
23. Confirm non-loopback self-access reaches the helper login page in Chromium.
24. Log in as a helper through the HTTP helper flow.
25. Confirm helper page chrome shows `Logout`.
26. Log out and confirm the helper account is removed.
27. Restart the installed runtime from the extracted tarball tree and confirm the web service comes back.
28. Stop the runtime and confirm the web service is gone.

## Expected Results

- every covered command exits successfully except bare `dashboard`, which should
  return usage with a non-zero status
- `dashboard version` reports the installed release version
- `dashboard init` creates starter state without requiring manual setup
- `dashboard update` succeeds in the container from a user-provided fake-project `./.developer-dashboard/cli/update` command through the normal command-hook path
- the installed `dashboard` binary works without `perl -Ilib`
- the fake project's `./.developer-dashboard` tree becomes the active local runtime root with the home tree as fallback
- a broken config Perl collector reports an error without stopping other configured collectors
- a healthy config collector still reports `ok` and stays green in `dashboard indicator list`, `dashboard ps1`, and `/system/status`
- the web service serves the root editor on `127.0.0.1:7890`
- the browser can load both the editor and a saved fake-project bookmark page from the fake project bookmark directory
- the browser sees sorted shared `nav/*.tt` fragments above the main page body on that fake-project bookmark page
- the installed `/ajax/<file>` route streams early output chunks promptly enough to prove browser-visible progress instead of silent buffering
- non-loopback access produces the helper login page
- helper logout removes both the helper session and the helper account
- `dashboard stop` leaves no active listener on port `7890`
- runtime stop/restart behavior still works when listener ownership must be
  discovered through `/proc` instead of `ss`
- `dashboard restart` also succeeds when a listener pid survives the first stop
  sweep and must be discovered by a late port re-probe

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
asset loading, legacy Ajax binding, and final DOM rendering checks.

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
- Chromium verifies the editor, saved bookmark page, and helper login page
- the web lifecycle and helper browser flow behave as expected
