# Fixed Bugs

## 2026-04-20 (Phase 131: Skill Dependency Policy Unification)

- Fixed the skill dependency policy drift so installed skills now process
  `ddfile`, `aptfile`, `brewfile`, `cpanfile`, and `cpanfile.local` in a
  documented stable order instead of only supporting the older
  `aptfile`-then-`cpanfile` flow.
- Fixed shared-versus-local Perl dependency handling for skills so `cpanfile`
  now installs into the home-level `~/perl5` tree across root, child, skill,
  and nested skill layers, while `cpanfile.local` installs into that skill's
  own `./perl5` tree.
- Fixed skill runtime library exposure so dispatched skill commands now inherit
  both the shared `~/perl5/lib/perl5` stack and any participating skill-local
  `perl5/lib/perl5` trees from layered skill roots.
- Fixed dependency metadata visibility and guardrails so skill inventory now
  reports `has_ddfile`, `has_brewfile`, and `has_cpanfile_local`, and the
  dependency installer skips already-installed or in-flight `ddfile`
  dependencies instead of looping back into itself.

## 2026-04-20 (Phase 129: Which Edit Reentry)

- Fixed the command-inspection usability gap where `dashboard which` could only
  print the resolved command path and hook chain even when the user already
  knew they wanted to open the resolved file for editing.
- Added `dashboard which --edit` so built-in helpers, layered custom commands,
  single-level skill commands, and nested skill commands now re-enter the
  public `dashboard open-file` path with the resolved command file instead of
  duplicating editor-launch logic inside `which`.
- Synced the README, the main manual, the private `which` helper POD, the
  public `dashboard` synopsis, and the dedicated `doc/which-command.md` guide
  so the new editing flow is documented alongside the existing `COMMAND` and
  `HOOK` inspection output.

## 2026-04-20 (Phase 130: Release Tarball Integration Asset Packaging)

- Fixed the release packaging drift where `dist.ini` still excluded
  `integration/` and every Markdown file, so the built tarball dropped the
  testing guides and integration helpers that install-time tarball tests read.
- Added a tarball-content regression to the release metadata gate so the built
  `Developer-Dashboard-X.XX.tar.gz` must now contain the shipped
  `doc/integration-test-plan.md`, `doc/testing.md`, `doc/windows-testing.md`,
  and the key `integration/` helper scripts.
- Synced the integration-assets gate and release guide so installed
  distributions now expect those verification assets to stay present instead
  of treating them as checkout-only files.

## 2026-04-20 (Phase 128: Tracked Testing Workflow Documentation)

- Fixed a CI-only `t/13-integration-assets.t` failure where `doc/testing.md`
  existed locally but was ignored by `.gitignore`, so GitHub Actions checked
  out a tree without the file and the test died while opening it.
- Unignored `doc/testing.md`, kept the document in the repository, and
  hardened the integration-assets gate so it now asserts that the testing
  workflow document both exists and is tracked before reading it.

## 2026-04-20 (Phase 128: cdr Completion And Unreadable Tree Safety)

- Fixed `cdr` path discovery so unreadable subdirectories are skipped
  explicitly instead of aborting the whole search with `opendir(...)` errors
  when one protected tree appears under the search root.
- Added `dashboard path complete-cdr` and wired the generated bash, zsh, and
  PowerShell shell bootstraps so `cdr`, `dd_cdr`, and `which_dir` now expose
  live tab completion for saved aliases and matching directory basenames.
- Expanded path-helper and shell-smoke regression coverage to pin the
  unreadable-directory safety path and the generated `cdr` completion contract.

## 2026-04-20 (Phase 127: WSL cmd.exe And Portable d2 Bootstrap)

- Fixed the mixed Windows/WSL launcher drift where `.cmd` and `.bat` command
  argv resolution leaked `/mnt/c/.../cmd.exe` instead of the stable
  `cmd.exe` token expected by the Windows execution contract.
- Fixed the shell bootstrap portability gap where POSIX `d2` helpers
  hardcoded the Perl binary that generated the bootstrap, which could break on
  systems that later loaded the snippet under a different Perl install.
- Fixed the documentation drift by clarifying that POSIX shell bootstraps keep
  JSON helper decoding on the generating Perl interpreter but re-enter the
  `dashboard` script directly for the `d2` shortcut itself.

## 2026-04-20 (Phase 126: Command Suggestion Guidance)

- Fixed the switchboard usability gap where a mistyped top-level command only
  dumped the generic help block and gave no direct hint about the intended
  command.
- Fixed dotted skill dispatch drift by suggesting the nearest installed skill
  command, including nested `skills/<repo>/skills/<repo>/...` trees, when the
  user mistypes the skill command tail.
- Fixed the shell completion drift by wiring `dashboard` and `d2` Tab
  suggestions back into the live runtime command inventory instead of leaving
  shell users to guess built-ins and installed skill commands manually.
- Fixed the documentation gap by adding a dedicated command suggestion guide
  and syncing the README and main manual with the new typo-guidance behavior.

## 2026-04-19 (Phase 125: Shell Bootstrap d2 Shortcut)

- Fixed the shell integration gap where users still had to type the full
  `dashboard` command name after loading the generated bootstrap.
- Fixed bootstrap parity by generating a `d2` shortcut for bash, zsh, POSIX
  `sh`, and PowerShell, so the short form forwards into the same dashboard
  command path across supported shells.
- Fixed the doc drift by documenting the generated shell helpers in the README,
  the main manual, and a dedicated shell bootstrap doc page, with regression
  tests that execute `d2 version` through the generated POSIX shell bootstrap
  and verify the PowerShell alias wiring.

## 2026-04-19 (Phase 124: Temp State Root Recreation)

- Fixed the restart/runtime bug where collector startup could die after a
  reboot or temp cleanup removed the shared hashed state root under `/tmp`,
  because the metadata writer tried to open `runtime.json` before recreating
  that hashed directory.
- Fixed the temp-state rewrite path by making the path registry recreate the
  missing hashed state root first and then rewrite `runtime.json`, so layered
  collectors, indicators, and sessions can recover automatically when the temp
  tree is gone.

## 2026-04-19 (Phase 123: Local Skill Reinstall And Plain List Output)

- Fixed the local skill install gap where `dashboard skills install` could not
  accept a direct checked-out skill repository path even though the user
  already had the source locally.
- Fixed reinstall behaviour by making repeated installs replace the isolated
  installed copy instead of failing on an existing repo name, with local
  checked-out skills synced through `rsync` and gated on `.git/` plus
  `.env` `VERSION=...` qualification.
- Fixed the skills list terminal output drift by making table output the
  default and replacing unreadable colored toggle glyphs with explicit
  `enabled` and `disabled` text that aligns with the column header.
- Fixed the release packaging leak where the local kwalitee gate pulled
  `Module::CPANTS::Analyse` and `Module::CPANTS::Kwalitee` into generated
  install-time test prerequisites, which broke blank-environment `cpanm`
  verification even though those modules are only needed for the release gate.
- Fixed the local checked-out skill reinstall runtime gap where direct local
  installs failed outright when the host or blank-environment container did
  not have the external `rsync` binary on `PATH`.

## 2026-04-19 (Phase 122: Command Inspection And Nested Skill Which)

- Fixed the command-inspection gap by adding `dashboard which`, which shows
  the exact resolved runnable file and the participating hook files for
  built-in helpers, layered custom commands, and dotted skill commands.
- Fixed nested skill introspection drift by making the same inspection path
  understand repeated `skills/<repo>/.../skills/<repo>` trees, so
  `dashboard which nest.level1.level2.here` resolves the final nested
  `cli/here` file instead of failing at the top skill root.
- Fixed release-consistency drift by documenting the inspection contract in
  the main manuals and shipping the helper as part of the private staged
  built-in command set.

## 2026-04-19 (Phase 121: Skill Hook Result Overflow)

- Fixed the skill-dispatch overflow bug where large accumulated hook
  `RESULT` payloads were still serialized inline in the skill child env,
  causing `Argument list too long` failures even though the main switchboard
  already had a file-backed overflow path.
- Fixed skill command handoff consistency by making skill hooks and skill
  commands use `Developer::Dashboard::Runtime::Result` for `RESULT`,
  `RESULT_FILE`, `LAST_RESULT`, and `LAST_RESULT_FILE` just like the main
  dashboard hook chain.
- Fixed backward-compatibility drift by keeping `execute_hooks` on its old
  empty-result shape when no hooks run, while still exposing the immediate
  previous hook payload to real skill commands.

## 2026-04-19 (Phase 120: Layered Env Expansion And Comment Parsing)

- Fixed the plain `.env` precedence gap by keeping same-level load order
  strict as `.env` first and `.env.pl` second, so executable env logic sees
  the final plain-file values from that layer instead of racing them.
- Fixed the plain `.env` parser gap by supporting whole-line `#` comments,
  whole-line `//` comments, and `/* ... */` block comments across multiple
  lines without silently accepting malformed syntax.
- Fixed the missing value-composition support by adding plain `.env`
  expansion for leading `~`, `$NAME`, `${NAME:-default}`, and
  `${Namespace::function():-default}`, with explicit failures for missing
  functions and other malformed expressions.

## 2026-04-19 (Phase 119: Layered Env Contract And Provenance Audit)

- Fixed the missing DD-OOP-LAYERS env contract by loading `.env` and
  `.env.pl` files from root to leaf across both plain directory ancestry and
  participating `.developer-dashboard/` runtime layers before command
  execution.
- Fixed skill-env leakage risk by loading skill-local env files only when a
  skill command or skill hook is actually running, instead of exposing those
  overrides to unrelated non-skill commands.
- Fixed the missing env provenance API by adding
  `Developer::Dashboard::EnvAudit`, which records the winning file for each
  dashboard-managed env key so commands, hooks, and tests can inspect where
  a value came from.

## 2026-04-19 (Phase 119: Restart Stability Window)

- Fixed the runtime restart acknowledgement gap where `dashboard restart` or
  background `dashboard serve` could report success after the first startup
  acknowledgement even though the replacement web pid or collector loop died a
  moment later.
- Fixed collector startup drift by requiring each restarted managed loop to
  stay visible through a short startup stability window before the lifecycle
  command reports success, and by stopping any already-started collectors when
  one replacement loop fails that stability check.
- Fixed replacement web-runtime drift by requiring the managed web pid and the
  requested listener to stay alive through the same short stability window,
  instead of trusting the first ready poll alone.

## 2026-04-19 (Phase 118: Layered Config Delta Writes And Thin Perl Handoff)

- Fixed the layered config write bug where a child `./.developer-dashboard`
  could save one local alias and accidentally copy inherited parent
  `config.json` domains such as `collectors` and `web` into the child layer.
- Fixed the DD-OOP-LAYERS mutator gap by making writable config updates read
  only the deepest writable layer file before saving, so the child layer keeps
  just its local delta while inherited config still comes from parent reads.
- Fixed thin-helper checkout drift by forcing Perl-backed staged helpers and
  hooks through the active dashboard `lib/` root, so `dashboard ...` no longer
  falls onto an older installed `Developer::Dashboard` copy that happens to be
  earlier in `PERL5LIB`.

## 2026-04-18 (Phase 117: Restart Dead-On-Arrival PID Ack)

- Fixed the restart lifecycle bug where `dashboard restart` could report a new
  web pid even though the replacement runtime died before the listener was
  really usable.
- Fixed the weak readiness contract by requiring restart to verify both a
  live managed web pid and an accepting TCP listener on the requested port,
  instead of trusting the first startup acknowledgement alone.
- Fixed listener-discovery race sensitivity by falling back to a direct local
  TCP probe when the port is already accepting connections but process-table
  listener ownership has not populated yet.

## 2026-04-18 (Phase 116: Layered Collector Placeholder Shadowing)

- Fixed the layered collector indicator shadowing bug where a child
  `.developer-dashboard/` folder with no collector override could keep an old
  placeholder `missing` indicator state pinned red over a healthy inherited
  parent-layer collector result.
- Fixed the DD-OOP-LAYERS state-resolution gap by teaching collector sync to
  distinguish the deepest local indicator file from the nearest inherited
  indicator file, instead of always preserving the deepest placeholder state.
- Fixed the missing guardrail for this case by adding a regression that
  creates parent and child runtime layers with child `config.json` presence
  and proves the inherited parent `ok` state is restored during collector
  sync.

## 2026-04-18 (Phase 115: Go Java Main-Doc Drift)

- Fixed the top-level documentation drift around executable `.go` and `.java`
  custom commands by adding explicit `dashboard hi` and `dashboard foo`
  examples to both `README.md` and the main POD.
- Fixed the hidden-docs risk where Go/Java command dispatch existed only in a
  deep runtime paragraph by making the main user manual state directly that
  executable `.go` commands run through `go run` and executable `.java`
  commands run through `javac` and `java`.
- Fixed the missing guardrail for this contract by extending the
  release-metadata gate so future doc drift around Go/Java source-command
  support fails automatically.

## 2026-04-18 (Phase 114: Collector Timestamp Timezone Split)

- Fixed the collector scheduler-versus-log timezone split by making collector
  status and transcript timestamps use the machine's local system time with
  an explicit numeric offset, so cron-based collectors no longer look an hour
  behind the wall clock during daylight-saving periods.
- Fixed collector state inconsistency by trimming persisted `last_run` values
  before returning them through the public collector output API, instead of
  leaking raw newline-terminated file payloads into structured output.
- Fixed housekeeper compatibility risk by teaching collector log retention to
  parse both the new local-offset timestamps and older UTC `Z`
  transcript entries, so existing logs still rotate correctly after the
  timestamp contract change.

## 2026-04-18 (Phase 113: Release Build Directory Hygiene Drift)

- Fixed release artifact hygiene drift by making the tarball kwalitee gate
  fail when stale unpacked `Developer-Dashboard-X.XX/` build directories
  remain in the repository root beside the current tarball.
- Fixed the gap between documented release cleanup and enforced release
  behavior, so the repo no longer depends on humans remembering to remove old
  `dzil` build directories by hand.
- Fixed release consistency drift by requiring one matching unpacked build
  directory and one matching tarball version for the kwalitee gate before the
  work can be called release-clean.

## 2026-04-18 (Phase 112: Browser Top-Right Chrome Suppression Gap)

- Fixed the missing browser-only chrome suppression mode by adding
  `dashboard serve --no-indicators` and the compatibility alias
  `dashboard serve --no-indicator`, so users can clear the whole top-right
  browser area without affecting terminal prompt indicators.
- Fixed browser-versus-terminal coupling risk by hiding only the web
  interface top-right status strip, username, host/IP link, and live
  date-time line while leaving `/system/status` and `dashboard ps1`
  unchanged.
- Fixed restart persistence drift for this browser chrome mode by saving the
  flag in `web.no_indicators`, so `dashboard restart` keeps the same web-only
  chrome state until a later `dashboard serve --indicators` run turns it back
  off again.

## 2026-04-18 (Phase 111: Read-Only Serve Editor Exposure)

- Fixed browser read-only mode drift by adding
  `dashboard serve --no-editor` and the compatibility alias
  `dashboard serve --no-endit`, so users can serve saved pages without
  exposing the bookmark editor or raw bookmark source through the browser.
