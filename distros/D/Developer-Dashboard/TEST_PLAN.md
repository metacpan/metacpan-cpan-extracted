# Developer Dashboard Comprehensive Test Plan

## Purpose

This plan defines 100 verification scenarios across the Developer Dashboard
ecosystem. It is intended to cover CLI, runtime state, saved bookmarks,
collectors, auth, Docker resolution, packaging, integration, and browser-facing
behavior. Scenarios `B001` through `B050` are browser-focused scenarios.

## Execution Model

- `Automated`: already suited for unit, integration, or scripted execution.
- `Manual`: requires an operator, visual inspection, or interactive workflow.
- `Hybrid`: can be mostly scripted but still benefits from a human check.

## Non-Browser Scenarios

| ID | Area | Scenario | Mode |
| --- | --- | --- | --- |
| N001 | Install | Build the distribution tarball with `dzil build` from a clean checkout. | Automated |
| N002 | Install | Confirm only the latest `Developer-Dashboard-*.tar.gz` remains after a release build. | Automated |
| N003 | Install | Install the built tarball with `cpanm` in a blank environment with tests enabled. | Automated |
| N004 | Install | Verify `dashboard version` matches the shipped module version from the built tarball. | Automated |
| N005 | Install | Verify the installed binaries include `dashboard`, `of`, `open-file`, `pjq`, `pyq`, `ptomq`, and `pjp`. | Automated |
| N006 | Metadata | Verify `dist.ini`, `Changes`, README release snippets, and module version stay aligned. | Automated |
| N007 | Metadata | Verify runtime prereqs explicitly include `JSON::XS`. | Automated |
| N008 | Metadata | Verify repository/provides metadata is present in the built distribution metadata. | Automated |
| N009 | CLI | Run bare `dashboard` and confirm non-zero usage output. | Automated |
| N010 | CLI | Run `dashboard help` and confirm extended POD-backed help renders. | Automated |
| N011 | CLI | Run `dashboard init` in an empty runtime and confirm starter state is created. | Automated |
| N012 | CLI | Confirm `dashboard init` seeds `welcome`, `api-dashboard`, and `db-dashboard`. | Automated |
| N013 | CLI | Confirm `dashboard page new` produces canonical older bookmark syntax. | Automated |
| N014 | CLI | Confirm `dashboard page save` persists a bookmark under the effective dashboards root. | Automated |
| N015 | CLI | Confirm `dashboard page list` returns sorted saved bookmark ids including nested ids. | Automated |
| N016 | CLI | Confirm `dashboard page show` round-trips saved bookmark source exactly. | Automated |
| N017 | CLI | Confirm `dashboard page encode` and `dashboard page decode` round-trip bookmark content. | Automated |
| N018 | CLI | Confirm `dashboard page urls` emits edit/render/source URLs for a saved page. | Automated |
| N019 | CLI | Confirm `dashboard page render` renders bookmark HTML and top chrome. | Automated |
| N020 | CLI | Confirm `dashboard page source` prefers saved page ids over token decoding. | Automated |
| N021 | CLI | Confirm `dashboard paths` reports project-local runtime roots when they exist. | Automated |
| N022 | CLI | Confirm `dashboard path list` exposes older aliases and runtime roots. | Automated |
| N023 | CLI | Confirm `dashboard path resolve` works for built-in aliases such as `bookmarks_root`. | Automated |
| N024 | CLI | Confirm `dashboard path add` stores a custom alias using a home-relative form in config. | Automated |
| N025 | CLI | Confirm `dashboard path del` removes a custom alias idempotently. | Automated |
| N026 | CLI | Confirm `dashboard shell bash` emits working `cdr` and `which_dir` helpers. | Automated |
| N027 | CLI | Confirm `dashboard open-file` resolves direct files and recursive pattern searches. | Automated |
| N028 | CLI | Confirm `dashboard open-file` resolves Perl modules and Java class names. | Automated |
| N029 | CLI | Confirm `dashboard pjq` extracts dotted JSON paths from stdin and files. | Automated |
| N030 | CLI | Confirm `dashboard pyq` extracts dotted YAML paths from stdin and files. | Automated |
| N031 | CLI | Confirm `dashboard ptomq` extracts dotted TOML paths from stdin and files. | Automated |
| N032 | CLI | Confirm `dashboard pjp` extracts dotted Java properties paths from stdin and files. | Automated |
| N033 | Hooks | Confirm built-in commands run hook files from `cli/<command>` in sorted order. | Automated |
| N034 | Hooks | Confirm `.d` hook directories behave the same as direct command hook directories. | Automated |
| N035 | Hooks | Confirm hook stdout and stderr stream live while still accumulating into `RESULT`. | Automated |
| N036 | Hooks | Confirm later hooks can read earlier hook output through `Runtime::Result`. | Automated |
| N037 | Hooks | Confirm directory-backed custom commands run `run` after their hook files. | Automated |
| N038 | Hooks | Confirm a project-local CLI command overrides the home CLI command. | Automated |
| N039 | Runtime | Confirm `dashboard restart` in a plain repo does not create a project-local `.developer-dashboard` unless opted in. | Automated |
| N040 | Runtime | Confirm `dashboard stop` removes the active web listener. | Automated |
| N041 | Runtime | Confirm runtime root precedence prefers project-local state and falls back to home state. | Automated |
| N042 | Runtime | Confirm bookmark lookup searches project-local dashboards before home dashboards. | Automated |
| N043 | Runtime | Confirm config lookup searches project-local config before home config. | Automated |
| N044 | Runtime | Confirm `Folder->dd` and `Folder->runtime_root` do not duplicate `.developer-dashboard`. | Automated |
| N045 | Indicators | Confirm `dashboard indicator set` persists indicator state correctly. | Automated |
| N046 | Indicators | Confirm `dashboard indicator list` returns custom and core indicators. | Automated |
| N047 | Indicators | Confirm `dashboard indicator refresh-core` discovers project, git, and docker states. | Automated |
| N048 | Indicators | Confirm `dashboard ps1` renders compact and extended prompt modes. | Automated |
| N049 | Collectors | Confirm `dashboard collector run` executes configured command collectors. | Automated |
| N050 | Collectors | Confirm `dashboard collector inspect` exposes current collector metadata. | Automated |

