# Developer Dashboard Delivery, Security, and Release Rules

Follow `ELLEN.md` as the primary operating guide.

These rules are ordered by priority. If there is any conflict, the higher priority section wins.

## P0. Hard safety and scope rules

These rules decide what is allowed at all.

### 1. Stay within project scope

1. Do not change anything inside `OLD_CODE`.
2. Do not copy code line by line from `OLD_CODE`.
3. You may read `OLD_CODE` to understand behaviour and concepts, but any new implementation must be fresh code based on understanding, not copy-and-paste.
4. Do not inspect, modify, stop, restart, or interfere with unrelated Docker processes or containers.
5. Ditch all code related to Companies House, EWF, XMLGW, CHIPS, Tuxedo, CHS, Grover, CIDEV, PBS, credentials, and any sensitive data.
6. Do not commit or push anything from `OLD_CODE`.

### 2. Security first

1. Perform a security audit on every change.
2. Follow `SECURITY.md` and everything inside `SECURITY_CHECKS.md`.
3. Never suppress errors.
4. Treat warnings as errors.
5. Make logs explicit and visible.
6. Fix problems rather than hiding, bypassing, or masking them.
7. Never hide broken behaviour behind fallback logic unless that behaviour is explicit, documented, and tested.

### 3. No silent failures

1. Expose errors clearly.
2. If something stalls, breaks, or behaves unexpectedly, fix it properly.
3. Never swallow errors or silently continue in a broken state.

---

## P1. Delivery gates for every code change

Nothing is done until these all pass.

### 4. TDD is mandatory

1. All changes must be done using Test Driven Development.
2. Add or update unit tests under `t/`.
3. Write the test first where practical, then implement, then refactor.

### 5. Tests and coverage must pass

1. All tests must pass.
2. Test coverage must be 100%.
3. Treat warnings as test failures and fix them.
4. Do not leave untested branches, helper functions, scripts, or modules.

### 6. Documentation is mandatory

1. Document all changes in `doc/`.
2. Update `README.md`.
3. Update POD in `Developer/Dashboard.pm`.
4. `README.md` and the POD in `Developer/Dashboard.pm` must stay in sync in full detail.
5. Documentation must reflect the actual implementation, not planned behaviour.
6. Never mention any md files in any POD documentation inside .pm, .pl and .t files. NEVER.

### 7. Change log and release metadata must be updated

1. Update `Changes`.
2. Record bug fixes in `FIXED_BUGS.md`.
3. Bump the version and keep it aligned with `dist.ini`.
4. Never reuse the same version number.
5. Version format must always be `X.XX`.

   * Valid example: `1.69`
   * Invalid examples: `1.69.1`, `1.6.9`
6. When the version is updated, all Perl modules under `lib` must use the same version.

---

## P2. Coding standards

These rules apply while implementing the change.

### 8. Perl library rules

1. Use `JSON::XS` for JSON.
2. Use `LWP::UserAgent` for HTTP and HTTPS.
3. Use `Capture::Tiny` for capturing command output.

### 9. Never use

1. `LWP::Simple`
2. `HTTP::Tiny`
3. `JSON::PP`
4. `capture_merged`

### 10. Required `Capture::Tiny` pattern

Use `Capture::Tiny` in this form:

```perl
use Capture::Tiny qw(capture);

my ($stdout, $stderr, $exit) = capture {
   system($command);
};
```

Rules for this pattern:

1. Use `capture`, not `capture_merged`.
2. The exit code must come from the capture block pattern above, not from a separate command or hidden wrapper.
3. Do not replace this with shell tricks or silent redirection.

### 11. Code documentation standards

Every function must have updated comments explaining:

1. what it does
2. input arguments
3. expected output

Because Perl is loosely typed, this notation is required across the codebase.

### 12. POD everywhere

1. Scripts, tests, and modules must include or update POD under `__END__`.
2. POD documentation must be in sync with the implementation in full detail.
3. POD must not be stale, vague, or inconsistent with actual behaviour.
4. `FULL-POD-DOC` is a standing rule: every repo-owned Perl file must carry comprehensive POD, not a one-line stub.
5. Under `FULL-POD-DOC`, each `.pm`, `.pl`, `.t`, `bin/dashboard`, `app.psgi`, and staged private helper script must explain:

   * what it is
   * what it is for
   * why it exists
   * when to use it
   * how to use it
   * what uses it
   * multiple examples to use it
6. Contributors must not have to guess why a Perl file exists or how it fits into the runtime.
7. No FULL-POD-DOC for Developer::Dashboard.pm module

### 13. `dashboard` main command must stay thin