- Fixed cosmetic-only locking risk by denying `/app/<id>/edit`,
  `/app/<id>/source`, and bookmark-save POST routes with explicit `403`
  responses when `web.no_editor` is enabled, instead of merely hiding the
  visible editor links.
- Fixed restart persistence drift by saving the read-only browser flag in
  `web.no_editor`, so `dashboard restart` keeps the same served access mode
  until a later `dashboard serve --editor` run turns it off again.

## 2026-04-18 (Phase 110: Docker Service State Visibility Gap)

- Fixed the blind spot around isolated compose markers by adding
  `dashboard docker list`, `dashboard docker list --enabled`, and
  `dashboard docker list --disabled` so users can inspect effective service
  state without scanning layered docker folders by hand.
- Fixed CLI-versus-resolver drift by exposing the service-state inventory
  through `Developer::Dashboard::DockerCompose->list_services`, which keeps
  service listing on the same DD-OOP-LAYERS lookup and marker rules as
  compose resolution itself.

## 2026-04-18 (Phase 109: Docker Service Disable Marker Manual Toggle Gap)

- Fixed the manual-only isolated compose toggle flow by adding
  `dashboard docker disable <service>` and
  `dashboard docker enable <service>` so users no longer need to create or
  delete `disabled.yml` files by hand.
- Fixed local override friction for inherited docker services by writing the
  toggle marker into the deepest runtime docker root, which lets a child
  project layer disable a home service locally without mutating the home
  service folder itself.

## 2026-04-18 (Phase 108: Folder Rehydration Convenience Gaps)

- Fixed the missing convenience constructor for code that already has the
  public Folder path inventory by adding
  `Developer::Dashboard::PathRegistry->new_from_all_folders`.
- Fixed caller friction around the new path inventory API so code can rebuild
  a fresh `PathRegistry` object from `Developer::Dashboard::Folder->all`
  without manually splatting that hash in multiple places.
- Fixed the same repeated constructor plumbing for collectors by adding
  `Developer::Dashboard::Collector->new_from_all_folders`, which builds a
  collector store from the Folder-derived runtime roots through the new
  path-registry convenience constructor.

## 2026-04-18 (Phase 107: Public Path Inventory API Drift)

- Fixed the missing public Perl API for the full `dashboard paths` payload by
  adding `Developer::Dashboard::PathRegistry->all_paths`,
  `Developer::Dashboard::PathRegistry->all_path_aliases`, and
  `Developer::Dashboard::Folder->all`.
- Fixed CLI-versus-library drift by making the lightweight paths helper reuse
  those public methods instead of maintaining a separate private payload
  builder.

## 2026-04-17 (Phase 106: Multi-Level Nested Skill Dispatch Path Drift)

- Fixed dotted skill dispatch for repeated nested skill levels so commands
  such as `dashboard nest.level1.level2.here` now resolve
  `skills/level1/skills/level2/cli/here` inside the installed `nest` skill.
- Fixed the nested provider path builder so each dotted nested skill segment
  maps to its own repeated `skills/<repo>` directory pair instead of being
  flattened into one incorrect path.

## 2026-04-17 (Phase 105: Nested Skill Dotted Dispatch)

- Fixed dotted skill dispatch so commands inside nested
  `skills/<repo>/cli/` trees are reachable through the same public dotted
  route, for example `dashboard ho.foo.foo` now resolves
  `skills/foo/cli/foo` inside the installed `ho` skill.
- Fixed nested skill command runtime setup by reusing the resolved nested
  skill root for command lookup, hook lookup, and isolated env variables
  instead of treating every dotted command tail as a flat `cli/<command>`
  file name.

## 2026-04-17 (Phase 104: Release POD And Kwalitee Metadata Drift)

- Fixed release POD parsing errors by removing the remaining non-ASCII inline
  POD text from shipped Perl files that caused `Test::Pod` and CPANTS to
  report malformed documentation in the built tarball.
- Fixed release security-policy metadata by shipping `SECURITY.pod` with the
  private contact address and disclosure process inside the distribution
  instead of relying on repository-only Markdown files that are excluded from
  the tarball.
- Fixed release contribution metadata by shipping `CONTRIBUTING.pod` and
  adding an explicit `Test::Pod` gate plus metadata checks so future builds
  fail before PAUSE if the release artifact drops those kwalitee signals.

## 2026-04-17 (Phase 103: Housekeeper Rotation And Built-In Merge Drift)

- Fixed collector transcript growth so the built-in `housekeeper` pass now
  rotates collector log files when a collector declares `rotation` or
  `rotations`, supporting trailing-line retention plus
  minute/hour/day/week/month time windows.
- Fixed built-in `housekeeper` override drift so a config entry named
  `housekeeper` now merges with the built-in job instead of replacing it,
  which means changing only `interval` or nested `indicator` metadata keeps
  the inherited Perl `code` and `cwd`.
- Fixed silent retention misconfiguration by making invalid collector rotation
  keys or non-integer retention values fail explicitly during the housekeeper
  pass instead of being ignored.

## 2026-04-16 (Phase 102: Temp Housekeeper Collector)

- Fixed temp-state buildup by adding a built-in `housekeeper` collector and a
  matching `dashboard housekeeper` command that clean stale dashboard-owned
  temp roots, oversized Ajax payload files, and stale `dashboard-result-*`
  runtime result temp files.
- Fixed stale temp-state identification by recording runtime metadata inside
  each hashed `/tmp/<user>/developer-dashboard/state/<hash>/` root, so cleanup
  can preserve the active DD-OOP-LAYERS state roots and remove dead ones.
- Fixed built-in collector portability by implementing the default
  `housekeeper` collector as in-process Perl `code`, so it does not depend on
  shell `PATH` resolution when the runtime is exercised from a source checkout
  or a staged helper environment.

## 2026-04-16 (Phase 101: Go And Java Hook Launchers)

- Fixed hook-runner language handling so executable `.go` files inside
  `<command>.d/` hook folders now run through `go run` instead of being treated
  like opaque binaries.
- Fixed Java hook execution so executable `.java` files inside `<command>.d/`
  hook folders now compile through `javac` into an isolated temp directory and
  then run through `java` using the declared main class from the source file.
- Fixed direct CLI source-command lookup so `dashboard <command>` now resolves
  executable `cli/<command>.go` and `cli/<command>.java` files instead of
  falling through to the usage screen.
- Fixed hook coverage drift by adding platform-level launcher coverage plus CLI
  smoke coverage for Go and Java hook files, with live hook execution checks
  when the corresponding host toolchains are installed.

## 2026-04-14 (Phase 100: Collector TT Icon Data Drift)

- Fixed collector-managed indicator rendering so TT-style `indicator.icon`
  values such as `[% a %]` now decode collector `stdout` JSON into Perl data
  and render a live icon instead of persisting the raw template text.
- Fixed collector/config-sync drift by storing the configured TT icon source as
  separate metadata and preserving the already-rendered live icon during later
  `sync_collectors()` passes, so `dashboard indicator list` and
  `dashboard ps1` do not revert to raw `[% ... %]`.
- Fixed silent TT collector icon failures by turning invalid collector JSON or
  Template Toolkit render problems into explicit collector errors with visible
  stderr and red indicator state.

## 2026-04-14 (Phase 99: Collector Log Surface Drift)

- Fixed `dashboard collector log` so it no longer reads only the mostly-empty
  shared collector loop log and collapse to blank output after successful
  collector runs.
- Added named collector log inspection through
  `dashboard collector log <name>`, with explicit unknown-collector failures
  and explicit no-log-yet output for configured collectors that have not run.
- Persisted per-collector log transcripts in collector state and added TDD
  coverage for named, aggregate, older-state snapshot, and error-path log
  reads.

## 2026-04-13 (Phase 98: Tarball Kwalitee Drift Guard)

- Added an explicit tarball-level kwalitee gate so release verification now
  checks the built `Developer-Dashboard-X.XX.tar.gz` with
  `Module::CPANTS::Analyse` and requires every indicator to pass.
- Fixed the release workflow so tagged PAUSE automation installs the CPANTS
  analyzer and reruns that focused tarball kwalitee gate immediately after
  `dzil build`.
- Documented that source-tree kwalitee probes are not the authoritative check
  for this repository and that CPANTS drift must be verified against the built
  tarball instead.

## 2026-04-12 (Phase 97: Same-Repo Skill Layer Fallback Drift)

- Fixed same-repo `DD-OOP-LAYERS` skill fallback so a deeper
  `skills/<repo-name>/` checkout no longer shadows the whole inherited skill
  repo when it only overrides part of it.
- Fixed layered skill runtime lookup so missing child-layer `cli/<command>`
  files, missing bookmark files, missing `dashboards/nav/` folders, and
  missing skill config keys now fall back to the base skill layer while
  keeping deepest overrides for matching files and keys.
- Expanded the focused skill regressions plus synced manuals so dotted skill
  command dispatch, skill bookmark routes, nav discovery, and merged skill
  config keep that same-repo layered fallback contract explicit.

## 2026-04-11 (Phase 96: Blank-Env Cpanm Generic Tarball Drift)

- Fixed the blank-environment install path so the integration harness now
  stages the mounted tarball to a versioned local `/tmp/Developer-Dashboard-X.XX.tar.gz`
  path before invoking `cpanm`.
- Fixed the release-gate drift where `cpanm` could treat the generic mounted
  `/artifacts/Developer-Dashboard.tar.gz` filename like a lookup target and
  install an older CPAN release instead of the just-built host artifact.
- Added TDD coverage in `t/13-integration-assets.t` and updated the blank-env
  runner POD and integration plan so the versioned staging rule remains
  explicit.

## 2026-04-11 (Phase 95: Singular Skill Command Surface Drift)

- Removed the singular `dashboard skill <repo-name> <command>` public command
  so installed skill execution now uses the dotted
  `dashboard <repo-name>.<command>` route consistently.
- Rerouted dotted skill execution through the remaining staged `skills`
  helper and dropped the retired private `share/private-cli/skill` asset from
  the release surface.
- Taught helper staging to remove the old dashboard-managed
  `~/.developer-dashboard/cli/dd/skill` helper on refresh and updated the
  synced manuals, shipped skill guide, and release metadata to keep the
  dotted-only command contract explicit.

## 2026-04-11 (Phase 94: Scorecard License Recognition Drift)

- Fixed the live Scorecard `License` check drift by replacing the root
  `LICENSE` file with a canonical GPL text that GitHub can
  classify instead of an undecidable dual-license blob.
- Added `LICENSE-Artistic-1.0-Perl` so the alternative Perl 5 Artistic option
  remains explicit in the repository while the root license file stays
  machine-recognizable.
- Expanded `t/34-scorecard-guardrails.t` so TDD now locks the new license
  layout in place before the post-push Scorecard gate runs again.

## 2026-04-11 (Phase 92: Release README Kwalitee Drift)

- Fixed the built-distribution kwalitee failure where the host-built tarball
  no longer shipped any top-level readme after the Markdown exclusion rule
  removed checkout-only docs from release artifacts.
- Added a plain release `README` companion for the tarball so CPAN and
  kwalitee consumers still receive a shipped readme without re-including the
  checkout-only documentation set.
- Updated the synced top-level manuals, testing guide, and release-metadata
  guard so future release builds keep that readme requirement explicit.

## 2026-04-11 (Phase 91: Skill Docker Coverage Drift)

- Fixed the last uncovered `Developer::Dashboard::PathRegistry` helper by
  adding direct regression coverage for
  `installed_skill_docker_roots()`.
- Fixed the release-gate drift where the full `Devel::Cover` run dropped to
  `99.9 / 99.9 / 99.9` because the enabled-only and
  `include_disabled => 1` skill docker-root paths were no longer exercised
  explicitly.
- Updated the synced testing docs and release metadata so the hard
  `100.0 / 100.0 / 100.0` `lib/` coverage requirement still names the focused
  skill regression that closes this path.

## 2026-04-11 (Phase 90: Layered Skill Lookup Drift)

- Fixed the skills runtime so `DD-OOP-LAYERS` now applies to skill roots as
  well as pages, hooks, config, and state. Installing a skill now writes into
  the deepest participating layer instead of always forcing the checkout into
  the home runtime.
- Fixed layered skill lookup drift by making same-named deeper skills shadow
  higher-layer copies by repo name while still allowing home-only skills to be
  inherited when no deeper override exists.
- Fixed the public dotted command shortcut so `dashboard repo.cmd` now uses
  the same layered skill resolution path as the library runtime instead of a
  hardcoded `~/.developer-dashboard/skills` probe.
- Fixed layered docker skill discovery so skill `config/docker/` roots now
  participate from their owning runtime layer rather than only from the home
  skill tree.
- Updated the synced manuals and release-metadata guard so the supported skill
  contract now documents layered installs, deepest-first lookup, and repo-name
  shadowing.

## 2026-04-11 (Phase 89: Skill Activation And Inventory Drift)

- Fixed the missing installed-skill activation controls by adding
  `dashboard skills enable <repo-name>` and
  `dashboard skills disable <repo-name>`. Skills can now be parked locally
  without uninstalling their isolated checkout and later restored with an
  explicit enable step.
- Fixed skills inventory drift by expanding `dashboard skills list` to report
  enabled state, CLI/page/docker/collector/indicator counts, and JSON booleans
  for config and dependency files, with an optional terminal table view for
  quick inspection.
- Fixed the missing per-skill inspection command by adding
  `dashboard skills usage <repo-name>`, which returns detailed command hook,
  page/nav, docker, config, and collector metadata even when the target skill
  is disabled.
- Fixed disabled-skill runtime leakage so disabled skills no longer
  participate in dotted command dispatch, dedicated `/app/<repo>` routes,
  shared nav rendering, collector fleet loading, config merge, or docker root
  discovery until they are explicitly re-enabled.
- Updated the synced top-level manuals, integration plan, and release-metadata
  guard so the supported skill activation and inventory lifecycle is described
  and regression-checked instead of drifting behind the code.

## 2026-04-10 (Phase 88: Release Tarball Repo-Only Asset Drift)

- Fixed release tarball content drift so the repo-only `integration/`
  verification helpers no longer ship inside the CPAN/PAUSE distribution.
  Those helpers remain source-tree verification assets and the release gate
  now treats them as such.
- Fixed the packaged update contract so the checkout-only top-level
  `updates/` folder no longer ships in the release tarball. The installed
  `dashboard update` path remains the documented user-provided layered
  runtime command under `.developer-dashboard/cli/update` and
  `.developer-dashboard/cli/update.d`.
- Fixed the built-distribution regression tests so they no longer assume
  source-only `integration/` and `updates/` folders must exist in the
  packaged tree, while still checking those assets in the source checkout.

## 2026-04-10 (Phase 87: Skill Fleet And Global Nav Drift)

- Fixed installed skill runtime integration so collectors declared inside a
  skill `config/config.json` now join the same managed fleet as the system
  config, which means `dashboard serve`, `dashboard restart`, and
  `dashboard stop` load and manage skill collectors together with the
  dashboard-owned collectors.
- Fixed skill collector naming so installed skill collectors are normalized to
  repo-qualified names such as `example-skill.status`, keeping collector loop
  names, process titles, and indicator state unambiguous across multiple
  installed skills and the main runtime.
