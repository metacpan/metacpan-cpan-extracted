# Developer Dashboard

## Purpose

`Developer Dashboard` is the full product name.

`dashboard` is the canonical command-line executable.

`DD` remains an acceptable short product nickname.

Build a new, smaller Developer Dashboard focused on reusable developer tooling primitives rather than older company-specific workflows.

Developer Dashboard is intended to be fully project-neutral and suitable for open source distribution.

The long-term goal is that any developer should be able to use it for any project, with project-specific behavior added only through config and plugins.

The new system should preserve the strongest ideas from the older project:

- a lightweight dashboard engine that can render pages from encoded instructions
- shareable page state via compact encode/decode URLs
- filesystem and project navigation helpers
- a smart `docker_compose` wrapper
- command-line indicators that reflect local system state
- a small plugin-style model for reusable dashboards and actions

The new system should not be tied to older service names, older middleware, older database tooling, or any fixed company-specific folder structure.

## Product Goal

Provide a portable local developer cockpit that combines:

- a browser UI for dashboards and tools
- a shell companion layer for path jumping and helper commands
- a small runtime for composing reusable internal tools from declarative or semi-declarative definitions
- a prompt-status layer integrated with `PS1`

The product goal is explicitly not tied to any single company, team, codebase, or service family.

It should be usable as:

- a personal local developer toolkit
- a team-shared project dashboard
- an open source base platform for custom extensions

## Design Principles

- Core first: extract reusable mechanics, not business workflows.
- Local first: optimize for localhost usage and personal developer environments.
- Portable by default: no hardcoded employer/team paths in the core.
- Extensible: service-specific workflows must live outside the core.
- Inspectable: encoded pages must be debuggable and reversible.
- Minimal magic surface: keep the “magic” useful, explicit, and documented.
- Project-neutral by default: core behavior must assume nothing about the user’s repos.
- Open-source ready: naming, packaging, defaults, and docs must be suitable for public distribution.

## Non-Goals

- Rebuilding all older dashboards in v1.
- Shipping older company workflows in core.
- Embedding environment-specific sensitive-material logic in core.
- Supporting every older script and bookmark format unchanged.
- Creating a hosted multi-tenant SaaS product.

## Open Source Position

Developer Dashboard is intended to be publishable as an open source project.

That means the core must be:

- generic
- documented
- configurable
- safe to install on unrelated projects
- free from employer-specific assumptions

Project-specific behavior should live in:

- repo-local config
- plugin packages
- optional extension bundles

## Distribution Goal

The ecosystem should be distributable as a CPAN module and installable outside the original development environment.

This implies:

- clean packaging boundaries
- minimal install assumptions
- documented CLI entrypoints
- stable module namespaces
- optional features that degrade cleanly when dependencies are absent
- a thin public `dashboard` entrypoint that lazy-loads the full runtime only
  for commands that actually need it
- shipped seeded bookmark assets that live outside the main command script and
  resolve correctly both from a source checkout and from the installed
  distribution share directory

Recommendation:

Treat distribution as a first-class product requirement, not an afterthought.

## User Types

### 1. Solo developer

Wants a local dashboard, path shortcuts, container helpers, and a few custom tools.

### 2. Team maintainer

Wants to define reusable dashboards, indicators, and helper commands for a repo or team.

### 3. Power user

Wants to create shareable encoded dashboard pages and custom actions without modifying core code heavily.

## Core Capabilities

### 1. Dashboard Engine

The system must render pages from structured page definitions.

Supported page sources:

- local files in a dashboards directory
- encoded page payloads in URLs
- generated pages from registered providers

Each page definition should support:

- metadata: title, description, tags
- layout content
- form inputs
- actions
- optional server-side handlers
- optional client-side enhancement scripts

The engine should support two modes:

- trusted local mode for full power features
- safer mode for limited/shared content rendering

### 2. Encode/Decode Page Sharing

The system must support turning a page definition or page state into a compact shareable token.

Minimum requirements:

- encode structured page payload to URL-safe text
- decode token back to the original structured representation
- preserve enough fidelity for round-trip editing
- provide “view source” and “rendered view” modes
- expose a human-debuggable raw representation

Preferred implementation characteristics:

- compression before base64/url-safe encoding
- deterministic output where practical
- versioned payload format

Example payload classes:

- full page definition
- page definition plus state
- action request context

### 3. Dashboard Definition Format

The new format should borrow the strength of the old bookmark model without tightly coupling to the older syntax.

V1 should support:

- a structured text format or JSON/YAML/TOML
- optional embedded templates
- optional action blocks
- optional hidden internal state

Earlier-inspired concepts worth preserving:

- title
- stash/state
- html/template section
- code/action sections
- shareable source view

Open decision:

- either define a new canonical format
- or support a compatibility adapter for old bookmark files later

Recommendation:

Use a new canonical format and add older import later if needed.

### 4. Local Command Runtime

The dashboard must be able to run local commands in a controlled way.

Requirements:

- synchronous command execution for quick actions
- background command execution for long-running tasks
- captured stdout/stderr
- exit status visibility
- timeouts
- working-directory control
- env var injection
- simple structured result object

The runtime should distinguish between:

- safe built-in actions
- trusted local custom actions

### 5. Seeded Workspaces And Optional Runtime Drivers

The base runtime should ship a small set of editable starter bookmarks that
demonstrate what the bookmark engine can do without bundling project-specific
logic.

Current seeded workspaces should include:

- `api-dashboard` and `sql-dashboard` as the default starter bookmarks
- `api-dashboard` as a file-backed HTTP workspace
- `sql-dashboard` as a file-backed SQL workspace

`dashboard init` must preserve an existing
`~/.developer-dashboard/config/config.json`. Re-running it may add missing
defaults, helper commands, or seeded pages, but it must not wipe or replace
user config.