## Browser Scenarios

| ID | Area | Scenario | Mode |
| --- | --- | --- | --- |
| B001 | Editor | Load `/` on exact loopback and confirm the root bookmark editor renders. | Automated |
| B002 | Editor | Confirm the root editor no longer shows a manual Update button. | Automated |
| B003 | Editor | Confirm editor textarea blur/change auto-submit still works. | Automated |
| B004 | Editor | Confirm the syntax-highlight overlay preserves line alignment with the textarea. | Hybrid |
| B005 | Editor | Confirm `HTML:` sections highlight tag, CSS, and JS tokens appropriately. | Automated |
| B006 | Editor | Confirm `CODE*` sections highlight Perl keywords, vars, strings, and comments. | Automated |
| B007 | Editor | Confirm TT placeholders in `HTML:` remain visible in edit mode and do not collapse into rendered text. | Automated |
| B008 | Editor | Confirm a saved bookmark edit posts back to `/page/<id>/edit` when transient URLs are disabled. | Automated |
| B009 | Editor | Confirm the Play link for a saved bookmark edit page points to `/page/<id>`. | Automated |
| B010 | Editor | Confirm the View Source link for a rendered saved page points to `/page/<id>/edit`. | Automated |
| B011 | Editor | Confirm the share link on saved pages stays on the named saved route instead of a transient token. | Automated |
| B012 | Editor | Confirm nested bookmark ids such as `nav/foo.tt` open in `/page/nav/foo.tt/edit`. | Automated |
| B013 | Editor | Confirm browser saves preserve nested bookmark ids without flattening paths. | Automated |
| B014 | Parser | Confirm a standalone `---` line terminates a older section in the browser editor view. | Automated |
| B015 | Parser | Confirm trailing prose after `---` does not leak back into the saved `CODE*` body in edit mode. | Automated |
| B016 | Parser | Confirm trailing prose after `---` does not generate runtime Perl compile errors in play mode. | Automated |
| B017 | Saved Pages | Load `/app/index` and confirm a saved bookmark renders through the older route. | Automated |
| B018 | Saved Pages | Load `/page/<id>` and confirm rendered bookmark content appears with top chrome. | Automated |
| B019 | Saved Pages | Confirm page `TITLE:` only populates the HTML `<title>` and not the page body unless explicitly rendered. | Automated |
| B020 | Saved Pages | Confirm request query params merge into page state for rendered saved pages. | Automated |
| B021 | Saved Pages | Confirm `nav/*.tt` fragments render above the main body in sorted filename order. | Automated |
| B022 | Saved Pages | Confirm `env.current_page` is available to nav fragments and saved pages. | Automated |
| B023 | Saved Pages | Confirm `env.runtime_context.current_page` is available to nav fragments. | Automated |
| B024 | Static Assets | Confirm `/js/<file>` serves bookmark-local assets from `dashboards/public/js`. | Automated |
| B025 | Static Assets | Confirm `/css/<file>` serves bookmark-local assets from `dashboards/public/css`. | Automated |
| B026 | Static Assets | Confirm `/others/<file>` serves bookmark-local assets from `dashboards/public/others`. | Automated |
| B027 | Static Assets | Confirm project-local runtime assets under `./.developer-dashboard/dashboard/public/js` are served. | Automated |
| B028 | Static Assets | Confirm MIME types for JS, CSS, JSON, XML, HTML, and images are correct in browser responses. | Automated |
| B029 | Static Assets | Confirm directory traversal attempts on static routes return `400` or `403`. | Automated |
| B030 | Static Assets | Confirm missing static files return `404`. | Automated |
| B031 | Ajax | Confirm saved bookmark `Ajax(file => ...)` endpoints resolve under `/ajax/<file>?type=...`. | Automated |
| B032 | Ajax | Confirm saved bookmark Ajax handlers stream `stdout` to the browser response. | Automated |
| B033 | Ajax | Confirm saved bookmark Ajax handlers stream `stderr` to the browser response. | Automated |
| B034 | Ajax | Confirm existing executable Ajax files under `dashboards/ajax` run without being overwritten. | Automated |
| B035 | Ajax | Confirm Ajax file routes work while transient token URLs are disabled. | Automated |
| B036 | Transient Policy | Confirm `/?token=...` is rejected with `403` when transient URLs are disabled. | Automated |
| B037 | Transient Policy | Confirm `/action?atoken=...` is rejected with `403` when transient URLs are disabled. | Automated |
| B038 | Transient Policy | Confirm `/ajax?token=...` is rejected with `403` when transient URLs are disabled. | Automated |
| B039 | Transient Policy | Confirm posting a bookmark file from the root editor is still allowed when transient URLs are disabled. | Automated |
| B040 | Auth | Confirm non-loopback access to `/` renders the helper login page. | Automated |
| B041 | Auth | Confirm helper login succeeds with a valid helper account. | Automated |
| B042 | Auth | Confirm helper page chrome shows the helper username after login. | Automated |
| B043 | Auth | Confirm helper page chrome shows `Logout` after login. | Automated |
| B044 | Auth | Confirm helper logout clears the session and removes the helper account. | Automated |
| B045 | Auth | Confirm exact-loopback admin access does not show the helper logout link. | Automated |
| B046 | Chrome | Confirm top chrome shows local username, machine IP/host link, and live date-time. | Automated |
| B047 | Chrome | Confirm `/system/status` updates the top status strip without breaking page render. | Hybrid |
| B048 | Integration | Confirm headless Chromium can load the root editor from the installed blank-environment tarball. | Automated |
| B049 | Integration | Confirm headless Chromium can load a saved fake-project bookmark page from the installed blank-environment tarball. | Automated |
| B050 | Integration | Confirm headless Chromium can load the helper login page from non-loopback access in the blank-environment integration flow. | Automated |

## Ownership Mapping

- Packaging and release: `N001-N008`
- CLI and hooks: `N009-N038`
- Runtime, indicators, and collectors: `N039-N050`
- Browser editor and saved pages: `B001-B023`
- Static assets and Ajax: `B024-B035`
- Browser transient policy and auth: `B036-B045`
- Browser chrome and installed integration flow: `B046-B050`

## Recommended Execution Order

1. Run fast unit and metadata tests with `prove -lr t`.
2. Run browser-sensitive web and static-file tests.
3. Run the blank-environment integration flow with headless Chromium.
4. Use the remaining manual and hybrid scenarios as release-gate spot checks.