- Fixed nav rendering so `dashboards/nav/*` from every installed skill now
  appears not only on `/app/<repo-name>` routes but also in the shared nav
  strip rendered above normal saved `/app/<page>` routes such as `/app/index`,
  and documented that runtime contract in the README, main POD, shipped skill
  reference, and integration test plan.
- Fixed the top-level `Developer::Dashboard.pm` manual audit gap by replacing
  the brittle `SEE ALSO` private-module links with stable self-links into the
  main manual, correcting the browser-service FAQ framing, and extending the
  release-metadata gate plus contributor testing guide so those regressions are
  checked explicitly in future releases.
- Completed the same `Developer::Dashboard.pm` audit across the rest of the
  main manual by removing `L<Developer::Dashboard::...>` private-module POD
  links from the product guide, then tightened the release-metadata gate so
  the top-level manual must stay self-contained instead of depending on brittle
  internal cross-links.
- Fixed the missed `AGENTS.override.md` documentation boundary so shipped Perl
  POD and the synced top-level product manuals no longer point readers at
  repo-internal `.md` filenames such as the skill or SQL support guides.
  Those guides are now referenced conceptually, and the release-metadata gate
  rejects future `.md` filename references in shipped Perl POD and the synced
  top-level manuals.
- Fixed release tarball gather drift so local `node_modules/` dependency trees
  and the private `test_by_michael/` scratch area no longer ship inside the
  built distribution. The release-metadata gate now requires explicit exclude
  rules for both paths so this cannot silently reappear at release time.

## 2026-04-10 (Phase 86: Skill Packaged Tree FindBin Drift)

- Fixed installed and built-dist loading for the skill runtime release by
  removing source-tree `FindBin` assumptions from shipped library modules.
  The packaged tree now loads those modules from the installed Perl library
  path instead of depending on the checkout path that happened to build the
  tarball.
- Added a regression guard so shipped library modules that are meant to load
  from the installed distribution cannot quietly reintroduce `FindBin`-based
  source-tree `use lib` behavior.
- Rebuilt the skill-runtime release as a new version after that packaging fix
  and reran the packaged-tree plus blank-environment verification flow.

## 2026-04-10 (Phase 85: Skill Runtime Layer And Routing Drift)

- Fixed the skills install/runtime contract so a Git-backed skill repo now stays self-contained under `~/.developer-dashboard/skills/<repo-name>/` instead of pretending its `cli/`, `dashboards/`, `config/`, `aptfile`, `cpanfile`, and Docker files are merged into the normal dashboard runtime folders.
- Fixed skill command dispatch so installed commands can now be reached through both `dashboard skill <repo-name> <command>` and the short `dashboard <repo-name>.<command>` form, with the dispatcher still running sorted `cli/<command>.d/` hooks inside the isolated skill runtime.
- Fixed skill browser and config integration so `/app/<repo-name>` resolves `dashboards/index`, `/app/<repo-name>/<id>` resolves named skill pages, `dashboards/nav/*` loads into those routes, installed skill config merges under underscored keys such as `_example-skill`, and skill `config/docker/...` plus `aptfile` / `cpanfile` lifecycle behavior are now documented and regression-tested.

## 2026-04-10 (Phase 84: Query Eval And Xml Decode Drift)

- Fixed the shared `*q` command family so split query arguments are rejoined and `$d` now works as a real Perl-expression entrypoint instead of only as a whole-document selector. That means commands such as `dashboard jq file.json sort keys %$d` and the same pattern through STDIN now evaluate against the decoded document instead of degrading into the wrong path lookup.
- Fixed `xmlq` so it now decodes XML into traversable hashes and arrays with `_attributes` and `_text` fields instead of only returning a raw XML wrapper, bringing XML in line with the rest of the query helpers.
- Fixed dependency metadata drift by declaring the non-core query runtime prerequisites consistently in `Makefile.PL`, `cpanfile`, and `dist.ini`, then adding release-metadata coverage so future runtime-module additions fail fast if one metadata file is forgotten.

## 2026-04-10 (Phase 83: Hook Stop And Last Result Drift)

- Fixed custom CLI hook lifecycle control so a hook now stops the remaining `<command>.d` chain only when its `stderr` contains the explicit `[[STOP]]` marker, while plain non-zero exits are still recorded but no longer act like an implicit stop request.
- Fixed hook-state chaining so later hooks and the final command now receive both the full `RESULT` payload and the immediate previous-hook payload through `LAST_RESULT`, with `Developer::Dashboard::Runtime::Result->last_result()` returning `{ file, exit, STDOUT, STDERR }`.
- Expanded unit, shell smoke, and product-doc coverage so the hook stop marker plus previous-hook handoff are documented and regression-tested instead of living as an implicit behavior guess.

## 2026-04-10 (Phase 82: Top-Level Manual Drift)

- Fixed `README.md` and `Developer::Dashboard.pm` so the top-level manual no longer embeds contributor-only `FULL-POD-DOC` and Scorecard process rules that distract from the actual product behavior.
- Fixed the top-level FAQ so it now describes the real browser stack as Dancer2 on PSGI through Plack/Starman instead of incorrectly claiming the project does not require a web framework.
- Fixed the top-level dependency FAQ so it now describes active `LWP::UserAgent` usage in the saved `api-dashboard` request runner and Java source lookup path instead of claiming outbound HTTP is unused.
- Moved the contributor-contract clarification back into contributor-facing docs such as `doc/testing.md` and `agents.md`, keeping `README.md` and `Developer::Dashboard.pm` synced as product documentation.

## 2026-04-10 (Phase 81: Full Pod Boilerplate Drift)

- Fixed shipped FULL-POD-DOC quality drift by replacing the repeated copy-paste POD template across modules, entrypoints, and staged helpers with file-specific documentation that now describes each file's real responsibility, handoff, and usage examples.
- Expanded `t/15-release-metadata.t` so release verification now fails if the old generic FULL-POD-DOC boilerplate reappears in shipped Perl assets.
- Tightened the contributor contract so shipped Perl docs now have to show the common path plus a meaningful edge or debugging path in their examples, which prevents another drift back to shallow one-sample POD.
- Added a synced 10-common / 10-edge example bank to `README.md` and `Developer::Dashboard.pm` so contributors have a concrete reference for what "detailed examples" means in this repo.

## 2026-04-09 (Phase 80: Mac Shell Path Alias Drift)

- Fixed `t/05-cli-smoke.t` so the shell-helper `cdr` and `which_dir` assertions now compare canonical path identity instead of raw strings, which keeps macOS source-tree runs green when the same temp tree appears as `/var/...` in the shell and `/private/var/...` from `pwd`.

## 2026-04-09 (Phase 79: Workflow Coverage Gate Spacing Drift)

- Fixed the GitHub workflow coverage gate so `test.yml`, `release-cpan.yml`, and `release-github.yml` no longer fail after a real `100.0 / 100.0 / 100.0` `Devel::Cover` run just because the runner printed a different amount of spacing on the `Total` line.
- Expanded `t/34-scorecard-guardrails.t` so workflow coverage checks now fail under TDD if they drift back to a brittle fixed-spacing `grep -F` match instead of a regex match on the semantic `Total` summary line.

## 2026-04-09 (Phase 78: Release CPAN And Mac Shell Portability Drift)

- Fixed the GitHub `Release To CPAN` workflow so the hosted Ubuntu release runner no longer fails on one stale PowerShell expectation, untracked integration assets, inherited broken OpenSSL config, or Chromium sandbox defaults during the packaged-tree smoke path.
- Fixed `dashboard shell` POSIX helper generation so `cdr` and `which_dir` decode JSON through the same Perl interpreter that generated the shell fragment instead of a bare `perl -MJSON::XS ...` call, which removes the macOS `JSON::XS` ABI mismatch against `/usr/bin/perl`.
- Fixed macOS path-portability assertions so `/var/...` and `/private/var/...` aliases are treated as the same real temp tree across `locate_dirs_under`, `CLI::Paths cdr`, and the shell-helper smoke coverage.

## 2026-04-09 (Phase 77: Open File Regex And Java Source Drift)

- Fixed `dashboard of` / `dashboard open-file` so scoped search tokens are now real case-insensitive regexes instead of quoted substring matches, which means patterns such as `Ok\.js$` match `ok.js` without drifting into `ok.json`.
- Fixed Java class lookup so it can now resolve source from local `-sources.jar`, `-src.jar`, `src.zip`, `jar`, and `war` archives, and can mirror a matching Maven source jar into the dashboard cache when no live `.java` file exists locally.
- Fixed `cdr` and `which_dir` narrowing so later arguments are treated as regexes instead of quoted substring tokens beneath either the alias root or the current directory, with explicit invalid-regex failures instead of silent empty results.

## 2026-04-09 (Phase 76: CDR Keyword Root Drift)

- Fixed `cdr` so a saved first argument now stays the alias root for follow-up keyword narrowing instead of being discarded and replaced by the old top-level workspace/project search.
- Fixed the non-alias `cdr` path so all arguments are now treated as AND-matched directory keywords beneath the current directory, with one match changing directory and multiple matches printed instead of choosing one silently.
- Kept the shell bootstrap thin by moving the target-selection logic into `dashboard path cdr`, and expanded unit plus shell smoke coverage for alias-only, alias-plus-keyword, and pure-keyword search flows.

## 2026-04-09 (Phase 75: Hook Result Exec Overflow And Historical Seed Refresh Drift)

- Fixed `dashboard` command dispatch so oversized accumulated hook `RESULT` payloads no longer blow up `exec()` with `Argument list too long`; the runtime now keeps small payloads inline in `RESULT` and spills larger payloads into a file-backed `RESULT_FILE` channel that `Developer::Dashboard::Runtime::Result` reads transparently.
- Expanded CLI smoke and unit coverage so later hooks plus the final command still see the same logical hook stdout/stderr data through `Runtime::Result` after the overflow fallback engages.
- Fixed `dashboard init` upgrade bridging so older dashboard-managed `sql-dashboard` saved copies from pre-manifest runtimes are recognized as refreshable managed seeds instead of being mistaken for user edits and left on stale browser UI.

## 2026-04-09 (Phase 74: JS Fuzz Perl Prereq Drift)

- Fixed `.github/workflows/fuzz-js.yml` so the JS property/fuzz job now boots the Perl toolchain before it invokes `dashboard encode` and `dashboard decode`.
- Fixed the GitHub-hosted failure where the very first fuzz counterexample died on `Can't locate Capture/Tiny.pm` instead of exercising the property, because the workflow only installed Node dependencies and never ran `cpanm --installdeps --notest .`.
- Expanded `t/34-scorecard-guardrails.t` so the fuzz workflow now hard-fails under TDD if it ever drops the Perl setup step or the repo Perl dependency install step again.

## 2026-04-09 (Phase 73: GitHub Release Workflow Drift)

- Fixed the GitHub workflow gap that left `Signed-Releases` with nothing to inspect by adding `.github/workflows/release-github.yml`, which rebuilds the distribution, reruns tests and coverage, and publishes a GitHub release asset set with the tarball, checksum, and detached signature.
- Fixed `.github/workflows/release-cpan.yml` so tagged releases no longer fail while locating the built tarball; it now picks up `Developer-Dashboard-*.tar.gz` from the repo root instead of a nonexistent `.build/` directory.
- Fixed the workflow hang risk by adding explicit `concurrency` groups and `timeout-minutes` guards to the shipped GitHub workflows, and locked those requirements into `t/34-scorecard-guardrails.t`.

## 2026-04-09 (Phase 72: Covered Loop Guard Drift)

- Fixed `t/07-core-units.t` so covered runs detect both `HARNESS_PERL_SWITCHES=-MDevel::Cover` and `PERL5OPT=-MDevel::Cover` before entering the collector-loop fork branch.
- Stopped `Devel::Cover` runs from dropping into the live loop path that dies with `stop loop` after the assertions have already passed, which previously broke TAP completion and blocked the 100% coverage gate.

## 2026-04-08 (Phase 71: Seeded SQL Dashboard Refresh Drift)

- Fixed `dashboard init` and runtime bootstrap so a stale dashboard-managed saved `sql-dashboard` copy now refreshes to the current shipped seed instead of leaving an older browser UI in place after upgrade.
- Added a recorded seeded-page md5 manifest plus a historical bridge digest for the older shipped `sql-dashboard` copy, so upgrades can refresh known dashboard-managed starter pages while still preserving diverged user-edited saved pages.
- Expanded CLI, update-manager, unit, and Playwright browser coverage so stale managed starter pages are refreshed before the browser serves them.

## 2026-04-08 (Phase 70: SQL Workspace Focus And Schema Explorer Drift)

- Fixed the SQL Dashboard workspace split by moving the left-side collection rail behind inner `Collection` and `Run SQL` tabs under the main `SQL Workspace` tab, so the runner/result pane stays the default focus instead of losing width to the collection manager all the time.
- Fixed the schema column-type display by deriving human type labels and positive length labels from DBI metadata, preventing raw numeric type codes and negative lengths from leaking into the browser for drivers such as MSSQL/ODBC and Oracle-style metadata.
- Fixed the schema-table usability gap by adding a live filter box, explicit table-name copy actions, and a `View Data` action that jumps back to `Run SQL` with a ready `select * from <table>` query.
- Expanded the fake-driver, real SQLite, and Docker-backed RDBMS Playwright coverage so the new workspace tabs plus schema filter/copy/view-data flow stay browser-verified.

## 2026-04-08 (Phase 69: SQL Dashboard Override Shadow Drift)

- Fixed the SQL Dashboard schema regression guard by making `t/26-sql-dashboard.t` fail if the schema browser ever calls `execute()` on `table_info()` or `column_info()` metadata handles again, matching the `SQL-HY010` ODBC failure mode seen on the stale `hov1` runtime.
- Documented that a saved `~/.developer-dashboard/dashboards/sql-dashboard` page overrides the shipped seeded page, so upgraded machines can keep old SQL Dashboard bugs until that saved override is updated or removed.
- Documented `dashboard page source sql-dashboard` as the first diagnostic step when SQL Dashboard browser behaviour looks older than the current repo copy.

## 2026-04-08 (Phase 68: Scorecard Gatekeeper Drift)

- Fixed repository policy drift by making `SCORECARD-GATEKEEPER` explicit in the public docs, release guide, and contributor override rules instead of treating Scorecard as a best-effort check.
- Fixed the repo-side Scorecard gaps by adding a tracked root `LICENSE`, tracking the published `SECURITY.md`, adding `.github/dependabot.yml`, and adding pinned least-privilege workflows for CodeQL, GHCR packaging, and `fast-check` fuzzing.
- Fixed the weak workflow bootstrap path by removing the `curl https://cpanmin.us | perl` install pattern from the GitHub Actions workflows and relying on the Perl setup action plus `cpanm` directly.
- Added `t/34-scorecard-guardrails.t`, `t/35-js-fast-check.t`, `t/fuzz/scorecard-fast-check.mjs`, and `SCORECARD_ACTIONS.md` so Scorecard policy drift is now backed by executable tests and a living remediation checklist.
- Fixed remaining repo-detected supply-chain drift by banning top-level workflow `write` permissions, moving the required writes to job scope, pinning the blank-env Docker base image by digest, and adding `.clusterfuzzlite/Dockerfile` so Scorecard sees a supported fuzzing integration in this mostly-Perl repository.