The shipped source for seeded workspaces should live outside the main command
script as shipped assets or dedicated modules so bookmark bodies do not bloat
the public `dashboard` entrypoint.

`DD-OOP-LAYERS` is a required runtime contract. Starting at
`~/.developer-dashboard` and walking down through every parent directory until
the current working directory, every existing `.developer-dashboard/` layer
must participate as one inherited runtime stack. The deepest layer must remain
the write target and first lookup hit, but bookmarks, shared `nav/*.tt`,
config, collectors, indicators, auth/session lookups, runtime
`local/lib/perl5`, static assets, and custom CLI hooks must all inherit across
that full layer chain.

Dashboard-managed built-in helper extraction is the explicit exception to the
layered write target. `dashboard init` and on-demand helper staging must only
seed built-in helper scripts under `~/.developer-dashboard/cli/`, while
user-provided commands and hook directories continue to participate across the
full `DD-OOP-LAYERS` chain.

Home helper staging must stay non-destructive. `dashboard init` may add or
update dashboard-managed built-in helpers under `~/.developer-dashboard/cli/`,
but it must preserve pre-existing user-owned colliding files plus unrelated
files and directories there instead of deleting or overwriting them.

The public `dashboard` entrypoint must remain a real switchboard. Built-in
command bodies must live outside `bin/dashboard` under `share/private-cli/`.
Dedicated helper bodies may serve focused commands such as query, open-file,
ticket, path, and prompt helpers, while broader built-in command sets may use
thin staged wrappers that delegate into a private shared runtime such as
`~/.developer-dashboard/cli/_dashboard-core`.

The seeded `api-dashboard` should keep its behavior inside the bookmark source
itself rather than requiring a dedicated product module for the dashboard
logic. It should support:

- file-backed Postman collections under `config/api-dashboard/<collection-name>.json`
- owner-only `config/api-dashboard` directory permissions (`0700`) with owner-only saved collection json files (`0600`) because request auth can be stored there
- request tabs, collection tabs, and browser URL restoration for the active collection/request/tab state
- request-token carry-over for `{{token}}` placeholders across requests in the same collection
- a hide/show request-credentials panel inside the workspace with `Basic`, `API Token`, `API Key`, `OAuth2`, `Apple Login`, `Amazon Login`, `Facebook Login`, and `Microsoft Login` presets
- Postman `request.auth` import/export so saved collections stay valid Postman v2.1 JSON while the bookmark can still render and edit the credentials in-browser
- outgoing auth application through headers or query strings during request send, including provider-style OAuth token presets that keep the actual token and client values user-supplied
- browser previews for JSON, text, PDF, image, and TIFF responses

The seeded `sql-dashboard` should keep its behavior inside the bookmark source
itself rather than requiring a dedicated product module for the dashboard
logic. It should support:

- file-backed connection profiles under `config/sql-dashboard/<profile-name>.json`
- file-backed SQL collections under `config/sql-dashboard/collections/<collection-name>.json`
- owner-only `config/sql-dashboard` and `config/sql-dashboard/collections` directory permissions (`0700`) with owner-only profile and collection json files (`0600`)
- create, edit, and delete flows for connection profiles
- create, edit, delete, and reuse flows for SQL collections that stay independent from connection profiles
- one merged `SQL Workspace` tab with a phpMyAdmin-style master-detail layout where collection tabs live in a left navigation rail, the saved SQL list for the active collection sits directly below that heading, and the editor plus results stay together on the right
- the active saved SQL name always visible in the workspace, and saving a different SQL name into the same collection adds another saved SQL entry instead of overwriting the selected one
- a large primary SQL textarea with content-based auto-resize, one understated action row beneath the editor, no redundant in-workspace schema-open button, and compact inline `[X]` deletion for saved SQL entries beside the list item they belong to
- shareable browser URL state for the portable `connection` id, active tab, selected collection, selected saved SQL item, selected schema table, and current SQL text instead of a saved SQL file
- share URLs that carry `dsn|user` without a password and rebuild a draft connection profile on another machine when the matching saved profile is missing there
- auto-run of shared SQL only when the receiving machine already has a matching saved profile with a saved local password
- generic `DBI` execution rather than a single database brand
- installed-driver dropdown backed by visible `DBD::*` modules, with driver switches rewriting only the `dbi:<Driver>:` DSN prefix
- schema browsing through metadata calls such as `table_info` and `column_info`
- programmable result handling through statement separators and instruction hooks such as `SQLS_SEP`, `INSTRUCTION_SEP`, `STASH`, `ROW`, `BEFORE`, and `AFTER`
- singleton saved-Ajax workers for bootstrap, profile save/delete, collection save/delete, execution, and schema browsing

Database driver support should be optional instead of bundled by default.
The runtime should provide a command such as `dashboard cpan <Module...>` that:

- installs requested Perl modules into the active runtime's local library tree
- records those modules in `./.developer-dashboard/cpanfile`

The `dashboard` CLI and bookmark runtime must apply `DD-OOP-LAYERS`
consistently:

- custom commands resolve from the deepest matching `./.developer-dashboard/cli/<command>` layer, then outward toward `~/.developer-dashboard/cli`
- per-command hooks in `<command>/` or `<command>.d/` run for every discovered layer from home to leaf
- shared `nav/*.tt` and bookmark TT includes merge across all layers while letting the deepest matching bookmark id override parent copies
- config arrays such as `collectors` and `providers` merge across layers by logical identity instead of dropping parent entries wholesale

Windows support should follow the same boundary in code, docs, and release
verification:

- the supported baseline on Windows is PowerShell plus Strawberry Perl
- Git Bash is optional and Scoop is optional; they are setup helpers, not runtime requirements
- fast forced-Windows logic checks should stay in `t/`
- a real Windows smoke should use `integration/windows/run-strawberry-smoke.ps1`
- the rerunnable VM gate should use `integration/windows/run-host-windows-smoke.sh`
  with reusable env-file settings that delegate to the lower-level QEMU
  launcher