1. The `dashboard` main command must be as thin as possible.
2. Decompose reusable behaviour into dedicated Perl modules or separate Perl scripts.
3. `dashboard` must behave as a lazy loader.
4. Do not load large parts of the application when only a lightweight subcommand such as `jq` is needed.
5. Bookmark handling must not bloat the main `dashboard` command.
6. Shared functionality must be moved into reusable modules where appropriate.

### 14. Shebang rule

All Perl scripts must use:

```perl
#!/usr/bin/env perl
```

Do not use hardcoded Perl paths.

---

## P3. Verification, runtime checks, and packaging

These checks happen after coding and before commit or push.

### 15. Runtime environment checks

1. Follow `ELLEN.md`.
2. Proactively check for Docker container errors relevant to the work being changed.
3. Do not inspect unrelated containers.
4. If a relevant container shows errors, treat that as part of the work and fix it.

### 16. Frontend verification

1. For frontend changes, verify in the browser that behaviour is correct and usable.
2. Do not rely only on reading code or test output.
3. Check that the UI is practical, not just technically functional.

### 17. Mandatory security and repo checks before build and before push

Follow `SECURITY.md` and `SECURITY_CHECKS.md`, and run the repo security checks before build and before push.

Minimum local checks:

```bash
rg -n "LWP::Simple|HTTP::Tiny|JSON::PP|capture_merged" bin lib t
rg -n "companies house|ewf|xmlgw|chips|tuxedo|chs|grover|cidev|pbs|password=|dsn=" bin lib README.md doc t
rg -n "X-Content-Type-Options|nosniff|Content-Security-Policy|X-Frame-Options|Referrer-Policy|SameSite=Strict|HttpOnly" lib doc SECURITY.md
rg -n "Transient token URLs are disabled|_transient_url_tokens_allowed|verify_user|login_response|_session_cookie" lib/Developer/Dashboard/Web lib/Developer/Dashboard/Auth.pm
rg -n "DBI->connect|\\$dbh->prepare\\(\\$sql\\)|table_info|column_info" bin/dashboard lib t
prove -lv t/08-web-update-coverage.t t/web_app_static_files.t t/17-web-server-ssl.t
```

Additional required rules:

P1. Make sure all action items from scorecard are 10 out of 10 full marks.
1. Do not run live `scorecard` as an early pre-commit local gate on this machine. Finish the local repository gates first, then commit, then push, and only then run `scorecard` against the pushed repository state and record the result.
2. On this machine, do not trust a plain non-interactive `bash -lc` scorecard probe by itself because `GITHUB_AUTH_TOKEN` is loaded through the interactive shell init path.
3. The required command on this machine is:

```bash
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

4. If that interactive-shell command works, do not claim Scorecard is blocked or missing auth.
5. If that interactive-shell command fails, record the real failure text instead of guessing.
6. If `scorecard` is not installed or cannot inspect the active repository even through the correct shell path, say so explicitly and do not claim Scorecard passed.
7. Treat any of the following as stop-and-fix issues:

   * new raw SQL execution path
   * missing auth gate
   * missing security header
   * unsafe redirect
   * directory traversal
   * secret leak
   * forbidden library usage
8. For intentionally user-driven tools such as `sql-dashboard`, raw SQL execution must stay explicit and user-authored.
9. Do not add hidden query concatenation.
10. Do not add background SQL generation around user-driven SQL tools.
11. `SCORECARD-GATEKEEPER` is a standing rule: nothing is done, complete, released, or safe to claim as finished until Scorecard reports every actionable check at `10 / 10` and the remaining non-actionable checks are proven impossible to change from the repository side.
12. Under `SCORECARD-GATEKEEPER`, document the live failing checks, turn them into an explicit task list, fix repo-side items with TDD, complete the local gates, commit the change, push any GitHub-side configuration changes needed for Scorecard to observe them, then rerun Scorecard until the report is clean.
13. If Scorecard only reflects a fix after the repository is pushed, the loop is mandatory: `fix -> test -> commit -> push -> rerun scorecard`.
14. Never say the work is complete while Scorecard still shows a repo-fixable failure below `10 / 10`.
15. If a Scorecard check cannot reach `10 / 10` because of an external platform limitation, historical repository age, or contributor makeup, state that exact blocker explicitly with evidence instead of pretending the repository is fully done.

### 18. Dependency hygiene

1. Check the dependency list.
2. Remove dependencies that are no longer used anywhere in the code.
3. After cleanup, verify there are no missing dependencies required for correct operation.
4. Dist and runtime dependencies must match real usage.

### 19. Integration and packaging verification

1. Run integration tests.
2. Follow `doc/integration-test-plan.md`.
3. Build the tarball with `dzil`.
4. Install the tarball in a blank Docker environment using `cpanm` without `--notest`.
5. The tarball must install and test successfully in that blank environment.

### 20. Tarball hygiene

1. Keep only the latest generated tarball in the working directory.
2. Remove all older tarballs from the working directory.
3. Do not leave old build artefacts behind.

### 21. `cover_db` must not be in the tarball

1. `cover_db` must not be included in the tarball.
2. If it is not required by `dzil`, CPAN, or PAUSE, exclude it.
3. Build output must stay clean and release-focused.

### 22. Use of `Test::Kwalitee`

1. Fix all kwalitee issues.
2. Final state must be clean.
3. Do not ignore or defer kwalitee failures.

---

## P4. Behavioural and data safety rules

These protect user data and existing local setup.

### 23. `dashboard init` must not destroy user config

1. Running `dashboard init` again must not overwrite `config/config.json`.
2. If `config/config.json` already exists, leave it intact.
3. You may add or update CLI commands, generated files, or bookmark files where appropriate.
4. Never wipe, replace, or reset existing user config files without an explicit user action designed for that purpose.

### 23A. `DD-OOP-LAYERS` is a contract

1. Treat `DD-OOP-LAYERS` as a cross-runtime contract, not an implementation detail.
2. Start at `~/.developer-dashboard` and walk down through every parent directory until the current working directory.
3. Every existing `.developer-dashboard/` layer in that chain must participate.
4. The deepest discovered layer is the write target and first lookup hit.
5. Inheritance must apply to the whole ecosystem, not only CLI commands.
6. This includes bookmarks, shared `nav/*.tt`, config, collectors, indicators, auth/session lookups, runtime `local/lib/perl5`, static assets, `@INC` exposure, and CLI hooks.
7. Per-command hooks from `<command>/` or `<command>.d/` must run for every discovered layer from home to leaf.
8. Do not collapse the model back to a simple project-vs-home split.
9. Dashboard-managed built-in helper extraction is the explicit home-only exception: `dashboard init` and on-demand helper staging seed built-in helpers only under `~/.developer-dashboard/cli/`, not into child project layers.

### 23B. `dashboard` stays a switchboard

1. Keep the public `dashboard` command as a thin switchboard.
2. Built-in commands must hand off to staged helper scripts instead of loading their implementation directly in `bin/dashboard`.
3. Do not embed helper script bodies or other large command assets in `bin/dashboard`.
4. Built-in helper assets must live outside the entrypoint and remain lazily staged into `~/.developer-dashboard/cli/`.
5. `LAZY-THIN-CMD` is a standing rule: if a built-in command can be staged and handed off, its implementation does not belong in `bin/dashboard`.
6. Under `LAZY-THIN-CMD`, `bin/dashboard` may only do bootstrap, layered hook execution, helper staging, command resolution, and `exec`; built-in command bodies must live in dedicated helper scripts or private shared runtimes outside the public entrypoint.
7. Any shell/bootstrap helper generated by staged private runtimes must re-enter the public `dashboard` command path, not the private helper process path that happened to generate it.

---

## P5. Git and release workflow

These rules only happen after code, tests, documentation, packaging, and verification are all complete.

### 24. Meaningful git commits only

1. No empty commits.
2. Every commit must have a meaningful title.
3. Every commit must have meaningful context matching the actual change.

### 25. Tagging rules

1. Use `MISTAKE.md` references as git tags where applicable.
2. Keep tags meaningful and tied to actual tracked mistakes or fixes.

### 26. Push only after full verification

1. Only push after tests, coverage, docs, packaging, and verification are all complete.
2. For this repo, use `~/bin/git-push-mf` for authenticated pushes through `git@github.mf:manif3station/developer-dashboard.git`.
3. `git-push-mf` bootstraps `SSH_ASKPASS` from `MF_PASS` in the shell environment and unlocks `~/.ssh/mf` non-interactively.
4. Do not treat raw `git push origin ...` as the primary push path for this repo.
5. Before claiming push is blocked, try `~/bin/git-push-mf` first.

Typical usage:

```bash
git-push-mf origin master
git-push-mf origin v1.69 BOOKMARK-FORM-BLOAT
git-push-mf origin -f v1.96 TT-ERROR-SOURCE-LEAK
```

### 27. PAUSE release rules

1. Do **not** do a PAUSE release unless the user explicitly asks for it.
2. Do **not** release locally to PAUSE by default.
3. When the user explicitly asks for a PAUSE release:

   * use the version and tagging rules consistently
   * perform the release locally
   * tag `PAUSE_RELEASED_HERE` after release
4. On this machine, do not assume a plain non-interactive shell has PAUSE credentials loaded.
5. `PAUSE_PASS` is loaded through the interactive shell init path from `~/.bashrc`, so re-check with `bash -ic` before claiming PAUSE upload is blocked.
6. The remembered PAUSE username for this environment is `MICVU` unless the user says otherwise.
7. The preferred local release command on this machine is:

```bash
dashboard pause-release
```

8. `dashboard pause-release` lives at `~/.developer-dashboard/cli/pause-release` and is responsible for:

   * loading `~/.bashrc`
   * resolving the repo version from `dist.ini`
   * building or using `Developer-Dashboard-X.XX.tar.gz`
   * uploading to PAUSE as `MICVU` by default
   * updating and pushing `PAUSE_RELEASED_HERE` after a successful upload
9. If a dry run is needed, use:

```bash
dashboard pause-release --dry-run
```

10. Do **not** use `cpan-upload --dry-run` directly on this machine as a safety probe, because it can print the password-bearing uploader object in its debug output.

---

# Development Rules Summary

## 1. Scope and safety

1. Follow `ELLEN.md` as the operating guide.
2. Do not touch or inspect unrelated Docker processes.
3. Do not modify anything in `OLD_CODE`.
4. Do not copy code line by line from `OLD_CODE`.
5. Read `OLD_CODE` only to understand concepts and behaviour, then reimplement cleanly.
6. Remove or avoid all code related to Companies House, EWF, XMLGW, CHIPS, Tuxedo, CHS, Grover, CIDEV, PBS, credentials, and sensitive data.
7. Always perform a security audit.
8. Never suppress errors.
9. Treat Perl warnings as errors.
10. Make logs explicit and visible.
11. If something is broken, fix it properly rather than hiding it.

## 2. Mandatory delivery rules

12. All work must follow TDD.
13. Add or update unit tests in `t/`.
14. All tests must pass.
15. Coverage must be 100%.
16. Document all changes in `doc/`.
17. Record all bug fixes in `FIXED_BUGS.md`.
18. Update `Changes`.
19. Bump the version and keep it aligned with `dist.ini`.
20. Never reuse the same version number.
21. Version format must always be `X.XX`.
22. All Perl modules under `lib` must share the same version.
23. Update both `README.md` and the POD in `Developer/Dashboard.pm`.
24. `README.md` and `Developer/Dashboard.pm` POD must remain identical in content.

## 3. Perl implementation rules

25. Use `JSON::XS` for JSON.
26. Use `LWP::UserAgent` for HTTP and HTTPS.
27. Use `Capture::Tiny` for capturing command output.
28. Never use `LWP::Simple`, `HTTP::Tiny`, `JSON::PP`, or `capture_merged`.
29. Use `Capture::Tiny` in this form:

```perl
use Capture::Tiny qw(capture);

my ($stdout, $stderr, $exit) = capture {
   system($command);
};
```

30. Every function must document:

* purpose
* input arguments
* expected output

31. All Perl scripts must use:

```perl
#!/usr/bin/env perl
```

32. The `dashboard` main command must be thin and lazy-loaded.
33. Decompose reusable logic into modules or scripts.
34. Do not bloat `dashboard` with bookmark logic or unnecessary eager loading.

## 4. POD and internal documentation

35. Update POD comments across the codebase.
36. Scripts, tests, and modules must include POD under `__END__`.
37. Keep all documentation current and in sync with the implementation.

## 5. Verification rules

38. Proactively check relevant Docker container errors.
39. For frontend changes, verify behaviour in the browser.
40. Follow `SECURITY.md` and `SECURITY_CHECKS.md`.
41. Run the required repo security checks before build and before push.
42. Run integration tests according to `doc/integration-test-plan.md`.
43. Review and clean dependencies.
44. Build the release tarball with `dzil`.
45. Test install the tarball in a blank Docker container using `cpanm` without `--notest`.
46. Remove old tarballs and keep only the latest one.
47. Exclude `cover_db` from the tarball if it is not required for release.
48. Fix all kwalitee issues.

## 6. Git and release rules

49. Do not create empty commits.
50. Every commit must be meaningful and have a proper title.
51. Use `MISTAKE.md` references as git tags where applicable.
52. Push only after all checks pass.
53. Use `~/bin/git-push-mf` for authenticated pushes to this repo.
54. Do not use raw `git push origin ...` first on this repo; use the repo helper first.
55. Do not perform a PAUSE release unless the user explicitly asks for it.
56. If a PAUSE release is requested, tag `PAUSE_RELEASED_HERE` after release.

## 7. User config safety

57. `dashboard init` must not overwrite `config/config.json`.
58. Existing config must remain intact on repeated init runs.
58. It is acceptable to add or update CLI commands or bookmark files, but not destroy existing config.

Keep AGENTS.override.md as symlink. Do not remove it and place a hard file to this filename. I do not wish to leave any chase on the git history about this file.

---

## Reference

`https://chatgpt.com/c/69d43f4f-6cd8-8326-9c44-ed5c57b28e87`