## 2026-04-08 (Phase 66: Runtime Manager Ambient Process Drift)

- Fixed packaged `t/09-runtime-manager.t` isolation so ambient live dashboard-shaped processes on the host no longer hijack the `running_web` fallback assertion when the test is proving the recorded pid path without managed-process discovery.
- Added an explicit `_find_web_processes` stub to that regression, keeping source-tree, tarball, and PAUSE install runs stable even on hosts that already have unrelated dashboard runtimes active.
- Fixed `t/22-api-dashboard-playwright.t` reload drift by waiting for the persisted collection JSON to contain the saved request before the later export/import/reload path, and by scoping request clicks to the active visible collection panel so browser coverage no longer races against collection-tree rerenders under full-suite load.

## 2026-04-08 (Phase 65: SSL Alias SAN And Trust Drift)

- Fixed `dashboard serve --ssl` certificate generation so the generated local cert now covers the concrete non-wildcard bind host plus any configured `web.ssl_subject_alt_names`, instead of being limited to `localhost`, `127.0.0.1`, and `::1`.
- Fixed stale HTTPS cert reuse again so the dashboard now regenerates its self-signed cert when the expected SAN list changes, such as when a user adds one `/etc/hosts` alias or one direct IPv4/IPv6 access target.
- Fixed loopback alias-host browser access so requests that still arrive from loopback can use `localhost` or configured local aliases as local-admin routes instead of falling into helper-only `401` handling.
- Added focused SAN-alias coverage in `t/17-web-server-ssl.t`, loopback-alias trust coverage in `t/07-core-units.t`, and a real Chromium alias-host regression in `t/33-web-server-ssl-browser.t`.

## 2026-04-08 (Phase 64: SSL Cert Profile Drift)

- Fixed `dashboard serve --ssl` certificate generation so the generated local cert now advertises SAN coverage for `localhost`, `127.0.0.1`, and `::1`, plus the expected server leaf key-usage and extended-key-usage profile, instead of the earlier CA-style cert that modern browsers handled poorly.
- Fixed HTTPS startup for existing users by regenerating older dashboard certs automatically when they do not match the current browser-safe localhost/loopback profile, rather than reusing those broken certs forever.
- Added focused certificate-profile coverage in `t/17-web-server-ssl.t` and a real Chromium browser regression in `t/33-web-server-ssl-browser.t` so `dashboard serve --ssl` is no longer validated only by raw TLS sockets.

## 2026-04-08 (Phase 63: Enterprise SQL Driver Proof Gap)

- Fixed SQL dashboard live-driver coverage so the browser workflow is now proven against MSSQL through `DBD::ODBC` and Oracle through `DBD::Oracle`, in addition to the existing SQLite, MySQL, and PostgreSQL paths.
- Fixed SQL dashboard schema browsing for `DBD::ODBC` by removing the extra `execute()` call on `table_info()` and `column_info()` statement handles, which was tripping MSSQL with `SQL-HY010` during the browser schema flow.
- Fixed blank SQL profile UX so the driver selector now shows concrete DSN guidance and seeds usable DSN templates for SQLite, MySQL, PostgreSQL, MSSQL/ODBC, and Oracle instead of leaving users at a bare `dbi:Driver:` prefix.
- Added `SQL_DASHBOARD_SUPPORTS_DB.md` as the living checklist and support report for SQL dashboard database coverage, driver requirements, and browser-verification status.
- Fixed packaged-tree integration metadata checks so tarball installs in blank environments no longer fail on markdown docs that are intentionally excluded from the dist, while the source-tree tests still enforce those docs.

## 2026-04-08 (Phase 62: Home DD CLI Namespace Drift)

- Fixed `dashboard init` and `dashboard config init` so a missing `config/config.json` is created as `{}` and an existing config file is left untouched instead of being repopulated with a seeded example collector.
- Fixed dashboard-managed helper staging so built-in commands now live under `~/.developer-dashboard/cli/dd/`, while the user command space remains `~/.developer-dashboard/cli/` and child layers do not receive built-in `dd/` seeds.
- Added deep SQLite plus live Docker-backed MySQL/PostgreSQL Playwright coverage for the SQL dashboard without shipping `DBD::SQLite`, `DBD::mysql`, or `DBD::Pg` as base runtime prerequisites.
- Fixed the api-dashboard Playwright request click helper so covered runs no longer fail when the request list rerenders slowly enough for the original locator to detach before the click lands.

## 2026-04-07 (Phase 61: SQL Real Driver Coverage Gap)

- Fixed `sql-dashboard` so passwordless profiles such as SQLite may keep the database user blank, with the blank user preserved in the portable `connection=dsn|user` id instead of being rejected as missing input.
- Fixed shared SQLite route handling so a passwordless saved or reconstructed draft profile now auto-runs correctly without inventing a password requirement that does not exist for the DSN.
- Added a 50-case real SQLite Playwright matrix plus optional docker-backed MySQL/PostgreSQL Playwright coverage, while keeping `DBD::SQLite`, `DBD::mysql`, and `DBD::Pg` out of shipped runtime prerequisites.

## 2026-04-07 (Phase 60: TT Error Source Leak)

- Fixed bookmark `HTML:` render failures so Template Toolkit syntax errors now show a visible runtime error instead of leaking raw `[% ... %]` source into rendered page output.
- Fixed shared `nav/*.tt` error handling so broken nav fragments still surface their TT parse error in the shared nav strip instead of disappearing silently because `Template::Exception` objects were being skipped by the HTML fragment renderer.
- Added web-route, nav-renderer, CLI, and real-browser regression coverage for broken TT syntax in saved pages and raw nav fragments.

## 2026-04-07 (Phase 59: Init MD5 Rewrite Drift)

- Fixed `dashboard init` so dashboard-managed helper files under `~/.developer-dashboard/cli/` are compared by MD5 in Perl and skipped when the shipped content is unchanged, instead of being needlessly rewritten.
- Fixed runtime bootstrap seeding so shipped starter bookmark files such as `api-dashboard` and `sql-dashboard` also skip rewrite when the existing saved file already matches the shipped content digest.
- Added the reusable `Developer::Dashboard::SeedSync` module plus focused CLI and unit coverage to keep the MD5-based skip contract explicit and portable without relying on shell md5 commands.

## 2026-04-07 (Phase 58: Home CLI Helper Ownership Drift)

- Fixed `dashboard init` so it no longer overwrites a pre-existing user-owned helper file in `~/.developer-dashboard/cli/` when that path collides with a built-in helper name such as `jq`.
- Fixed home helper staging so dashboard-managed built-ins may still refresh, but unrelated files and directories in `~/.developer-dashboard/cli/` are preserved instead of being deleted or clobbered.
- Added unit-level and end-to-end CLI coverage for preserved helper collisions plus unrelated-file survival under the home runtime CLI root.

## 2026-04-07 (Phase 57: Raw Nav TT Bypass)

- Fixed shared `nav/*.tt` support so raw Template Toolkit fragment files such as `nav/here.tt` now render in the shared nav strip and through `/app/nav/<name>.tt` instead of being ignored unless they were wrapped as full bookmark documents.
- Fixed raw-nav validation drift by accepting only `nav/*.tt` files that actually look like TT or HTML fragments, so junk files such as `nav/broken.tt` stay out of the rendered nav instead of leaking plain text into the page chrome.
- Added web-route, nav-renderer, and real browser regression coverage for the raw-nav fragment path.

## 2026-04-07 (Phase 56: CLI TT Render Bypass)

- Fixed `dashboard page render` so saved bookmark pages now pass through `Developer::Dashboard::PageRuntime->prepare_page` before HTML rendering.
- Fixed CLI-side Template Toolkit rendering for bookmark `HTML:` sections, so `[% title %]` and other stash placeholders no longer leak into rendered output as raw text.
- Added CLI smoke coverage for saved-page TT rendering and re-verified the real browser bookmark render path with a live Chromium smoke.

## 2026-04-07 (Phase 55: Welcome Seed Dead Weight)

- Stopped seeding the default `welcome` bookmark during `dashboard init` and runtime bootstrap.
- Fixed fresh runtime defaults so new installs and blank environments now start with only `api-dashboard` and `sql-dashboard`.
- Fixed update-manager regression coverage so it verifies an isolated home runtime instead of tripping over the repo checkout's own `.developer-dashboard` tree.

## 2026-04-07 (Phase 54: Path Root Alias Assertion Drift)

- Fixed the packaged `t/21-refactor-coverage.t` `dashboard path project-root` assertion so it now compares path identity instead of raw strings.
- Fixed macOS install-time failures where the same temp repo could appear as `/var/...` in the test fixture and `/private/var/...` from `cwd()`, even though the command resolved the correct project root.
- Added explicit testing/documentation coverage for the CLI path portability contract so `cpanm` installs stay green on symlink-heavy platforms.

## 2026-04-07 (Phase 53: Canonical Path Layer Drift)

- Fixed DD-OOP-LAYERS discovery on symlink-heavy platforms such as macOS by comparing canonical path identities instead of raw path strings.
- Fixed layered runtime lookup so `/var/...` versus `/private/var/...` aliases no longer collapse runtime discovery back to the home layer or break deepest-layer writes.
- Added regression coverage for symlinked-home versus canonical-cwd path comparisons and re-verified the layered nav renderer that depends on the same runtime-layer chain.

## 2026-04-07 (Phase 52: Collector Lifecycle Drift)

- Fixed the `dashboard serve` lifecycle gap so a plain serve now starts configured collector loops alongside the web service instead of leaving collectors idle until a later restart.
- Fixed silent collector startup failure handling by surfacing the real loop startup error and stopping any collectors already launched in the same action.
- Added runtime-manager and CLI smoke coverage proving that `dashboard serve`, `dashboard restart`, and `dashboard stop` all keep collectors under the same managed lifecycle.

## 2026-04-07 (Phase 51: Doctor Result Assumption Leak)

- Fixed the `t/07-core-units.t` doctor assertion so it now clears ambient `RESULT` state before checking the empty-hook path.
- Fixed install-time fragility where inherited hook output in the environment could make the doctor unit test fail even though the runtime code was correct.
- Re-verified the full test suite after the guardrail change so the packaged install path no longer trips over that bad assumption.

## 2026-04-07 (Phase 50: Pod Guesswork Drift)

- Fixed contributor-documentation drift by adding the `FULL-POD-DOC` rule, so every repo-owned Perl file now explains what it is, what it is for, why it exists, when to use it, how to use it, what uses it, and a concrete example instead of stopping at terse stub POD.
- Fixed release-metadata blind spots by making `t/15-release-metadata.t` scan every repo-owned Perl file for the required documentation sections under `__END__`.
- Fixed README/manual/testing drift by documenting the new comprehensive POD floor in the public docs as well as the contributor override rules.

## 2026-04-07 (Phase 49: Built-In Body Leak)

- Fixed the remaining `dashboard` entrypoint bloat by moving the rest of the built-in command bodies out of `bin/dashboard`, so the public command is now only a switchboard that stages helpers, runs layered hooks, resolves the final target, and execs it.
- Fixed built-in command extraction by adding a shared private `~/.developer-dashboard/cli/_dashboard-core` runtime plus staged wrappers for the broader built-in command set, while keeping dedicated helper bodies for query, open-file, ticket, path, and prompt commands.
- Fixed shell bootstrap drift by making generated shell helpers re-enter the public `dashboard` entrypoint through Perl, with the repo `lib/` path carried across the helper handoff during source-tree runs.

## 2026-04-07 (Phase 48: Switchboard Layer Leak)

- Fixed the thin-entrypoint drift by moving the built-in lightweight helper sources into `share/private-cli/`, so `dashboard jq`, `dashboard of`, `dashboard ticket`, `dashboard path`, `dashboard paths`, and `dashboard ps1` now hand off through staged helper scripts instead of loading their implementations directly inside `bin/dashboard`.
- Fixed home-vs-layer helper staging drift so `dashboard init` and on-demand helper extraction now always seed dashboard-managed built-in helpers only under `~/.developer-dashboard/cli/`, while layered lookup and hook execution still apply to user-provided commands across `DD-OOP-LAYERS`.
- Fixed prompt branch detection drift by restoring the older `git branch` parsing path, keeping the trailing `🌿branch` prompt marker aligned with the classic shell helper behavior.

## 2026-04-07 (Phase 47: DD-OOP-LAYERS)

- Fixed the split runtime-layer model by making every existing `.developer-dashboard/` directory from `~/.developer-dashboard` down to the current working directory participate in one inherited runtime stack instead of only a project-vs-home pair.
- Fixed layered custom command lookup so the deepest matching CLI command still wins, while per-command hooks now run across every discovered layer from home to leaf instead of stopping at the first matching hook directory.
- Fixed layered bookmark/runtime inheritance so shared `nav/*.tt`, bookmark TT includes, config `collectors` and `providers`, collector/indicator state lookups, and runtime `local/lib/perl5` exposure now follow the same DD-OOP-LAYERS contract.

## 2026-04-07 (Phase 46: Non-Repo CLI Root Blind Spot)

- Fixed top-level custom command lookup so `dashboard <command>` now checks the current working directory's `./.developer-dashboard/cli` first, even when that directory is not inside a git repo.
- Fixed the lazy command-root resolver so a non-repo directory with `./.developer-dashboard/` but no matching local CLI override still falls back cleanly to `~/.developer-dashboard/cli/<command>`.
- Added CLI smoke coverage for both non-git local override resolution and non-repo home fallback resolution so the pre-runtime command-dispatch path stays correct.

## 2026-04-07 (Phase 45: Entry Point Bloat And Init Config Clobber)

- Fixed the `dashboard` entrypoint bloat by moving the shipped `welcome`, `api-dashboard`, and `sql-dashboard` starter bookmark source into `share/seeded-pages/`, so the public command no longer embeds those large bookmark bodies directly.
- Fixed installed seeded-page lookup so `dashboard init` now resolves those shipped starter bookmarks from the distribution share directory after `cpanm` installs, instead of assuming a source-tree relative path that only exists in the repo checkout.
- Fixed lightweight-command loading drift by keeping `dashboard jq`, `dashboard yq`, `dashboard of`, `dashboard open-file`, `dashboard ticket`, and `dashboard version` on explicit early-return paths that do not build the full web runtime first.
- Fixed `dashboard init` and `dashboard config init` so rerunning them preserves an existing `~/.developer-dashboard/config/config.json` instead of overwriting the user's saved config while still filling in missing defaults, helpers, and starter pages.
- Fixed shipped Perl shebang drift by restoring `/usr/bin/env perl` on the remaining test entrypoints and adding a loader regression test that guards every shipped Perl script path we rely on.

## 2026-04-06 (Phase 44: Coverage Artifact Tarball Leak)

- Fixed the release-artifact hygiene leak by excluding `cover_db` from the Dist::Zilla gather rules so a local covered test run no longer ships Devel::Cover output inside the public tarball.
- Tightened the release metadata guard so the source tree now checks that `cover_db` stays excluded before the next build is accepted.
- Rebuilt the release around the clean `1.79` tarball after confirming the earlier `1.78` artifact was contaminated by local coverage output.

## 2026-04-06 (Phase 43: Windows Perl Path Resolution And SSL Test Hardening)