- the Dockur-backed path should be able to auto-resolve the current 64-bit Strawberry Perl MSI from the official Strawberry Perl release feed instead of requiring a stale installer URL to be hard-coded in docs
- the Dockur-backed path should be able to stage that Strawberry Perl MSI from
  the Linux host into the OEM bundle and keep retained guests on configurable
  host web/RDP ports for reruns
- the Windows guest may use `cpanm --notest` for third-party dependency setup,
  but the dashboard-specific Windows smoke after install must still exercise
  the real CLI, collector, Ajax, web, and browser paths
- release tarballs must exclude local coverage output such as `cover_db` even
  when the source tree just finished a Devel::Cover run before `dzil build`
- keeps the implementation in the `dashboard` entrypoint instead of adding a dedicated SQL or CPAN manager product module
- makes the runtime-local Perl library visible to bookmark Ajax workers and other dashboard-managed processes by deriving `local/lib/perl5` from the active runtime root
- automatically installs `DBI` when a requested module is a `DBD::*` driver

This keeps the base tarball generic and easier to install while still letting
users opt into whichever database drivers their own projects require.

### 5. Directory Navigation Magic

The new project should include reusable shell helpers inspired by the older folder-jumping behavior.

Requirements:

- named locations
- fuzzy project lookup
- repo-aware shortcuts
- configurable path aliases
- no hardcoded company-specific directories in core

Examples:

- jump to current repo root
- jump to configured workspace folders
- jump to named service directories
- locate projects by partial name

Recommended model:

- config-driven path registry
- optional shell integration script for `cd`-style helpers
- repo-local overrides plus user-global overrides

## Earlier Path and File Abstraction Findings

The old `Folder.pm` and `File.pm` were a major part of the system design.

They were not just utility modules.

They defined:

- directory discovery
- writable state locations
- bookmark/config/data locations
- status file locations
- project path conventions
- shell helper targets

That abstraction is worth preserving in the new Developer Dashboard core.

The older company-specific path names and hardcoded repo assumptions are not.

### 1. `Folder.pm` Was a Path Registry

The older `Folder.pm` acted as a central registry of named directories.

It provided:

- home-relative directories
- temp/state/cache directories
- config roots
- bookmark roots
- startup roots
- project/workspace roots
- helper methods such as `cd`, `ls`, `locate`, and `any`

This is a strong reusable concept.

Recommendation:

The new core should have a path registry service that provides:

- named directory resolution
- auto-create for writable runtime directories
- repo-local and user-global overrides
- helper APIs for directory switching and project discovery

### 2. `File.pm` Was a Named File Registry

The older `File.pm` complemented `Folder.pm` by giving stable names to important files such as:

- logs
- state markers
- config files
- cache files
- bookmarks
- runtime status files

This is also worth preserving.

Recommendation:

The new core should have a file registry layer built on top of the folder registry.

It should provide:

- named file resolution
- simple helpers for `read`, `write`, `touch`, and `rm`
- well-defined runtime state files
- a clean separation between user config, repo config, and transient runtime files

### 3. The Good Part To Keep

The reusable design pattern is:

- code refers to named paths
- one module owns the mapping from logical name to physical filesystem path
- runtime state lives in predictable places
- the rest of the application does not hardcode ad hoc paths everywhere

That pattern should remain core to the new project.

### 4. What Must Be Removed

The new core must not hardcode names or paths tied to:

- older internal service names
- older middleware names
- older database adapters
- employer-specific docker workspaces
- employer-specific cloud config folders

Those belong only in optional plugins or repo-local config.

### 5. Path Discovery Should Become Generic

The old `Folder.pm` mixed generic helpers with many project-specific assumptions.

The generic parts worth preserving are:

- `cd` into a named location
- list entries in a named location
- resolve one of several possible directories
- locate projects by name fragment
- keep runtime files under a known local root

Recommendation:

The new path service should support:

- `workspace_roots`
- `project_roots`
- `named_paths`
- `runtime_root`
- `cache_root`
- `logs_root`
- `dashboards_root`
- `state_root`

### 6. Runtime State Should Stay File-Backed

The old design used the filesystem heavily for:

- indicators
- checker logs
- cached status
- sessions
- bookmarks
- generated data

That is aligned with the new local-first design.

Recommendation:

V1 should remain filesystem-first for runtime state, with named directories for:

- state
- cache
- logs
- dashboards
- plugins
- temp artifacts

### 7. Path Naming Should Be Logical, Not Historical

The new core should avoid historical service names in its registry.

Use logical names instead, such as:

- `home`
- `runtime`
- `cache`
- `logs`
- `config`
- `dashboards`
- `plugins`
- `workspace`
- `projects`

Service- or company-specific names should come only from config or plugins.

## Folder and File Registry Specification

This section defines the replacement for older `Folder.pm` and `File.pm`.

### 1. Purpose

The Developer Dashboard core must include a filesystem abstraction layer that provides stable logical names for important directories and files.

This abstraction is a core platform service.

### 2. Folder Registry Responsibilities

The folder registry must support:

- resolve named directories
- create writable runtime directories on demand
- list directory contents
- temporarily execute code in a resolved directory context
- locate projects across configured roots
- resolve the first available directory among alternatives

### 3. File Registry Responsibilities

The file registry must support:

- resolve named files from named directories
- read and write named files
- append or touch files
- remove named files
- expose stable logical names for logs, state, and config

### 4. Required Core Directory Domains

The new core should define logical directory domains such as:

- user home
- runtime root
- state root
- cache root
- logs root
- config root
- dashboards root
- plugins root
- temp root
- workspace roots
- project roots

### 5. Required Core File Domains

The new core should define logical file domains such as:

- prompt state files
- indicator state files
- checker logs
- command logs
- bookmarks or page-definition indexes
- local config files
- repo config files

