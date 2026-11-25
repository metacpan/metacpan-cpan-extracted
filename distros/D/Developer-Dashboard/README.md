<!-- Generated from lib/Developer/Dashboard.pm POD by script/sync-readme-from-pod. Do not edit manually. -->

# Developer Dashboard

<p align="center">
  <img src="docs/assets/banner.png" alt="Developer Dashboard — a home for day-to-day development" width="100%">
</p>

<p align="center">
  <a href="https://metacpan.org/pod/Developer::Dashboard"><img src="https://img.shields.io/cpan/v/Developer-Dashboard.svg" alt="CPAN version"></a>
  <img src="https://img.shields.io/badge/Perl-5.38%2B-2e6ea6?logo=perl&amp;logoColor=white" alt="Perl 5.38 and later">
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-1f2933" alt="macOS, Linux and Windows">
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licence-MIT-green.svg" alt="MIT licence"></a>
</p>

Developer Dashboard brings the everyday tools of local development into one place. Its browser interface, shell commands, prompt status, and scheduled checks share the same saved pages, settings, and runtime data.

## Choose a starting point

| Goal | Start here |
| --- | --- |
| Install it | [Installation](#installation) |
| Open it for the first time | [First Run](#first-run) |
| Save pages, links and actions | [Working With Pages](#working-with-pages) |
| Run scheduled checks in the prompt and browser | [Working With Collectors](#working-with-collectors) |
| Manage containers | [Docker Compose](#docker-compose) |
| Add reusable commands and integrations | [Skills System](#skills-system) |
| Contribute | [Maintainer Guide](#maintainer-guide) |

## Quick start

```sh
./install.sh          # macOS or Linux, from a checkout
```

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1   # Windows
```

```sh
cpanm --no-wget --notest Developer::Dashboard   # from CPAN
```

```sh
d2 init
d2 serve      # starts the web interface
```

## What's inside

- **Browser pages** for links, notes, forms, and reusable actions.
- **Command line tools** for opening files, navigating to project paths, querying structured data, managing pages, and running repeatable tasks.
- **Collectors and prompt status** for scheduled checks whose latest results can appear in the browser and shell prompt.
- **Project configuration** for path aliases, command extensions, API settings, and Docker Compose overlays, with project settings layered over shared settings.
- **Skills and integrations** for reusable commands, pages, and runtime extensions, including workspace-aware conversations through supported AI command line tools.
- **Cross-platform use** with installers and runtime support for macOS, Linux, and Windows.

## Repository map

```
bin/         d2 CLI entry points
lib/         Developer::Dashboard modules
script/      helpers, including the README sync script
share/       browser assets served by the web interface
t/           test suite (prove -j 10, with a coverage gate)
docs/        design notes and the README header
examples/    example pages, collectors and skills
install.sh   Unix and macOS bootstrap
install.ps1  Windows bootstrap
```

## Contributing

See the [Maintainer Guide](#maintainer-guide) for local development, testing and coverage. Open a pull request as a draft while work is in progress, and mark it ready only when it is done and verified.

## Licence

[MIT](LICENSE)

# INTRODUCTION

Developer Dashboard brings the everyday tools of local development into one
place. Its browser interface, shell commands, prompt status, and scheduled
checks share the same saved pages, settings, and runtime data.

Use it to keep project links and notes close at hand, run repeatable checks,
open files quickly, inspect structured data, and manage recurring container
workflows. Project-specific settings can sit alongside shared home settings,
so one installation can support several codebases without forcing them to use
the same pages or commands.

## Start Here

New users can follow the guide in this order:

- Install the command line tool using ["Installation"](#installation).
- Create the initial runtime and open the browser using ["First Run"](#first-run).
- Add saved pages and actions using ["Working With Pages"](#working-with-pages).
- Connect checks to prompt and browser status using ["Working With Collectors"](#working-with-collectors)
and ["Prompt Integration"](#prompt-integration).

Experienced users can go directly to the reference topics for
["Environment Customisation"](#environment-customisation), ["Browser Access Model"](#browser-access-model), ["Docker Compose"](#docker-compose),
and ["Skills System"](#skills-system).

## Main Capabilities

- **Browser pages** for links, notes, forms, and reusable actions.
- **Command line tools** for opening files, navigating to project paths, querying
structured data, managing pages, and running repeatable tasks.
- **Collectors and prompt status** for scheduled checks whose latest results can
appear in the browser and shell prompt.
- **Project configuration** for path aliases, command extensions, API settings,
and Docker Compose overlays, with project settings layered over shared settings.
- **Skills and integrations** for reusable commands, pages, and runtime extensions,
including workspace-aware conversations through supported AI command line tools.
- **Cross-platform use** with installers and runtime support for macOS, Linux, and
Windows.

# USER GUIDE

## Installation

Bootstrap a blank Alpine, Debian, Ubuntu, Fedora, or macOS machine from a checkout with:

    ./install.sh

Bootstrap a blank Windows PowerShell host from a checkout or the current shell with:

    powershell -ExecutionPolicy Bypass -File .\install.ps1
    irm https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.ps1 | iex

`install.sh` and `install.ps1` are checkout-only bootstrap helpers. They ship
in the source tree and release tarball so operators can run them explicitly
from a checkout, extracted tarball, or streamed bootstrap. CPAN and `cpanm`
do not install them as global commands.

When the Unix-like installer is streamed through `sh` without a checkout,
such as `curl ... | sh`, it uses embedded package manifests and creates a
temporary checkout before installing. This gives the bootstrap the same source
snapshot as the installer rather than relying on an older published release.

On Unix-like systems, the installer uses the package manifest for the host
(Debian-family, Alpine, Fedora, or macOS) to install system prerequisites. It
then prepares a user-local Perl environment, installs Developer Dashboard,
configures shell integration, and runs `d2 init`.

The installer displays progress and may ask for the operating-system password
when a system package manager requires elevated access. It prepares the
runtime and shell configuration for future sessions; a terminal-backed
installation also activates the new shell setup when possible.

Security and release validation use a hardened Perl baseline: `5.44`. The
Unix bootstrap accepts an existing host Perl from `5.38`; when it must build
an isolated fallback, it installs `perlbrew --notest install perl-5.44.0`.
The dependency set also pins `HTTP::Tiny` to `0.096` so the transitive
minimum inherited through Plack cannot resolve to versions with known TLS,
request-validation, or cross-origin redirect credential vulnerabilities. It
requires `YAML` `1.30` or newer because lower releases are affected by
CPANSA-YAML-2017-20285.

The Unix-like installer prepares its user-local Perl dependencies before
installing the checkout and initialising the runtime.

On Windows, `install.ps1` installs Git, Strawberry Perl, and Node.js when
needed, then installs the dashboard and initialises its runtime. It configures
the current user's PowerShell profile to load the generated environment and
shell bootstrap files. Use `d2 shell ps` to refresh those generated
PowerShell files later.

Future PowerShell sessions do not rely on installer-only helper functions
while loading the generated profile block.

The generated bash, zsh, POSIX sh, and PowerShell bootstraps share the same
tmux prompt behaviour. In a `d2 workspace` session with
`DEVELOPER_DASHBOARD_TMUX_STATUS=1`, indicators appear on the first row of the
two-line bottom status block. The second row keeps tmux's session and window
list.

The inline
prompt suppresses indicator fragments with `d2 ps1 --no-indicators`.

Ordinary tmux sessions keep the normal inline prompt. Developer Dashboard
does not edit the user's tmux config file to provide that behaviour, and it
uses session-local tmux options
instead of changing the whole tmux server. Those dashboard-managed tmux
sessions also refresh the status block at a 15-second cadence instead of a
hot 2-second loop.

When helper staging reruns during upgrades, the managed home runtime also
removes dashboard-owned older flat helper files from
`~/.developer-dashboard/cli/` so the public command and shell bootstrap
always converge on the current `~/.developer-dashboard/cli/dd/` helper
generation instead of silently reusing stale wrappers from older releases.

The Windows bootstrap does not try to self-install `App::cpanminus` while the downloaded
`cpanm` bootstrap script is still running, which avoids the Windows file
replacement failure that can break streamed `irm .../install.ps1 | iex`
installs.

The shipped distribution metadata also keeps `Plack::Test` and
`Test::Pod` out of the end-user install prerequisite path so blank Windows
hosts do not have to pull the `Test::SharedFork` dependency chain during the
bootstrap. The Windows bootstrap target stays literal: when
`DD_INSTALL_CPAN_TARGET` is set, `install.ps1` passes that exact value
through to `cpanm --notest` instead of trying to reinterpret it.

When that
override is unset in the streamed `irm .../install.ps1 | iex` path,
`install.ps1` clones the current GitHub `master` checkout into a temporary
local tree and installs that local checkout so the bootstrap installs the same
snapshot that shipped the installer instead of an older CPAN release.

The Windows smoke gate also checks that a new profile-loaded PowerShell
session can resolve `d2`, print `d2 version`, run
`d2 logs`, run `d2 restart`, and install at least one real
skill after that streamed bootstrap completes.

The generated PowerShell shell
bootstrap now forces UTF-8 console input and output encoding before it returns
the multi-line prompt from `d2 ps1`, so the prompt keeps the trailing
command marker on the next line and preserves indicator plus branch glyphs
such as heartbeat status and the trailing `🌿branch` fragment in normal
Windows terminals.

Useful bootstrap examples:

    ./install.sh
    SHELL=/bin/zsh ./install.sh
    DD_INSTALL_CPAN_TARGET=./Developer-Dashboard-X.XX.tar.gz ./install.sh
    curl https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.sh | sh
    powershell -ExecutionPolicy Bypass -File .\install.ps1
    $env:DD_INSTALL_CPAN_TARGET = '.\Developer-Dashboard-X.XX.tar.gz'; irm https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.ps1 | iex

Install from CPAN with:

    cpanm --no-wget --notest Developer::Dashboard

The CLI renders its usage and help output through `Pod::Usage` and
`Pod::Text`. The distribution requires `Pod::Text` 6.1.1 or later because
older `podlators` releases are vulnerable to CPU and memory exhaustion when
formatting deeply nested POD (CVE-2026-82560). The minimum is declared in
`cpanfile`, `Makefile.PL`, and `dist.ini`, and regression tests keep the
three dependency sources aligned.

The cross-platform test workflow also declares `Test::Harness` 3.48 as a
test-only prerequisite. Its `TAP::Harness::Env` module is needed by nested
Windows test runs and is not guaranteed to be present in Strawberry Perl, so
the Windows job installs and verifies it in the local test environment. This
does not add `Test::Harness` to end-user runtime installation. The workflow
uses separate full-suite steps: Unix-like runners retain `prove` in Bash,
while Windows uses PowerShell and invokes `App::Prove` through the
workflow-selected Perl. This avoids Git Bash selecting or rewriting paths for
a different Perl installation. `Makefile.PL` always declares
`Test::Harness` for test runs and declares `Devel::Cover` only outside
Windows, where its supported test toolchain can install it; Windows runs the
suite without coverage instrumentation.

Or install from a checkout with:

    perl Makefile.PL
    make
    make test
    make install

`Makefile.PL` uses a project-local `.perl5` library when it contains
installed modules. Otherwise it checks the user's `perl5` library under
`HOME` on Unix or `USERPROFILE` on Windows. If neither home variable is set,
it safely uses only the project-local candidate and emits no
undefined-variable warning.

## First Run

Initialise the runtime:

    d2 init

Inspect resolved paths:

    d2 paths
    d2 paths -o json
    d2 path resolve bookmarks_root
    d2 path add foobar /tmp/foobar
    d2 path add foobar /tmp/foobar -o json
    d2 path add .
    d2 path add scratch /tmp/scratch --create
    d2 path add scratch /tmp/scratch --create 0777
    d2 path del foobar
    d2 path rm foobar
    d2 files
    d2 files -o json
    d2 file add notes ~/notes.txt
    d2 file add notes ~/notes.txt -o json
    d2 file add scratch /tmp/scratch/notes.txt --create
    d2 file resolve notes
    d2 file del notes
    d2 which jq
    d2 which layered-tool
    d2 which nest.level1.level2.here
    d2 which --edit jq

Custom path aliases are stored in the effective d2 config root so shell
helpers such as `cdr foobar` and `which_dir foobar` keep working across
sessions. Installed skills can also provide `lib/Folder.pm` with path methods:
`cdr ch.workspace` checks the effective skill `config/config.json` alias
first, then loads `Folder.pm` and calls `Folder->workspace` only when no
configured alias exists.

If the module implements `Folder->__list__`, its
list-context alias names are merged into `d2 paths`, `d2 path
list`, `cdr` completion, and `d2 ch.` shell completion.

Typing a skill name
followed by a dot offers that skill's config aliases and listed module aliases;
only the named skill's module is loaded for this completion. That runtime merge
is read-only; `d2 path add` continues to write to config, and a config alias overrides a collision
with a module method. When a project-local `./.developer-dashboard` tree exists, alias
writes go there first; otherwise they go to the home runtime.

Under
`DD-OOP-LAYERS`, that write stays local to the deepest participating layer:
adding one child-layer alias does not copy inherited parent `config.json`
domains into the child file.

The child layer keeps only its own new delta and
still inherits the rest from home and parent layers at read time. When an
alias points inside the current home directory, the stored config uses
`$HOME/...` instead of a hard-coded absolute home path so a shared fallback
runtime remains portable across different developer accounts. Re-adding an
existing alias updates it without error, and deleting a missing alias is also
safe.

For `d2 paths`, the global alias view and skill-qualified aliases
share one installed-skill configuration inventory. Each participating skill's
layered `config/config.json` data is read once for that operation, preserving
home-to-project precedence while avoiding a second filesystem scan.

The machine-readable `d2 paths -o json` route does not load terminal
table-rendering helpers. Human-readable output still loads those helpers on
demand, so `d2 paths` and `d2 path list` retain their table
format without paying that import cost when only JSON is requested.

Runtime-layer ownership checks also canonicalise a candidate only once when
testing it against multiple layers. Each root remains freshly canonicalised
and compared at a path-component boundary, preserving symlink-aware security
checks while avoiding repeated candidate resolution.

The aggregate `d2 paths` inventory shares its runtime-layer candidate
list only for the duration of that one inventory call. This avoids repeating
the same ancestor scan across its permission checks without retaining a stale
layer list for later operations; a subsequent lookup discovers newly created
or removed runtime layers.

`PathRegistry::runtime_layers` follows the same freshness rule for a retained
registry object: unscoped calls refresh filesystem discovery, while the path
CLI shares a result only within one command. This keeps repeated reads within
one operation bounded while later operations discover newly created or removed
runtime layers.

When resolving path aliases, one grouped inventory is used and only each
skill's layered `path_aliases` domain is recursively merged. Unrelated config
fields and underscored skill namespaces do not affect the alias result, so
they are omitted without changing skill alias precedence or output.

Developer Dashboard now uses one CLI output contract for operator-facing
built-ins. By default, inventory and mutation commands print a human-readable
summary table. When a script or LLM needs the full raw payload, pass
`-o json`. Shell-plumbing commands that need one stable direct value such as
`d2 path resolve`, `d2 path project-root`, `cdr`, and
`which_dir` keep their direct output contracts instead of forcing a summary
table.

`cdr` now follows a two-stage path flow instead of only jumping to one alias
or one top-level project name. If the first argument resolves as a saved alias
and there are no later arguments, `cdr alias` still goes straight there.

If
the first argument resolves as a saved alias and more arguments remain,
`cdr` enters the alias root, then searches every directory under that root
with AND-matched regex keywords taken from the remaining arguments. One match
means `cd` into that directory; multiple matches mean print the full list and
stay at the alias root.

If the first argument is not a saved alias, `cdr`
treats every argument as an AND-matched regex search beneath the current
directory. One match means `cd` there; multiple matches mean print the list
and leave the current directory unchanged.

`which_dir` follows the same
selection logic but only prints the chosen target or match list instead of
changing directory. Unreadable subdirectories are skipped explicitly during
that search so one protected tree does not abort the whole lookup.

For `cdr` completion, the first argument lists aliases and direct child
directories only. Each following argument narrows one directory level and
lists that level's direct children; completion never recursively walks
unrelated descendants. An unregistered first argument remains a search term
just like later arguments, narrowing both directory lookup and completion.
This keeps TAB responsive in repositories with large dependency folders.

Both `cdr` and `which_dir` therefore use regex narrowing arguments, not
quoted substring tokens.

Examples:

    cdr foobar
    cdr foobar alpha foo bar
    cdr foobar 'alpha-foo$'
    cdr alpha red
    which_dir foobar alpha

Use `Developer::Dashboard::Folder` for runtime path helpers. It resolves the
same runtime, bookmark, config, and configured alias names exposed by
`d2 paths`, and therefore backs the same folder-oriented flow that
`cdr` and `which_dir` use, including names such as `docker`, without relying on
unscoped CPAN-global module names.

`d2 path add .` saves the current working directory under its basename.
`d2 path add <name> .` uses the current working directory as the
target for an explicit alias. `d2 path del .` and `d2 path rm .`
remove the alias that points at the current working directory instead of
treating `.` as a literal error token.

`d2 path add <name> <path> -c|--create[=MODE]` (DD-1005)
marks the alias as lazily creatable: the first time `cdr`, a workspace
route, or any direct Perl caller resolves it and the target directory does
not yet exist, it is created (with parents) before being returned - chmod'd
to the given octal mode (bare, `--create 0777`, `--create=0777`, or
`-c 0777` all work) when one is provided, or left at the implicit
umask-governed default otherwise.

An alias saved without `-c`/`--create`
behaves exactly as before this feature existed.

`d2 file add`
accepts the identical flag, but since a file alias points at a file rather
than a directory, "lazy create" there means only the file's PARENT
directory chain is created - the file itself is left absent for the
caller to write.

Use `Developer::Dashboard::File` for runtime file helpers. It resolves the
same built-in and config-backed file aliases exposed by `d2 files` and
`d2 file list`, supports direct reads and writes through one public
wrapper, and keeps file alias behaviour parallel with the folder/path contract.

It is the file-side twin of the existing Folder contract in the same way that
`d2 of` and `d2 open-file` are the file-side twins of
`cdr` and `which_dir`.

If you need the whole `d2 paths` payload in Perl, call
`Developer::Dashboard::Folder->all` or
`Developer::Dashboard::PathRegistry->all_paths` instead of rebuilding the
hash by hand. If you need a fresh path registry object from that public Folder
inventory, call `Developer::Dashboard::PathRegistry->new_from_all_folders`.

Runtime-layer ancestry stops at the configured home or project boundary. Exact
path spellings stop without canonicalisation; symlink-equivalent boundaries
resolve their canonical identity once per walk.

During one `all_paths` inventory or path CLI operation, ancestor runtime
layers are discovered once and reused by path resolution and permission checks;
the result is discarded at the operation boundary so later operations see
runtime-layer creation and removal. If you need a collector store from the same Folder-derived runtime roots, call
`Developer::Dashboard::Collector->new_from_all_folders`.

If you need the whole `d2 files` payload in Perl, call
`Developer::Dashboard::File->all` or
`Developer::Dashboard::FileRegistry->all_files` instead of rebuilding the
hash by hand.

File aliases follow the same effective-config write rules as path aliases. `d2 file add <name> <path>` writes to the deepest
participating config layer, keeps `$HOME/...` storage portable when the
target lives under the current home directory, updates existing aliases
idempotently, and lets `d2 file resolve <name>`,
`d2 of <name>`, or
`Developer::Dashboard::File->resolve($name)` read that alias back later.

When the alias name is a valid Perl method token,
`Developer::Dashboard::File->$name()` also works directly.

When the alias
is numeric such as `123`, use a scalar method name like
`my $name = 123; Developer::Dashboard::File->$name()` because bare
`->123` is not valid Perl syntax. `d2 files` prints the full
built-in plus configured file inventory as a table by default, while
`d2 file list` prints only the named configured file aliases.

Use
`-o json` with either command when you need the full raw payload.

`d2 of` and `d2 open-file` now treat configured file aliases
as direct file targets before they fall back to Perl-module, Java-class, or
regex search behaviour. If the first token resolves as a saved path alias and
the remaining tokens join into one existing relative file path inside that
aliased directory, `d2 of <path-alias> <relative-file>`
opens that exact file instead of treating the remaining tokens as regex
patterns.

That means flows such as
`d2 file add 123 /tmp/123.txt` followed by `d2 of 123`, or
`d2 path add foobar .` followed by `d2 of foobar 456.txt`, now
resolve the exact configured or scoped file target directly.

The hashed `state_root`, `collectors_root`, `indicators_root`, and
`sessions_root` paths live under the shared temp state tree, not inside the
layered runtime config tree. If a reboot or temp cleanup removes one of those
hashed state roots, the path registry recreates them automatically the next
time dashboard code resolves them.

Its `runtime.json` metadata is rewritten
only when missing, stale, or not owner-only; an unchanged owner-owned regular
file is left untouched, and a metadata symlink is refused.

For each path-registry instance, the account name used in the state-root path
is reused while the relevant environment values stay unchanged; changes to
those values are detected and resolved again.

Use `d2 which <target>` to inspect what `d2` would
execute before you run it. The command prints one
`COMMAND /full/path` line for the resolved file and then one
`HOOK /full/path` line for each participating hook in runtime execution
order.

That works for built-in helpers such as `jq`, layered custom commands
such as `layered-tool`, single-level skill commands such as
`example-skill.somecmd`, and multi-level nested skill commands such as
`nest.level1.level2.here`.

If you add `--edit`, `d2 which` skips the
inspection output and re-enters `d2 open-file` with the resolved
command file path so the normal editor-selection behaviour is reused.

Render shell bootstrap for bash, zsh, POSIX sh, or PowerShell:

    d2 shell bash
    d2 shell zsh
    d2 shell sh
    d2 shell ps

The generated zsh bootstrap now loads `compinit` before any `compdef`
registration, so a fresh macOS zsh shell can evaluate it without raising
`command not found: compdef`.

Audit runtime permissions:

    d2 doctor
    d2 doctor --fix

The doctor command also checks staged helper drift under
`~/.developer-dashboard/cli/dd/` and repairs dashboard-managed helper content
with `--fix` when the installed helper assets are current. On Debian-family
bash hosts it also repairs dashboard-managed shell bootstrap lines that were
previously appended after the non-interactive `return` guard in
`~/.bashrc`.

Resolve or open files from the CLI:

    d2 of --print My::Module
    d2 open-file --print com.example.App
    d2 open-file --print javax.jws.WebService
    d2 of --print notes
    d2 of --print . 'Ok\.js$'
    d2 of --print foobar 456.txt
    d2 open-file --print path/to/file.txt
    d2 open-file --print bookmarks index

Query structured files from the CLI:

    printf '{"alpha":{"beta":2}}' | d2 jq alpha.beta
    printf 'alpha:\n  beta: 3\n' | d2 yq alpha.beta
    printf '[alpha]\nbeta = 4\n' | d2 tomq alpha.beta
    printf 'alpha.beta=5\n' | d2 propq alpha.beta
    d2 jq file.json '$d'

Start the local app:

    d2 serve

Open the root path with no bookmark path to get the free-form bookmark editor directly. The browser now splits bookmark sections into separate editor blocks instead of making you manage one long source textarea by hand, but it still saves the same on-disk bookmark file format behind the scenes.

If you start the web service with `d2 serve --no-editor` or `d2 serve --no-endit`, the browser stays read-only instead and direct editor/source routes are blocked.

If you start it with `d2 serve --no-indicators` or `d2 serve --no-indicator`, the right-top browser chrome is cleared while normal page rendering still works.

Stop the local app and collector loops:

    d2 stop

Interactive terminal runs now print a task board on `stderr` first, then
mark each stop step as it finishes so the command does not appear hung while
the runtime waits for managed shutdown.

Restart the local app and configured collector loops:

    d2 restart

Interactive restarts print a task board on `stderr`. The active step is
highlighted, and completed or failed steps receive a status marker. The final
JSON result remains on `stdout`.

Stop and restart use numeric POSIX signals. This supports minimal Alpine and
iSH Perl builds that do not accept signal names such as `TERM`.

Create a helper login user:

    d2 auth add-user <username> <password>

Remove a helper login user:

    d2 auth remove-user helper

Helper sessions show a Logout link in the page chrome. Logging out removes both
the helper session and that helper account. Helper page views also show the
helper username in the top-right chrome instead of the local system account.
Exact-loopback admin requests do not show a Logout link.

## Managing API Keys For Saved Ajax Routes

List the effective machine-auth API registry:

    d2 api
    d2 api ls
    d2 api ls --key helper-bot
    d2 api ls --key helper-bot -o json

Create or update one API group from a raw secret:

    d2 api add --key helper-bot --secret raw-secret
    d2 api add --key helper-bot --secret rotated-secret
    d2 api add --key helper-bot --secret raw-secret --route /ajax/health --route /ajax/healthz
    d2 api add --key helper-bot --maybe-secret raw-secret --route /ajax/health --route /ajax/healthz

Add one exact saved Ajax route to an existing API group:

    d2 api add --key helper-bot --route /ajax/health
    d2 api add --key helper-bot --route /ajax/healthz

Remove one route or remove the whole API group:

    d2 api rm --key helper-bot --route /ajax/healthz
    d2 api rm --key helper-bot

The `d2 api` command manages the deepest writable runtime
`config/api.json` layer under `DD-OOP-LAYERS`. Listing shows the effective
merged registry from home through the active child layer together with any
installed-skill API fragments that contribute saved Ajax machine auth.

Updates
never rewrite installed skill files; they only change the writable runtime
layer for the current working context. List, add, and remove actions print
human-readable tables by default; use `-o json` when you need the full raw
machine payload.

When you pass `--secret`, the raw secret is hashed to a SHA-256 hex digest
before it is stored. `--maybe-secret` is the route-friendly alias for the
same raw secret input: if the key is missing it creates the group, and if the
key already exists it overwrites the stored secret while the command updates
the requested routes.

The saved JSON keeps the digest under `secret` plus the
exact allowed saved Ajax routes under `ajax`.

`d2 api add` accepts
one or more repeated `--route` flags, so one command can create the key,
hash the secret, and register multiple exact routes at once. Adding the same
route twice is a no-op. Removing an inherited API group from a deeper child
layer writes a child-layer tombstone so the parent definition is hidden
without editing the parent file.

## Working With Pages

Create a starter page document:

    d2 page new sample "Sample Page"

Save a page:

    d2 page new sample "Sample Page" | d2 page save sample

List saved pages:

    d2 page list

Render a saved page:

    d2 page render sample

`d2 page render` now uses the same page-runtime preparation path as
the browser route, so saved bookmark TT such as `[% title %]` and
`[% stash.foo %]` is rendered there too instead of only working under
`/app/<id>`.

Encode and decode transient pages:

    d2 page show sample | d2 page encode
    d2 page show sample | d2 page encode | d2 page decode

Run a page action:

    d2 action run system-status paths

Bookmark documents use the original separator-line format with directive
headers such as `TITLE:`, `STASH:`, `HEAD:`, `HTML:`, and `CODE1:`.
`HEAD:` accepts trusted raw HTML and inserts it inside the rendered document's
`<head>` element; do not place untrusted or user-supplied text there.

Posting a bookmark document with `BOOKMARK: some-id` back through the root
editor now saves it to the bookmark store so `/app/some-id` resolves it
immediately.

The browser editor now loads one visible block per bookmark section while it
keeps the canonical separator-based bookmark source in a hidden form field for
saves and play requests. Each visible block still uses the syntax-highlighted
overlay viewport that follows the real textarea scroll position by transform
instead of a second scrollbox, so long lines, full-text selection, and caret
placement stay aligned with the real editor.

Pressing `Tab` inside one block
starts the next section block, and the browser recomposes those blocks back
into the original separator-line bookmark document before it posts or plays
the page. The directive assist still understands `:---` when you paste older
single-textarea workflows into one block, expanding it to the full separator
line and seeding the next sensible directive.

Edit and source views preserve raw Template Toolkit placeholders inside
`HTML:` sections, so values such as `[% title %]` are kept in the bookmark
source instead of being rewritten to rendered HTML after a browser save. Template Toolkit rendering exposes the page title as `title`, so a bookmark
with `TITLE: Sample Dashboard` can reference it directly inside `HTML:`
with `[% title %]`.

Transient play and view-source links are also encoded
from the raw bookmark instruction text when it is available, so
`[% stash.foo %]` stays in source views instead of being baked into the
rendered scalar value after a render pass.

Earlier `CODE*` blocks now run before Template Toolkit rendering during
`prepare_page`, so a block such as `CODE1: { a =` 1 }> can feed
`[% stash.a %]` in the page body. Returned hash and array values are also
dumped into the runtime output area, so `CODE1: { a =` 1 }> both populates
stash and shows the bookmark-style dumped value below the rendered page body.

The `hide` helper no longer discards already-printed STDOUT, so
`CODE2: hide print $a` keeps the printed value while suppressing the Perl
return value from affecting later merge logic.

Page `TITLE:` values only populate the HTML `<title>` element. If a
bookmark should show its title in the page body, add it explicitly inside
`HTML:`, for example with `[% title %]`.

`/apps` redirects to `/app/index`, and `/app/<name>` can load
either a saved bookmark document, a saved ajax/url bookmark file, or an
installed skill index page when the smart route resolves to a skill.

Saved URL bookmark compatibility is preserved. A saved bookmark whose raw
content is an HTTP(S) URL returns a `302` redirect to that URL and appends the
current query string. A local route is forwarded inside the dashboard instead;
bookmark parameters are merged with request parameters, and array
parameters are reduced using `<name>.selected.pos` before forwarding.

Template Toolkit includes are skill-aware. A skill bookmark can use
`[% INCLUDE "fragment.tt" %]` for a file beside its dashboard, or
`[% INCLUDE "skills/foobar/dashboards/fragment.tt" %]` for an explicit
runtime skill path. Normal dashboard bookmarks continue to resolve includes
from their layered dashboards roots.

The `Ajax` helper renders supplied `code` as a Template Toolkit template
before either transient URL encoding or saved-file storage when `data
&#x3d;> \{ ... \}` is provided. For example,
`Ajax( code => 'print [% args %];', data => \{ args => 123 \}, ... )`
encodes or stores `print 123;` for the Ajax worker to execute.

## Working With Collectors

Ensure the home config file exists without seeding collectors:

    d2 config init

If `config/config.json` is missing, that command creates it as:

    {}

It does not inject an example collector, and if the file already exists it is
left untouched.

List collector status:

    d2 collector list
    d2 collector status shell.example

Inspect collector logs:

    d2 collector log
    d2 collector log shell.example

`d2 collector log` prints the known collector log streams.
`d2 collector log <name>` prints one collector transcript.

If a configured collector has not run yet, the command prints an explicit
no-log message instead of blank output.
`d2 collector status <name>` now also exposes watchdog
metadata for managed loops, including `watchdog_restart_count`,
`watchdog_last_unexpected_stop_at`, `watchdog_last_restart_at`, and
`watchdog_attention_required`, so repeated collector crashes are visible
instead of looking like silent disappearance.

Collector status timestamps and collector log headers use the machine's local
system time with an explicit numeric timezone offset such as `+0100`, so the
visible timestamps line up with cron scheduling on the same machine instead of
looking one hour behind during daylight-saving transitions.

Collector jobs support two execution fields:

- `command` runs a shell command string through the native platform shell:
`sh -lc` on Unix-like systems and PowerShell on Windows
- `code` runs Perl code directly inside the collector runtime

A collector may use `interval` polling or a standard five-field local-time
`cron` expression in `config/config.json`. The fields are minute, hour,
day-of-month, month, and day-of-week.

Numeric values, comma-separated lists,
ranges, range steps, `*/step`, and case-insensitive month and weekday names
are supported. When both day-of-month and day-of-week are restricted, either
matching field makes the date due, following crontab semantics.

To run once at the start of every hour, use `0 */1 * * *`: the first field
is the minute, so `0` selects minute zero, and `*/1` in the second field
selects every hour. Do not use `* */1 * * *` for an hourly run. Its first
field is `*`, which matches every minute, so it runs once per minute
throughout each hour.

An explicit
`schedule` value takes precedence over inferred scheduling; use
`"schedule": "cron"` with `cron` when you want to state the mode explicitly.

Missing or malformed cron expressions are rejected when the loop starts rather
than running once per scheduler poll.

For example, run a report at 09:00 on weekdays:

    {
      "collectors": [
        {
          "name": "weekday.report",
          "command": "./report",
          "cwd": "home",
          "cron": "0 9 * * MON-FRI"
        }
      ]
    }

Cron loops poll once per second and deduplicate execution within each matching
minute. They use the machine's local time and timezone.

A collector's `cwd` may be an absolute or relative directory, a built-in
directory accessor such as `home`, a configured `path_aliases` name, or a
skill-qualified `Folder.pm` alias such as `collectorpaths.workspace`. Config
aliases take precedence over skill-provided aliases. The latter are resolved
read-only from the installed skill's `lib/Folder.pm` using the same method
rules as `d2 path resolve`.

The built-in `housekeeper` collector is always present even when
`config/config.json` is otherwise empty. It runs every `900` seconds with
Perl `code` instead of a shell command, so it does not depend on `PATH`
resolution.

That collector removes stale hashed runtime state roots from the
shared temp tree under `/tmp/<user>/developer-dashboard/state/` and
removes older `developer-dashboard-ajax-*` temp files plus
`dashboard-result-*` runtime result temp files left behind in `/tmp/`. It
also rotates collector log transcripts when a collector defines `rotation`
or `rotations`.

`lines` keeps the trailing line count, while `minute`,
`minutes`, `hour`, `hours`, `day`, `days`, `week`, `weeks`,
`month`, and `months` keep only log entries newer than the requested
retention window. Both rules cut on entry boundaries, so a rotated
transcript always starts at a complete entry header: a line budget drops
whole entries rather than slicing one in half, and a budget smaller than
the newest entry empties the transcript instead of leaving a headerless
fragment behind.

Run it on demand with:

    d2 housekeeper
    d2 collector run housekeeper

If you need different cadence or behaviour, define your own collector named
`housekeeper` in config. That override now inherits the built-in `code` and
`cwd` defaults, so changing only `interval` or adding `indicator`
metadata is enough:

    {
      "collectors": [
        {
          "name": "housekeeper",
          "interval": 60,
          "indicator": {
            "icon": "🧹"
          }
        }
      ]
    }

Example collector definitions:

    {
      "collectors": [
        {
          "name": "shell.example",
          "command": "printf 'shell collector\n'",
          "cwd": "home",
          "interval": 60
        },
        {
          "name": "perl.example",
          "code": "print qq(perl collector\n); return 0;",
          "cwd": "home",
          "interval": 60,
          "indicator": {
            "icon": "P"
          }
        },
        {
          "name": "foobar",
          "command": "./foobar",
          "cwd": "home",
          "interval": 10,
          "mode": "multiple",
          "multiple": 3,
          "rotation": {
            "lines": 100,
            "days": 1
          },
          "indicator": {
            "name": "foobar.indicator",
            "label": "Foobar",
            "icon": "[% a %]"
          }
        }
      ]
    }

Collector concurrency defaults are explicit:

- When `mode` is omitted, the collector runs in `singleton` mode.
- In `singleton` mode, the scheduler skips a due run while an older run of the
same collector is still active.
- In `multiple` mode, the scheduler still starts due runs while older runs are
active, but only until `multiple` active runs are already in flight.
- When `mode` is `multiple` and `multiple` is omitted, the runtime uses
`2`.
- Collectors whose `command` re-enters `d2` through a shell
path now have a safety floor of `30` seconds even if config asks for a
smaller interval, because those recursive dashboard collectors are materially
heavier than direct shell probes. Set `allow_fast_poll` or
`allow_fast_dashboard_poll` on that collector, or set
`DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS`, when the faster
cadence is intentional and understood.
- When a collector sets `disable => 1` or `"disable": true`, dashboard
will not start that collector, explicit named starts reject it, and any
already-running managed loop for that collector is stopped during the next
collector lifecycle action. Managed indicator state for that collector is
also removed instead of lingering as if it were still active.

    The flag is read by its truth value, so a JSON literal `false` (or `0`,
    `"false"`, `"no"`, `"off"`) keeps the collector enabled while `true` and
    any other non-empty value disable it; `"disable": false` is not a disabled
    collector.

- Stopping a singleton collector loop also terminates the long-running command
currently owned by that loop, so `d2 stop collector foo` does not leave
the old worker command alive behind the stopped dispatcher.

Collector indicators follow the collector exit code automatically: `0`
stores an `ok` indicator state and any non-zero exit code stores `error`. When `indicator.name` is omitted, the collector name is reused
automatically.

When `indicator.label` is omitted, it defaults to that same
name. Configured collector indicators are seeded immediately, so prompt and
page status strips show them before the first collector run.

Before a
collector has produced real output it appears as missing.

Prompt output
renders an explicit status glyph in front of the collector icon, so
successful checks show fragments such as `✅🔑` while failing or not-yet-run
checks show fragments such as `🚨🔑`. Under `DD-OOP-LAYERS`, a deeper child layer no longer pins an inherited
collector indicator at that default `missing` placeholder just because the
child runtime has its own `.developer-dashboard/` folder.

If the child layer
does not override that collector config and only has the placeholder state,
dashboard now falls back to the nearest inherited real collector state such
as a parent-layer `ok` result instead of turning the same indicator red.

The top-right browser status strip now uses that same configured icon instead
of falling back to the collector name, and stale managed indicators are
removed automatically if the collector config is renamed. The browser chrome
now uses an emoji-capable font stack there as well, so UTF-8 icons such as
`🐳` and `💰` remain visible instead of collapsing into fallback boxes.

For TT-backed collector icons, a collector such as `./foobar` can print
`{"a":123}` on `stdout`; the runner decodes that JSON into Perl data and
renders `[% a %]` into the live icon `123`.

Later config-sync passes keep
the configured `icon_template` metadata and the already-rendered live
`icon`, so commands such as `d2 indicator list` and `d2 ps1`
do not revert the persisted icon back to raw `[% ... %]` text between runs. The blank-environment integration flow also keeps a regression for mixed
collector health: one intentionally broken Perl collector must stay red
without stopping a second healthy collector from staying green in
`d2 indicator list`, `d2 ps1`, and `/system/status`.

## Docker Compose

Show the Docker command reference without starting or inspecting containers:

    d2 docker --help

Both `d2 docker --help` and `d2 docker --help` print the available
Compose and service-management commands. The shell completion list includes
`compose`, `list`, `enable`, `disable`, and `development`; after
`docker development`, completion offers `enable` and `disable`.

Inspect the resolved compose stack without running Docker:

    d2 docker compose --dry-run config

Include addons or modes:

    d2 docker compose --addon mailhog --mode dev up -d
    d2 docker compose config green
    d2 docker compose config
    d2 docker list
    d2 docker list --disabled
    d2 docker list --enabled
    d2 docker disable green
    d2 docker enable green
    d2 docker development enable green
    d2 docker development disable green

The resolver also supports isolated service folders without adding entries to
dashboard JSON config. If
`./.developer-dashboard/config/docker/green/compose.yml` exists in the current
project it wins; otherwise the resolver falls back to
`~/.developer-dashboard/config/docker/green/compose.yml`. `d2 docker compose config` and operational commands first resolve the
base Compose config, including configured non-service project/addon/mode
files, and read its resulting `services:` map.

Only those service names are
used to discover isolated service folders; a service name appearing only in
the CLI arguments or in an unrelated runtime folder cannot introduce an
overlay. The base config resolution is a real `docker compose config` call,
not a raw YAML parse, so Compose's own includes, interpolation, and merge
rules determine the authoritative list. The selected per-service files are
then layered and materialised before the requested operation runs.

Service names emitted by Compose must be non-empty single path segments;
names containing separators or directory-navigation segments are rejected
before runtime folders are searched. If any matching `config/docker/<service>` directory in the active
runtime layers contains `disabled.yml`, the service is skipped. Each enabled isolated folder
contributes `compose.yml` as its base whenever it exists.

Its optional
`development.compose.yml` is layered after the base only when `develop.yml`
exists in any matching service folder across those layers; without a marker,
the development file is ignored even when present.

If the marker exists but the development
file does not, only the base is loaded and no error is raised. Toggle
development mode without creating or deleting the file manually with
`d2 docker development enable <service>` or
`d2 docker development disable <service>`.

A newly enabled
marker is written under the selected home runtime: `~/.developer-dashboard`
when it exists (or when neither runtime name exists), otherwise `~/.d2`. Disabling development removes every `develop.yml` marker for that service
across active layers.

To toggle the disabled marker without
creating or deleting the file manually, use
`d2 docker disable <service>` or
`d2 docker enable <service>`. The disable toggle uses the same
selected home runtime root.

`d2 docker enable <service>` removes
every `disabled.yml` marker for that service across active layers. To inspect the effective marker state without walking the folders manually,
use `d2 docker list`.

Add `--disabled` to show only disabled
services or `--enabled` to show only enabled services.

If the invocation directory contains `compose.yml`, `compose.yaml`,
`docker-compose.yml`, or `docker-compose.yaml`, those local files are the
base stack and the Compose command runs from that directory. For execution,
the first `docker compose config` runs against the base and other configured
non-service layers.

Its resolved services—not service names guessed from
command arguments—control isolated-service lookup across home, project, and
nested skill runtime roots. The selected service files are added only after
that first config succeeds; disabled folders are excluded and development
files require a matching `develop.yml` marker.

In a dry run, Docker is not
invoked, so the resolver reports a source-based preview instead of a
Compose-resolved service list. This distinction keeps dry-run non-executing
while ensuring real operations follow Compose's own effective service map. If
no local base or explicit Compose file exists but isolated runtime service
files do, the enabled files seed the first config pass to preserve
ecosystem-wide auto-discovery; Compose's resulting service map still controls
the final stack.

For operational actions such as `build`, `up`, and `down`, layered files are
first materialised into a temporary Compose file. The final Compose invocation
also receives the original project directory explicitly, so relative build and
volume paths and the default project identity continue to come from the local
Compose project rather than the temporary file's directory.

An explicit
`--project-directory` supplied by the user is preserved. An undefined Compose
argument or an empty/missing project-directory value is rejected before the
Compose executable is called.

The public helper routes these actions through
the materialising runner (not directly through the unresolved `-f` list),
keeps the temporary merged file until the operation exits, and streams Compose
stdout and stderr normally. This applies to `build`, `up`, `down`, and other
Compose operations; `config` remains available for inspection without starting
containers.

Before saving that merged output, the resolver preserves valid UTF-8 sequences
and converts isolated non-UTF-8 Windows-1252 bytes from the combined inputs to
UTF-8. The temporary file is written as raw bytes only after normalisation, so
the same clean merged YAML is used by `config`, `up`, `down`, `build`,
`ps`, `logs`, and other Compose operations. Undefined Windows-1252 octets
become the Unicode replacement character rather than being written as invalid
UTF-8.

This materialisation also runs when the dashboard resolver found no explicit
layered files. In that case Docker Compose discovers its ordinary base file
from the configured Compose working directory, emits the effective config,
and the requested operation consumes the generated temporary file. This keeps
the UTF-8 normalisation and common execution path consistent for `build`,
`ps`, and other verbs even when no runtime overlay was selected.

During compose execution the dashboard exports `DDDC` as the runtime
`config/docker` directory for the current runtime, so compose YAML can keep using
`${DDDC}` paths inside the YAML itself. Project-local isolated services are
discovered from that same
`./.developer-dashboard/config/docker/<service>/...` tree.

Wrapper flags such as
`--service`, `--addon`, `--mode`, `--project`, and `--dry-run` are
consumed first, and all remaining docker compose flags such as `-d` and
`--build` pass straight through to the real `docker compose` command.

If one resolved service comes from an installed skill docker root, the
resolver also loads that skill's `<skill-root>/.env` file into the compose
environment before docker-config, addon, and mode env overlays are applied. Only skills whose compose service files actually participate are included,
disabled skills are skipped, and `<skill-root>/.env.pl` is not executed from
this compose path.

Nested skill services expand their env chain from the root
nested skill to the participating leaf service, preserving overwritten parent
keys under cumulative aliases such as `foo_VERSION` and
`foo_bar_VERSION` before the leaf value becomes the plain key. The resolver
also exports one skill-specific `<skill-name>_DDDC` variable for each
participating skill, using the leaf skill name with non-identifier characters
normalised to underscores and pointing that variable at the owning
`config/docker/` root.

Nested skill services additionally export the full
cumulative skill path alias such as `foo_bar_zzz_DDDC` for the same compose
root, while the leaf alias stays available as `zzz_DDDC`.

When one or more Compose services are explicitly selected, skill env files
are resolved only for those selected services during interpolation; unrelated
skill service folders cannot replace a selected service's same-named env key
merely because they are enumerated later. If no selected service is present
in the effective base config, or the operation selects no service, env files
for all effective base services are used.

This keeps sequential commands such
as `d2 docker compose up foo` and `d2 docker compose up bar` scoped to the
matching skill env while preserving all-service operations. When `--dry-run` is omitted, the dashboard hands off with `exec` so the
terminal sees the normal streaming output from `docker compose` itself
instead of a dashboard JSON wrapper.

### Publishing Docker Hub images

The repository's master-push workflow publishes a runnable Docker image from
the latest `master` checkout. It first runs the repository `install.sh` to
install the platform tools and Perl environment, then builds a fresh
Dist::Zilla archive from that checked-out source and installs that archive
into the image with `cpanm --notest`.

This final local-archive install deliberately
replaces the version that the bootstrap installer may have fetched from
MetaCPAN, so the image contains the current repository code.

The regular container/release gates run the full test and coverage suites
before publishing. The multi-platform image build skips rerunning those suites
under QEMU for each target architecture; the tarball itself is still installed
and its install is verified separately in a blank Docker environment.

The workflow selects the GitHub Actions environment `release`, whose
secrets `DOCKER_HUB_USER` and `DOCKER_HUB_TOKEN` provide the Docker Hub
credentials. It pushes two tags under `DOCKER_HUB_USER/developer-dashboard`:
the distribution version read from `dist.ini` (for example `5.88`) and
`latest`.

A manual workflow dispatch also builds the current `master`
branch. The image targets `linux/amd64` and
`linux/arm64`; Docker does not support a macOS-kernel image platform, while
Apple Silicon can run the Linux arm64 image using Docker Desktop's Linux VM.

The Ubuntu Linux base image is pinned by its multi-platform manifest digest,
and every GitHub Action dependency is pinned to a full commit SHA.

For example, pull the moving tag or a pinned version:

    docker pull YOUR_DOCKER_HUB_USER/developer-dashboard:latest
    docker pull YOUR_DOCKER_HUB_USER/developer-dashboard:5.88

The container entrypoint is `d2`. The versioned tag is intended for selecting
a known image build; `latest` follows successful master builds.

## Prompt Integration

Render prompt text directly:

    d2 ps1 --jobs 2

`d2 ps1` now follows the original `~/bin/ps1` shape more closely: a
`(YYYY-MM-DD HH:MM:SS)` timestamp prefix, dashboard status and workspace info, a
bracketed working directory, an optional jobs suffix, and a trailing
`🌿branch` marker when git metadata is available. The prompt helper reads the
branch directly from on-disk git metadata instead of shelling out to
`git branch`, so repeated prompt renders stay lightweight on slower hosts such
as iSH.

Working-directory lookup uses `Cwd::getcwd` for the ordinary physical
path; it preserves a distinct logical `$PWD` only after confirming that both
paths identify the same directory.

If the workspace workflow seeded
`WORKSPACE_REF` or the older
`TICKET_REF` into the current tmux session, `d2 ps1` also reads that
context from tmux when the shell environment does not already export it, but it
skips that tmux probe entirely when the shell is not inside tmux. The branch marker preserves every component of a local branch such as
`team/feature`.

If HEAD is detached at a commit that matches an
`origin` remote-tracking ref, the marker shows `origin/team/feature` unless
the same-named local branch points to the same commit; only then is the
redundant `origin/` prefix omitted.

Packed and loose refs are both recognised,
while symlinked refs are not followed. When no matching remote ref exists, it
keeps the short commit id. All generated shell adapters
call this same `d2 ps1` renderer, so the branch label is consistent in
Bash, Zsh, sh, and PowerShell.

Generate shell bootstrap:

    d2 shell bash
    d2 shell zsh
    d2 shell sh
    d2 shell ps

The generated shell helper keeps the same bookmark-aware `cdr`, `dd_cdr`,
`d2`,
and `which_dir` functions across all supported shells. `cdr` first tries a
saved alias, then falls back to an AND-matched directory search beneath the
alias root or the current directory depending on whether that first argument
was a known alias.

One match changes directory, multiple matches print the
list, and `which_dir` prints the same selected target or match list without
changing directory.

The generated prompt adapters handle job counts by shell:

- Bash uses `\j`.
- Zsh refreshes `PS1` through a `precmd` hook.
- POSIX `sh` uses a prompt command without bash-specific escapes.
- PowerShell uses a `prompt` function.

The shell checks compare canonical paths, so equivalent macOS paths such as
`/var/...` and `/private/var/...` are treated as the same location.

`d2` is the command. It is a real, installed command shipped in `bin`, so
you can run `d2 version`, `d2 doctor`, or `d2 docker compose ps` -- in
scripts and fresh shells as well as interactively, without depending on the
shell bootstrap.

The same generated bootstrap also wires live tab completion for `d2`.
Bash registers `_dashboard_complete`, zsh registers
`_dashboard_complete_zsh`, and PowerShell registers
`Register-ArgumentCompleter` for the command name. Completion candidates
come from the live runtime instead of a hardcoded shell list, so built-in
commands, layered custom CLI commands, and installed dotted skill commands
all show up in suggestions.

For bash, the generated helper captures
completion payloads first instead of relying on process substitution, which
keeps completion responsive on macOS and inside packaged install-test shells.

The generated bootstrap also wires `cdr`,
`dd_cdr`, and `which_dir` completion. The first argument suggests saved
aliases plus matching directory names beneath the current directory, and later
arguments suggest matching directory basenames beneath the resolved alias root
or current directory without crashing when one subtree is not readable.

For the POSIX shell bootstrap, the generated helper now decodes its JSON
payloads through the same Perl interpreter that generated the shell fragment
instead of a bare `perl -MJSON::XS ...` call. That keeps `cdr` and
`which_dir` stable on macOS installs where `/usr/bin/perl` and a user-local
`~/perl5` XS stack do not belong to the same Perl build.

The generated
`d2` shortcut re-enters the `d2` script directly instead of
hardcoding the current Perl binary path, so the shortcut still works when the
bootstrap is loaded by a shell whose preferred Perl lives somewhere else.

On Windows, `d2 shell` auto-selects PowerShell by default, and
interpreter-backed runtime entrypoints such as collector `command` strings,
trusted command actions, saved Ajax files, custom CLI commands, hook files,
and update scripts now resolve `.ps1`, `.cmd`, `.bat`, and `.pl`
runners without assuming `sh` or `bash`. That keeps Strawberry Perl installs
usable without requiring a Unix shell just to load the dashboard runtime.

The Windows command launcher also normalises extensionless local `cmd` shims
back to `cmd.exe` so Linux, WSL, and packaging hosts that happen to expose a
helper named `cmd` do not break the expected Windows `.cmd` and `.bat`
dispatch contract during cross-platform tests or tarball installs.

The repository-only Windows verification assets follow the same layered
approach: fast forced-Windows unit coverage in `t/`, a real Strawberry Perl
host smoke in the source checkout, and a host-side rerun helper that delegates
to the QEMU launcher for release-grade Windows compatibility claims. The
supported baseline on Windows is PowerShell plus Strawberry Perl. Git Bash is
optional. Scoop is optional. They are setup helpers, not runtime requirements
for the installed `d2` command.

In the Dockur-backed path, the launcher
stages the Strawberry Perl MSI from the Linux host into the OEM bundle and can
keep multiple retained Windows guests alive on configurable host web/RDP ports
while it reruns the same smoke.

## Browser Access Model

The browser security model follows the original local-first trust concept:

- requests from loopback with a loopback host, such as `127.0.0.1`, `::1`, or `localhost`, are treated as local admin
- requests from loopback with a hostname listed under `web.ssl_subject_alt_names` are also treated as local admin
- requests from non-loopback IPs are treated as helper access
- outsider requests return `401` without a login page until at least one helper user exists
- after a helper user exists, outsider requests receive the helper login page
- helper access requires a login backed by local file-based user and session records
- helper sessions are file-backed, bound to the originating remote address, and expire automatically
- helper passwords must be at least 8 characters long
- state-changing requests are refused with an empty-bodied `403` when `Origin`
or `Referer` names anything other than this dashboard or a trusted local
alias, on every tier
- requests the browser labelled `Sec-Fetch-Site: cross-site` or `same-site` are
refused on **every** method, including `GET`, unless the accompanying
`Origin`/`Referer` names this dashboard or a trusted local alias

This keeps the fast path for loopback-local access while making non-loopback or shared access explicit.

The two cross-site checks above sit at one choke point that runs before trust
tier classification, because the loopback-admin tier authorises on the remote
address alone: there is no cookie in that decision, so `SameSite=Strict`
protects nothing there and any page the operator visits would otherwise reach
an already-authorised dashboard.

The fetch-metadata half covers `GET` because
`GET` is not a safe method on this product — `/ajax/<file>` runs an
operator-written saved handler as a child process from a plain `GET` — while
`Origin` is frequently absent on a `GET` and `Referer` can be suppressed by
the attacking page.

`Sec-Fetch-Site` is set by the browser and is a forbidden
header name, so page script can neither forge nor suppress it. Opening the
dashboard by typed URL or bookmark reports `Sec-Fetch-Site: none` and is
unaffected, as are `curl` and registered `x-dd-api-key` machine consumers,
which send no fetch metadata at all; following a link in from another site is
refused, which is deliberate on a route that executes saved handlers.

The editor and rendered pages also include a shared top chrome with share and
source links on the left and the original status-plus-alias indicator strip on
the right, refreshed from `/system/status`. That top-right area also includes the local username, the current host or IP
link, and the current date/time in the same spirit as the old local dashboard chrome.

The displayed address is discovered from the machine interfaces, preferring a VPN-style address when one is active, and the date/time is refreshed in the browser with JavaScript.

`d2 serve --no-indicators` and `d2 serve --no-indicator` clear that whole top-right browser-only area without changing the terminal prompt or `/system/status`. The bookmark editor also follows the old auto-submit flow, but now it waits
until focus leaves the whole editor form instead of firing every time you move
between section blocks.

For saved bookmark files, that browser save posts back
to the named `/app/<id>/edit` route, while the Play button
recomposes the visible blocks, saves the hidden source payload, and submits the
same form in render mode against `/app/<id>` instead of a transient
`token=` URL, so updates still work while transient URLs are disabled.

Smart-routed skill pages now follow that same browser contract on their
canonical aliases: `/app/<skill>/edit` and nested forms such as
`/app/<skill>/<sub-skill>/edit` load the underlying skill
bookmark source, `/app/<skill>/source` returns the raw skill
bookmark text, and Play keeps the browser on the smart route alias instead of
collapsing to the underlying `BOOKMARK: index` id from the skill file.

Bookmark parsing also treats a standalone `---` line as a section
break, preventing pasted prose after a code block from being compiled into the
saved `CODE*` body.

Saved bookmark loads now also normalise malformed bookmark icon bytes from older files before the
browser sees them. Broken section glyphs fall back to `◈`, broken item-icon
glyphs fall back to `🏷️`, and common damaged joined emoji sequences such as
`🧑‍💻` are repaired so edit and play routes stop showing Unicode replacement
boxes from older bookmark files.

The default web bind is `0.0.0.0:7890`. Trust is still decided from the request origin and host header, not from the listen address.

`DD-OOP-LAYERS` comparisons normalise canonical path identities, so symlinked
aliases such as macOS `/var/...` versus `/private/var/...` do not break
layer discovery, deepest-layer writes, or layered bookmark/nav lookup.
The CLI path helpers follow the same portability rule: commands such as
`d2 path project-root` may surface the canonical filesystem path, and
the supported contract treats macOS aliases such as `/var/...` and
`/private/var/...` as the same project root instead of different repos.

The same portability rule now also applies to the shell-helper and
`locate_dirs_under` regression suites, so equivalent temp roots are compared
by real path identity instead of raw string spelling.

## Runtime Lifecycle

The runtime manager follows the older local-service pattern:

- `d2 serve` starts the web service in the background by default
- On POSIX, background web startup launches the private `web-foreground`
helper through GoRoutine's shell-free process API. The runtime records the
listener only after the configured port accepts connections; if readiness
times out, it terminates and reaps the child and reports its exit status and
log paths.
- `d2 serve` starts the configured collector loops alongside the web
service, so a plain serve keeps collectors and the web runtime under the same
lifecycle action
- `d2 serve --foreground` keeps the web service attached to the terminal
- `d2 serve --ssl` enables HTTPS in Starman with the generated local
certificate and key, keeps that certificate on a browser-correct SAN profile
covering localhost, loopback IPs, the concrete non-wildcard bind host, and any
configured `web.ssl_subject_alt_names`, regenerates older dashboard certs when
they are stale, redirects non-HTTPS requests to the matching `https://...`
URL, and reuses the saved SSL setting on later `d2 restart` runs unless
you override it
- In SSL mode, the public frontend starts `web-ssl-backend-foreground` with
GoRoutine's shell-free OS-process API. Accepted client sockets are handled by
GoRoutine routines using the 0.12 shared filehandle support; shutdown stops
and waits for the backend process and drains client routine errors explicitly.
If a client or listener socket close fails, the frontend retains the first
close error, joins its workers, stops the managed backend, and then reports the
saved error so cleanup is not abandoned at the first failed close.
- On Windows, saved-Ajax `stdout` and `stderr` pipes are drained by one Perl
reader thread per pipe because `IO::Select` cannot reliably report anonymous
pipe readiness there. Chunks and read errors pass through a bounded event
queue; interrupted reads are retried, and a disconnected writer or fatal stream
error terminates the child and joins both readers before returning.
- `d2 serve --no-editor` and `d2 serve --no-endit` keep the
browser in read-only mode by hiding Share, Play, and View Source chrome,
denying `/app/<id>/edit`, `/app/<id>/source`, and
bookmark-save POST routes with `403`, and persisting that read-only flag for
later `d2 restart` runs until `d2 serve --editor` turns it back
off
- `d2 serve --no-indicators` and `d2 serve --no-indicator` keep
normal page rendering and left-side page chrome intact while clearing the
whole top-right browser-only chrome area, including the status strip,
username, host or IP link, and live date-time line, and persisting that flag
for later `d2 restart` runs until `d2 serve --indicators`
turns it back off
- `d2 serve logs` prints the web-service runtime log captured in the
d2 log file. `-t` prefixes lines with UTC timestamps, `--tail N`,
`--tail=N`, and `-n N` limit the initial output, and `-f` follows appended
lines. For example, `d2 serve logs -t --tail 100 -f` starts with the
final 100 lines and then follows new output.
- `d2 serve workers N` saves the default Starman worker count and starts
the web service immediately when it is currently stopped; `--host HOST` and
`--port PORT` can steer that auto-start path, and both
`d2 serve --workers N` and `d2 restart --workers N` can still
override the worker count for one run
- `d2 stop` stops both the web service and managed collector loops and,
prints the final lifecycle summary as a terminal table by default or JSON with
`-o json`; on an interactive terminal it also prints the full stop task board
on `stderr` before work starts so each shutdown step becomes visible instead
of silent waiting.

    The shutdown path now also follows the saved managed
    listener port back to the real listener pid when the live web process has
    renamed itself into a `starman master` shape, so minimal Docker runs still
    stop the actual serving process instead of leaving the listener behind.

    Managed collector stop and restart flows also wait for the previous loop to
    really die before accepting a replacement, so a slow shutdown does not leave a
    stale collector process rewriting loop state while the next restart is proving
    the new pid.

- `d2 stop web` only stops the managed web service
- `d2 stop collector` only stops managed collector loops
- `d2 stop collector <name>` only stops the requested managed
collector loop, and collector-name shell completion suggests registered
collector names
- `d2 restart` stops both, starts configured collector loops again, then
starts the web service, prints the final lifecycle summary as a terminal table
by default or JSON with `-o json`, and only reports success after the
replacement collector loops and web runtime become visible and survive a short
post-ready confirmation window, with the web side still holding a live managed
pid and an accepting listener on the requested port.

    Restart now also reuses
    the saved listener port to recover the real serving pid when the web process
    has renamed itself into the underlying `starman master` form, so container
    restarts still own and replace the active listener instead of losing control
    after startup. On Linux hosts that are also running Developer Dashboard inside
    Docker containers, managed stop and restart paths now reject sibling runtime
    pids that live in a different Linux pid namespace, so a host-side restart does
    not accidentally kill or adopt a container-owned web listener or collector
    loop

- `d2 restart web` only restarts the managed web service
- `d2 restart collector` only restarts managed collector loops
- `d2 restart collector <name>` only restarts the requested
collector loop, including an on-demand manual collector by converting it into
a managed interval loop, and collector-name shell completion suggests
registered collector names
- managed collector loops also run under a watchdog supervisor; if a loop dies
unexpectedly after startup, the watchdog restarts it automatically, records
the restart attempt in collector status/logs, and after too many crashes
inside the watchdog window marks the collector `attention_required` so the
operator sees an explicit problem instead of infinite silent restart churn
- `d2 log` and `d2 logs` print the combined dashboard web log
plus collector logs
- `d2 logs --tail 100` or `d2 logs --tail=100` prints only the
last 100 lines of the combined output. The same `--tail` option accepts both
spellings for `d2 log web`, `d2 log collector`, and a named
collector log. `-n N` remains a compatible short form. `--tail=0` prints no
lines; negative or non-integer counts are rejected with usage information.

    `-t` prefixes each displayed line with a UTC timestamp. Collector output uses
    the recorded run timestamp; raw web output, which has no stored per-line event
    time, uses the time it is read. `-f` follows new lines from web logs, one
    collector, all collectors, or the combined view. Flags may be combined, so
    `d2 logs -f -t --tail 50` starts with the last 50 combined lines and
    continues following both sources.

- `d2 log web` prints only the dashboard web log and supports `-t`,
`--tail N`, `--tail=N`, `-n N`, and `-f`
- `d2 log collector` prints only collector logs and accepts `-t`,
`-f`, and the same trailing-line limit
- `d2 log collector <name>` prints only the requested collector
log, accepts `-t`, `-f`, `--tail N`, and `--tail=N`, and collector-name
shell completion suggests registered collector names
- interactive restart and stop task boards mark the active step with a blue
`-`, stream active detail lines in blue, mark completed steps with a green
`[OK]`, mark failed steps with a red `[X]` plus red failure detail lines,
keep the final table or JSON summary on `stdout`, and use numeric POSIX
shutdown signals so minimal Alpine/iSH Perl builds that reject `TERM` by
name still terminate managed web and collector processes correctly
- web shutdown and duplicate detection do not trust pid files alone; they validate managed processes by environment marker or process title and use a `pkill`-style scan fallback when needed
- When a collector pid file is missing, duplicate detection checks both the
process table and the parent-written loop state. That state closes the short
startup interval before a newly forked supervisor adopts its process title, so
a concurrent start does not fork a second loop.

## Environment Customisation

After installing with `cpanm`, the runtime can be customised with these environment variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`

    Overrides the saved page or bookmark directory.

- `DEVELOPER_DASHBOARD_CHECKERS`

    Limits enabled collector or checker jobs to a colon-separated list of names.

- `DEVELOPER_DASHBOARD_CONFIGS`

    Overrides the config directory.

- `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS`

    Allows browser execution of transient `/?token=...`, `/action?atoken=...`,
    and older `/ajax?token=...` payloads. The default is off, so the web UI only
    executes saved bookmark files unless this is set to a truthy value such as
    `1`, `true`, `yes`, or `on`.

Collector definitions come only from dashboard configuration JSON, so config
remains the single source of truth for path aliases, providers, collectors,
and Docker compose overlays.

## Updating Runtime State

Run your user-provided update command:

    d2 update

If `./.developer-dashboard/cli/update` or
`./.developer-dashboard/cli/update/run` exists in the current project it is
used first; otherwise the home runtime fallback is used. `d2 update`
runs that command after any sorted hook files from `update/` or `update.d`.

Re-running `d2 init` keeps an existing
`~/.developer-dashboard/config/config.json` intact. If the file is missing,
init creates it as `{}`. The command refreshes dashboard-managed helpers in
`~/.developer-dashboard/cli/dd/` and preserves user-owned saved pages.

When `d2 init` refreshes a dashboard-managed helper or shipped
starter file, it compares the existing content against the shipped content by
MD5 inside Perl first. If the content already matches, init skips the copy
instead of rewriting the file unnecessarily.

When bookmark `HTML:` or shared `nav/*.tt` fragments hit a Template Toolkit
syntax error, render mode now shows a visible `runtime-error` block instead
of leaking the raw `[% ... %]` source into the browser or
`d2 page render` output.

Home helper staging is non-destructive too. `d2 init` may add or
update dashboard-managed built-in helpers only under
`~/.developer-dashboard/cli/dd/`. User commands and hook directories stay in
`~/.developer-dashboard/cli/` and in child-layer
`./.developer-dashboard/cli/` roots, and init must not overwrite or delete
those user-space files while refreshing the home-only dd namespace.

The public `d2` entrypoint also stays thin for all built-in commands. It only stages and execs helper assets from `share/private-cli/`: dedicated
helper bodies for `d2 jq`, `d2 yq`, `d2 of`,
`d2 open-file`, `d2 workspace`, `d2 path`,
`d2 paths`, `d2 file`, `d2 files`, and
`d2 ps1`, plus thin wrappers for the
remaining built-ins that hand off to the shared private
`_dashboard-core` runtime.

The shipped starter bookmark source lives under
`share/seeded-pages/`, and the shipped helper scripts live under
`share/private-cli/`, so neither bookmark bodies nor helper script bodies
are embedded directly in the command script. Installed copies resolve the same seeded pages and helper assets from the
distribution share directory, so `d2 init` works after a `cpanm`
install and not just from a source checkout.

Those helper-backed built-ins
also rewrite their live process title to `developer-dashboard ...`, so
process listings stay aligned with the public command names instead of
exposing the staged helper path.

When `d2` re-execs a Perl-backed helper or hook, it also forces the
same active dashboard `lib/` root into that child Perl process. That keeps
thin switchboard handoff on the current checkout code instead of drifting onto
an older installed `Developer::Dashboard` copy that may also be visible in
`PERL5LIB`.

`d2 cpan <Module...>` installs optional Perl modules into the
active runtime-local `./.developer-dashboard/local` tree and appends matching
`requires 'Module';` lines to `./.developer-dashboard/cpanfile`.

The command
stays implemented in the d2 entrypoint rather than introducing a
separate CPAN manager product module, and saved Ajax workers infer the
same runtime-local `local/lib/perl5` path directly from the active runtime
root. When the requested modules include `DBD::*`, the command also installs
and records `DBI` automatically so generic database driver requests work with
a single command.
per-database notes for that workspace.

## Skills System

Extend dashboard with isolated skill packages:

Install a skill from either a Git repository URL or a local checked-out skill
repository:

    d2 skills install browser
    d2 skills install foo/bar
    d2 skills install git@github.com:user/example-skill.git
    d2 skills install https://github.com/user/example-skill.git
    d2 skills install /absolute/path/to/example-skill
    d2 skills install --notest browser
    d2 skills install -b main git@github.com:user/example-skill.git
    d2 skills install browser foo/bar git@github.com:user/example-skill.git
    d2 skills install --ddfile
    d2 skill list

Bare one-word skill names are expanded against the official
`https://github.com/manif3station/` GitHub base, so
`d2 skills install browser` clones
`https://github.com/manif3station/browser`. Two-part `owner/repo`
shorthand is expanded against GitHub too, so
`d2 skills install foo/bar` clones `https://github.com/foo/bar`.

Full URLs such as `https://github.com/user/example-skill.git` and
`git@github.com:user/example-skill.git` are used exactly as supplied. Use `-b <branch>` or `--branch <branch>` to select a remote
Git branch explicitly.

For a new checkout without this option, the installer
tries `master` first and `main` second. On a reinstall, it keeps the named
branch currently checked out in the installed skill directory unless an
explicit `-b` overrides it.

A detached checkout has no named branch to keep,
so the normal `master` then `main` selection is used. The branch option is
for remote Git sources; it is rejected for local directory and `--ddfile`
installs rather than being silently ignored.

When a skill contains `ddfile` or `ddfile.local` but no dependency install is
needed, the progress label says so; it reports the manifest as missing only
when that file is actually absent. Multiple explicit sources can be supplied to one install command.

Developer
Dashboard installs them in the order given, prints a progress rundown before
work starts, and registers every source once. The default install summary is a terminal table with each skill's `.env`
`VERSION` before and after the install.

Use `-o json` when a script needs the
raw result payload.

`d2 skill` is
accepted as a singular alias for the `d2 skills` management command
family, so `d2 skill list` and `d2 skill install browser` are
equivalent to the plural form. It does not replace dotted skill execution;
installed skill commands still run as `d2 <skill>.<command>`.

For Perl commands, the `lib/` directory of the skill layer providing the
command is the first module search path in the child process `@INC`. Other
participating skill libraries follow it, then shared local libraries.

For
`/app/<skill>/<page>` pages, CODE blocks similarly place the
exact skill layer supplying the page first in their scoped `@INC`, followed
by the remaining skill layers. A skill can therefore use a module such as
`DB.pm` with `use DB;` without adding a manual library path.

Git sources are cloned. Direct local checked-out directories are synced in
place instead of recloned, using `rsync` when it is available and the
built-in Perl tree-copy fallback when it is not. That means
`d2 skills install` also acts as reinstall and update for an already
installed skill.

A direct local directory is only accepted when it is a
checked-out Git repository with a `.git/` directory plus a `.env` file that
declares `VERSION=...`; otherwise the install is rejected. The installed
copy lives in its own isolated skill root under the deepest participating
`DD-OOP-LAYERS` runtime.

In a home-only session that is
`~/.developer-dashboard/skills/<repo-name>/`. In a deeper project
layer that already has its own `.developer-dashboard/`, the install target
becomes
`<that-layer>/.developer-dashboard/skills/<repo-name>/`. Each explicit `d2 skills install <source>`, including every
source in a multi-source command, also registers that exact source in
`~/.developer-dashboard/ddfile` unless it is already listed there.

When
`~/.developer-dashboard/.gitignore` already exists, the install also adds
`skills/<repo-name>/` for each installed skill without duplicating
existing entries, so users who keep the dashboard runtime in Git do not
accidentally track cloned skill trees. The installer also honors an existing
`~/.developer-dashboard/.gitiignore` spelling as a compatibility safety net.

Calling bare `d2 skills install` with no source reads that root
`ddfile` and reinstalls every listed skill as an update batch, showing the
same progress rundown and before/after version table.

If no listed skill
changes version, the summary explicitly says `No update.`. First-time installs
from that root `ddfile` still report `installed` even when the skill ships no
`.env` `VERSION` metadata. If the root `ddfile` does not exist yet or has no
installable entries, the command returns an explicit error telling the user to
install a skill first or pass a skill source.

When an operator later runs
`d2 skills uninstall <repo-name>`, the home root
`ddfile` now drops any exact source lines that resolve back to that repo name
while leaving comments and unrelated entries untouched.

Long-running dependency manifests now show a Docker-build-style live detail
window under the active epic task. That rolling window keeps the newest ten
detail lines from tools such as `brew`, `npx npm install`, `cpanm`, and
`make`, collapses automatically when the task completes, and leaves the full
epic checklist visible while the active manifest streams.

Developer Dashboard does not merge the skill's `cli/`, `dashboards/`,
`config/`, `ddfile`, `ddfile.local`, `aptfile`, `apkfile`, `dnfile`,
`wingetfile`, `brewfile`, `Makefile`, `dockerfile`, `package.json`, `cpanfile`,
`cpanfile.local`, or Docker files into the
normal runtime folders.

`d2 skills install --ddfile` reads dependency manifests from the
current directory instead of taking one explicit skill source. If `ddfile`
exists there, each listed source installs into the base home-layer skills root
at `~/.developer-dashboard/skills/<repo-name>/` even when the command
is run inside a deeper child `.developer-dashboard/` layer.

If `ddfile.local`
exists there, each listed source installs into the current directory's nested
`skills/<repo-name>/` tree instead. When both manifests are present,
the command processes `ddfile` first and `ddfile.local` second.

Repeated
`d2 skills install --ddfile` runs also act as reinstall and refresh
for already-installed targets, just like repeated explicit
`d2 skills install <source>` runs. Interactive `d2 skills install` runs also print a task board on
`stderr`; multi-source and bare update-all installs show one task for every
source before any clone or dependency step starts.

For a single skill, the
board begins with fetch and layout only, then appends dependency tasks after
the fetched skill root has been inspected.

A dependency row appears only when
the matching manifest file really exists, and operating-system-specific rows
such as `aptfile`, `apkfile`, `dnfile`, `wingetfile`, and `brewfile`
appear only on matching host families.

When a single skill ships dependency
manifests such as `package.json` or `Makefile`, the matching task updates to
show the detected file path so a long-running `npm`, `make`, `cpanm`, or
package-manager step stays visible instead of looking blind, with a rolling
detail window that keeps the newest progress lines under the active task in
blue and leaves failure detail lines visible in red when a manifest step stops
with an error.

Installed dotted skill commands such as `d2 demo-skill.foo` now hand
control to the real skill command after hook processing instead of wrapping
the main command in an extra capture layer. That keeps interactive prompting
behaviour intact for commands that print a prompt and then read from standard
input.

Skill lookup also follows `DD-OOP-LAYERS`, but a same-named deeper skill is
now layered instead of flattening the whole repo. The home
`~/.developer-dashboard/skills/<repo-name>/` checkout is the base
layer, and any deeper
`.developer-dashboard/skills/<repo-name>/` checkout becomes an
inherited layer for that same skill.

Runtime lookup walks those
participating skill layers for `cli/<command>`,
`cli/<command>.d`, `dashboards/*`, `dashboards/nav/*`,
`config/config.json`, and `perl5/lib/perl5`.

If a child layer omits a file,
folder, or config key, lookup falls back to the base layer. If multiple
layers provide the same file or config key, the deepest layer still wins that
override.

List installed skills:

    d2 skills list
    d2 skills list -o json

The default output is a padded table with the columns `Repo`, `Enabled`,
`CLI`, `Pages`, `Docker`, `Collectors`, and `Indicators`. The
`Enabled` column prints the readable values `enabled` or `disabled` so the
table stays aligned and copied terminal output stays unambiguous.

Use `-o json` when you want structured output. It returns a `skills` array
where each item reports:

- repo name
- installed path
- `enabled` as a JSON boolean
- CLI command, page, docker service, collector, and indicator counts
- JSON booleans for `has_config`, `has_ddfile`, `has_aptfile`,
`has_apkfile`, `has_dnfile`, `has_brewfile`, `has_cpanfile`,
`has_cpanfile_local`, `has_makefile`, and `has_dockerfile`

Inspect one installed skill:

    d2 skills usage example-skill
    d2 skills usage example-skill -o json

The default output is a readable multi-section summary. It still returns the
installed skill state even when the skill is disabled, including:

- CLI commands plus whether each command has hooks and how many
- bookmark pages and `dashboards/nav/*` entries
- docker service folders and the files inside each one
- the merged config key such as `_example-skill`
- declared collectors, their repo-qualified names, and indicator metadata

Use `-o json` when you need the full machine-readable payload for the same
usage data.

Update registered skills to their latest versions:

    d2 skills install

Disable a skill without uninstalling it:

    d2 skills disable example-skill

Disabling keeps the checkout in its current layered skills root but removes it
from normal runtime lookup. That means:

- `d2 <repo-name>.<command>` stop dispatching into that
skill
- `/app/<repo-name>` and `/app/<repo-name>/<page>`
stop serving that skill's pages
- skill collectors, docker roots, config, and shared nav stop joining the
active runtime
- `d2 skills list` and
`d2 skills usage <repo-name>` still report the installed skill
so it can be inspected and re-enabled later

Enable a previously disabled skill:

    d2 skills enable example-skill

Enabling removes the local disabled marker and restores the skill to command
dispatch, browser routes, collector loading, docker lookup, config merge, and
shared nav rendering.

Execute a skill command:

    d2 example-skill.somecmd arg1 arg2

The dotted form is the public route. If `example-skill` is installed and
ships `cli/somecmd`, `d2 example-skill.somecmd` resolves the correct
layered skill command. If the active child layer for that same repo omits
`cli/somecmd`, the command falls back to the nearest inherited skill layer
that still provides it.

That same dotted dispatch also applies to runtime-backed command files such as
`cli/report.py` and `cli/webhook.js`. In those cases the resolved skill
command still runs through the same public `d2 <skill>.<command>`
route, with Python-backed files launched through `python` and JavaScript-backed
files launched through `node`.

If the skill command itself lives below nested
`skills/<repo>/.../skills/<repo>` trees, the same dotted
public form keeps walking those nested skill roots until it resolves the final
`cli/<cmd>` file. For example:

    d2 nest.level1.level2.here
    d2 which nest.level1.level2.here

The first command executes the nested skill command. The second prints the
resolved nested `cli/here` file plus any matching hook files that would run
before it.

Nested skill trees under `skills/<repo>/cli/` stay reachable through
that same public dotted route, including multiple nested levels. For example,
if `example-skill` ships `skills/foo/skills/bar/cli/baz`, then
`d2 example-skill.foo.bar.baz` resolves the nested command through the
installed skill tree.

A nested skill can also expose its default command as `cli/__init__` (with any
supported executable extension). Naming that nested skill directly invokes
its initializer, including at multiple nested levels:

    d2 example-skill.foo
    d2 example-skill.foo.bar

When a deeper nested skill has its own initializer, it takes precedence over
an ancestor skill's generic initializer. Explicit command files are resolved
before initializer fallbacks, so a real command is never shadowed by
`__init__`.

isolated skill root, runs sorted hooks from `cli/somecmd.d/`, and then runs the
main command.

Uninstall a skill:

    d2 skills uninstall example-skill

Each installed skill lives under
`<participating-layer>/.developer-dashboard/skills/<repo-name>/`
with:

- **cli/**

    Skill commands (executable scripts, never installed to system PATH)

- **cli/&lt;cmd>.d/**

    Hook files for commands (sorted pre-command hooks)

- **dashboards/**

    Skill-shipped pages, including `dashboards/index`

- **dashboards/nav/**

    Skill nav fragments and bookmark pages loaded into
    `/app/<repo-name>` routes and into the shared nav strip rendered
    above normal saved `/app/<page>` routes such as `/app/index`

- **config/config.json**

    Skill-local JSON config, merged into runtime config under
    `_<repo-name>`. Any declared `collectors` join the managed fleet
    under repo-qualified names such as `example-skill.status`

- **config/api.json**

    Skill-local machine auth config for selected `/ajax/...` routes. Entries merge
    through the same skill-layer contract, keep SHA-256 secret digests plus exact
    saved Ajax route lists, and allow remote callers to send `X-DD-API-Key` plus
    `X-DD-API-Secret` instead of a helper session for those registered saved Ajax
    handlers.

- **config/docker/**

    Skill-local Docker Compose roots that participate in layered docker service lookup

- **state/**

    Persistent skill state and data

- **logs/**

    Skill output logs

- **ddfile**

    Optional dependent skill list installed after package managers run

- **ddfile.local**

    Optional skill-private dependent skill list installed after `ddfile` into the
    owning skill's `skills/<repo-name>/` tree, separate from the runtime-wide
    skill inventory

- **aptfile**

    Optional Debian-family system packages installed through
    `sudo apt-get install -y` after Dashboard checks each listed package and
    keeps only the missing packages in the install request

- **brewfile**

    Optional macOS Homebrew packages installed through `brew install`

- **wingetfile**

    Optional Windows packages installed through `winget install --id ... --exact
    \--accept-package-agreements --accept-source-agreements --disable-interactivity`

- **Makefile**

    Optional skill install workflow run before `ddfile`, using `make`,
    `make test` when a `test` or `tests` target exists unless
    `d2 skills install --notest` is used, `make install`, and
    `make clean` when a `clean` target exists

- **dnfile**

    Optional Fedora system packages installed through
    `sudo dnf install -y` after Dashboard checks each listed package and keeps
    only the missing packages in the install request

- **package.json**

    Optional Node dependencies installed into `$HOME/node_modules` by running
    `npx --yes npm install <dependency-spec...>` inside a private dashboard staging
    workspace and then merging the resulting packages into
    `$HOME/node_modules`

- **requirements.txt**

    Optional Python dependencies installed through
    `python -m pip install --user --requirement requirements.txt`

- **cpanfile**

    Optional shared Perl dependencies installed into `~/perl5`

- **cpanfile.local**

    Optional skill-local Perl dependencies installed into
    `<skill-root>/perl5`

Skills are completely isolated from the main dashboard runtime and from other
skills. Removing a skill is simple: `d2 skills uninstall <repo-name>`
cleanly removes only that skill's directory and unregisters matching install
sources from the home root `ddfile`.

Hook lifecycle details:

- hooks run in sorted filename order from `cli/<command>.d/`
- each hook result is appended to `RESULT`
- the immediately previous hook payload is exposed through `LAST_RESULT`
- oversized hook payloads spill into `RESULT_FILE` or
`LAST_RESULT_FILE` before later skill hook or command execs would hit the
kernel arg/env limit
- executable `.py` hooks run through `python`
- executable `.js` hooks run through `node`
- executable `.go` hooks run through `go run`
- executable `.java` hooks compile with `javac` and then run through `java`
- later hooks are skipped only when a hook writes the explicit marker
`[[STOP]]` to `stderr`
- ordinary non-zero exit codes are recorded but do not act like an implicit stop
request

### Additional Skill Behaviour

When `~/.developer-dashboard/.gitignore` exists, skill installs add
`skills/<repo-name`/> entries without duplication so cloned skill trees stay
out of the tracked runtime tree.

Skill-shipped pages mount under app-style routes such as
`/app/<repo-name`> and `/app/<repo-name`/&lt;page>>.

Under `DD-OOP-LAYERS`, same-name skills shadow by the deepest matching repo
name while missing files still fall back to the base skill layer.

Skill fleet integration:

- collectors declared in a skill `config/config.json` join the same managed
fleet used by the system config
- `d2 serve`, `d2 restart`, and `d2 stop` manage those
skill collectors together with the system-owned collectors
- skill collector names are normalised to
`<repo-name>.<collector-name>` so collector process titles,
status rows, and indicator state stay unambiguous
- indicator configuration attached to those skill collectors participates in the
normal prompt and browser status flow
- disabled skills are excluded from that fleet until they are re-enabled

Skill browser routes:

- `/app/<repo-name>` renders `dashboards/index`
- `/app/<repo-name>/<page>` renders `dashboards/<page>`
- nested child skills under `skills/<repo-name>/` extend those same
routes, so `/app/<repo-name>/<sub-skill>` renders that child
skill's `dashboards/index` and
`/app/<repo-name>/<sub-skill>/<page>` renders that
child skill's `dashboards/<page>`
- skill-local ajax handlers under `dashboards/ajax/*` resolve at
`/ajax/<repo-name>/...` and nested child skills extend that prefix as
`/ajax/<repo-name>/<sub-skill>/...`. Optional
`config/routes.json` metadata can also publish canonical custom ajax
paths such as `/v1/status`, but the smart
`/ajax/<repo-name>/...` resolver stays the parent route and custom
paths are fallback-only after smart route lookup misses
- runtime-level `config/routes.json` aliases can also point at normal saved
bookmark ids such as `/app/learn.ai` plus the built-in `/ajax/...`,
`/js/...`, `/css/...`, and `/others/...` route families, so one dashboard
runtime can expose shorter stable public paths like `/java` without changing
the underlying saved filename
- skill-local static assets under `dashboards/public/js/*`,
`dashboards/public/css/*`, and `dashboards/public/others/*` resolve at
`/js/<repo-name>/...`, `/css/<repo-name>/...`, and
`/others/<repo-name>/...`, with nested child skills extending those
same prefixes under `/js/.../<sub-skill>/...`,
`/css/.../<sub-skill>/...`, and `/others/.../<sub-skill>/...`.

    Optional `config/routes.json` metadata can also publish canonical custom
    `/js`, `/css`, and `/others` paths for those same assets, but the smart
    `/js/...`, `/css/...`, and `/others/...` routes still stay the parent
    resolvers and custom paths remain fallback-only after the smart lookup misses

- the installed web server uses the same smart longest-prefix dispatcher for
those `/app`, `/ajax`, `/js`, `/css`, and `/others` routes, so installed
skill-local pages, Ajax handlers, and public assets work through the shipped
PSGI route layer without being copied into the shared dashboard roots
- `dashboards/nav/*` is loaded into those skill app routes and into the shared
nav strip above normal saved `/app/<page>` routes such as
`/app/index`, so every installed skill can contribute top-level nav at once.
Nested installed skills under repeated `skills/<repo>` trees also
join that shared nav discovery path, which means a route such as
`/app/ho/coverage` can pick up nav fragments from
`skills/ho/skills/coverage/dashboards/nav/*` in addition to the top-level
skill nav
- the older `/skill/<repo-name>/bookmarks/<id>` route still works for direct bookmark rendering
- disabled skills drop out of both the dedicated skill routes and the shared nav
strip until they are re-enabled

Skill dependency and docker layering:

- if a `ddfile` exists, each listed dependency is installed after package and
language dependency manifests through
`d2 skills install <dependency>` while already-installed or
in-flight skills are skipped to avoid loops
- if a `ddfile.local` exists under an installed skill, each listed dependency
is then installed into that owning skill's private
`skills/<repo-name>/` tree, separate from the runtime-wide skills
inventory
- if an operator runs `d2 skills install --ddfile` inside a directory
that contains `ddfile`, every listed source is reinstalled or refreshed into
the base `~/.developer-dashboard/skills/` root
- if that same directory also contains `ddfile.local`, every listed source is
then reinstalled or refreshed into the current directory's nested
`skills/<repo-name>/` tree after the global `ddfile` pass completes
- if an `aptfile` exists on a Debian-family host, Dashboard checks each listed
package first and only prints and installs the packages that are still missing
through `sudo apt-get install -y`; interactive progress output only shows this
row when both the manifest exists and the host is Debian-family
- if an `apkfile` exists on an Alpine host, Dashboard checks each listed
package first and only prints and installs the packages that are still missing
through `sudo apk add --no-cache`; interactive progress output only shows this
row when both the manifest exists and the host is Alpine
- if a `dnfile` exists on a Fedora host, Dashboard checks each listed package
first and only prints and installs the packages that are still missing through
`sudo dnf install -y`; interactive progress output only shows this row when
both the manifest exists and the host is Fedora
- if a `wingetfile` exists on a Windows host, Dashboard installs each listed
package id through `winget install --id ... --exact
--accept-package-agreements --accept-source-agreements
--disable-interactivity`; interactive progress output only shows this row when
both the manifest exists and the host is Windows
- if a `brewfile` exists on macOS, its package list is printed and then
installed through `brew install`; interactive progress output only shows this
row when both the manifest exists and the host is macOS
- if a `Makefile` exists, Dashboard runs it after the Perl dependency
manifests and before any deferred `ddfile` processing, using `make`,
`make test` when a `test` or `tests` target exists unless
`d2 skills install --notest` was requested, `make install`, and
`make clean` when a `clean` target exists; interactive progress output only
shows this row when the file exists
- if a `package.json` exists, its Node dependencies are installed into
`$HOME/node_modules` by running `npx --yes npm install <dependency-spec...>`
inside a private dashboard staging workspace and then merging the resulting
packages into `$HOME/node_modules`, so unrelated `$HOME/package.json` files
do not break skill installs; interactive progress output only shows this row
when the file exists
- if a `requirements.txt` exists, its Python dependencies are installed through
`python -m pip install --user --requirement requirements.txt` from the skill
root before the Perl dependency manifests run; interactive progress output only
shows this row when the file exists
- if a `cpanfile` exists, its Perl dependencies are installed into `~/perl5`;
interactive progress output only shows this row when the file exists
- if a `cpanfile.local` exists, its Perl dependencies are installed into the
skill-local `perl5/` tree; interactive progress output only shows this row
when the file exists
- skill `config/docker/...` roots participate in docker service discovery after
the home runtime `config/docker` root and before deeper project-layer
`config/docker/...` overrides
- disabled skills are skipped by docker root discovery until they are
re-enabled

### Skill Authoring

To build a new skill, start with a Git repository that contains `cli/`,
`config/config.json`, optional `config/api.json`, and optional `dashboards/`, `dashboards/nav/`,
`state/`, `logs/`, `ddfile`, `ddfile.local`, `aptfile`, `apkfile`,
`dnfile`,
`brewfile`, `Makefile`, `package.json`, `requirements.txt`, `cpanfile`, and `cpanfile.local` files under the skill
root.

Skill commands are file-based
commands run through the dotted
`d2 <repo-name>.<command>` form.

Skill hook files live
under `cli/<command>.d/`, skill app pages render from
`/app/<repo-name>` and `/app/<repo-name>/<id>`, and
the older `/skill/<repo-name>/bookmarks/<id>` route still
resolves direct bookmark renders. If `config/config.json` declares
collectors, those collectors join the normal managed fleet under
repo-qualified names such as `example-skill.status`, which means
`d2 serve`, `d2 restart`, and `d2 stop` treat them the
same way they treat system-owned collectors.

If `config/api.json` declares API
clients, those entries join the layered machine-auth allowlist for exact
saved `/ajax/...` route paths owned by that skill.

The repository also ships a dedicated skill authoring guide, and the installed
reference is available through the POD module
`Developer::Dashboard::SKILLS`.

Together they cover the isolated skill layout, environment variables such as
`DEVELOPER_DASHBOARD_SKILL_ROOT`, bookmark syntax such as `TITLE:` and
`CODE1:`, browser helpers such as `fetch_value()` and `stream_data()`, and
configuration merge keys such as `_example-skill`.

The guide describes automatic dependency installation order:
`aptfile -` apkfile -> dnfile -> wingetfile -> brewfile -> package.json -> requirements.txt -> cpanfile -> cpanfile.local -> Makefile -> ddfile -> ddfile.local>.
The explicit `d2 skills install --ddfile` option handles the deferred
`ddfile -` ddfile.local> pass separately.

It also explains shared and skill-local dependency directories, the install
targets used for Node and Python packages, optional Makefile commands, Docker
layering, and when to use dashboard-wide command hooks instead of skill-local
hooks.

Skill dashboard CODE blocks and saved skill Ajax handlers load the active
skill's root-to-leaf `.env` and `.env.pl` files. For example,
`print $ENV{FOO}` in either path can read `FOO=BAR` from that skill's
`.env`. Page values are request-local and saved Ajax values are passed only to
the child process; neither leaks into the long-lived web worker or other
requests.

For operators rather than authors, `d2 skills list`,
`d2 skills usage <repo-name>`,
`d2 skills disable <repo-name>`, and
`d2 skills enable <repo-name>` are the supported controls for
inventorying and toggling installed skills without deleting their isolated
runtime trees.

# FEATURE REFERENCE

## Shared Nav Fragments

If `nav/*.tt` files exist under the saved bookmark root, every non-nav page
render includes them between the top chrome and the main page body.

For the default runtime that means files such as:

- `~/.developer-dashboard/dashboards/nav/foo.tt`
- `~/.developer-dashboard/dashboards/nav/bar.tt`

And with route access such as:

- `/app/nav/foo.tt`
- `/app/nav/foo.tt/edit`
- `/app/nav/foo.tt/source`

The bookmark editor can save those nested ids directly, for example
`BOOKMARK: nav/foo.tt`. Raw TT/HTML fragment files under `nav/` also work
without bookmark wrappers, for example:

    [% index = '/app/index' %]
    <a href=[% index %]>[% index %]</a>

On a page like `/app/index`, the direct `nav/*.tt` files are loaded in
sorted filename order, rendered through the normal page runtime, and inserted
above the page body. Non-`.tt` files, subdirectories under `nav/`, and junk
files that do not look like TT or HTML fragments are ignored by that shared
nav renderer.

Under `DD-OOP-LAYERS`, the shared nav renderer now scans every inherited
`dashboards/nav/` layer from `~/.developer-dashboard` down to the current
directory, keeps parent-only fragments visible, and lets a deeper layer
replace the same `nav/<name>.tt` id without losing the rest of the
shared nav set. Template includes used by those bookmarks follow the same
layered bookmark lookup path.

Installed skill nav also follows nested
`skills/<repo>/skills/<child>/...` trees now, so a nested
skill can contribute `dashboards/nav/index.tt` or other shared fragments
without being flattened back into only the first installed-skill level.

The web application keeps a per-instance inventory of the discovered nav
fragment ids so unchanged directories are not enumerated on every request.
The inventory is reused only while each ordered `nav/` directory retains the
same high-resolution filesystem identity and metadata signature.

Adding or
removing a fragment changes that signature and refreshes the next request.
Only the filename inventory is reused: every fragment's contents are loaded
and rendered for each request, so edits remain visible without an ID rescan.

Merged runtime configuration is also cached between web requests when the
native filesystem watcher is active. Before reusing a cached configuration,
the worker checks high-resolution metadata for watched roots and exact config
files as well as the watcher and environment signatures. This catches atomic
config-file replacement immediately, even if a macOS filesystem event has not
yet been delivered. If native watching is unavailable, the portable validator
also hashes config contents so same-size edits remain visible. A fresh merge
is cached only when the before-and-after signatures still match; filesystem
inspection and read failures remain explicit.

Missing nav directories continue to contribute no items; an incomplete
directory scan is not cached, and filesystem stat, read, or close failures
remain explicit.

Saved-page lookup selects the first existing layered candidate, then the
secure-read path performs the containment check immediately before its
no-follow open. Candidate lookup does not repeat that same resolved-path check
earlier; both normal page reads and raw-entry reads still use the guarded open.

For one web request, ordered candidate roots are discovered lazily once and
shared by its saved-page loads; a later request receives a fresh root list.
Direct PageStore calls outside a web request do not retain a root snapshot.

Shared nav fragments and normal bookmark pages both render through Template
Toolkit with `env.current_page` set to the active request path, such as
`/app/index`. The same path is also available as
`env.runtime_context.current_page`, alongside the rest of the request-time
runtime context.

Token play renders for named bookmarks also reuse that saved
`/app/<id>` path for nav context, so shared `nav/*.tt` fragments do
not disappear just because the browser reached the page through a transient
`/?mode=render&token=...` URL.

Shared nav markup now wraps horizontally by default and inherits the page
theme through CSS variables such as `--panel`, `--line`, `--text`, and
`--accent`, so dark bookmark themes no longer force a pale nav box or hide
nav link text against the background.

## What You Get

- a browser interface on port `7890` for pages, status, editing, and helper
access
- a shell entrypoint for file navigation, page operations, collectors,
indicators, auth, and Docker Compose
- saved runtime state that lets the browser, prompt, and CLI all see the same
prepared information
- a place to collect project-specific shortcuts without rebuilding your daily
workflow for every repo

## Web Interface And Access Model

Run the web interface with:

    d2 serve

By default it listens on `0.0.0.0:7890`, so you can open it in a browser at:

    http://127.0.0.1:7890/

Run `d2 serve --ssl` to enable HTTPS with a generated self-signed
certificate under `~/.developer-dashboard/certs/`, then open:

    https://127.0.0.1:7890/

When SSL mode is on, plain HTTP requests on that same host and port are
redirected to the equivalent `https://...` URL before the dashboard route
runs.

The generated certificate covers `localhost`, `127.0.0.1`, and `::1`. It
also includes a concrete non-wildcard `--host HOST` value and any additional
names or IPs in `config/config.json` under
`web.ssl_subject_alt_names`.

Older dashboard certs are
rotated forward automatically when they no longer match that expected profile.
Browsers still show the normal self-signed certificate warning until you trust
the generated certificate locally.

Run `d2 serve --no-editor` or `d2 serve --no-endit` to keep
the browser in read-only mode. That hides the Share, Play, and View Source
links, blocks bookmark editor and source routes with `403`, blocks
bookmark-save POST requests even if someone tries to hit them directly, and
persists the mode so later `d2 restart` runs stay read-only until you
switch it back with `d2 serve --editor`.

Run `d2 serve --no-indicators` or `d2 serve --no-indicator` to
clear the whole top-right browser chrome area. That hides the browser-only
indicator strip, username, host or IP link, and live date-time line without
changing `/system/status` or terminal prompt output such as `d2 ps1`,
and persists the mode until `d2 serve --indicators` turns it back on.

For example, if you want the same dashboard cert to work for one local
`/etc/hosts` alias and one LAN IP, keep the runtime config like this:

    {
      "web": {
        "ssl_subject_alt_names": [
          "dashboard.local",
          "192.168.1.20",
          "fd00::20"
        ]
      }
    }

The access model is deliberate:

- numeric loopback and loopback-only hostnames such as `localhost` do not
require a password when the request still originates from loopback
- configured loopback aliases listed under `web.ssl_subject_alt_names` are also
treated as local-admin when they still arrive from loopback
- helper access is for everyone else, including non-loopback IPs and other
machines on the network
- the loopback-admin shortcut applies only to direct (plain HTTP) connections;
under `d2 serve --ssl` the public front-proxy relays TLS to an internal
loopback backend, so every backend connection looks like loopback and cannot
prove the real client is local -- in that mode the shortcut is disabled and
even loopback HTTPS requests require a helper login
- helper logins let you share the dashboard safely without turning every browser
request into full local-admin access

In practice that means the developer at the machine gets friction-free local
admin access, while shared or forwarded access is forced through explicit
helper accounts. Helper passwords use PBKDF2-HMAC-SHA256 with 210,000 iterations.

When the compiled Dashboard XS extension and a compatible system OpenSSL
`libcrypto` are available, the same derivation runs through OpenSSL's native
PBKDF2 function; this preserves the existing salts, stored hashes, and
verification format. If the native library is unavailable or the password
cannot safely use the byte-oriented XS path, authentication uses the existing
`Digest::SHA` implementation.

MakeMaker compiles the extension as
part of the normal distribution build; a source checkout without the compiled
object uses the equivalent Perl implementation. Overloaded references retain
Perl stringification behaviour, and native-load errors other than a genuinely
missing object remain visible.

The XS result retains the Perl UTF-8 and taint
flags. Quoted attribute values use a separate single-pass XS loop that escapes
the body metacharacters and both quote characters together; source-only builds
and overloaded references retain the Perl path.

For path ancestry checks, byte-identical nonempty path strings are recognised
before calling `abs_path`; different spellings still use canonical resolution
to preserve symlink-aware behaviour. Component-boundary checks use the active
`File::Spec` separator and case-tolerance rules, including Windows drive roots
and backslash paths, so a textual prefix cannot be mistaken for a descendant.

Cold ratios against serial were 0.21, 0.90, 0.97, and 0.89; warmed
ratios were 0.92, 1.18, 1.13, and 1.18. MCE module import is excluded, so
these cold figures understate its one-shot cost. Cold MCE was slower at every
size, and warmed gains remained below 1.2 times; it is not added to the
one-shot path command. Collector startup remains sequential so readiness failures retain their
existing fail-fast behaviour.

If no helper user exists yet in the active dashboard runtime, outsider requests return
`401` with an empty body and do not render the login form at all.

When a saved `index` bookmark exists, opening `/` now redirects straight to
`/app/index` so the saved home page becomes the default browser entrypoint. When no saved `index` bookmark exists yet, `/` still opens the free-form
bookmark editor.

If a user opens an unknown saved route such as `/app/foobar`, the browser now
opens the bookmark editor with a prefilled blank bookmark for that requested
path instead of showing a 404 error page.

When helper access is sent to `/login`, the login form now keeps the original
requested path and query string in a hidden redirect target.

After a
successful helper login, the browser is sent back to that saved route, such as
`/app/index`, instead of being dropped at `/`.

## Collectors, Indicators, And PS1

Collectors are background or on-demand jobs that prepare state for the rest of
the dashboard. A collector can run a shell command or a Perl snippet, then
store stdout, stderr, exit code, and timestamps as file-backed runtime data.

That prepared state drives indicators. Indicators are the short status records
used by:

- the shell prompt rendered by `d2 ps1`
- the top-right status strip in the web interface
- CLI inspection commands such as `d2 indicator list`

This matters because prompt and browser status should be cheap to render. Instead of re-running a Docker check, VPN probe, or project health command
every time the prompt draws, a collector prepares the answer once and the rest
of the system reads the cached result.

When the status strip or indicator-list command reads indicators, the store
resolves the applicable runtime roots once for that listing and searches those
roots in precedence order. It still reads the indicator files on each request,
so updates and inherited-versus-local overrides remain visible.

During each collector
sync, the store now resolves ordered indicator roots once and passes that
snapshot through all collector comparisons and the final inventory. Decoded
indicator files are cached only for that sync; writes and deletions invalidate
the affected entry, and a later request rereads disk state. A Docker regression
checks one root resolution and one physical file read per indicator, next-sync
visibility of an external state change, and correct inventory after retirement.

Workspace sessions use a
two-line bottom status block: the first row is the d2 indicator strip
with the trailing date-time segment, and the second row keeps tmux's normal
session and indexed window list. Ordinary tmux sessions keep the normal
inline prompt.

The
workspace workflow seeds a dedicated
`DEVELOPER_DASHBOARD_TMUX_STATUS=1` session flag for that behaviour, and
Developer Dashboard also treats the older `TICKET_REF` session reference as a
fallback signal so older workspace sessions do not keep duplicating indicators in the
inline prompt.

Developer Dashboard updates tmux through session-local runtime
commands instead of editing any user tmux config file or changing unrelated
tmux sessions on the same server. Configured collector indicators now prefer the configured icon in both places,
and when a collector is renamed the old managed indicator is cleaned up
automatically so the prompt and top-right browser strip do not show both the
old and new names at the same time.

Those managed indicator records now also
preserve a newer live collector status during restart/config-sync windows, so
a healthy collector does not flicker back to `missing` after it has already
reported `ok`.

If `indicator.icon` contains Template Toolkit syntax such as `[% a %]`, the
collector runner now treats collector `stdout` as JSON, decodes it through
`JSON::XS`, exposes hash keys as direct template variables plus `data`, and
persists the rendered icon as the live indicator value. Invalid JSON or TT
render failures are explicit collector errors: the collector `stderr` records
the template problem and the indicator stays red instead of silently falling
back.

### System menu indicator configuration

`Developer::Dashboard::SystemMenu->items_for_platform` projects
configured indicator names and their current icons for the `macos`,
`windows`, or `ubuntu` selector. Each platform selector is opt-in; a missing
or false value disables that item. Invalid values for any supported selector
are rejected even when the current host is another platform. The projection
preserves configuration order and does not start a native menu by itself. The
private `web-foreground` runtime supplies merged configuration and the shared
indicator store to `Developer::Dashboard::SystemMenu::Runner`. The runner
starts the menu only when an indicator is enabled for the current host and
keeps the helper active for the foreground web-service lifetime. It stops and
joins the GoRoutine worker when the service returns or fails; disabled or
unsupported platform settings do not load the native adapter. The existing
`d2 ps1` output remains unchanged.

The native System::Menu adapter starts the platform helper in a controlled
GoRoutine worker. On Ubuntu, the helper uses Ayatana AppIndicator3 and a GTK
menu; rendered status icons are kept in a private temporary icon-theme
directory and removed when the helper shuts down. Building from source
requires the Ayatana AppIndicator3 and GTK3 development packages; runtime
requires a desktop session with AppIndicator support. The helper reports a
clear error when no desktop session is available. Source and compile tests do
not prove that a desktop shell visibly displayed the menu; hosted platform
verification is required for each supported operating system. Linux CI and
the published Docker image install those native development packages before
building the helper. The macOS helper uses ARC and treats deprecated AppKit APIs
as errors. The Windows full-suite job installs Test::Harness without
Devel::Cover, which does not configure on its supported Windows runner; the
four-metric coverage gate remains on Linux.

If optional watcher setup fails and watcher shutdown also fails, the dispatcher
reports the close failure even when that watcher has no `last_error` method.

## Why It Works As A Developer Home

The pieces are designed to reinforce each other:

- pages give you a browser home for links, notes, forms, and actions
- collectors prepare state for indicators and prompt rendering
- indicators summarise that state in both the browser and the shell
- path aliases, open-file helpers, and data query commands shorten the jump from
I know what I need to I am at the file or value now
- Docker Compose helpers keep recurring container workflows behind the same
`d2` entrypoint

That combination makes the dashboard useful as a real daily base instead of
just another utility script.

## Works Across Languages

Developer Dashboard supports mixed-language teams and polyglot repositories.
It provides common navigation, status, and repeatable workflows across a
project, regardless of the language used for its application code.

- a local browser home
- repeatable health checks and status indicators
- path shortcuts and file-opening helpers
- JSON, YAML, TOML, or properties inspection from the CLI
- a consistent Docker Compose wrapper

File helpers can locate source files, structured data, and project-local
container configuration alongside the browser and prompt tools.

Project-specific behaviour is added through configuration, saved pages, and
user CLI extensions.

# MODULE NAMESPACING

All project modules are scoped under the `Developer::Dashboard::` namespace
to prevent pollution of the CPAN ecosystem. Core helper modules are available
under this namespace:

- Developer::Dashboard::File

    File I/O helpers with alias support for older bookmark compatibility.

- Developer::Dashboard::Folder

    Folder path resolution and discovery with runtime registry support.

- Developer::Dashboard::DataHelper

    JSON encoding and decoding helpers for older bookmark code.

- Developer::Dashboard::Zipper

    Token encoding and Ajax command building for transient URL construction.

- Developer::Dashboard::Runtime::Result

    Hook result environment variable decoding and access for command runners.

Project-owned modules now live only under the `Developer::Dashboard::`
namespace so the distribution does not pollute the CPAN ecosystem with
generic package names. The bookmark CODE runtime imports the short JSON helper
names from `Developer::Dashboard::DataHelper` automatically for every block.
The shared JSON wrapper lazily reuses its fixed-configuration canonical
encoder and UTF-8 decoder within each Perl interpreter; calls requiring
different encoder options construct their own configured encoder.

## Main Concepts

The runtime has a few shared parts:

- Path and file registries

    Resolve the layered home, project, and skill locations used for configuration,
    pages, logs, collectors, and other runtime data.

- Pages and actions

    Store saved pages, render browser views, and run configured actions with their
    working directory, environment, and timeout settings.

- Collectors and indicators

    Run scheduled or on-demand checks, save their results, and expose concise
    status to the browser and shell prompt.

- Web and command interfaces

    Provide the local browser UI and the `d2` command line entry point over
    the same runtime data.

- Skills and extensions

    Add isolated commands, pages, configuration, and collectors that can be
    layered with the shared and project runtimes.

The implementation modules are under the `Developer::Dashboard::` namespace.
The command guides below describe supported user-facing behaviour; module
references are most useful when embedding or extending the system.

## Environment Variables

The distribution supports these compatibility-style customisation variables:

- `DEVELOPER_DASHBOARD_BOOKMARKS`

    Override the saved page root.

- `DEVELOPER_DASHBOARD_CHECKERS`

    Filter enabled collector/checker names.

- `DEVELOPER_DASHBOARD_CONFIGS`

    Override the config root.

- `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS`

    Allow browser execution of transient `/?token=...`, `/action?atoken=...`,
    and older `/ajax?token=...` payloads. The default is off, so the web UI only
    executes saved bookmark files unless this is set to a truthy value such as
    `1`, `true`, `yes`, or `on`.

## Transient Web Token Policy

Transient page tokens still exist for CLI workflows such as `d2 page encode`
and `d2 page decode`, but browser routes that execute a transient payload
from `token=` or `atoken=` are disabled by default.

That means links such as:

- `http://127.0.0.1:7890/?token=...`
- `http://127.0.0.1:7890/action?atoken=...`
- `http://127.0.0.1:7890/ajax?token=...`

return a `403` unless `DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS` is enabled.
Saved bookmark-file routes such as `/app/index` and
`/app/index/action/...` continue to work without that flag.

Saved bookmark
editor pages also stay on their named `/app/<id>/edit` and
`/app/<id>` routes when you save from the browser, so editing an
existing bookmark file does not fall back to transient `token=` URLs under the
default deny policy.

`Ajax` helper calls inside saved bookmark `CODE*` blocks should use
an explicit `file => 'name.json'` argument. When a saved page supplies that
name, the helper stores the Ajax Perl code under the saved dashboard ajax tree and emits a
stable saved-bookmark endpoint such as
`/ajax/name.json?type=text`.

Skill pages use the same helper contract. Without
extra skill route metadata the generated saved endpoint is namespaced under the
longest matching skill route, for example
`/ajax/example-skill/name.json?type=text` or
`/ajax/example-skill/sub-skill/name.json?type=text`.

The runtime config tree
and installed skills can both ship `config/routes.json` to declare canonical
custom paths for normal saved app pages, skill-local app pages, Ajax handlers,
JavaScript assets, CSS assets, and other public assets. The schema is a JSON
object whose keys are the public custom paths and whose values are either one
smart local route string or an object with `to` plus an optional `type`, for
example

    {
       "/java" : "/app/learn.ai",
       "/v1/status" : {
          "to" : "/ajax/status",
          "type" : "json"
       },
       "/hello/world" : "/app/hello/world",
       "/main.css" : "/css/hello/world.css",
       "/hey.js" : "/js/hey/how/are/you.js",
       "/what/are/you" : "/others/hello/world/you.html"
    }

When that file is present, skill pages emit the declared canonical
`ajax` path such as `/v1/status` instead of the default `/ajax/...` url,
and runtime-level aliases such as `/java` can point at normal saved bookmark
ids such as `/app/learn.ai` without treating the dot as skill notation. The
same manifest also makes the declared custom `/app`, `/js`, `/css`, and
`/others` paths requestable.

The smart longest-prefix routes remain the
parent resolvers:
`/app/example-skill/...`, `/ajax/example-skill/...`,
`/js/example-skill/...`, `/css/example-skill/...`, and
`/others/example-skill/...` are always checked first, and any declared custom
path is checked only after the normal smart route misses.

Runtime-level custom
paths from the active `config/routes.json` layer chain follow the same
fallback rule against the built-in `/app`, `/ajax`, `/js`, `/css`, and
`/others` route handlers. If neither the smart route nor the custom path
resolves, the request falls through to the normal `404` response.

Ajax custom
routes default to `json` when no explicit `type` is present, and the
optional `type` value can also be `html`,
`text`, or an arbitrary raw mime type such as
`application/vnd.example+json`. Those saved Ajax handlers run the stored file
as a real process, defaulting to Perl unless the file starts with a shebang,
and stream both `stdout` and `stderr` back to the browser as they happen.

That keeps bookmark Ajax workflows usable even while transient token URLs stay
disabled by default, and it means bookmark Ajax code can rely on normal
`print`, `warn`, `die`, `system`, and `exec` process behaviour instead of
a buffered JSON wrapper. The same layered runtime config chain and installed-skill config trees can now
ship `config/api.json` files that authorise selected `/ajax/...` routes for
machine-to-machine callers without forcing a helper login form.

The schema is a
JSON object keyed by API client name.

Each entry must provide a stored SHA-256
hex digest under `secret` plus an `ajax` array of exact saved Ajax route
paths such as `/ajax/stream.txt` or
`/ajax/example-skill/status.json`. When a non-admin remote request targets one
of those registered `/ajax/...` paths, the caller can send
`X-DD-API-Key: NAME` and `X-DD-API-Secret: RAW-SECRET`.

Developer Dashboard
hashes the raw secret with SHA-256, compares it to the stored digest, and
executes the saved Ajax handler when they match.

Missing or wrong credentials
for a registered API route return `403` with the JSON body
`{"status":"forbidden"}`.

Existing helper-session auth still works on the
same saved Ajax routes, so browser workflows and machine callers can coexist on
one handler without adding a second copy of the route. Like the rest of
`DD-OOP-LAYERS`, runtime `config/api.json` files merge from home to the
deepest active child layer, and installed skills contribute their own layered
`config/api.json` fragments for skill-local saved Ajax routes.

The built-in
`d2 api` command is the supported way to inspect or update the writable
runtime layer for that registry.

An entry carrying `"disabled": true` (or the same flag under `_disabled`)
is dropped from the registry; a JSON literal `false` there keeps the key
visible, including values such as `"disabled": 0` or `"disabled": "no"`.

Saved bookmark Ajax handlers default to `text/plain` when no explicit
`type => ...` argument is supplied, and the generated Perl wrapper now
enables autoflush on both `STDOUT` and `STDERR` so long-running handlers
show incremental output in the browser instead of stalling behind process
buffers.

If a saved handler also needs refresh-safe process reuse, pass
`singleton => 'NAME'` in the `Ajax` helper.

The generated URL carries the singleton name, and the worker runs as
`d2 ajax: NAME`. A refreshed request replaces the older matching
worker.

`d2 stop` and `d2 restart` also stop singleton Ajax workers.
Closing a browser tab sends a `pagehide` cleanup request to
`/ajax/singleton/stop?singleton=NAME`.

If `code => ...` is omitted, `Ajax(file => 'name')` targets the
existing executable at `dashboards/ajax/name` instead of rewriting it. Static files referenced by saved bookmarks are resolved from the effective
runtime public tree first and then from the saved bookmark root.

The web layer
also provides a built-in bundled `/js/jquery.js` asset that serves the local
copy of jQuery 4.0.0, with `/js/jquery-4.0.0.min.js` kept as a compatibility
alias for the same shipped payload even when no runtime file has been copied
into `dashboard/public/js` yet.

The bundled browser tab icon works the same
way: browsers request `/favicon.ico` on their own for every page load, so that
route is served outside the authorisation gate, on every trust tier and before
any helper login, from the bundled 16x16 icon. Dropping your own
`dashboard/public/others/favicon.ico` into any runtime layer overrides it.

Skills can ship the same classes of assets
under their own dashboard tree: `dashboards/ajax/*` resolves at
`/ajax/<repo-name>/...` or
`/ajax/<repo-name>/<sub-skill>/...`, and
`dashboards/public/js/*`, `dashboards/public/css/*`, and
`dashboards/public/others/*` resolve at
`/js/<repo-name>/...`, `/css/<repo-name>/...`, and
`/others/<repo-name>/...` with the same nested-skill extension,
for example `/js/<repo-name>/<sub-skill>/path/file.js`.

If a
request such as `/js/<repo-name>/foo/bar.js` or
`/js/<repo-name>/<sub-skill>/foo/bar.js` does not exist in the
skill-local public tree, the web layer falls back to the normal nested
saved-bookmark asset path `dashboards/public/js/...` or saved Ajax file path
`dashboards/ajax/...` instead of assuming the leading path segments must
belong to a skill.

Saved bookmark editor and view-source routes also protect literal inline
script content from breaking the browser bootstrap. If a bookmark body
contains HTML such as `/script`, the editor now escapes the inline JSON
assignment used to reload the source text, so the browser keeps the full
bookmark source inside the editor instead of spilling raw text below the page.

Saved browser workspaces can also show a request-specific token form above the
editor whenever the current request uses `{{token}}` placeholders, carrying
those token values across matching placeholders in the same workflow so later
requests can reuse the operator-supplied values without manual copy-and-paste.

Bookmark rendering now emits saved `set_chain_value()` bindings after
the bookmark body HTML, so pages that declare `var endpoints = {}` and then
call helpers from `$(document).ready(...)` receive their saved `/ajax/...`
endpoint URLs without throwing a play-route JavaScript `ReferenceError`.

Bookmark pages now also expose
`fetch_value(url, target, options, formatter)`,
`stream_value(url, target, options, formatter)`, and
`stream_data(url, target, options, formatter)` helpers so a bookmark can bind
saved Ajax endpoints into DOM targets without hand-writing the fetch and
render boilerplate. `stream_data()` and `stream_value()` now use
`XMLHttpRequest` progress events for browser-visible incremental updates, so
a saved `/ajax/...` endpoint that prints early output updates the DOM before
the request finishes.

Those helpers support plain text, JSON, and HTML output. Saved Ajax bindings
are available after the page declares its endpoint root, so
`$(document).ready(...)` callbacks can call helpers such as
`fetch_value(endpoints.foo, '#foo')` on first render.

For response inspection panels, place the Response Body and Response Headers
tabs below the response `pre` box. This keeps the main response visible while
the details remain accessible.

## User CLI Extensions

Unknown top-level subcommands can be provided by executable files under
the current working directory's `./.developer-dashboard/cli` first, then the
nearest git-backed project runtime `./.developer-dashboard/cli` when it is a
different directory, and then `~/.developer-dashboard/cli`. For example,
`d2 foobar a b` will exec the first matching
`cli/foobar` with `a b` as argv, while preserving stdin, stdout, and
stderr.

A direct custom command can also be stored as an executable
`cli/<command>.pl`, `cli/<command>.py`, `cli/<command>.js`, `cli/<command>.go`,
`cli/<command>.java`, `cli/<command>.sh`,
`cli/<command>.bash`, `cli/<command>.ps1`,
`cli/<command>.cmd`, or `cli/<command>.bat`, and
`d2 <command>` resolves the same logical command name to
those files.

Concrete source-backed examples:

    d2 hi
    d2 foo

If `cli/hi.go` is executable, `d2 hi` runs it through `go run`.
If `cli/report.py` is executable, `d2 report` runs it through `python`.

If `cli/webhook.js` is executable, `d2 webhook` runs it through `node`.
If `cli/foo.java` is executable, `d2 foo` compiles it with `javac`
into an isolated temp directory and then runs the declared main class with
`java`.

To demonstrate a custom `update` command with a hook, create both files in a
runtime CLI layer and then invoke the switchboard:

    mkdir -p ~/.developer-dashboard/cli/update.d
    printf '#!/usr/bin/env perl\nprint "custom update\\n";\n' > ~/.developer-dashboard/cli/update
    chmod +x ~/.developer-dashboard/cli/update
    printf '#!/bin/sh\nprintf "before update\\n"\n' > ~/.developer-dashboard/cli/update.d/01-log
    chmod +x ~/.developer-dashboard/cli/update.d/01-log
    perl -Ilib bin/d2 update

The command file is user-provided, not a built-in. The hook runs before it;
project-local runtime layers take precedence over the home layer.

If a user mistypes a command, dashboard now prints an explicit unknown-command
error together with the closest matching public command before the usual usage
summary. The same guidance also applies to dotted skill commands, so
`d2 alpha-skill.run-tset` suggests the nearest installed dotted skill
command instead of only dumping generic help.

## Built-in command help and completion

Every dashboard-managed built-in command and its public actions use one help
catalogue. Request help with `--help`, `-h`, or a trailing `help`, for
example `d2 api add --help`, `d2 api add help`, or the global form
`d2 help docker development enable`.

The public `version` command also
supports `d2 version --help` and global `d2 help version`. Bare `d2 help`,
`d2 --help`, and `d2 -h` print a concise index of public built-in commands
instead of the full module manual.

Top-level TAB completion lists commands and
dotted skill commands; path aliases are offered in the `d2 workspace
<alias>` position instead of being mixed into the command list. Help is returned before the built-in
command body runs, while the normal main and per-command hook order is
preserved. The global help form and command help include actionable usage and
the available action/options where applicable.

The same catalogue supplies TAB candidates for public commands, nested actions,
and supported option flags. Bash and zsh call the live `d2 complete`
helper, so their candidates stay aligned with the command catalogue rather than
maintaining separate shell-side action lists. Existing dynamic completions for
skills, workspace sessions, collectors, and workspace path aliases remain
available.

When a skill with the same name exists in project and home runtime
layers, its dotted command candidates are merged from every participating
layer and duplicate command names appear once; execution still uses the
normal deepest-layer lookup.

`cdr` TAB completion lists aliases and direct
child directories. Each entered narrowing term descends one matching directory level before
suggesting the next child, avoiding recursive scans of unrelated repository
and dependency trees. When a command has a default action, the root help and completion also expose
that action's options; for example, `d2 api --key helper-bot -o json` lists
API keys without requiring the explicit `ls` action.

`DD-OOP-LAYERS` is now the runtime contract for the whole local ecosystem.
Starting at the home directory and walking down through every parent directory
until the current working directory, every existing `.developer-dashboard/`
and `.d2/` runtime directory participates. When both names exist at the same
depth, both are searched independently; `.developer-dashboard/` has priority
over `.d2/` at that depth and remains the write target.

The deepest available
runtime root is the write target, but bookmarks, `nav/*.tt`, config,
collectors, indicators, auth/session state lookups, runtime
`local/lib/perl5`, Docker Compose service folders, skills, and custom CLI
hooks are inherited across the full chain instead of only a single
project-or-home split.

Per-command hooks can live in `cli/<command>` or
`cli/<command>.d` at each runtime layer, from home to the current
directory.

Executable hooks run in sorted order within each layer. Layers run from home
to the deepest active directory, and non-executable files are skipped.

Hook output streams to the terminal and is also accumulated as JSON in
`RESULT`.

If that JSON grows too large for a safe
`exec()` environment, `d2` spills it into `RESULT_FILE` and
`Developer::Dashboard::Runtime::Result` reads the same logical payload from
there so later hooks and the final command still see the same result set
without tripping `Argument list too long`. Built-in commands such as `d2 jq`
use the same hook directory.

A
directory-backed custom command can provide its real executable as
`~/.developer-dashboard/cli/<command>/run`, and that runner receives
the final `RESULT` plus `LAST_RESULT` environment variables.

After each hook
finishes, the updated `RESULT` JSON is written back into the environment
before the next sorted hook starts, and `LAST_RESULT` is rewritten to the
structured result for the hook that just ran, so later hook scripts can react
to earlier hook output and also inspect the immediate previous hook in a stable
shape. `LAST_RESULT` carries `file`, `exit`, `STDOUT`, and `STDERR`.

Only an explicit `[[STOP]]` marker in one hook's `stderr` stops the
remaining hook files for that command. A non-zero exit code alone is still
recorded, but it does not skip later hooks.

Executable `.py` hook files and
direct `.py` custom commands run through `python`. Executable `.js` hook files and
direct `.js` custom commands run through `node`.

Executable `.go` hook files and
direct `.go` custom commands run through `go run`. Executable `.java`
hook files and direct `.java` custom commands are compiled with `javac`
into an isolated temp directory and then run through `java` using the
declared main class from the source file.

Perl hook code can use `Runtime::Result` to decode `RESULT` safely, read the
immediate `last_result`, and inspect per-hook `stdout`, `stderr`, exit
codes, or the last recorded hook entry.
If a Perl-backed command wants a compact final summary after its hook files
run, it can also call `Developer::Dashboard::Runtime::Result->report()` to print a simple
success/error report for each sorted hook file.

### Layered Env Files

Environment files are part of the same `DD-OOP-LAYERS` contract.
When `dashboard ...` runs, it loads every participating plain-directory env
file and runtime-layer env file from parent to child before command hooks,
custom commands, or built-in helpers execute. This is one interleaved pass,
not a pass over all plain directories followed by a pass over all runtime
directories.

For each directory from the selected root toward the current directory, the
pass loads its plain `.env` and `.env.pl` files, then the `.env` and
`.env.pl` files in runtime roots located under that directory. Sibling
`.d2` and `.developer-dashboard` roots retain their discovered order, with
deeper directories loaded later. Explicit runtime roots outside the plain
directory chain are loaded before that chain so child `.env.pl` files can
read their inherited values. The participating files are:

- `<root>/.env`
- `<root>/.env.pl`
- each deeper ancestor directory `.env`
- each deeper ancestor directory `.env.pl`
- each participating `.developer-dashboard/.env` and `.d2/.env`
- each participating `.developer-dashboard/.env.pl` and `.d2/.env.pl`

Deeper files win because later layers overwrite earlier keys. Plain `.env`
files must contain explicit `KEY=VALUE` lines, and the load order at one
directory is always `.env` first and then `.env.pl`, followed by its
runtime-root files. Plain `.env` parsing
ignores blank lines, whole-line `#` comments, whole-line `//` comments, and
`/* ... */` block comments that can span multiple lines. Plain `.env`
values also support:

- leading `~` expansion to `$HOME`
- `$NAME` expansion from the current effective environment
- `${NAME:-default}` expansion with a fallback value
- `${Namespace::function():-default}` expansion through a static Perl function

Expansion can see system env keys, values loaded from earlier layers, and
values assigned by earlier lines in the same `.env` file. Missing functions,
malformed lines, malformed keys, and unterminated block comments fail
explicitly instead of being skipped silently. Executable logic can live in
`.env.pl`, which is run directly and may set `%ENV` programmatically.

Skill-local env files are loaded only when a skill command or skill hook is
actually running. A normal non-skill command inherits only the root-to-leaf
runtime env chain. For a skill command, home-level runtime env files load
first as defaults, then each participating skill root loads from the base
installed skill layer to the deepest matching child skill layer, applying:

- `<skill-root>/.env`
- `<skill-root>/.env.pl`

Skill `.env` and `.env.pl` values override matching values from the home
runtime. Skill `cli/.env` and `cli/.env.pl` values are applied after the skill
root files.

Any deeper project runtime layers are applied last, so the nearest
project runtime still has final precedence among file-based values. Values
explicitly inherited from the invoking shell have highest precedence and are
preserved across every env-file layer; a file may populate a variable that the
caller did not set, but cannot replace an exported caller value.

Skill
overrides stay isolated to the skill execution path and do not leak into
unrelated commands.

The runtime chain is collected from the DD-OOP layers rooted at the current
working directory, walking its existing parent directories toward the leaf.
For skill execution, the home runtime portion is applied before the skill
chain and deeper runtime layers after it. Therefore a nested command such as
`d2 foo.bar.bob` receives home defaults, then the `foo` and `bar` skill
overrides, then any nearer project runtime values.

For nested skill commands such as `d2 foo.bar.zzz.show`, the skill env
chain expands from the root nested skill to the leaf skill before the command
runs:

- `skills/foo/.env`
- `skills/foo/skills/bar/.env`
- `skills/foo/skills/bar/skills/zzz/.env`

If a deeper nested skill overrides the same key, the parent value is preserved
under that parent skill alias before the deeper skill replaces the plain key.
For example, if all three nested skills assign `VERSION`, the leaf command
sees `VERSION` from `zzz`, `foo_VERSION` from `foo`, and
`foo_bar_VERSION` from `foo.bar`.

The Docker Compose resolver also loads `<skill-root>/.env` for each installed
skill whose `config/docker/<service>/compose.yml` or
`config/docker/<service>/development.compose.yml` file actually participates in
the resolved compose stack. A service's `compose.yml` is its base and is loaded
whenever present; `development.compose.yml` is loaded afterward only while the
service's `develop.yml` marker is enabled.

That compose-only skill env layer
stays isolated to the compose resolver, respects disabled skills, and does not
execute `<skill-root>/.env.pl`.

Nested skill compose services use that same
root-to-leaf env expansion, so a participating leaf service such as
`skills/foo/skills/bar/skills/zzz/config/docker/zzz/compose.yml` loads the
env chain from `foo` to `foo.bar` to `foo.bar.zzz` and preserves parent
overrides under aliases such as `foo_VERSION` and `foo_bar_VERSION`.

Perl code can inspect where a dashboard-managed env key came from with
`Developer::Dashboard::EnvAudit`.

Single-key lookup:

    use Developer::Dashboard::EnvAudit;

    my $entry = Developer::Dashboard::EnvAudit->key('FOO');

That returns either `undef` for normal system env keys or a hashref like:

    {
        value   => 'bar',
        envfile => '/full/path/to/.env',
    }

Full inventory lookup:

    my $all = Developer::Dashboard::EnvAudit->keys;

The audit records only dashboard-loaded env keys. System-provided keys that
did not come from a dashboard-managed `.env` or `.env.pl` file are left
untracked on purpose.

For example, a layered `.env` file can now look like:

    # root defaults
    ROOT_CACHE=~/cache
    API_BASE=https://example.test
    TOKEN=${ACCESS_TOKEN:-anonymous}
    MESSAGE=${Local::Env::Helper::message():-hello}

    /*
    child layers can still override
    any value later in the root-to-leaf chain
    */
    CHAINED=$ROOT_CACHE/$TOKEN

A separate mechanism, `# include <skill.path>`, pulls another
skill's own `.env`/`.env.pl` in by name rather than by layer position -
see ["EMBEDDING IN PERL CODE"](#embedding-in-perl-code) for `env->include(...)`, its `.env.pl`
counterpart.

## Open File Commands

`d2 of` is the shorthand name for `d2 open-file`.

These commands support:

- direct file paths
- `file:line` references
- Perl module names such as `My::Module`, resolved against every directory in
the running Perl's `@INC`
- Java class names such as `com.example.App` or `javax.jws.WebService`
- recursive regex searches inside a resolved directory alias or path
- recursive content searches with `d2 of grep -nr <pattern>
<directory>`

Without `--print`, `d2 of` and `d2 open-file` now behave like
the older picker workflow again: one unique match opens directly in
`--editor`, `VISUAL`, `EDITOR`, or `vim` as the final fallback, and
multiple matches render a numbered prompt. At that prompt you can press Enter
to open all matches with `vim -p`, type one number to open one file, type comma-separated
numbers such as `1,3`, or use a range such as `2-5`.

Scoped searches also
rank exact helper/script names before broader regex hits, so
`d2 of . jq` lists `jq` and `jq.js` ahead of `jquery.js`.

Every
scoped search token is treated as a case-insensitive regex, so
`d2 of . 'Ok\.js$'` matches `ok.js` but not `ok.json`. Content grep passes arguments directly to the system `grep` executable (no
shell expansion), adds filename and line-number output for reliable file
selection, then opens the unique matching files using the same chooser. Add
`--print` before `grep` to print the unique paths without opening an editor.

Java class lookup first checks live `.java` files under the current project,
workspace roots, and `@INC`-adjacent source trees. If no live source file
exists, it also searches local source archives such as `-sources.jar`,
`-src.jar`, `src.zip`, `war`, and `jar` files under the current roots,
`~/.m2/repository`, Gradle caches, and `JAVA_HOME`.

When a local archive
still does not provide the requested class, the helper can fetch a matching
Maven source jar, cache it under
`~/.developer-dashboard/cache/open-file/`, and then open the extracted Java
source.

## Data Query Commands

These built-in commands parse structured text and can then either extract a
dotted path or evaluate a Perl expression against the decoded document through
`$d`:

- `d2 jq [path] [file]` for JSON
- `d2 yq [path] [file]` for YAML
- `d2 tomq [path] [file]` for TOML
- `d2 propq [path] [file]` for Java properties
- `d2 iniq [path] [file]` for INI
- `d2 csvq [path] [file]` for CSV
- `d2 xmlq [path] [file]` for XML

If the selected value is a hash or array, the command prints canonical JSON.
If the selected value is a scalar, it prints the scalar plus a trailing
newline.

The file path and query text are order-independent, and `$d` selects the
whole parsed document. For example, `cat file.json | d2 jq '$d'` and
`d2 jq file.json '$d'` return the same result.

If the query text uses
`$d` inside a Perl expression, the command evaluates that expression against
the decoded document. For example, `echo '{"foo":[1],"bar":[2]}' | dashboard
jq 'sort keys %$d'` prints `["bar","foo"]`.

The same contract applies to
`yq`, `tomq`, `propq`, `iniq`, `csvq`, and `xmlq`.

`xmlq` follows the same decoded-data model as the other query commands. XML
elements decode into nested hashes and arrays, repeated sibling tags become
arrays, attributes live under `_attributes`, and mixed text lives under
`_text`. That means `printf '<root`&lt;value>demo&lt;/value>&lt;/root>' | dashboard
xmlq root.value> prints `demo`, while `d2 xmlq feed.xml '$d'` prints
the full decoded XML tree as canonical JSON.

# FAQ

## Is this tied to a specific company or codebase?

No. The core distribution is intended to be reusable for any project.

## Where should project-specific behaviour live?

In configuration, saved pages, and user CLI extensions. The core should stay generic.

## Is the software spec implemented?

The current distribution implements the core runtime, page engine, action runner, provider loader, prompt and collector system, web lifecycle manager, and Docker Compose resolver described by the software spec.

What remains intentionally lightweight is breadth, not architecture:

\- provider pages and action handlers are implemented in a compact v1 form
\- bookmark-file pages are supported, with Template Toolkit rendering and one clean sandpit package per page run so `CODE*` blocks can share state within a bookmark render without leaking runtime globals into later requests

## How is the browser UI served?

The browser UI runs as the dashboard web service you start with
`d2 serve`. Internally that service is a PSGI application served
through the shipped web runtime, while CLI-only commands continue to work
without keeping the browser service running.

## Why does a custom hostname sometimes require login?

Only loopback-origin requests with a loopback hostname such as `127.0.0.1`,
`::1`, or `localhost` receive automatic local-admin treatment. A custom alias
hostname also works as local admin when you list it under
`web.ssl_subject_alt_names` and the request still arrives from loopback.

## Why does a non-loopback host still get 401 without a login page?

Until at least one helper user exists, outsider access is disabled entirely.
That includes non-loopback IPs, forwarded hostnames, and any hostname that is
not loopback-local for the current request. Add a helper user first, then
outsider requests will receive the login page instead of the disabled-access
response.

## Why is the runtime file-backed?

Because prompt rendering, dashboards, and wrappers should consume prepared state quickly instead of re-running expensive checks inline.

## What JSON implementation does the project use?

The project uses `JSON::XS` for JSON encoding and decoding, including shell helper decoding paths.

## What does the project use for command capture and HTTP clients?

The project uses `Capture::Tiny` for command-output capture via `capture`,
with exit codes returned from the capture block rather than read separately.
It uses `LWP::UserAgent` for real outbound HTTP in active runtime paths such
as the Java source lookup or mirror path behind `d2 of` and
`d2 open-file`.

# EMBEDDING IN PERL CODE

Perl code that wants the same runtime the `d2`/`d2` command line
resolves - a configured path alias, or the output of any other subcommand -
does not need to build a path registry, file registry, and config loader by
hand. `use Developer::Dashboard` exports `d2()`, a memoised runtime handle
scoped to the current working directory:

    use Developer::Dashboard;

    my $foo = d2->paths->{foo};                    # in-process, no subprocess
    my $out = d2->doctor->();                       # shells to `d2 doctor`
    my $lst = d2->collector->list->();               # `d2 collector.list`
    my $res = d2->run( 'tira.ticket.show', '--ref', 'DD-726' );
                                                      # run() takes words separately

`d2->paths` resolves in-process, the same table `d2 paths`
prints. Any other bareword method name starts a **lazy chain** that mirrors
the CLI's own dotted dispatch at arbitrary depth - `d2->foo->bar->()`
runs `d2 foo.bar` - and **nothing executes until the chain is
terminated with a call**, the trailing `->()`.

An un-terminated chain is
inert in boolean, numeric and string context, and stringifies to something
obviously non-executing such as `d2 proxy: foo.bar`, so a stray debug print
cannot run a command.

`d2->run(...)` remains available and takes its
words as separate arguments. Output is decoded from
JSON into a real Perl structure automatically when it looks like JSON,
otherwise returned as plain text; a failing subcommand raises an exception
with its error output attached rather than returning silently as if it had
succeeded.

`use Developer::Dashboard` also makes `env->include(...)` available, the
`.env.pl` counterpart to the `# include <skill.path>` comment
directive a plain `.env` file can use. It pulls one named skill's own
`.env`/`.env.pl` in by its dotted path, namespacing every resulting
variable under the skill's path in UPPERCASE with double underscores - `foo`'s
nested `bar` sub-skill's own `BOB=1` arrives as `$ENV{FOO_BAR__BOB}`, never
a bare `$ENV{BOB}`:

    use Developer::Dashboard;

    env->include('foo.bar');      # foo's nested bar sub-skill only
    env->include('foo.bar.*');    # foo.bar, plus every sub-skill nested under it

Unlike `d2`, `env` cannot be a plain exported sub: Perl resolves a bareword
immediately before `->` as a literal package name at parse time
regardless of any same-named sub, so `env` is a real second package declared
inside this file - loading `Developer::Dashboard` is what makes it
available, the same practical effect as `d2`'s own export.

See ["Layered
Env Files"](#layered-env-files) for the `.env`-file-native `# include <skill.path>`
directive this method mirrors.

## Native concurrent work and shared Perl data

`Developer::Dashboard::GoRoutine` provides a distribution-owned XS API for
native worker callbacks, shared Perl data, and explicit child-process
supervision. It is part of the Developer Dashboard Perl namespace; callers do
not need to install or load a separate GoRoutine distribution.

For a single-import interface, `use Developer::Dashboard` exports `d2` and
the GoRoutine functions `go`, `wait_all`, `share`, `channel`, `spawn`,
`process_running`, `process_exited`, `wait_process`, and
`terminate_process`. The GoRoutine source syntax for `go sub { ... }` and
`share my $value = ...` is installed by that import as well. The original
`use Developer::Dashboard::GoRoutine` import remains available.

Use `go` to run a Perl callback on a native worker and `wait_all` when the
parent needs a completion barrier. Workers execute in cloned Perl interpreters.
On Windows, cloning also requests the host-clone flag when the active Perl
headers provide it, while retaining the pointer table needed to map callbacks.
The process-wide worker count is drained during normal interpreter shutdown,
and callback exceptions are reported as Perl warnings rather than silently
discarded.

The GoRoutine 0.04 contract adds graph-based sharing through `share`; it is
distinct from the GoRoutine 0.05 routine-control API. GoRoutine 0.05 makes
`go` return a `Developer::Dashboard::GoRoutine::Routine` handle with
`is_running`, `age`, `status`, `kill`, `timeout`, and `is_killed`
methods. Timeouts can be replaced or disabled with zero, and Perl `exit`
inside a worker ends that worker rather than the parent process. Cancellation
is cooperative at Perl opcode boundaries. POSIX workers can also be woken from
blocking waits, but an opaque native or system call is not forcibly terminated;
use `spawn` when an independently terminable process is required.

`share` makes an object graph visible across the parent and worker
interpreters. Supported values are scalars, hashes, arrays, nested combinations,
scalar references, and ordinary blessed objects whose data is held by those
Perl reference types. The API preserves aliases, cycles, blessing, normal
dereferencing, and methods that operate on shared Perl data. Perl Unicode string
semantics are preserved across the XS boundary. Compiled regular expressions
are shared as pattern text and reconstructed as native `REGEXP` references,
including inline modifiers. Named format references are shared as fully
qualified symbol names and resolved as native `FORMAT` references in each
interpreter. Scalar updates and hash/array structural operations are protected
by a native lock. References to
opaque interpreter or library resources, including code references, file or
socket handles, and objects backed by native pointers, are not supported as
shared data.

For example:

    use Developer::Dashboard;

    share my $state = { completed => 0, results => [] };
    go sub {
        $state->{completed}++;
        push $state->{results}->@*, { ok => 1 };
    } for 1 .. 4;
    wait_all();

`spawn`, `process_running`, `process_exited`, `wait_process`, and
`terminate_process` are a separate API for OS child processes. `spawn` takes
an executable argument vector and optional working-directory and standard-
stream paths; it does not invoke a shell. Use it where a distinct process ID,
process isolation, or child-process lifecycle is required. Worker threads are
not substitutes for those process semantics.

# MAINTAINER GUIDE

Build, change, and verify the project using these contributor notes.

## Local Development

Follow `CONTRIBUTING.pod` for the complete contributor workflow.

Build a distribution archive:

    dzil clean
    dzil build

Run the checkout's command line interface:

    perl -Ilib bin/d2 help
    perl -Ilib bin/d2 version

When documentation changes, regenerate this README from the main POD:

    script/sync-readme-from-pod

## Testing And Coverage

### Test suite

Run the full Perl test suite from the repository root:

    prove -lr t

The maintained end-to-end scenario plan defines expected routes, inputs, and
outputs. Hosted workflows provide additional platform checks and packaging
verification.

Tests that observe managed collector child output must wait for the asynchronous
log event with a bounded wall-clock timeout, then keep an explicit assertion
that the expected message arrived. In `t/07-core-units.t`, the wait belongs in
the `broken-loop` test before its child is stopped and the log is asserted; do
not put it in a neighboring collector test. This avoids assuming one fixed
sleep is enough on every hosted runner.

For local GitHub Actions runs executed through `act`, use:

    d2 github-workflow --container-options "--init"

The init process reaps orphaned child processes so process-group cleanup tests
observe the expected exit behavior. This option does not skip tests or change
their assertions.

Pull requests are checked by the shared Jenkins job `D2/testing-v1`, which
runs the full suite on macOS arm64, Linux amd64, Linux arm64, and Windows
amd64. Linux and macOS install `Devel::Cover` into the local
dependency tree and export that tree through `PERL5LIB` before running the
complete suite. Coverage-gate regression tests launch child Perl processes, so
those processes must resolve the same coverage serializer and project
dependencies as the parent test process.

When a MakeMaker build has created `blib/arch`, dashboard-managed Perl
environments put that directory ahead of installed Perl libraries. This keeps
source modules paired with the checkout's freshly built XS extension instead
of loading an older installed binary that may not provide the current XSUB
API. The coverage gate also includes `blib/arch` in its child-process
`PERL5LIB`, while the test suite continues loading its Perl modules from
`lib/`.

`Devel::Cover` is declared as a test prerequisite in the distribution
metadata. This lets a clean release-tarball test environment run its coverage
gate tests without an undeclared manual install. It is not an end-user runtime
dependency.

On macOS ARM64, the same workflow installs Homebrew `openssl@3`, verifies that
its headers and `libssl.dylib` are present for ARM64, and exports the formula
prefix as `OPENSSL_PREFIX` before building `Net::SSLeay`. This makes the
OpenSSL selection explicit for the native TLS dependency used by
`IO::Socket::SSL` and `LWP::Protocol::https`. The runner log now includes
verbose diagnostics from this focused `Net::SSLeay` build if it fails.

Each platform stage builds the Dashboard XS extension before running the
coverage suite. Unix build and coverage steps use Bash; Windows amd64 uses
PowerShell, and Windows arm64 uses the native CLANGARM64 Perl and toolchain. The
Windows jobs check their runner architectures and fail if the native target is
not available; they do not report skipped native tests as a pass.

Checkout dependencies are installed into `local/lib/perl5`. The Linux
workflow adds that directory to `PERL5LIB` before invoking `perl Makefile.PL`,
because the configure-time `File::ShareDir::Install` dependency is needed
before MakeMaker can create `blib`. Linux also installs
`libayatana-appindicator3-dev` and `libgtk-3-dev` before building the native
System Menu helper; these provide the pkg-config libraries and headers required
by `native/system_menu_helper_linux.c`. On Linux, `Makefile.PL` checks for
both pkg-config modules. If either is unavailable, it prints a notice and omits
the optional helper target so CPAN testers without desktop headers can still
build and test the distribution; invoking the System Menu without its helper
still fails clearly. Set `DD_REQUIRE_SYSTEM_MENU_HELPER=1` to require the
native helper, as the Linux coverage workflow does. The Windows builds use
Perl's configured path separator when assembling the same local library path.
Workflow regression tests check these setup requirements.

The Linux coverage gate passes `blib/arch` and the local dependency library
through `PERL5LIB` after compiling the extension. It instruments `lib/` rather
than copied `blib/lib` sources. This ensures child Perl processes load the
native extension built by the current checkout and keeps coverage from counting
duplicate source copies.

### Library coverage

Install Devel::Cover into the local development library and run the repository
gate:

    cpanm --no-wget --notest --local-lib-contained ./.perl5 Devel::Cover
    export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
    export PATH="$PWD/.perl5/bin:$PATH"
    perl script/coverage-gate

The gate requires 100.0% statement, subroutine, branch, and condition coverage
for `lib/`. Its report disables optional `gcov` output from compiled XS
artefacts: this gate measures Perl modules, while native XS behavior is checked
by functional tests, and extra C-file tables or diagnostics would invalidate
the single-table report parser. The instrumented run also excludes the
repository `t/` tree: test files are not coverage targets, and their dynamic
fixtures can cause Devel::Cover source-map warnings. This does not reduce
coverage because the report is explicitly scoped to `lib/`. The three
GoRoutine ithread tests (`t/231`, `t/237` and `t/238`) run in a separate,
uninstrumented `prove` process because Devel::Cover cannot safely instrument
ithreads. They remain mandatory tests, and a failure in either suite prevents a
coverage verdict. A passing run exits with status `0`. Run one coverage job at
a time on a host.

### Integration and release checks

For an installed-package check in a blank environment, run:

    integration/blank-env/run-host-integration.sh

After building a distribution, check its release metadata and kwalitee with:

    prove -lv t/36-release-kwalitee.t

Security-sensitive changes require the OWASP ASVS 5.0 review and a cross-check
against the OWASP Top 10, alongside repository security checks. The full
contribution and release sequence is documented in the contributor guide.

Push a `vX.XX` tag so the tag-triggered GitHub release workflow runs. It
publishes tarball, checksum, and detached signature assets. The release also
publishes a `.intoto.jsonl` provenance asset; build provenance, not merely a
signature, is required for the Signed-Releases Scorecard check.

Changing `dist.ini` alone does not create a GitHub Release. The pushed tag must
match the distribution version and point at the commit containing that version.
The release workflow runs tests and all-metric coverage before building or
publishing; if either gate fails, the previous successful GitHub Release remains
the latest. Check the tag's workflow run and its first failed step before
retrying.

Some optional native integrations are unavailable on release runners. Their
success and failure paths therefore need deterministic fake-backend tests so
the coverage gate verifies the actual adapter logic without relying on a host
library being installed.

Do not treat Scorecard as a pre-commit local gate. Finish local tests,
documentation, security, coverage, and packaging checks, then commit and push
with the authenticated `git-push-mf` helper before running live Scorecard.
For repository-fixable findings, repeat the sequence fix -> test -> commit -> push -> rerun scorecard until the checks pass.

Run numeric coverage QA after the normal `prove -lr t` test gate. It applies
to every change, not only releases; the target is 100.0 on all four metrics:
statement, branch, condition, and subroutine coverage for `lib/`.

# SEE ALSO

["Main Concepts"](#main-concepts),
["Working With Collectors"](#working-with-collectors),
["Runtime Lifecycle"](#runtime-lifecycle),
["Skills System"](#skills-system)

# AUTHOR

Developer Dashboard Contributors

# LICENCE

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT licence. The repository root `LICENSE` file carries the
canonical MIT text used for repository metadata, GitHub licence detection, and
distribution packaging.

Like most widely used open-source licences, those licence texts include strong
disclaimers. In practical terms the software is provided `"as is"`, no
warranty is given, and the authors are not accepting liability for damages
caused by somebody using the free software wrongly or suffering a problem on
their own side. That licence disclaimer is the main baseline protection for
normal open-source distribution, although it is not unlimited and local law
can still matter.