- Fixed the Windows Strawberry smoke path-resolution bug by allowing an empty `ResolvedPerl` value to reach the fallback resolver, then resolving real executable paths through PowerShell command metadata plus `where.exe` before deriving Strawberry runtime directories.
- Fixed the rerunnable Dockur smoke drift by staging the Strawberry Perl MSI from the Linux host into the OEM bundle, supporting configurable retained host ports, and allowing the Windows guest smoke to use `cpanm --notest` for third-party dependency installs while still running the real dashboard runtime smoke afterward.
- Fixed the SSL live-server regression test so a failed `IO::Socket::SSL->new(...)` now reports the underlying SSL error and produces clean test failures instead of dereferencing an undefined socket handle and aborting the file.
- Re-verified the normal Linux install path with the blank-environment host integration, which still installs `Developer-Dashboard-1.78` successfully and completes the end-to-end runtime smoke after the Windows-harness changes.

## 2026-04-06 (Phase 42: Windows VM Smoke Rerun And Support Boundary)

- Fixed the Windows smoke rerun gap by adding `integration/windows/run-host-windows-smoke.sh`, a one-command host helper that loads reusable `windows-qemu.env` settings, builds a fresh tarball when needed, and delegates to the checked-in QEMU launcher.
- Fixed the stale-session KVM gap by teaching `integration/windows/run-qemu-windows-smoke.sh` to re-exec under `sg kvm` when the user has been added to the `kvm` group but the current shell has not picked that group up yet.
- Fixed the Dockur bootstrap drift by adding a Dockur-backed Windows VM mode, official Strawberry Perl release-feed MSI auto-resolution, and updated docs/tests around the supported Windows runtime baseline: PowerShell plus Strawberry Perl, with Git Bash and Scoop kept optional.
- Fixed the executable-bit blind spot by expanding `t/13-integration-assets.t` so the checked-in Windows smoke launchers must remain executable in the repo.

## 2026-04-06 (Phase 41: API Dashboard Request Credentials And Secure Persistence)

- Fixed the missing `api-dashboard` request-auth flow by adding a hide/show workspace credentials panel with bookmark-local `Basic`, `API Token`, `API Key`, `OAuth2`, `Apple Login`, `Amazon Login`, `Facebook Login`, and `Microsoft Login` presets backed by Postman `request.auth` import/export.
- Fixed the request-auth execution gap by applying saved request auth to outgoing headers or query strings during `api-dashboard` sends instead of forcing operators to hand-maintain equivalent raw headers for every request.
- Fixed the project-local `api-dashboard` secret-storage gap by tightening `./.developer-dashboard/config/api-dashboard` to owner-only `0700` and every saved collection JSON file there to owner-only `0600`, and expanded the saved-Ajax plus Playwright coverage around that path.

## 2026-04-06 (Phase 40: SQL Workspace Quiet Editor And Inline Actions)

- Fixed the SQL workspace clutter drift by making the editor the primary focus, growing the textarea with its content, and replacing the loud editor toolbar with one understated action row beneath the SQL textarea.
- Fixed the redundant schema-open control in the SQL workspace by removing the extra in-editor button and keeping schema navigation on the top `Schema Explorer` tab instead.
- Fixed the saved-SQL delete sprawl by moving deletion to a compact inline `[X]` affordance beside each saved SQL entry so the action stays visually tied to the item it removes.

## 2026-04-05 (Phase 39: SQL Workspace Layout And Multi-Save)

- Fixed the SQL workspace usability split by merging SQL collections and editing into one `SQL Workspace` tab with a phpMyAdmin-style master-detail layout so the active collection tabs and that collection's saved SQL list stay together in the left navigation rail beside the editor.
- Fixed the saved-SQL context gap by keeping the active saved SQL name visible in the workspace and making the saved SQL list heading show which collection owns the visible SQL list.
- Fixed the SQL collection overwrite bug by treating a different SQL name in the same collection as a new saved SQL entry instead of overwriting the selected one, and expanded the unit, browser, and CLI smoke coverage around that flow.
- Fixed the `dzil build` duplicate-license blocker by excluding the tracked `LICENSE` file from `GatherDir` so the `[License]` plugin can generate the packaged license file without aborting the build.

## 2026-04-05 (Phase 38: SQL Collections And Shareable Connections)

- Fixed the SQL workspace portability gap by replacing profile-name URL state with a portable `connection=dsn|user` id, rebuilding a draft profile from that shared id on machines that do not already have the saved connection, and auto-running the shared SQL only when a matching locally saved password already exists.
- Fixed the missing SQL collection layer by persisting saved SQL under `./.developer-dashboard/config/sql-dashboard/collections/<collection-name>.json`, keeping collections independent from connection profiles, and restoring those collections as tabbed browser state on load.
- Fixed the SQL driver-selection gap by replacing the free-text driver field with a dropdown of visible `DBD::*` modules that rewrites only the `dbi:<Driver>:` DSN prefix, moved all sql-dashboard saved Ajax endpoints onto singleton workers, and expanded the saved-Ajax plus Playwright coverage around the new flow.

## 2026-04-05 (Phase 37: SQL Profile Permission Hardening)

- Fixed the SQL workspace profile-storage permission gap by tightening `./.developer-dashboard/config/sql-dashboard` to owner-only `0700` and every saved profile JSON file to owner-only `0600`.
- Fixed upgrade drift for older SQL profile stores by having the bookmark bootstrap/profile-read path repair insecure existing profile directory and file modes instead of only securing newly written files.
- Updated browser and saved-Ajax regression coverage plus the shipped docs and software spec so the secured SQL profile persistence model stays explicit and verified.

## 2026-04-05 (Phase 36: SQL Isolation Cleanup)

- Fixed the isolation drift in the new SQL workspace release by removing the dedicated `Developer::Dashboard::CPANManager` core module and keeping runtime driver installation in the `dashboard cpan <Module...>` script path instead.
- Fixed saved-Ajax runtime driver loading without the extra module by deriving `./.developer-dashboard/local/lib/perl5` directly from the active runtime root before bookmark Ajax workers spawn.
- Replaced the old manager-module unit coverage with `t/28-runtime-cpan-env.t` and updated the public docs and software spec so the shipped description matches the script-local runtime driver design.

## 2026-04-05 (Phase 35: Generic SQL Dashboard)

- Fixed the seeded SQL workspace gap by replacing the placeholder `db-dashboard` starter with a bookmark-local `sql-dashboard` that keeps connection profiles under `config/sql-dashboard/<profile-name>.json`, restores shareable URL state, supports profile create/edit/delete, and runs SQL through generic `DBI` instead of a single database brand.
- Fixed optional database-driver packaging drift by adding `dashboard cpan <Module...>`, which installs requested modules into `./.developer-dashboard/local`, appends them to the runtime `cpanfile`, and automatically records `DBI` when users request a `DBD::*` driver.
- Added browser and saved-Ajax regression coverage for the SQL workspace, added runtime-driver regression coverage, and updated testing docs, integration docs, and `SOFTWARE_SPEC.md` so the seeded SQL workflow and runtime driver model stay documented and verified.

## 2026-04-05 (Phase 34: Bookmark Markup Simplification)

- Removed the old split bookmark form directives so `HTML:` is now the only supported bookmark markup section.
- Removed the old form-section render paths from page rendering, nav-fragment rendering, and editor syntax-highlighting so removed directives no longer stay half-supported behind the parser.
- Updated public docs, shipped POD, and `SOFTWARE_SPEC.md` to describe the simplified bookmark syntax and added release guards that fail if removed form directives come back.

## 2026-04-05 (Phase 33: Skill Authoring Documentation)

- Fixed the documentation gap around authoring new skills by adding a shipped `SKILL.md` guide that explains the expected repository structure, command dispatch model, `cli/<command>.d/` hooks, bookmark routes, bookmark syntax, browser helpers, and custom CLI extension points.
- Added `Developer::Dashboard::SKILLS` as installed POD so the same skill-authoring reference is available after CPAN installation, not only in a source checkout.
- Tightened the release-metadata test so future releases fail if the public docs stop covering the supported skill authoring workflow and runtime boundaries.

## 2026-04-05 (Phase 32: Documentation Terminology Cleanup)

- Removed internal-history wording from markdown docs, shipped POD, release notes, and bug logs so public-facing documentation now describes bookmark compatibility and older runtime shapes directly.
- Added a release-metadata guard that fails if markdown docs or shipped POD reintroduce that internal wording.
- Fixed the tarball doc set by shipping `SOFTWARE_SPEC.md` again, so built-distribution release tests see the same public documentation inventory as the source tree.

## 2026-04-04 (Phase 22: API Dashboard Postman Workspace)

- Replaced the seeded `api-dashboard` bookmark’s single raw request form with a Postman-style workspace that supports collection import/export, multiple request tabs, and local request saving inside collections.
- Added a saved bookmark Ajax bootstrap endpoint for loading neutral Postman collections from the runtime `config/postman` directory and a saved request sender endpoint backed by `LWP::UserAgent`, so API testing no longer depends on browser CORS.
- Fixed the clean-install packaging gap by declaring the embedded API sender runtime prerequisites in `Makefile.PL`, so blank `cpanm` environments install `LWP::UserAgent`, `HTTP::Request`, and `URI` before the bookmark Ajax sender tests run.

## 2026-04-04 (Phase 21: Stream-Data Browser Fix)

- Fixed older bookmark `stream_data()` so it exists again and updates DOM targets from incremental saved Ajax output instead of waiting for the whole response to finish.
- Fixed older bookmark `stream_value()` so it now uses the same progressive browser streaming path instead of degrading to a one-shot `fetch().text()` request.

## 2026-04-04 (Phase 19: Open-File Vim Tabs)

- Fixed `dashboard of` / `dashboard open-file` so blank Enter at the chooser again uses `vim -p` for the final exec path. That restores the old behavior where “open all matches” opens them as tabs instead of invoking vim without tab mode.

## 2026-04-04 (Phase 18: Open-File Match Ranking)

- Fixed scoped `dashboard of` / `dashboard open-file` search ordering so exact helper/script names are ranked before broader substring hits, restoring the expected `dashboard of . jq` behavior where `jq` and `jq.js` appear before `jquery.js`.

## 2026-04-04 (Phase 17: Open-File Multi-Select Parity)

- Fixed `dashboard of` / `dashboard open-file` so the chooser matches the real old workflow instead of forcing a single selection. A single unique match now opens immediately, while multi-match searches allow one number, comma-separated numbers, numeric ranges, or blank input to open all matches.

## 2026-04-04 (Phase 15: Open-File Picker Restore)

- Fixed `dashboard of` / `dashboard open-file` so multi-match searches no longer degrade into a raw printed list. The command now prints numbered matches, prompts for a selection, and opens the chosen file through the editor path again.
- Fixed the missing editor fallback in the shared open-file implementation. When `--editor`, `VISUAL`, and `EDITOR` are all absent, the command now falls back to `vim`, so direct lookups like `dashboard of . jq` open in an editor again instead of only printing a path.

## 2026-04-04 (Phase 14: Private Ticket Helper Restore)

- Restored `ticket` as a dashboard-managed private helper under `~/.developer-dashboard/cli/` so `dashboard ticket` stays part of the built-in toolchain without shipping a public `ticket` executable in the CPAN-installed PATH.
- Added shared tmux ticket-session logic that reuses existing sessions, creates missing sessions with a `Code1` window, and seeds `TICKET_REF`, `B`, and `OB` into the tmux session environment.

## 2026-04-04 (Phase 13: Private Open-File Helper Restore)

- Fixed private helper staging drift by restoring `of` and `open-file` under `~/.developer-dashboard/cli/` while still keeping them out of the global CPAN-installed PATH.
- Fixed runtime helper regression coverage by proving the private `of` and `open-file` wrappers still resolve direct files, Perl module names, and Java class names just like the main `dashboard of` / `dashboard open-file` paths.

## 2026-04-04 (Phase 12: Public CLI Pollution Cleanup)

- Fixed remaining CPAN PATH pollution by removing standalone `of` and `open-file` executables from the shipped distribution. Those names were still being installed globally even though the same behavior already existed behind `dashboard of` and `dashboard open-file`.
- Confirmed there are no repo-shipped public standalone `ticket` executables or other remaining generic helper binaries in the distribution. `dashboard` is now the only intended public CPAN-facing executable, while private helper assets remain staged under `~/.developer-dashboard/cli/`.

## 2026-04-04 (Phase 1: macOS fix + Namespacing)

- Fixed macOS cpanm installation test 14 failure where `Developer::Dashboard::Runtime::Result::_command_name()` was prioritizing the stale `$ENV{DEVELOPER_DASHBOARD_COMMAND}` environment variable over the actual script path in `$0`, causing incorrect command name attribution in hook execution reports. The fix now derives the command name from normalized `$0` first, preserves trailing-slash script names correctly, treats root-like paths as `dashboard`, and only falls back to the environment variable when `$0` is genuinely empty.
- Completed the namespace cleanup so project-owned Perl modules live only under the `Developer::Dashboard::` prefix. Unscoped modules such as `DataHelper`, `File`, `Folder`, `Zipper`, and `Runtime::Result` are no longer shipped by the distribution.

## 2026-04-04 (Phase 3-5: CLI Refactoring + PATH Prevention)

- Fixed CLI naming conflict risk by removing 'p' prefix from query subcommands, renaming: `pjq` → `jq`, `pyq` → `yq`, `ptomq` → `tomq`, `pjp` → `propq`. The old names are still supported through backward-compatible dispatch mapping.
- Added new query subcommands for expanded data format support: `iniq` for INI files, `csvq` for CSV files, `xmlq` for XML files.
- Fixed system PATH pollution by removing decomposed query subcommands from tarball installation. These commands now live as private dashboard-managed helper files under `~/.developer-dashboard/cli/`, and `dashboard` dispatches to that private runtime helper area instead of relying on public generic command names such as `jq` and `yq`.

## 2026-04-04 (Phase 8: Skill System Implementation)

- Implemented new isolated skill system for installable Git-backed dashboard extensions. Users can now install, update, and uninstall skills using dashboard commands:
  * `dashboard skills install <git-url>` - clone and prepare a skill from any Git repository
  * `dashboard skills uninstall <repo-name>` - cleanly remove a skill by repository name
  * `dashboard skills update <repo-name>` - pull latest changes from skill's repository
  * `dashboard skills list` - enumerate all installed skills with metadata
  * `dashboard skill <repo-name> <command> [args...]` - execute a skill's command
- Fixed skill isolation by storing each skill under `~/.developer-dashboard/skills/<repo-name>/` with mandatory structure: `cli/`, `config/config.json`, `config/docker/`, `state/`, `logs/`, and `local/` for isolated dependencies. This keeps skills isolated from the main runtime and from each other, with simple uninstall by directory removal.
- Added skill extension support for hooks and helpers through `cli/<cmd>.d/` hook directories, allowing skills to extend their own commands with pre/post hooks in the same style as main dashboard.
- Implemented skill configuration support via `config/config.json` plus isolated `cpanfile` handling through per-skill local libraries under `~/.developer-dashboard/skills/<repo-name>/local`.

## 2026-04-04 (Phase 11: Skill App Route Namespacing)