### 6. Configurable Mapping

Directory and file mappings must be configurable through:

- global user config
- repo-local config
- plugin-provided extensions

The core should provide defaults, but users must be able to override them.

### 7. Path Helper API

The runtime should expose a small set of path helper primitives, conceptually similar to the best parts of older `Folder.pm`.

Examples:

- resolve a named directory
- resolve a named file
- list a named directory
- run in a named directory
- locate a project by alias or fuzzy name

### 8. Shell Integration

The `cdr` and related shell helpers should rely on the same registry used by the web/runtime layers.

This ensures:

- one source of truth for path mapping
- consistent behavior between shell and dashboard
- easier extension through plugins and config

### 9. Plugin Boundary

Plugins may contribute:

- additional named paths
- additional named files
- workspace discovery rules
- project alias packs

But the core must remain generic when no plugins are installed.

### 6. Docker Compose Magic Command

The system should provide a wrapper around Docker Compose that reduces repeated context setup.

Requirements:

- resolve compose files from current project or configured services
- support common actions: `ps`, `up`, `down`, `logs`, `exec`, `config`, `restart`
- allow named service aliases
- expose effective command before running when desired
- support repo-specific defaults

Nice-to-have:

- auto-detect compose file in repo
- support multiple compose projects
- shortcuts for common service exec commands
- dashboard integration for container status and quick actions

The wrapper must remain transparent:

- users should be able to see what real command will run
- failures should surface raw stderr cleanly

## Earlier Docker Compose Findings

This section captures the reusable parts of the older `docker_compose` wrapper while explicitly rejecting company-specific behavior from the new core.

### 1. The Earlier Wrapper Was a Context Resolver

The old `docker_compose` command was not just a shortcut for `docker compose`.

It acted as a resolver that:

- changed into the expected project docker root
- assembled the effective compose file list
- applied service overlays
- injected environment defaults
- then executed the final `docker compose ...` command

This is the core design idea worth preserving.

### 2. Compose File Resolution Was Layered

The older wrapper built a final compose invocation from:

- a base compose file
- zero or more service overlays
- optional addon overlays
- optional development/live-update overlays

This layering model is reusable and should be part of the new core.

Recommendation:

The new Developer Dashboard should define a compose resolution pipeline with:

- base compose sources
- named overlay sources
- addon overlays
- optional mode-specific overlays such as `dev`

### 3. Service State Influenced Overlay Choice

The old wrapper read external service state and used it to decide whether a service should use:

- normal compose overlay
- development/live-update compose overlay

The older company-specific implementation should be removed, but the pattern is useful.

Recommendation:

The new system should allow overlay selection based on:

- explicit flags
- local config
- plugin-provided state

The core should not depend on any employer-specific status file.

### 4. Addons Were a Valuable Concept

The old `--addons=...` mechanism allowed optional services to be added to the compose stack without changing the base project definition.

This is a strong reusable idea.

Recommendation:

The new compose wrapper should support:

- named addons
- addon-specific overlays
- optional addon modes such as `addon/dev`

### 5. The Wrapper Also Mutated Environment

The old implementation mixed compose resolution with:

- external sensitive-material setup
- proxy behavior
- VPN-aware network behavior
- bespoke path normalization

These are not core behaviors.

They must be removed from the new core.

Recommendation:

The new core may support environment mutators only through plugins, with strict separation from compose resolution.

Core must not assume:

- AWS
- VPN
- proxy hosts
- employer network topology
- ticket-folder directory conventions

### 6. The Wrapper Must Stay Transparent

The best property of the old design is that the final operation was still plain `docker compose`.

That must remain true in the new system.

Required behavior:

- resolve the effective compose context
- print or expose the final command when requested
- then execute standard `docker compose`

The wrapper should never hide the real command structure.

## Docker Compose Resolver Specification

This section defines the reusable replacement for the older wrapper.

### 1. Purpose

The `docker_compose` feature in the new Developer Dashboard core should be a project-aware compose resolver and launcher.

It should make common multi-file compose workflows easier without hiding Docker itself.

### 2. Responsibilities

The compose resolver must be responsible for:

- locating the active project root
- locating compose configuration sources
- assembling the final ordered list of compose files
- applying addon and mode selections
- launching the final `docker compose` command

The compose resolver must not be responsible for:

- cloud authentication
- VPN detection
- employer-specific proxy behavior
- company-specific folder rewrites

Those belong only in optional plugins.

### 3. Inputs

The resolver should be able to accept input from:

- current working directory
- repo-local config
- user-global config
- explicit CLI flags
- optional plugin-provided context

### 4. Resolution Model

The final compose stack should support these conceptual layers:

- base compose file or files
- project overlays
- service overlays
- addon overlays
- mode overlays such as `dev`, `debug`, or `live`

Overlay precedence should be explicit and documented.

### 5. Canonical Operations

The wrapper should support familiar docker compose operations such as:

- `ps`
- `up`
- `down`
- `logs`
- `exec`
- `config`
- `restart`
- `rm`
- `cp`

The wrapper should pass through unknown docker compose arguments where possible.

### 6. Suggested Interface

The exact CLI is still open, but the shape should support commands like:

- `dashboard docker compose ps`
- `dashboard docker compose up`
- `dashboard docker compose exec app bash`

Optionally, a convenience shim named `docker_compose` may call into the DD runtime.

### 7. Addon Model

Addons should be defined in config rather than hardcoded in the runtime.

Each addon may specify:

- name
- one or more compose files
- optional modes
- optional default env vars

### 8. Mode Model

Modes should be generic and composable.

Examples:

- `dev`
- `debug`
- `watch`
- `test`

The core must not hardcode a special meaning for employer-specific modes.

### 9. Environment Injection Policy

The core resolver may support environment injection, but only in a generic, explicit way.

Examples:

- repo config env
- addon env
- mode env
- plugin-provided env mutator

