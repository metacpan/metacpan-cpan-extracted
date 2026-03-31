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
- bootstrap: `dashboard init`, `dashboard update`
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

## Environment

The test container should be intentionally minimal:

- base image: official Perl runtime image
- no preinstalled Developer Dashboard
- only generic build, browser, and HTTP tooling added
- a temporary `HOME` so the installed app must bootstrap itself from scratch

The repo checkout is not mounted into the container as the app under test.
Only the host-built tarball is mounted into the blank container.

## Test Data

The integration run creates:

- a temporary home directory under `/tmp`
- a fake project root under `/tmp/fake-project`
- fake project `bookmarks`, `configs`, and `startup` directories
- environment-variable overrides for:
  - `DEVELOPER_DASHBOARD_BOOKMARKS`
  - `DEVELOPER_DASHBOARD_CONFIGS`
  - `DEVELOPER_DASHBOARD_STARTUP`
- a saved page named `sample`
- a saved legacy bookmark page named `project-home`
- a helper user for explicit add/remove testing
- a second helper user for browser login/logout cleanup testing
- a temporary Compose project under `/tmp`

## Execution Flow

1. Build the distribution tarball on the host with `dzil build`.
2. Start the blank container with only that host-built tarball mounted into it.
3. Install the mounted tarball with `cpanm --notest`.
4. Extract the same tarball inside the container so update scripts can run from the built artifact contents.
5. Verify the installed CLI responds to `dashboard help`.
6. Verify bare `dashboard` returns usage output.
7. Create a fake project root with bookmark, config, and startup directories and export the dashboard override variables toward them.
8. Run `dashboard init` and confirm runtime roots and starter pages exist.
9. Run `dashboard update` from the extracted tarball tree and confirm the update pipeline completes in the clean container.
10. Exercise path, prompt, shell, encode/decode, and indicator commands.
11. Exercise collector write/run/read/start/restart/stop flows, including a fake-project startup collector definition.
12. Exercise page create/save/show/encode/decode/render/source flows inside the fake bookmark directory.
13. Exercise builtin action execution.
14. Exercise docker compose dry-run resolution against a temporary project.
15. Start the installed web service.
16. Confirm exact-loopback access reaches the editor page in Chromium.
17. Confirm the browser can render a saved fake-project bookmark page from the fake project bookmark directory.
18. Confirm non-loopback self-access reaches the helper login page in Chromium.
19. Log in as a helper through the HTTP helper flow.
20. Confirm helper page chrome shows `Logout`.
21. Log out and confirm the helper account is removed.
22. Restart the installed runtime from the extracted tarball tree and confirm the web service comes back.
23. Stop the runtime and confirm the web service is gone.

## Expected Results

- every covered command exits successfully except bare `dashboard`, which should
  return usage with a non-zero status
- `dashboard init` creates starter state without requiring manual setup
- `dashboard update` succeeds in the container from the extracted tarball contents
- the installed `dashboard` binary works without `perl -Ilib`
- the fake project directories become the active bookmark, config, and startup roots
- the web service serves the root editor on `127.0.0.1:7890`
- the browser can load both the editor and a saved fake-project bookmark page from the fake project bookmark directory
- non-loopback access produces the helper login page
- helper logout removes both the helper session and the helper account
- `dashboard stop` leaves no active listener on port `7890`

## Out Of Scope

These are not treated as failures for this blank-environment run:

- outbound integrations not implemented by the current core
- actual privileged Docker daemon execution inside the container

The docker command family is validated through `--dry-run`, which is enough to
prove that the installed CLI resolves the compose stack correctly in a clean
environment.

## Invocation

Build the tarball on the host and run the integration harness with:

```bash
integration/blank-env/run-host-integration.sh
```

## Pass Criteria

The run passes when:

- the container exits `0`
- the app under test comes only from the host-built tarball
- the installed `dashboard` CLI completes the scripted fake-project flow from the mounted tarball install
- Chromium verifies the editor, saved bookmark page, and helper login page
- the web lifecycle and helper browser flow behave as expected