- Implemented skill app route namespacing by adding `/skill/:repo-name/:route` pattern to web app dispatch. Each skill's HTTP endpoints stay under its own isolated namespace, and skill bookmark bundles can now render through `/skill/<repo-name>/bookmarks/<id>` without leaking into `/app/...`.
- Fixed potential skill route interference by validating that routes only match on fully qualified skill names and by returning explicit 404 responses for missing skills and missing skill bookmark routes.

## 2026-04-03

- Fixed browser indicator fallback drift so configured collector icons now render in both the top-right browser strip and `dashboard ps1` instead of leaking collector names when an icon was configured.
- Fixed browser status icon visibility by using an emoji-capable font stack in the top-right chrome, so UTF-8 collector icons such as `🐳` and `💰` stay visible in Chromium and macOS browsers instead of collapsing into fallback boxes.
- Fixed stale collector rename ghosts by removing managed indicator records whose collector names no longer exist in config, so renaming a collector no longer leaves both the old and new indicator in the prompt or `/system/status`.
- Fixed hook-summary ergonomics by adding `Runtime::Result->report()`, so Perl-backed custom commands can print a compact success/error report after their sorted hook files finish.
- Fixed older bookmark Ajax bootstrap ordering by moving saved `set_chain_value(...)` bindings after bookmark body declarations and by adding `fetch_value()` / `stream_value()` helpers, so pages that declare `var endpoints = {};` can populate DOM targets from saved `/ajax/...` endpoints inside `$(document).ready(...)` on first render.
- Fixed UTF-8 CLI/output drift by making dashboard JSON, prompt, and hook-report output consistently emit UTF-8, so collector icons and `Runtime::Result->report()` glyphs survive shell output, `/system/status`, and file-backed state round trips.
- Fixed checkout-local Perl command drift by exporting the active dashboard `lib/` path through `PERL5LIB`, so shebang-backed custom command runners keep loading the current checkout modules instead of a stale installed copy.
- Fixed permissive home-runtime storage by tightening `~/.developer-dashboard` directories to `0700`, regular runtime files to `0600`, and owner-executable runtime files to owner-only `0700`.
- Fixed permission-audit blind spots by adding `dashboard doctor` and `dashboard doctor --fix`, so current and older dashboard roots under `$HOME` can be checked and repaired for owner-only file and folder access.
- Fixed Windows verification drift by checking in `integration/windows/run-strawberry-smoke.ps1` and `integration/windows/run-qemu-windows-smoke.sh`, so Strawberry Perl and full-system Windows validation now live in the repo instead of in ad-hoc manual notes.
- Fixed Windows command-resolution test gaps by extending the forced-Windows unit coverage for `PATHEXT`, `.ps1`, `.cmd`, and `.pl` dispatch, so platform regressions fail in the fast test loop before the slower Windows smoke gates run.
- Fixed Unix-shell lock-in across the command runtime by routing collector `command` strings, trusted page actions, saved Ajax script execution, update scripts, and custom CLI runners through a shared platform layer, so Windows Strawberry Perl installs no longer require `sh` or `bash` just to execute dashboard-managed commands.
- Fixed PowerShell prompt bootstrap support by adding `dashboard shell ps`, so Windows sessions now get the same bookmark-aware navigation helpers through a PowerShell `prompt` function instead of incorrectly relying on the POSIX `PS1` variable.
- Fixed browser-visible SSL redirect failure by placing a same-port HTTP frontend in front of the SSL backend, so `dashboard serve --ssl` now returns a real `307` to `https://HOST:PORT/...` instead of resetting plain-HTTP browser connections on the public port.
- Fixed outsider-bootstrap verification drift by documenting that the disabled-login `401` only applies when the active runtime has no helper users, so project-local helper-user state no longer gets mistaken for a broken browser auth gate.
- Tightened outsider bootstrap denial so pre-helper outsider requests now return a silent `401` with an empty body instead of explaining helper setup, avoiding a needless hint to untrusted clients while still blocking the login screen.
- Fixed outsider-login bootstrap drift by denying outsider requests with `401 with an empty body` when no helper account exists yet, so `localhost` and other non-admin hosts stop showing a dead-end login form before helper access has been configured.
- Fixed SSL redirect drift by wrapping the SSL-enabled PSGI app with an HTTP-to-HTTPS redirect, so any request that still reaches the app as plain HTTP is sent to the matching `https://...` URL before the dashboard route executes.
- Fixed bash-only shell bootstrap output by adding `dashboard shell zsh`, so macOS zsh sessions now get the same bookmark-aware navigation helpers and a `precmd`-refreshed dashboard prompt with zsh job counting.
- Fixed POSIX shell bootstrap gaps by adding `dashboard shell sh`, so non-bash Linux `/bin/sh` sessions now get `cdr`, `dd_cdr`, `which_dir`, and a prompt command that does not depend on bash-only `\j` escapes.
- Fixed prompt-format drift by changing `dashboard ps1` to follow the older `~/bin/ps1` layout, using a parenthesized timestamp prefix, bracketed working directory, and trailing `🌿branch` marker instead of the older brace-wrapped project context.
- Fixed prompt ticket-context loss by teaching `dashboard ps1` to read `TICKET_REF` from the active tmux session environment when the ticket workflow seeded it there but the current shell process did not export it directly.
- Fixed documentation-scope drift by removing release and deployment workflow detail from the main README and `Developer::Dashboard` POD, keeping those user-facing docs focused on runtime behavior while leaving operational release procedure in `doc/update-and-release.md`.
- Fixed packaged-test runtime leakage by clearing `DEVELOPER_DASHBOARD_BOOKMARKS`, `DEVELOPER_DASHBOARD_CONFIGS`, and `DEVELOPER_DASHBOARD_CHECKERS` inside the affected tests, so a developer's local override environment no longer breaks tarball installs and `cpanm` test runs.
- Fixed macOS temp-path comparison drift by normalizing canonical paths inside the affected tests, so `/var/...` and `/private/var/...` temporary directories compare as the same location.
- Fixed clean-runtime CLI smoke setup by creating the generated `~/.developer-dashboard/config` directory before writing `config.json`, preventing early install-time test failure on blank environments.
- Fixed Linux-only runtime-manager test assumptions by skipping `/proc`-dependent assertions on hosts where `/proc` process inspection is unavailable.
- Fixed root-entry drift so opening `/` now uses the saved `index` bookmark as the default home page by redirecting to `/app/index` when that bookmark exists, instead of always dropping into the blank editor first.
- Fixed unknown-route editor drift so opening a missing saved route such as `/app/foobar` now opens the bookmark editor with a prefilled blank bookmark for that requested path instead of returning a 404 error page.
- Fixed saved-bookmark path normalization gaps by stripping a leading `/app/` prefix during dashboards-tree persistence and lookup, so bookmark ids written as `/app/<id>` still save and load from the normal relative bookmark path.
- Fixed helper-login return-path loss so a helper user who was sent to `/login` from a protected page such as `/app/index` now returns to that original page after successful login instead of always landing on `/`.
- Fixed helper redirect hardening gaps by sanitizing the post-login target and rejecting malformed, protocol-relative, external, newline-injected, and `/login...` loop targets before issuing the redirect.

## 2026-04-02

- Fixed saved bookmark route duplication where pages carrying a raw bookmark id like `/app/index` built links such as `/app//app/index/edit`, so View Source and related saved-page links now normalize saved ids before building `/app/...` routes.
- Fixed shared `nav/*.tt` presentation drift by removing the hardcoded vertical inline flex layout and the pale nav background, so nav fragments now wrap horizontally by default and inherit the bookmark theme colors instead of hiding text on dark pages.
- Fixed remaining HTTPS startup bug where `dashboard serve --ssl` passed only the generated certificate and key paths into Plack/Starman but did NOT enable SSL mode itself, so the listener still came up as plain HTTP; the server now forwards `ssl => 1` as well, making the runtime bind as real HTTPS and keeping restart persistence aligned with the saved SSL setting.
- Fixed critical SSL parameter passing bug where `dashboard serve --ssl` would silently fail to enable HTTPS: the ssl flag was parsed and saved, but was NOT being forwarded to the Web::Server constructor in the app_builder callback, causing Starman to run without SSL configuration even though all parameters were queued correctly; now the ssl parameter flows through the entire chain: CLI -> Config -> RuntimeManager -> app_builder -> Web::Server -> Starman SSL configuration.
- Fixed malformed older bookmark icon rendering by normalizing saved bookmark files with broken UTF-8 icon bytes during load, so `/app/<id>` and `/app/<id>/edit` now show stable fallback glyphs instead of `�` boxes and still repair common damaged joined emoji such as `🧑‍💻`.
- Fixed singleton-managed saved Ajax worker cleanup so `dashboard stop` and `dashboard restart` now sweep `dashboard ajax: NAME` processes, and browser bookmark pages send a `pagehide` cleanup beacon to `/ajax/singleton/stop` so closing the tab does not leave singleton workers running in the background.
- Fixed bookmark editor line drift by restoring syntax highlighting inside a clipped overlay viewport that follows the real textarea scroll position by transform, so long bookmark text selection and caret placement no longer land on the wrong visible line.
- Fixed bookmark editor bottom-of-file drift by preserving the final blank line in the overlay, so long saved bookmark edits no longer leave the visible overlay one line shorter than the real textarea.
- Fixed saved bookmark editor script-mode drift by preserving `<script>` versus `<style>` mode correctly across the server-side highlighter, so multi-line JavaScript blocks in `/app/<id>/edit` no longer get recolored as CSS-style attribute/value pairs.
- Fixed bookmark editor self-rewritten token markup by protecting browser and server highlight spans with placeholders during later regex passes, so exact saved bookmark edits no longer leak placeholder markers or token fragments that dislocate the visible overlay while typing.
- Fixed `dashboard serve workers N` stop-state behavior by starting the web service immediately after saving the new worker count when no managed listener is running, with optional `--host` and `--port` support for that auto-start path.
- Fixed bookmark editor typing misalignment by removing width-changing bold styling from the visible directive highlight overlay, so the highlighted text no longer drifts away from the real textarea caret while typing in the browser editor.
- Fixed saved bookmark Ajax refresh leaks by adding `singleton => 'NAME'` support to `Ajax(...)`, so the runtime now renames Perl ajax workers to `dashboard ajax: NAME` and kills older matching workers before starting a refreshed replacement stream.
- Fixed GitHub Actions Node 20 checkout drift by moving the workflows to `actions/checkout@v5` and forcing JavaScript actions onto Node 24, so hosted runners no longer warn that the release/test workflows depend on the deprecated Node 20 action runtime.
- Fixed remaining web-layer coverage gaps by adding direct regressions for the jQuery static-file alias branch, Dancer streaming-failure fallback, and runtime log follow mode, bringing the reviewed `lib/` Devel::Cover report back to 100%.
- Fixed runtime web-process false positives by excluding `dashboard serve logs ...` and `dashboard serve workers ...` helper commands from managed-web detection, so shutdown and restart scans no longer confuse those CLI helpers for the actual Starman service.
- Fixed missing tail-follow control on `dashboard serve logs` by adding `-n N` and `-f`, so users can start from the last requested log lines and continue following appended Dancer2 and Starman output live.
- Fixed missing web-runtime visibility by adding `dashboard serve logs`, so users can read the combined Dancer2 and Starman log output directly from the CLI instead of opening the runtime log file manually.
- Fixed hardcoded Starman worker control by adding persisted `dashboard serve workers N` settings plus one-off `--workers N` overrides for serve and restart, so users can raise or lower worker counts without patching code.
- Fixed saved bookmark Ajax print buffering by enabling autoflush in the generated Perl wrapper for file-backed handlers, so long-running `/ajax/<file>` routes now show incremental browser output even when the saved code only does plain `print` plus `sleep`.
- Fixed blank-environment ajax-stream regression coverage by adding a real installed-route `/ajax/...` streaming check to the integration runner, so future releases prove that the first chunks arrive live instead of only verifying that the worker process stays alive.
- Fixed saved bookmark Ajax default-type drift by making `Ajax jvar => ..., file => ...` and `/ajax/<file>` default to `text/plain` output instead of `html` or `json` when no explicit type is supplied.
- Fixed Dancer2 ajax stream buffering by forwarding streamed `/ajax/...` chunks through Dancer's delayed-response writer instead of collecting them into one final string first, so long-running bookmark Ajax handlers can show output incrementally again.
- Fixed shared `nav/*.tt` context drift on transient play routes by making named bookmark token renders reuse the saved `/app/<id>` current-page path, so nav fragments no longer disappear or flip conditional output just because the browser reached the page through `/?mode=render&token=...`.
- Fixed repeated slow manual bookmark-browser repros by adding a dedicated host-side `integration/browser/run-bookmark-browser-smoke.pl` workflow, so saved bookmark issues now have one fast real-browser smoke path instead of requiring the full blank-environment integration cycle every time.
- Fixed missing `/js/jquery.js` bookmark support by serving a built-in local jQuery-style compatibility shim when no runtime asset overrides it, so saved bookmark pages no longer fail immediately with `$` undefined just because no copied runtime JS file exists.
- Fixed browser-verified older `Ajax jvar => 'foo.bar', file => 'foobar'` bookmark flow coverage, confirming that `foo.bar` is bound to the saved `/ajax/foobar?...` endpoint and that any remaining non-update in the user's sample bookmark is due to the page's own `.display` versus `class=disply` mismatch rather than a dashboard route failure.

## 2026-04-02

- Fixed saved bookmark editor script breakout by escaping inline JSON assignment text before it is embedded into the browser boot script, so literal bookmark HTML such as `</script>` no longer closes the editor bootstrap early and spills raw source text under the page.
- Fixed older saved bookmark bootstrap ordering by defining `set_chain_value()` and the other older helpers before rendering bookmark body HTML, so `Ajax jvar => ...` bindings no longer throw `ReferenceError: Can't find variable: set_chain_value` on play routes.

## 2026-04-01