The resolver must make it visible which environment variables are being injected.

### 10. Project Discovery

The resolver should support project discovery using:

- current git repo
- configured workspace roots
- repo-local config markers
- explicit `--project` or equivalent selector

### 11. Transparency and Debuggability

The resolver must support a mode that shows:

- resolved project root
- selected addons
- selected modes
- resolved compose files in order
- final command line

This is required so users can debug the wrapper rather than being trapped behind magic.

### 12. Plugin Boundary

The core resolver may be extended through plugins for:

- cloud sensitive material
- network prechecks
- additional compose discovery logic
- project-specific overlays

But these plugins must remain optional.

The core must still function without any employer-specific plugin installed.

### 7. Prompt Indicator System

The system should expose small status indicators for shell prompts and dashboard views.

This is a first-class subsystem in DD.

The old model is worth preserving:

- checks refresh state out of band
- prompt rendering reads cached state quickly
- indicators are small, composable, and visible in the terminal

The new version must keep the idea but make it generic and plugin-driven.

Requirements:

- indicator producers write status to local state files or a small state store
- prompt integration reads current status quickly
- indicators support text/icon/color semantics
- update mechanism works both on demand and in background loops
- prompt rendering must not perform slow checks inline
- stale indicator state must be handled explicitly

Initial generic indicators:

- Docker availability
- Git dirty state
- current project context
- user-defined checks

Possible plugin-provided indicators:

- VPN connected/disconnected
- cloud auth valid/expired
- network reachable/unreachable
- local services up/down
- toolchain ready/not ready

Important:

- indicator names and meanings must be generic in core
- service-specific indicators belong in extensions
- core must not assume a specific VPN, cloud account, or employer-specific service

### 7.a. PS1 Integration

DD must provide a dedicated prompt integration layer.

Requirements:

- expose a `dashboard ps1` command as the canonical prompt entrypoint
- support `bash` first in v1
- support wiring `PS1` directly to command substitution, following the older shape
- render from cached status only
- support compact and extended display modes
- support colored and plain-text output
- degrade cleanly when no indicators are enabled

Earlier compatibility insight:

- in the old project, `.bashrc` used `export PS1='$(ps1 jobs=\j)'`
- `bin/ps1` printed the full prompt body, including time, indicators, cwd, jobs, and git branch

V1 should preserve that user experience conceptually:

- `PS1` should be able to call a DD-owned executable directly
- the command should accept prompt-context inputs such as shell job count
- the command should be fast enough for per-prompt execution

Suggested interface:

- `dashboard ps1 --jobs <n>`

or a shell-friendly equivalent that still allows:

- `export PS1='$(dashboard ps1 --jobs \j)'`

Prompt rendering rules:

- never block the shell on slow network or process checks
- use checker output already persisted by the runtime
- allow async refresh outside the prompt render path
- keep shell glue thin and move logic into the DD runtime
- include prompt context such as cwd, current project alias, jobs count, and git branch when available

### 8. Background Checkers

The system should support lightweight recurring checks.

Requirements:

- named checks
- configurable interval
- timeout
- start/stop/list status
- persistence of last result
- logs for each checker

Checkers should be usable for:

- shell prompt indicators
- dashboard health panels
- project readiness checks

Checker and indicator responsibilities should stay separate:

- checkers gather or refresh state
- indicators present that state in prompt/dashboard form

## Earlier Polling and Data Collection Findings

The old system did not rely on live checks inside every consumer process.

Instead, it used background polling jobs to prepare data into files, then other processes read those files later.

This is one of the strongest architectural ideas in the older codebase and should be preserved in the new core.

### 1. The Earlier Model Was Producer/Consumer

The architecture was effectively:

- background producers poll or compute state
- producers write output to predictable files
- consumer processes read cached files

Consumer examples in the old system:

- `bin/ps1`
- dashboard pages
- `docker_compose`
- auto-reload logic

This is the right model for DD because it keeps prompt rendering and dashboard refresh fast.

### 2. Startup Was a Job Launcher

The `startup` folder defined recurring background jobs declaratively.

Each startup file contained a JSON-like array of arguments for `run_bg`, such as:

- job name
- interval
- timeout
- working directory
- command
- optional crontab schedule

The launcher in `dashboard-sys-check-on`:

- read a startup whitelist
- loaded each startup file
- templated the arguments
- passed them into `run_bg`

The reusable design idea is:

- startup jobs should be data-driven
- jobs should be centrally launched
- jobs should not require bespoke daemon code for every check

### 3. `run_bg` Was the Real Polling Engine

The core polling primitive in the older system was `System::DataProcess::run_bg`.

It provided:

- named background jobs
- process naming
- start/stop/restart/ps
- fixed interval execution
- optional crontab-style scheduling
- timeout support
- working-directory control
- persisted stdout and stderr
- persisted `last_run`
- inspection commands for consumers

This is a very strong reusable core concept.

Recommendation:

DD should include a generic collector runtime with capabilities equivalent to:

- register job
- start job
- stop job
- restart job
- inspect job
- fetch stdout
- fetch stderr
- fetch last-run timestamp
- fetch combined output

### 4. File-Backed Job Output Was the Integration Surface

The older polling system wrote per-job data under a collector directory.

Each job had a directory containing at least:

- `stdout`
- `stderr`
- `last_run`
- process metadata

This meant every consumer could integrate by reading files instead of re-running checks.

This is worth preserving.

Recommendation:

The new core should keep collector output file-backed in v1.

Each collector should have a stable runtime directory with:

- job metadata
- latest stdout
- latest stderr
- latest success/error summary
- last-run timestamp
- optional structured output payload

### 5. Atomic Updates Matter

The old runtime wrote output using pending files and renamed them into place.

That is an important detail because readers such as prompt renderers and dashboards should not see partially written data.

Recommendation:

The new collector runtime must use atomic write-and-rename behavior for job outputs and state snapshots.

### 6. Prompt and Dashboard Were File Consumers

The older `ps1` command did not run Docker, VPN, DB, or AWS checks itself.

Instead, it read indicator files created by background jobs.

Similarly, dashboards read cached status from:

- indicator files
- collector outputs
- status marker files

This separation should be preserved.

Rule for the new system:

- prompt rendering reads only cached state
- dashboard polling reads only cached state or explicit action endpoints
- expensive checks run in collectors, not in the prompt path

### 7. Indicators Were Just One Consumer Format

The older system produced two related file-backed data shapes:

- collector data files under the data collector root
- indicator/status marker files under system state roots

That separation is useful.

Recommendation:

DD should keep distinct concepts for:

- collector output
- indicator state
- status markers

A collector may update one or more indicators, but the two should remain different abstractions.

### 8. Wrappers Also Consumed Prepared Data

The old `docker_compose` wrapper read prepared files such as service status and cached sensitive material rather than computing everything itself.

This is an important pattern:

- wrappers should consume prepared data when possible
- wrappers should not become mini-orchestrators that repeat heavy checks inline

Recommendation:

The new DD wrappers should be able to consume collector output through a stable API and file layout.

### 9. Scheduling Should Support Interval and Cron Modes

The old system supported both:

- fixed interval polling
- crontab-like schedules

That is worth preserving because some checks should run continuously while others should run only at specific times.

Recommendation:

The new collector runtime should support:

- `interval`
- `cron`
- `manual`

### 10. Logging and Inspectability Were Important

The older system logged collector activity and allowed fetching logs and latest outputs.

That is important operationally because background jobs are otherwise opaque.

Recommendation:

DD must include collector observability features:

- list running jobs
- view collector logs
- inspect last run
- inspect current cached output
- inspect current job configuration

## Collector Runtime Specification

This section translates the older polling model into the new DD core.

### 1. Purpose

DD must include a collector runtime for recurring or scheduled background tasks that prepare data for other DD subsystems.

### 2. Responsibilities

The collector runtime must support:

- launching named jobs
- scheduling jobs
- persisting job output
- persisting job metadata
- exposing job status for consumers and debugging

### 3. Collector Job Types

The runtime should support at least:

- interval collectors
- cron collectors
- on-demand collectors

### 4. Collector Output Model

Each collector should have a stable runtime directory containing files such as:

- `stdout`
- `stderr`
- `last_run`
- `status.json` or equivalent structured state
- `job.json` or equivalent metadata

### 5. Collector Status Model

Each collector should expose status such as:

- name
- enabled/disabled
- running/stopped
- last started time
- last completed time
- last success time
- last failure time
- last exit code

### 6. Consumer Contract

Other DD subsystems should consume collector output through a stable read API or stable file layout.

Expected consumers include:

- `dashboard ps1`
- dashboard status views
- wrapper commands
- plugins

### 7. Indicator Integration

Collectors may optionally publish to indicator state.

The indicator layer should not need to know how the collector was run.

### 8. Job Definitions

Collector job definitions should be declarative and file-based.

A job definition should include:

- job name
- command or handler
- schedule
- timeout
- working directory
- env overrides
- output format hints

### 9. Startup Loader

DD should support a startup loader that discovers enabled collector definitions and starts them.

This should be config-driven rather than hardcoded.

### 10. Plugin Boundary

Plugins may contribute collector jobs for:

- network checks
- cloud session checks
- repo health checks
- local service health checks
- custom project automation

But the collector runtime itself must remain generic.

### 9. Extensibility Model

The new system should support extensions without modifying the core runtime.

Extension types:

- dashboard definitions
- custom action handlers
- path alias packs
- checker definitions
- indicator definitions
- prompt segment definitions
- docker service mappings

Recommended loading order:

1. core defaults
2. user global config
3. repo local config
4. optional extension packs

## Proposed Architecture

### 1. Core Web App

Responsibilities:

- page routing
- render encoded pages
- serve dashboard definitions
- execute permitted actions
- expose status endpoints

### 2. Core Runtime Library

Responsibilities:

- encode/decode payloads
- dashboard parsing
- template rendering
- command execution
- background process management
- state persistence

### 3. Shell Integration Layer

Responsibilities:

- `cdr`-style path jumping
- prompt indicator rendering
- `PS1` integration
- helper command wrappers
- project context discovery

### 4. Config Layer

Responsibilities:

- resolve user and repo config
- merge defaults and overrides
- validate config schemas

### 5. Extension Layer

Responsibilities:

- load dashboards
- register actions
- add checkers and indicators
- add path aliases and docker aliases

## Suggested Data Model

### Dashboard Definition

Fields:

- `id`
- `title`
- `description`
- `tags`
- `source_version`
- `inputs`
- `state`
- `layout`
- `actions`
- `permissions`

### Action Definition

Fields:

- `id`
- `label`
- `kind`
- `command` or `handler`
- `cwd`
- `env`
- `timeout_ms`
- `background`

### Indicator Result

Fields:

- `name`
- `status`
- `label`
- `updated_at`
- `message`
- `source`
- `stale_after`
- `priority`
- `prompt_visible`

### Path Alias

Fields:

- `name`
- `path`
- `scope`
- `tags`

## Configuration

Core should support both:

- global user config
- repo-local config

Configuration domains:

- dashboard directories
- path aliases
- project roots
- docker defaults
- enabled checkers
- prompt indicator settings
- prompt renderer settings
- trusted action policy

## Security Model

This is a local-first trusted developer tool, but command execution still needs boundaries.

V1 security posture:

- local machine, trusted user
- unsafe command execution only from trusted local files
- encoded remote/shared payloads should be renderable without implicit arbitrary execution

This means:

- rendering and execution should be separable
- encoded pages must not automatically become full arbitrary code execution unless explicitly trusted
- action execution should be opt-in per source or per dashboard

## Migration Guidance From Earlier