- Fixed incomplete Dancer2 migration by moving the browser route table into explicit `Developer::Dashboard::Web::DancerApp` handlers, so the shipped web stack now uses Dancer2-native route ownership instead of a single catch-all bridge into the old dispatcher.
- Fixed blank-environment integration log silence by streaming long-running command stdout and stderr live from the runner, so `cpanm` install/test work and Chromium-backed browser checks no longer look hung while they are still progressing.
- Fixed blank-environment integration version drift by reading the expected installed version from the extracted tarball instead of hard-coding a stale release number in the runner.
- Fixed saved bookmark local static-file lookup so `/js/*`, `/css/*`, and `/others/*` now resolve both the effective runtime `dashboard/public/...` tree and `dashboards/public/...`, making saved local assets such as `dashboards/public/js/jquery.js` work after browser saves.
- Fixed older bookmark section parsing so a standalone `---` line ends the current section, preventing trailing pasted prose from being compiled into `CODE*` blocks or echoed back into the bookmark editor.
- Fixed saved bookmark editor routing so browser updates from `/app/<id>/edit` keep saving through the named bookmark route and keep the Play link on `/app/<id>` instead of a transient `token=` URL when transient web tokens are disabled.
- Fixed saved bookmark route drift by removing the parallel `/page/...` surface and serving saved render, edit, source, and action routes consistently from `/app/...` only.
- Fixed blank-environment helper route drift by switching the post-login integration flow from the removed `/page/welcome` path to `/app/welcome`, so the prebuilt-container release verification follows the same saved-route surface as the shipped app.
- Fixed blank-environment browser drift by probing for an installed headless browser and bootstrapping Chromium when the prebuilt `dd-int-test:latest` image is stale, so browser-backed verification no longer dies on a missing `chromium` binary.
- Fixed web restart port-release races by waiting for the previous listener on the managed port to disappear before starting the replacement server, preventing intermittent `Address already in use` failures during `dashboard restart`.
- Fixed minimal-container listener discovery by falling back to `/proc` socket ownership scans when `ss` is unavailable, so `dashboard stop` and `dashboard restart` still find Starman listener pids inside the prebuilt `dd-int-test:latest` image.
- Fixed the remaining blank-container restart race by re-probing the managed web port for late listener pids after the first shutdown sweep, so `dashboard restart` no longer leaves port `7890` occupied after the initial TERM/KILL pass.
- Fixed managed web detection for the Dancer2/Starman master-worker split, so the runtime now still trusts the recorded web master pid when the listener is reported as a separate worker pid on the managed port.
- Fixed CLI startup side effects by deferring bookmark migration, configured path-alias loading, and collector indicator sync until commands that need them actually run, reducing surprise runtime-directory creation during unrelated commands.
- Fixed local-runtime creation drift by keeping `dashboard restart` in a plain git repo on the home runtime instead of creating a new project-local `.developer-dashboard` tree unless that repo has already opted in.
- Fixed saved bookmark Ajax process drift by running stored `Ajax(file => ...)` handlers as real processes, so normal `print`, `warn`, `die`, `system`, and `exec` output flows back to the browser through the same live stream.
- Fixed saved bookmark `/ajax` buffering by executing the stored Perl code directly and streaming raw output to the browser, so ajax progress appears live instead of waiting for a fully buffered response.
- Fixed saved bookmark Ajax file placement by storing named `file => ...` handlers under `.developer-dashboard/dashboards/ajax/...`, so bookmark Ajax files live beside the saved bookmark tree instead of under the runtime cache.
- Fixed saved bookmark Ajax existing-file handling by making `Ajax(file => '...')` without `code => ...` target the existing executable under `.developer-dashboard/dashboards/ajax/...` instead of replacing it with an empty file.
- Fixed transient-url-disabled saved bookmark Ajax endpoint shape by emitting `/ajax/<file>?type=...` and resolving saved handlers from the shared dashboards ajax tree instead of requiring page-scoped query parameters.
- Fixed saved bookmark Ajax breakage under the transient-url hardening policy by adding named `file => ...` Ajax handlers that store code under the saved dashboards ajax tree and execute through `/ajax/<file>?type=...` without requiring transient tokens.
- Fixed saved Ajax stream warning noise by guarding closed-handle `fileno` comparisons, so process-backed ajax coverage runs no longer emit uninitialized-value warnings.
- Fixed browser token-execution exposure by disabling transient `/?token=...`, `/action?atoken=...`, and older `/ajax?token=...` routes by default, so opening an untrusted localhost link no longer runs transient payloads unless `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is enabled explicitly.
- Fixed root-editor policy drift by continuing to allow posted bookmark files while rejecting unsaved transient root-editor execution when transient URL tokens are disabled.
- Fixed plain `Folder` compatibility drift so direct calls such as `perl -MFolder -e 'print Folder->docker'` now lazy-load config-backed path aliases from the active runtime and match the aliases shown by `dashboard paths`.
- Fixed `Folder->dd` and `Folder->runtime_root` returning a doubled `~/.developer-dashboard/.developer-dashboard` path when the current working directory was already inside the home runtime repository.
- Fixed runtime-root precedence drift by making a project-local `./.developer-dashboard` tree the first lookup root for bookmarks, config, CLI commands and hooks, auth users, sessions, and isolated docker service folders, while still falling back to `~/.developer-dashboard` when the local item is absent.
- Fixed local bookmark seeding gaps by adding sanitized `api-dashboard` and `db-dashboard` starter pages to `dashboard init`, so the runtime ships editable built-in request and SQL workspaces without carrying forward company-specific or credential-bearing older bookmark content.
- Fixed blank-environment parity drift by moving the integration harness onto a real fake-project `./.developer-dashboard` tree instead of env-var bookmark/config overrides, so the tarball install exercises the same local-over-home runtime precedence as the shipped code.

## 2026-03-31

- Fixed blank-environment install stalls by exporting `PERL_CANARY_STABILITY_NOPROMPT` alongside the other noninteractive installer variables, so clean-container `cpanm` runs do not hang on dependency prompts from the `JSON::XS` toolchain.
- Fixed CLI hook state visibility by rewriting `RESULT` after each executable hook finishes, so the next sorted hook can react to the accumulated JSON from earlier hook runs instead of only the final command seeing it.
- Fixed Perl hook ergonomics by adding `Runtime::Result`, so hook scripts can read prior hook stdout, stderr, exit codes, and the last hook entry without hand-decoding the raw `RESULT` JSON string.
- Fixed configuration drift by removing separate startup and plugin extension roots, so collectors, providers, path aliases, and docker overlays now come from dashboard config JSON as the single source of truth.
- Fixed blank-environment override drift by moving the fake-project collector regression setup into config JSON instead of a separate startup directory, so the installed runtime exercises the same configured collector path used in normal operation.
- Fixed CLI hook directory naming drift by accepting both `~/.developer-dashboard/cli/<command>/` and `~/.developer-dashboard/cli/<command>.d/` as equivalent hook folders, so either naming style runs the same executable files before the main command.
- Fixed CLI hook progress visibility by replacing the buffered command-hook capture path with a streaming runner, so users can see hook stdout and stderr as each executable file runs instead of staring at a blank terminal until the command finishes.
- Fixed CLI hook RESULT propagation by keeping the streamed stdout and stderr accumulated into the final per-hook JSON blob, so later hooks and the real command still receive structured `RESULT` data after visible progress output.
- Fixed bookmark Template Toolkit context for saved pages and shared nav fragments by setting `env.current_page` to the active request path, so TT conditionals no longer see only the raw process environment and can branch on routes such as `/app/index`.
- Fixed bookmark runtime-context exposure by adding `env.runtime_context.current_page`, so nav fragments and bookmark pages can read the current route from the same runtime-context hash used during rendering.
- Fixed CPAN metadata gaps by adding explicit Dist::Zilla `provides` and repository resources, so generated META files declare shipped modules and the source repository instead of leaving Kwalitee warnings for missing metadata.
- Fixed policy-document gaps by adding root `SECURITY.md` and `CONTRIBUTING.md` files, with a vulnerability-reporting contact and contributor workflow guidance for the published distribution.
- Fixed nested bookmark route drift by letting saved page routes accept ids such as `nav/foo.tt`, so bookmark-editor pages and source routes work for subdirectory-backed saved bookmarks instead of only one path segment.
- Fixed nested bookmark save failures by creating parent directories automatically for saved ids such as `nav/foo.tt`, so bookmark-editor saves can write shared nav pages without manual directory setup.
- Fixed shared page-nav composition by rendering direct `nav/*.tt` bookmark files in sorted filename order between the top chrome and the main page body on other saved pages, while still keeping `/app/nav/foo.tt` itself as a normal editable bookmark page.
- Fixed unconfigured `Folder` runtime drift by making `Folder->dd` and AUTOLOAD-backed root aliases such as `Folder->runtime_root` lazily bootstrap the default dashboard path registry from `HOME`, so compatibility code sees the same runtime root as `dashboard paths` before explicit `configure()`.
- Fixed `Folder` naming drift by teaching `AUTOLOAD` to resolve `runtime_root`, `bookmarks_root`, `config_root`, and `startup_root` through the existing compatibility aliases, so compatibility code can use the same root-style names shown by `dashboard paths`.
- Fixed blank-container integration contamination by delaying `DEVELOPER_DASHBOARD_BOOKMARKS`, `DEVELOPER_DASHBOARD_CONFIGS`, and `DEVELOPER_DASHBOARD_STARTUP` until after `cpanm` finishes installing the tarball, so the shipped test suite still runs against a clean runtime.
- Fixed installed-version visibility by adding `dashboard version`, so an installed runtime can report its shipped Developer Dashboard version without inspecting module files.
- Fixed update-output ambiguity by documenting and testing that `dashboard update` prints the common RESULT JSON map directly.
- Fixed runtime update architecture drift by making `dashboard update` use the same top-level command hook path as every other `dashboard <command>` instead of delegating command-folder execution to `UpdateManager`.
- Fixed runtime update execution drift by making `dashboard update` run any executable regular file in `~/.developer-dashboard/cli/update` while still skipping non-executable files.
- Fixed update-path drift by moving `dashboard update` to `~/.developer-dashboard/cli/update`, so runtime-managed update scripts no longer depend on the current working directory or the repo-local `./updates` folder.
- Fixed missing-update-dir failures by making `dashboard update` return `{}` when `~/.developer-dashboard/cli/update` does not exist yet.
- Fixed CLI hook extensibility by letting every `dashboard <command>` use an optional `~/.developer-dashboard/cli/<command>` hook directory where executable files run in sorted filename order, non-executable files are skipped, and captured `stdout`/`stderr` are exposed to later hooks and the final command through `RESULT` JSON.
- Fixed custom CLI directory support by allowing `~/.developer-dashboard/cli/<command>/run` to serve as the real executable for directory-backed custom commands after the hook files finish.
- Fixed collector state recovery so a malformed persisted `status.json` for a collector such as `vpn` is treated as missing state and is overwritten on the next write instead of crashing collector startup during `dashboard restart`.
- Fixed collector-failure regression coverage by adding a blank-environment and unit test scenario where one broken Perl startup collector stays red without stopping a second healthy collector or its green indicator state.
- Fixed tarball-install validation drift by removing `cpanm --notest` from the blank-environment integration flow, so the shipped artifact is exercised with install-time tests enabled.
- Fixed older bookmark runtime output so `CODE1: { a => 1 }` now both merges `{ a => 1 }` into stash for Template Toolkit rendering and dumps the returned structure into the visible runtime output area.
- Fixed older bookmark runtime order so `CODE*` blocks execute before Template Toolkit rendering, allowing returned hashes such as `{ a => 1 }` to feed `[% stash.a %]` in page HTML.
- Fixed the `hide` helper so `hide print $a` keeps the printed stdout while suppressing the Perl return value instead of dropping the whole block output.
- Fixed bookmark Template Toolkit context by exposing the page title as `title`, so `[% title %]` in `HTML:` now renders the `TITLE:` value.
- Fixed transient bookmark source drift by encoding play/view-source links from the raw instruction text when it exists, so `[% stash.foo %]` no longer collapses into rendered output such as `1` after visiting render mode.
- Fixed browser editor source drift further by making the editor boot script and initial syntax overlay use the raw bookmark instruction text instead of a prepared page body, so `[% ... %]` Template Toolkit tokens no longer disappear after the editor finishes loading.
- Fixed documentation value drift by rewriting the README, main POD, and architecture guide intro to explain what a developer actually gets from Developer Dashboard, how the web UI, collectors, prompt indicators, CLI helpers, and Docker tooling fit together, and why the product works as a developer home across mixed-language projects.
- Fixed web-access documentation gaps by documenting the default `0.0.0.0:7890` bind, passwordless exact `127.0.0.1` admin access, and helper-tier sharing model explicitly in the README and POD.
- Fixed module-description thinness by expanding the documented purpose of the `Developer::Dashboard::*` modules so readers can understand how the runtime is assembled without reading the whole source tree first.

## 2026-03-30

- Fixed main POD encoding drift by declaring UTF-8 before the documented Unicode collector status glyph examples, so POD parsers no longer warn about non-ASCII content appearing before an encoding declaration.
- Fixed GitHub release-runner dependency fragility further by preinstalling the full `App::Cmd` prerequisite chain before `Dist::Zilla`, so fresh Ubuntu runners do not depend on cpanm resolving that stack in one brittle step.
- Fixed tarball release-test drift by skipping GitHub workflow assertions in built archives where `.github/workflows/release-cpan.yml` is intentionally not shipped.
- Fixed release-test timing flakiness by giving the managed-loop sorting regression a short bounded wait for forked test loops to become visible on slower hosts.
- Fixed GitHub CPAN release workflow bootstrap drift by installing `App::Cmd` before `Dist::Zilla`, so release jobs no longer fail on missing `App::Cmd::*` modules during dependency setup.
- Fixed top-level documentation positioning drift by rewriting the README, main POD, and architecture guide to explain the real value of Developer Dashboard as a developer home instead of abstract "project-neutral" wording.
- Fixed release hygiene drift by making old `Developer-Dashboard-*.tar.gz` artifacts an explicit cleanup step before each new build, instead of leaving stale tarballs around between release validations.
- Fixed release cleanup drift further by removing stale `Developer-Dashboard-*` Dist::Zilla build directories before each new build, instead of leaving old extracted release trees behind in the repository root.
- Fixed collector execution rigidity by allowing collector jobs to run Perl via a `code` field while keeping `command` as shell execution, so host checks and other local probes no longer need to abuse shell strings for embedded Perl.
- Fixed bookmark-editor source drift by preserving raw Template Toolkit placeholders such as `[% title %]` in edit and source views instead of replacing them with already-rendered HTML after a browser POST.
- Fixed collector visibility drift by seeding configured collector indicators before the first run, so prompt and page status views show every configured check instead of only previously-executed ones.
- Fixed collector prompt ambiguity by prefixing collector icons with explicit `✅` and `🚨` status glyphs, so healthy and failing checks are visually distinct even when the collector icon itself stays the same.
- Fixed collector indicator verbosity by defaulting the indicator name and label from the collector name, so simple checks no longer need to repeat the same identifier in multiple indicator fields.
- Fixed shared-config path portability by storing custom home-relative path aliases as `$HOME/...` in global config and expanding them back to concrete local paths at runtime.
- Fixed installed shell path resolution so named aliases stored as `$HOME/...` expand correctly during `dashboard path resolve`, `which_dir`, and `cdr` instead of being returned literally.
- Fixed isolated docker compose folder precedence so each folder contributes `development.compose.yml` when present, otherwise `compose.yml`, and auto-scanned folders can be vetoed with `disabled.yml`.
- Fixed docker compose CLI passthrough parsing so real docker compose flags such as `-d` and `--build` are no longer misread as dashboard wrapper options like `dry-run` before the final command is executed.
- Fixed non-dry-run docker compose execution so `dashboard docker compose ...` now `exec`s the resolved `docker compose` command and streams normal compose output instead of printing a dashboard JSON envelope.
- Fixed path-alias management gaps by adding persistent `dashboard path add` and `dashboard path del` commands so custom `cdr` aliases can be created and removed without hand-editing config files.
- Fixed isolated docker compose activation so plain passthrough commands such as `dashboard docker compose config` preload only isolated service folders explicitly marked active, while service names mentioned in passthrough args such as `config green` are still inferred before the real docker compose command is built.
- Fixed compose passthrough drift so service names mentioned after `dashboard docker compose` are inferred before the real docker compose command is built, and isolated `development.compose.yml` service overlays are included automatically.
- Fixed tarball metadata test drift by teaching the release check to accept both repository and Dist::Zilla-generated Makefile.PL quoting for shipped executables.
- Fixed shell path navigation drift so `cdr` and `which_dir` resolve named dashboard paths such as `bookmarks_root` before falling back to project-name search.
- Fixed docker-compose config sprawl by restoring old-style isolated service-folder discovery under the dashboard docker config root, so per-service compose files can live outside the merged JSON config.
- Fixed docker overlay path rigidity by expanding `${VAR}` and `$VAR` placeholders in configured compose file paths, restoring old-style `DDDC`-driven global config patterns.
- Fixed nested config merge loss so repo-local docker config extends global docker service, addon, mode, and env maps instead of replacing them wholesale.
- Fixed root-editor bookmark persistence so posting an older instruction document with `BOOKMARK: index` now saves the page immediately and makes `/app/index` resolve it instead of failing with `Page 'index' not found`.
- Fixed tarball test drift by teaching the release-facing tests to fall back to shipped META.json when `dist.ini` is intentionally absent from the built archive.
- Fixed YAML query command naming by renaming the mistaken `yjq` command to `pyq` across the CLI, standalone executable, tests, and release documentation.
- Fixed release-version drift by cutting a fresh `0.41` artifact for the already-correct standalone CLI and integration assets instead of reusing the stale `0.40` tarball.
- Fixed release-metadata drift by adding a regression test that keeps `lib/Developer/Dashboard.pm`, `dist.ini`, `Changes`, shipped executable entries, and tarball verification guidance aligned.
- Fixed CLI startup weight by splitting the open-file and structured-data query built-ins into standalone installed executables instead of always loading the full `dashboard` runtime.
- Fixed proxy CLI dispatch so `dashboard of`, `dashboard open-file`, `dashboard pjq`, `dashboard yjq`, `dashboard ptomq`, and `dashboard pjp` now exec their lightweight sibling executables early.
- Fixed blank-container harness drift so `integration/blank-env/run-host-integration.sh` honors a supplied host tarball instead of rebuilding unconditionally.
- Fixed release-artifact drift by excluding `dist.ini` from the Dist::Zilla tarball so install targets do not receive local release-builder configuration.
- Fixed structured-data CLI gaps by adding built-in JSON, YAML, TOML, and Java-properties query commands with dotted-path extraction.
- Fixed structured-data query consistency so file-path and query-path argument order is interchangeable and `$d` selects the full parsed document across JSON, YAML, TOML, and Java-properties commands.
- Fixed CLI navigation gaps by adding built-in `dashboard of` and `dashboard open-file` commands with direct file, `file:line`, Perl module, Java class, and recursive pattern resolution.
- Fixed CLI extensibility gaps by dispatching unknown top-level `dashboard` subcommands to executable programs in `~/.developer-dashboard/cli` with argv and stdin passthrough.
- Fixed prompt fallback drift by removing the invented `DD` status marker from blank installs with no indicators.
- Fixed test-fixture hygiene by replacing the remaining dummy helper login passphrases in tests, integration assets, and POD examples with neutral placeholder values.
- Fixed helper chrome drift by showing the authenticated helper username in the top-right user marker instead of always rendering the local system account.
- Fixed Devel::Cover harness drift by making the daemon-style collector loop tests coverage-safe instead of letting covered child processes break TAP completion in `t/07-core-units.t`.
- Fixed collector-loop coverage gaps by adding direct wrapped-fork and child-dispatch tests for `Developer::Dashboard::CollectorRunner` so the full `lib/` report returns to 100% statement and subroutine coverage.

## 2026-03-29

- Fixed integration-plan drift by extending the blank-container test plan to require browser-backed verification and fake-project environment overrides instead of only CLI smoke coverage.
- Fixed integration-browser drift by installing Chromium in the blank-environment container and using it to verify the editor, saved fake-project bookmark page, and helper login page.
- Fixed fake-project flow drift by wiring the integration runner through `DEVELOPER_DASHBOARD_BOOKMARKS`, `DEVELOPER_DASHBOARD_CONFIGS`, and `DEVELOPER_DASHBOARD_STARTUP` and verifying that installed dashboard commands honor those overrides.
- Fixed integration-invocation drift by requiring the host-built tarball flow through `integration/blank-env/run-host-integration.sh` and `docker compose ... run --build --rm blank-env`.
- Fixed artifact-isolation drift by mounting only the host-built tarball into the blank container instead of mounting the live repo source as the app under test.
- Fixed update-path drift in the blank-container run by extracting the mounted tarball inside the container so `dashboard update` runs from built artifact contents.
- Fixed older naming drift by adding `bookmarks` and `bookmarks_root` path aliases for integration and user compatibility.
- Fixed release-confidence gaps by adding a clean-container integration harness that builds with Dist::Zilla, installs with cpanm, and exercises the installed dashboard CLI.
- Fixed deployment-validation gaps by documenting a comprehensive blank-environment integration test plan for the installed runtime.
- Fixed CPAN packaging drift by excluding the checked-in `Makefile.PL` from `GatherDir` so `dzil build` no longer aborts on duplicate `Makefile.PL` output.
- Fixed built-tarball dependency drift by enabling `AutoPrereqs` so an installed `dashboard` binary pulls in runtime modules such as `Template`.
- Fixed installed CLI source resolution so `dashboard page source welcome` and similar saved bookmark ids are not misclassified as transient tokens.
- Fixed helper logout drift by adding a helper-only Logout link in the page chrome instead of showing it to exact-loopback admin views.
- Fixed helper logout cleanup so logging out now removes both the active helper session and the helper account itself.
- Fixed editor workflow drift by removing the manual Update button and restoring the old textarea change/blur auto-submit behavior.
- Fixed machine-address drift by discovering the machine IP from the active interfaces instead of echoing the request host into the top-right chrome.
- Fixed clock drift by making the top-right date and time update live in the browser instead of staying frozen at the initial render.
- Fixed top-right chrome drift by restoring the old local user, host/IP, and date-time context alongside the page status strip.
- Fixed Docker indicator alias drift by restoring the old page-header style of `🟢🐳` instead of `🟢Docker`.
- Fixed page-header indicator drift by restoring the original `status + alias` model from `Playground.pm` instead of using prompt icons or prompt ordering.
- Fixed top-chrome drift by restoring the old indicator-strip behavior instead of rendering the full shell prompt at the top of bookmark pages.
- Fixed title-render drift by keeping bookmark `TITLE:` values in the HTML `<title>` element only instead of also injecting them into the page body.
- Fixed runtime-isolation drift by switching older `CODE*` execution to one throwaway sandpit package per page run, matching the old cleanup model more closely.
- Fixed bookmark-format drift by restoring the original `KEY:` plus `:--------------------------------------------------------------------------------:` file structure as the canonical bookmark source format.
- Fixed directive drift by removing synthetic bookmark directives from saved bookmark serialization and returning to the old directive set.
- Fixed rendering drift by switching bookmark HTML template processing to Template Toolkit with `stash`, `ENV`, and `SYSTEM` available in templates.
- Fixed older runtime drift so `CODE*` blocks now render captured `STDOUT` into the page and display captured `STDERR` as visible runtime errors.
- Fixed editor drift by adding live section highlighting for bookmark directives, HTML blocks, and Perl `CODE*` blocks while editing.
- Fixed editor interaction drift by moving syntax highlighting into the same editing surface instead of a separate side preview.
- Fixed transient-token test coverage drift by escaping transient page tokens in the browser-facing tests to match real query-string transport.

## 2026-03-27

- Fixed constructor state loss in `Developer::Dashboard::CollectorRunner` where `files` and `paths` were not reliably stored, breaking collector execution.
- Fixed constructor state loss in `Developer::Dashboard::Web::Server` where `host` and `port` were not reliably stored, breaking explicit server binding.
- Fixed shell bootstrap generation so `\j` is preserved literally for bash `PS1` instead of being interpolated by Perl.
- Fixed duplicate results from project path discovery by deduplicating `locate_projects` output across configured roots.
- Fixed update-script shell bootstrap directory creation by creating nested config directories before writing bootstrap files.
- Fixed dependency refresh update script so it uses `which cpanm` instead of trying to execute the shell builtin `command`.
- Fixed environment customization gaps by adding support for `DEVELOPER_DASHBOARD_BOOKMARKS`, `DEVELOPER_DASHBOARD_CHECKERS`, `DEVELOPER_DASHBOARD_CONFIGS`, and `DEVELOPER_DASHBOARD_STARTUP`.

## 2026-03-28

- Fixed route-model drift by replacing the landing page at `/` with the old free-form bookmark editor.
- Fixed default-bookmark drift by restoring `/apps -> /app/index` compatibility.
- Fixed page-chrome drift by rendering shared share/source links and prompt-style status at the top of edit and render pages.
- Fixed editor drift by making the web textarea post raw instruction text back through `/` again.

- Fixed helper-auth hardening gaps by enforcing username validation, minimum password length, and `0600` permissions on persisted user records.
- Fixed session hardening gaps by expiring helper sessions automatically, binding them to the originating remote address, and storing them with `0600` permissions.
- Fixed web-response hardening gaps by adding CSP, no-store, frame-deny, nosniff, no-referrer, and no-store headers to the local HTTP server.
- Fixed documentation hygiene by removing literal password examples and replacing them with placeholders.
- Fixed repository hygiene outside the read-only older reference tree by confirming the active tree is clear of the banned company-specific references.

- Fixed old bookmark route drift by adding generic `/app/<name>` forwarding for saved bookmark files and saved URL bookmark entries.
- Fixed old ajax compatibility drift by adding a generic `/ajax` token execution path in the new dashboard runtime.
- Fixed older helper drift by restoring project-neutral `Ajax`, `acmdx`, `j`, `je`, `Folder`, and `File` compatibility surfaces for bookmark code blocks.
- Fixed older parser drift by accepting lowercase `code1:` style sections instead of only uppercase `CODE1:`.
- Fixed the real `api` bookmark compatibility gap so the new runtime now generates the older `configs.collections.all` and `configs.send.request` endpoint bindings during render.

- Fixed old-Playground feature drift by supporting both older bookmark syntax and the modern section syntax in the page engine.
- Fixed older rendering gaps by adding placeholder expansion for bookmark markup content before page render.
- Fixed older runtime gaps by adding trusted `CODE*` execution with stash merge and captured output for saved/provider pages.
- Fixed transient trust drift by keeping older `CODE*` blocks disabled for transient encoded pages unless explicitly enabled.
- Fixed documentation drift that still claimed the old bookmark syntax required a future importer even after compatibility support was added.

- Fixed stale documentation examples that still showed the pre-simplification `dashboard auth add-user <user> <pass> <role>` shape instead of the current two-argument form.
- Fixed coverage blind spots in action trust fallbacks, page resolver saved-page listing, cron scheduling branches, prompt context rendering, and docker compose execution paths so `lib/` is back to 100% statement and subroutine coverage.
- Fixed local repository hygiene by ignoring the `.perl5/` toolchain directory used for local Devel::Cover installs.

- Fixed page-model drift by replacing JSON-first saved and transient page storage with canonical instruction documents as required by the spec.
- Fixed page runtime-state drift by merging query parameters, form submissions, and request context into page state before render and action execution.
- Fixed action-transport drift by adding a separate encoded action payload path instead of relying only on page-token-plus-action-id routing.
- Fixed collector-runtime drift by adding timeout and env handling plus cron-style schedule support to managed collector execution.
- Fixed collector-inspection gaps by persisting combined output and exposing job/output/status inspection data through the CLI and storage layer.
- Fixed prompt-feature drift by adding compact and extended prompt modes, ANSI color support, and stale indicator rendering.
- Fixed indicator-feature drift by adding generic built-in indicator refresh for Docker, Git, and project context.
- Fixed docker-compose layering drift by exposing explicit project, service, addon, and mode overlay precedence in the resolver output.
- Fixed repo rule drift by adding function-level purpose/input/output comments across the Perl codebase and POD trailers across scripts, modules, update scripts, and tests.
- Fixed `Developer::Dashboard::Collector::read_output` so empty stdout and stderr files are read in scalar context and do not collapse hash keys.
- Fixed checker filtering semantics to match the older colon-separated `DEVELOPER_DASHBOARD_CHECKERS` contract exactly.
- Fixed repository hygiene by removing older company-specific code and embedded sensitive material before open-source publication.
- Fixed collector deduplication so pid files are trusted only when the live process title matches the managed `dashboard collector: <name>` convention.
- Fixed collector shutdown so unrelated foreign processes are no longer terminated just because a stale pid file exists.
- Fixed updater restart detection so it uses validated running loop state instead of blindly trusting every `*.pid` file.
- Fixed `Developer::Dashboard::Web::App` constructor state loss so `pages` and `sessions` are retained alongside `auth` and request routing does not collapse at runtime.
- Fixed the web server request bridge so the app receives method, host, cookie, request body, and peer address, enabling the local-admin versus helper security split.
- Fixed response handling so redirect-style headers such as `Location` and `Set-Cookie` are preserved when the app returns them.
- Fixed JSON implementation drift by replacing remaining `JSON::PP` usage with `JSON::XS`, including the shell bootstrap path used by `dashboard shell`.
- Fixed top-level documentation drift by bringing `README.md` and the `Developer::Dashboard` POD back into sync for the current command set and auth model.
- Fixed command-capture drift by replacing remaining backtick and `qx{}` paths with `Capture::Tiny` in the runtime, update scripts, and smoke tests.
- Fixed Capture::Tiny usage drift by removing the last `capture_merged` calls and standardizing on `capture` as required by the repo rules.
- Fixed capture exit handling drift by returning exit codes from the `capture` block itself instead of reading `$?` separately afterward.
- Fixed default listen-address friction by changing `dashboard serve` to bind all interfaces by default while keeping helper gating in the request trust logic.
- Fixed web-service lifecycle drift by making `dashboard serve` run as a managed background service by default and adding matching stop/restart control paths.
- Fixed shutdown reliability so web and collector stop operations no longer depend on pid files alone and can fall back to `pkill`-style managed-process scans.
- Fixed older web-process detection so older plain `dashboard serve` perl listeners are now discovered and terminated by `dashboard stop` and `dashboard restart`.
- Fixed false web-process deduplication so `dashboard serve` no longer treats the invoking shell command, tracing wrappers, or its own current process as an already running web service.
- Fixed plugin discovery by correcting the duplicate-file guard so first-seen plugin JSON files are actually loaded.
- Fixed Docker Compose resolution by correcting the duplicate-file guard so discovered compose files and overlays survive into the final stack.
- Fixed command-routing drift by removing the special built-in `dashboard update` branch, so `update` now behaves like any other user-provided top-level command while still receiving `RESULT` from its ordered hook files.
- Fixed missing PAUSE test dependency metadata by pinning `JSON::XS` explicitly in the Dist::Zilla runtime prerequisites, so clean tarball installs always declare the JSON backend module.
2026-04-10 (Phase 83: Top-Level Manual Release Alignment)
- Problem: the top-level manual cleanup was left as an uncommitted local `2.18`
  state, so there was no new release number, no fresh tarball identity, and no
  release-aligned commit for the actual documentation correction.
- Fix: bumped the release to `2.19`, rebuilt the dist, and aligned the
  top-level manual cleanup with a fresh commit/push cycle.