## Earlier Engine Findings

This section captures the specific reusable mechanics discovered in the old `Playground.pm` and bookmark system.

These findings should inform the new core design directly.

### 1. Source of Truth Was Instruction Text

In the older system, the primary unit was not a route, component, or database record.

It was an instruction document.

That document was a structured text payload split into sections such as:

- `TITLE`
- `ICON`
- `BOOKMARK`
- `STASH`
- `HTML`
- `CODE0..CODEN`

The instruction document could come from either:

- a text area submitted by the user
- a compressed token in the URL
- a bookmark file stored on disk

This is the most important engine idea worth preserving.

### 2. The Earlier Runtime Had a Stable Four-Step Pipeline

The old `Playground->run()` pipeline was effectively:

1. parse input instruction
2. normalize and reassemble instruction
3. render page/form/template
4. execute code blocks

That flow matters because the URL, rendering, and execution all derived from the same canonical instruction payload.

Recommendation for the new Developer Dashboard:

- preserve a canonical page document lifecycle
- parse incoming page definition
- merge request/page state
- reserialize into canonical form
- derive share URLs from the canonical form
- render from the canonical form

### 3. Saved and Unsaved Pages Were Different Views of the Same Document

The old system had two page modes.

#### Unsaved page

An unsaved page lived only in the encoded URL.

The flow was:

- user edits instruction text
- runtime normalizes it
- runtime compresses and encodes it
- page is reopened from `?token=...`

This gave ad hoc, shareable, transient pages.

#### Saved page

A saved page lived as a file in the bookmarks directory.

Important older detail:

- the saved bookmark file usually stored the raw instruction source
- it did not need to store the tokenized URL permanently

When `/app/<name>` was opened:

- the bookmark file was read from disk
- if it contained raw instruction text, the runtime converted it into a tokenized display URL on the fly
- request parameters were merged into the bookmark parameters
- the request was internally forwarded into the normal page pipeline

This distinction is important and should be preserved conceptually in the new system.

Recommendation:

- saved page = persisted source definition
- unsaved page = transient encoded definition
- both should feed the same runtime pipeline

### 4. URL Semantics Were a Core Product Feature

The old system generated multiple URL forms from the same canonical instruction text.

Main page URL forms:

- editable form: `/?token=...`
- rendered-only form: `/?display=only&token=...`
- source-view form: `/?display=source&token=...`

This was not just transport.

It was part of the user experience:

- edit
- play
- share
- inspect source

Recommendation:

The new Developer Dashboard should preserve these concepts in modernized form:

- editable page URL
- render-only page URL
- source-view URL
- stable encoded payload format with versioning

### 5. Canonical Reassembly Was Important

The old runtime did not simply execute the incoming payload as-is.

It parsed the instruction into parts, merged state into `stash`, then reassembled the full document into a normalized instruction string before generating share URLs.

That normalization step is important because it:

- gives one canonical source form
- allows request state to become part of the document
- ensures URLs represent the current effective page definition

Recommendation:

The new runtime should explicitly define a canonical serialization format and use it as the basis for:

- URL encoding
- file persistence
- source viewing
- diffing

### 6. The Page Definition Included Both UI and Behavior

Earlier bookmarks mixed:

- page metadata
- view markup
- form definitions
- state/stash
- executable code blocks

This made the engine powerful but also unsafe.

What should be preserved:

- a page definition can describe both UI and actions
- forms and layout should live together with page state
- pages should be self-contained enough to share

What should not be preserved unchanged:

- arbitrary code execution directly from untrusted encoded page payloads
- raw eval-heavy parsing as the default model

### 7. AJAX Was a Second Encoded Execution Channel

The old system also supported tokenized action URLs, not just tokenized page URLs.

That flow was:

- template a code snippet
- gzip + base64 encode it
- generate `/ajax?token=...&type=...`
- decode and execute server-side

This was a separate execution path used for dynamic or asynchronous actions.

The reusable design idea is strong:

- page transport and action transport can be separate
- actions can be encoded, parameterized, and invoked independently

Recommendation:

The new system should support distinct encoded artifact types:

- page payloads
- action payloads

But the new system must add explicit trust and permission rules around executable actions.

### 8. Request Parameters Were Part of the Page State Model

The old runtime merged most incoming request parameters into the page stash/state.

That meant a bookmark could behave like a parameterized app without needing a separate controller for every route.

This is a useful reusable concept.

Recommendation:

The new system should support parameterized pages where:

- page source defines inputs and defaults
- request/query/form data merges into runtime state
- runtime state can be reflected back into the canonical serialized page

### 9. Bookmark Routing Was a Resolver Layer

The `/app/<name>` route in the old system was not the application itself.

It was a resolver:

- map name to stored source or stored URL
- translate into a normal page invocation
- merge bookmark params with current web params
- forward into the main engine

Recommendation:

The new system should keep an explicit page resolver layer with support for:

- named saved pages
- transient encoded pages
- repo-local pages
- user-global pages

### 10. The Real Earlier Architecture Pattern

The older engine can be summarized as:

- document source layer
- canonical serialization layer
- encoded URL transport layer
- renderer layer
- action execution layer

That pattern is reusable and should be preserved in the new architecture.

The new Developer Dashboard should deliberately rebuild this pattern with stronger safety and clearer boundaries.

## Page Model Specification

This section translates the older findings into explicit requirements for the new system.

### 1. Page Sources

The new runtime must support the following page sources:

- saved page definition from disk
- transient encoded page from URL
- generated page from a provider/plugin

All sources must be converted into the same internal page document model before rendering.

### 2. Page Modes

The new runtime must support at least these page modes:

- edit mode
- render-only mode
- source-view mode

These modes should be first-class URL or route states, not ad hoc UI flags.

### 3. Canonical Serialization

Every page document must have a canonical serialized representation.

This representation must be used for:

- persistence
- shareable encoding
- source inspection
- change comparison

### 4. Saved Page Semantics

A saved page must store the source page definition, not merely a rendered URL.

The runtime may derive shareable URLs from it dynamically.

This keeps saved artifacts:

- inspectable
- diffable
- portable
- editable

### 5. Unsaved Page Semantics

An unsaved page should exist as a transient encoded payload and should not require filesystem persistence.

It must still support:

- rendering
- source viewing
- parameter merging
- sharing

### 6. Parameterized Page State

Page definitions must support runtime state that can be populated from:

- default values
- query parameters
- form submissions
- plugin-provided context

The system should define which state is:

- persisted in source
- transient in runtime only
- reflected into generated share URLs

### 7. Action Transport

The system should support actions as distinct executable resources related to a page but separate from the page payload itself.

These actions may be addressed through:

- named actions
- signed or trusted action identifiers
- encoded action payloads

The old AJAX token pattern should be treated as inspiration, not copied directly.

### 8. Trust Boundary

The old engine mixed rendering and execution too freely.

The new system must separate:

- rendering a page definition
- executing trusted actions
- executing arbitrary local code

Minimum rule:

- encoded shared pages must be renderable without automatically granting arbitrary execution

### 9. Compatibility Position

The new core does not need full older bookmark syntax compatibility in v1.

However, the architecture must make it possible to add:

- a older bookmark importer
- a older page adapter
- a migration tool from old bookmark files to the new page format

### Preserve

- encoded/shareable dashboard state
- file-based dashboard definitions
- local system checkers
- prompt indicator concept
- prompt-linked `ps1` rendering
- path abstraction
- docker wrapper ergonomics
- quick internal-tool composition

### Drop From Core

- hardcoded company-specific repos and paths
- older database, service, and middleware assumptions
- bespoke auth based on support-person files
- company-specific startup routines
- employer-specific AWS logic

### Rebuild As Optional Extensions Later

- SQL dashboards
- XML tools
- email testing tools
- service-specific config viewers
- company-specific environment health checks

## V1 Scope

V1 should deliver:

- a local web app with a small dashboard engine
- encode/decode shareable page URLs
- file-based dashboards in a new canonical format
- command execution for trusted actions
- configurable path aliases with shell integration
- a `docker_compose` wrapper
- a generic indicator/checker framework
- a `PS1` integration command backed by plugin-driven indicators

## Out of Scope For V1

- full older bookmark compatibility
- advanced auth
- cloud sync
- multi-user permissions
- marketplace/distribution system
- visual dashboard builder UI

## Open Technical Decisions

These need to be settled before implementation:

1. Implementation language and stack for the new core.
2. Canonical dashboard definition format.
3. Templating model.
4. Action execution trust model.
5. Background process model for checkers.
6. State storage format: files only or lightweight embedded DB.
7. Shell support targets: bash only first, or zsh/fish too.

## Recommended Decisions

### Stack

Use a modern, portable stack with strong local tooling support.

Recommendation:

- TypeScript/Node.js for the web app and shared runtime
- small shell scripts for terminal integration

Reason:

- easier portability than the old Perl stack
- good support for local HTTP apps, process control, schema validation, and browser UI
- easier future extension model

Alternative:

- keep Perl for faster older concept transfer

This is viable, and it becomes significantly more attractive if CPAN distribution is a primary goal.

Revised stack note:

- if the priority is maximum continuity with the old code and straightforward CPAN packaging, Perl is a serious option
- if the priority is broader frontend/runtime ergonomics, TypeScript remains attractive

This decision should now be driven largely by the intended distribution model.

### Packaging Direction

Because CPAN distribution is a stated goal, the architecture should be packaging-aware from the start.

If Perl is chosen:

- Developer Dashboard should be packaged as a CPAN distribution
- CLI commands such as `dashboard` or compatibility shims should be installed from the distribution
- plugin packages should be designed so they can also be shipped as CPAN distributions when appropriate

If a non-Perl core is chosen:

- CPAN packaging becomes less natural and should be reconsidered carefully

Recommendation:

If CPAN is a real distribution target rather than a vague possibility, prefer a Perl-first architecture for the core runtime.

### Dashboard Format

Recommendation:

- structured YAML or JSON with explicit fields
- optional Markdown/HTML/template content blocks

Avoid:

- heavy implicit parsing rules that recreate too much older ambiguity

### State Storage

Recommendation:

- filesystem-first for v1

Store:

- dashboard sources
- encoded payload metadata
- checker status
- logs
- path alias config

This best matches the local-first model and keeps the system transparent.

## Success Criteria

The project is successful when:

- a developer can install it without employer-specific setup
- a dashboard can be defined in a local file and rendered in the browser
- a dashboard can be encoded into a shareable URL and round-trip decoded
- shell helpers can jump to configured project directories quickly
- the docker wrapper removes repeated compose boilerplate
- prompt indicators reflect live local state through generic checkers
- prompt rendering is fast enough to use continuously in `PS1`
- service-specific workflows can be added without changing core
- the core can be packaged and installed as an open source distribution
- unrelated projects can adopt it without editing the core codebase

## Proposed Delivery Phases

### Phase 0. Spec and boundaries

- finalize product scope
- finalize architecture choices
- define trust boundaries

### Phase 1. Core runtime

- page format
- encode/decode logic
- render pipeline
- config loading

### Phase 2. Local actions

- command runner
- background jobs
- logs and results

### Phase 3. Shell integration

- path alias system
- `cdr` helper
- prompt indicators
- docker wrapper

### Phase 4. Extension model

- repo-local dashboard packs
- custom indicators
- custom action handlers

### Phase 5. Earlier import

- selectively port useful old workflows as optional extensions

## Immediate Next Step

Before coding, decide and lock:

- implementation stack
- dashboard definition format
- trust model for encoded pages and executable actions
- configuration file locations
- initial shell targets
