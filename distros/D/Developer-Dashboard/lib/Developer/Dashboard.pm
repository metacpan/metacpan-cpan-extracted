package Developer::Dashboard;

use strict;
use warnings;

our $VERSION = '0.94';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Developer::Dashboard - a local home for development work

=head1 VERSION

0.94

=head1 INTRODUCTION

Developer::Dashboard gives a developer one place to organize the moving parts of day-to-day work.

Without it, local development usually ends up spread across shell history,
ad-hoc scripts, browser bookmarks, half-remembered file paths, one-off health
checks, and project-specific Docker commands. With it, those pieces can live
behind one entrypoint: a browser home, a prompt status layer, and a CLI
toolchain that all read from the same runtime.

It brings together browser pages, saved notes, helper actions, collectors,
prompt indicators, path aliases, open-file shortcuts, data query tools, and
Docker Compose helpers so local development can stay centered around one
consistent home instead of a pile of disconnected scripts and tabs.

When the current project contains F<./.developer-dashboard>, that tree becomes
the first runtime lookup root for dashboard-managed files. The home runtime
under F<~/.developer-dashboard> stays as the fallback base, so project-local
bookmarks, config, CLI hooks, helper users, sessions, and isolated docker
service folders can override home defaults without losing shared fallback data
that is not redefined locally.

Release tarballs contain installable runtime artifacts only; local Dist::Zilla release-builder configuration is kept out of the shipped archive.
Frequently used built-in commands such as C<of>, C<open-file>, C<pjq>, C<pyq>,
C<ptomq>, and C<pjp> are also installed as standalone executables so they can
run directly without loading the full C<dashboard> runtime.
Before publishing a release, the built tarball should be smoke-tested with
C<cpanm> from the artifact itself so the shipped archive matches the fixed
source tree.
Repository metadata should also keep explicit repository links, shipped module
C<provides>, and root F<SECURITY.md> / F<CONTRIBUTING.md> policy files aligned
for CPAN and Kwalitee consumers.

It provides a small ecosystem for:

=over 4

=item *

saved and transient dashboard pages built from the original bookmark-file shape

=item *

legacy bookmark syntax compatibility using the original
C<:--------------------------------------------------------------------------------:> separator plus directives such as
C<TITLE:>, C<STASH:>, C<HTML:>, C<FORM.TT:>, C<FORM:>, and C<CODE1:>

=item *

Template Toolkit rendering for C<HTML:> and C<FORM.TT:>, with access to
C<stash>, C<ENV>, and C<SYSTEM>

=item *

legacy C<CODE*> execution with captured C<STDOUT> rendered into the page and
captured C<STDERR> rendered as visible errors

=item *

legacy-style per-page sandpit isolation so one bookmark run can share runtime
variables across C<CODE*> blocks without leaking them into later page runs

=item *

old-style root editor behavior with a free-form bookmark textarea when no path is provided

=item *

file-backed collectors and indicators

=item *

prompt rendering for C<PS1>

=item *

project/path discovery helpers

=item *

a lightweight local web interface

=item *

action execution with trusted and safer page boundaries

=item *

config-backed providers, path aliases, and compose overlays

=item *

update scripts and release packaging for CPAN distribution

=back

Developer Dashboard is meant to become the developer's working home:

=over 4

=item *

shared nav fragments from saved C<nav/*.tt> bookmarks rendered between the top
chrome and the main page body on other saved pages

=item *

a local dashboard page that can hold links, notes, forms, actions, and
rendered output

=item *

a prompt layer that shows live status for the things you care about

=item *

a command surface for opening files, jumping to known paths, querying data, and
running repeatable local tasks

=item *

a configurable runtime that can adapt to each codebase without losing one
familiar entrypoint

=back

=head2 Shared Nav Fragments

If C<nav/*.tt> files exist under the saved bookmark root, every non-nav page
render includes them between the top chrome and the main page body.

For the default runtime that means files such as:

=over 4

=item *

F<~/.developer-dashboard/dashboards/nav/foo.tt>

=item *

F<~/.developer-dashboard/dashboards/nav/bar.tt>

=back

And with route access such as:

=over 4

=item *

C</app/nav/foo.tt>

=item *

C</page/nav/foo.tt/edit>

=item *

C</page/nav/foo.tt/source>

=back

The bookmark editor can save those nested ids directly, for example
C<BOOKMARK: nav/foo.tt>. On a page like C</app/index>, the direct C<nav/*.tt>
files are loaded in sorted filename order, rendered through the normal page
runtime, and inserted above the page body. Non-C<.tt> files and subdirectories
under C<nav/> are ignored by that shared-nav renderer.

Shared nav fragments and normal bookmark pages both render through Template
Toolkit with C<env.current_page> set to the active request path, such as
C</app/index>. The same path is also available as
C<env.runtime_context.current_page>, alongside the rest of the request-time
runtime context.

=head2 What You Get

=over 4

=item *

a browser interface on port C<7890> for pages, status, editing, and helper
access

=item *

a shell entrypoint for file navigation, page operations, collectors,
indicators, auth, and Docker Compose

=item *

saved runtime state that lets the browser, prompt, and CLI all see the same
prepared information

=item *

a place to collect project-specific shortcuts without rebuilding your daily
workflow for every repo

=back

=head2 Web Interface And Access Model

Run the web interface with:

  dashboard serve

By default it listens on C<0.0.0.0:7890>, so you can open it in a browser at:

  http://127.0.0.1:7890/

The access model is deliberate:

=over 4

=item *

exact numeric loopback admin access on C<127.0.0.1> does not require a
password

=item *

helper access is for everyone else, including C<localhost>, other hosts, and
other machines on the network

=item *

helper logins let you share the dashboard safely without turning every browser
request into full local-admin access

=back

In practice that means the developer at the machine gets friction-free local
admin access, while shared or forwarded access is forced through explicit
helper accounts.

=head2 Collectors, Indicators, And PS1

Collectors are background or on-demand jobs that prepare state for the rest of
the dashboard. A collector can run a shell command or a Perl snippet, then
store stdout, stderr, exit code, and timestamps as file-backed runtime data.

That prepared state drives indicators. Indicators are the short status records
used by:

=over 4

=item *

the shell prompt rendered by C<dashboard ps1>

=item *

the top-right status strip in the web interface

=item *

CLI inspection commands such as C<dashboard indicator list>

=back

This matters because prompt and browser status should be cheap to render.
Instead of re-running a Docker check, VPN probe, or project health command
every time the prompt draws, a collector prepares the answer once and the rest
of the system reads the cached result.

=head2 Why It Works As A Developer Home

The pieces are designed to reinforce each other:

=over 4

=item *

pages give you a browser home for links, notes, forms, and actions

=item *

collectors prepare state for indicators and prompt rendering

=item *

indicators summarize that state in both the browser and the shell

=item *

path aliases, open-file helpers, and data query commands shorten the jump from
I know what I need to I am at the file or value now

=item *

Docker Compose helpers keep recurring container workflows behind the same
C<dashboard> entrypoint

=back

That combination makes the dashboard useful as a real daily base instead of
just another utility script.

=head2 Not Just For Perl

Developer Dashboard is implemented in Perl, but it is not only for Perl
developers.

It is useful anywhere a developer needs:

=over 4

=item *

a local browser home

=item *

repeatable health checks and status indicators

=item *

path shortcuts and file-opening helpers

=item *

JSON, YAML, TOML, or properties inspection from the CLI

=item *

a consistent Docker Compose wrapper

=back

The toolchain already understands Perl module names, Java class names, direct
files, structured-data formats, and project-local compose flows, so it suits
mixed-language teams and polyglot repositories as well as Perl-heavy work.

Project-specific behavior is added through configuration, saved pages, and
user CLI extensions.

=head1 DOCUMENTATION

=head2 Main Concepts

=over 4

=item * Path Registry

L<Developer::Dashboard::PathRegistry> resolves the runtime roots that
everything else depends on, such as dashboards, config, collectors,
indicators, CLI hooks, logs, and cache.

=item * File Registry

L<Developer::Dashboard::FileRegistry> resolves stable file locations on top of
the path registry so the rest of the system can read and write well-known
runtime files without duplicating path logic.

=item * Page Model

L<Developer::Dashboard::PageDocument> and L<Developer::Dashboard::PageStore>
implement the saved and transient page model, including bookmark-style source
documents, encoded transient pages, and persistent bookmark storage.

=item * Page Resolver

L<Developer::Dashboard::PageResolver> resolves saved pages and provider pages
so browser pages and actions can come from both built-in and config-backed
sources.

=item * Actions

L<Developer::Dashboard::ActionRunner> executes built-in actions and trusted
local command actions with cwd, env, timeout, background support, and encoded
action transport, letting pages act as operational dashboards instead of static
documents.

=item * Collectors

L<Developer::Dashboard::Collector> and
L<Developer::Dashboard::CollectorRunner> implement file-backed prepared-data
jobs with managed loop metadata, timeout/env handling, interval and cron-style
scheduling, process-title validation, duplicate prevention, and collector
inspection data. This is the prepared-state layer that feeds indicators,
prompt status, and operational pages.

=item * Indicators and Prompt

L<Developer::Dashboard::IndicatorStore> and L<Developer::Dashboard::Prompt>
expose cached state to shell prompts and dashboards, including compact versus
extended prompt rendering, stale-state marking, generic built-in indicator
refresh, and page-header status payloads for the web UI.

=item * Web Layer

L<Developer::Dashboard::Web::App> and
L<Developer::Dashboard::Web::Server> provide the browser interface on port
C<7890>, including the root editor, page rendering, login/logout, helper
sessions, and the exact-loopback admin trust model.

=item * Open File Commands

C<dashboard of> and C<dashboard open-file> resolve direct files, C<file:line>
references, Perl module names, Java class names, and recursive file-pattern
matches under a resolved scope so the dashboard can shorten navigation work
across different stacks.

=item * Data Query Commands

C<dashboard pjq>, C<dashboard pyq>, C<dashboard ptomq>, and C<dashboard pjp>
parse JSON, YAML, TOML, and Java properties input, then optionally extract a
dotted path and print a scalar or canonical JSON, giving the CLI a small
data-inspection toolkit that fits naturally into shell workflows.

=item * Standalone CLI Commands

Standalone C<of>, C<open-file>, C<pjq>, C<pyq>, C<ptomq>, and C<pjp> provide
the same behavior directly, without proxying through the main C<dashboard>
command, for lighter-weight shell usage.

=item * Runtime Manager

L<Developer::Dashboard::RuntimeManager> manages the background web service and
collector lifecycle with process-title validation, C<pkill>-style fallback
shutdown, and restart orchestration, tying the browser and prepared-state
loops together as one runtime.

=item * Update Manager

L<Developer::Dashboard::UpdateManager> runs ordered update scripts and
restarts validated collector loops when needed, giving the runtime a
controlled bootstrap and upgrade path.

=item * Docker Compose Resolver

L<Developer::Dashboard::DockerCompose> resolves project-aware compose files,
explicit overlay layers, services, addons, modes, env injection, and the
final C<docker compose> command so container workflows can live inside the
same dashboard ecosystem instead of in separate wrapper scripts.

=back

=head2 Environment Variables

The distribution supports these compatibility-style customization variables:

=over 4

=item * C<DEVELOPER_DASHBOARD_BOOKMARKS>

Override the saved page root.

=item * C<DEVELOPER_DASHBOARD_CHECKERS>

Filter enabled collector/checker names.

=item * C<DEVELOPER_DASHBOARD_CONFIGS>

Override the config root.

=back

=head2 User CLI Extensions

Unknown top-level subcommands can be provided by executable files under
F<./.developer-dashboard/cli> first and then F<~/.developer-dashboard/cli>.
For example, C<dashboard foobar a b> will exec the first matching
F<cli/foobar> with C<a b> as argv, while preserving stdin, stdout, and
stderr.

Per-command hook files can live under either
F<./.developer-dashboard/cli/E<lt>commandE<gt>> or
F<./.developer-dashboard/cli/E<lt>commandE<gt>.d> first, then the same paths
under F<~/.developer-dashboard/cli/>. Executable files in the selected
directory are run in sorted filename order before the real command runs,
non-executable files are skipped, and each hook now streams its own
C<stdout> and C<stderr> live to the terminal while still accumulating those
channels into C<RESULT> as JSON. Built-in commands such as C<dashboard pjq>
use the same hook directory. A
directory-backed custom command can provide its real executable as
F<~/.developer-dashboard/cli/E<lt>commandE<gt>/run>, and that runner receives
the final C<RESULT> environment variable. After each hook finishes, the updated
C<RESULT> JSON is written back into the environment before the next sorted hook
starts, so later hook scripts can react to earlier hook output.

Perl hook code can use C<Runtime::Result> to decode C<RESULT> safely and read
per-hook C<stdout>, C<stderr>, exit codes, or the last recorded hook entry.

=head2 Open File Commands

C<dashboard of> is the shorthand name for C<dashboard open-file>.

These commands support:

=over 4

=item *

direct file paths

=item *

C<file:line> references

=item *

Perl module names such as C<My::Module>

=item *

Java class names such as C<com.example.App>

=item *

recursive pattern searches inside a resolved directory alias or path

=back

If C<VISUAL> or C<EDITOR> is set, C<dashboard of> and
C<dashboard open-file> will exec that editor unless C<--print> is used.

=head2 Data Query Commands

These built-in commands parse structured text and optionally extract a dotted
path:

=over 4

=item *

C<dashboard pjq [path] [file]> for JSON

=item *

C<dashboard pyq [path] [file]> for YAML

=item *

C<dashboard ptomq [path] [file]> for TOML

=item *

C<dashboard pjp [path] [file]> for Java properties

=back

If the selected value is a hash or array, the command prints canonical JSON.
If the selected value is a scalar, it prints the scalar plus a trailing
newline.

The file path and query path are order-independent, and C<$d> selects the
whole parsed document. For example, C<cat file.json | dashboard pjq '$d'> and
C<dashboard pjq file.json '$d'> return the same result. The same contract
applies to C<pyq>, C<ptomq>, and C<pjp>.

=head1 MANUAL

=head2 Installation

Install from CPAN with:

  cpanm Developer::Dashboard

Or install from a checkout with:

  perl Makefile.PL
  make
  make test
  make install

=head2 Local Development

Build the distribution:

  rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
  dzil build

Run the CLI directly from the repository:

  perl -Ilib bin/dashboard init
  perl -Ilib bin/dashboard auth add-user <username> <password>
  perl -Ilib bin/dashboard version
  perl -Ilib bin/dashboard of --print My::Module
  perl -Ilib bin/dashboard open-file --print com.example.App
  printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard pjq alpha.beta
  printf 'alpha:\n  beta: 3\n' | perl -Ilib bin/dashboard pyq alpha.beta
  mkdir -p ~/.developer-dashboard/cli/update.d
  printf '#!/usr/bin/env perl\nuse Runtime::Result;\nprint Runtime::Result::stdout(q{01-runtime});\nprint $ENV{RESULT} // q{}\n' > ~/.developer-dashboard/cli/update
  chmod +x ~/.developer-dashboard/cli/update
  printf '#!/bin/sh\necho runtime-update\n' > ~/.developer-dashboard/cli/update.d/01-runtime
  chmod +x ~/.developer-dashboard/cli/update.d/01-runtime
  perl -Ilib bin/dashboard update
  perl -Ilib bin/dashboard serve
  perl -Ilib bin/dashboard stop
  perl -Ilib bin/dashboard restart

User CLI extensions can be tested from the repository too:

  mkdir -p ~/.developer-dashboard/cli
  printf '#!/bin/sh\ncat\n' > ~/.developer-dashboard/cli/foobar
  chmod +x ~/.developer-dashboard/cli/foobar
  printf 'hello\n' | perl -Ilib bin/dashboard foobar

  mkdir -p ~/.developer-dashboard/cli/pjq
  printf '#!/usr/bin/env perl\nprint "seed\\n";\n' > ~/.developer-dashboard/cli/pjq/00-seed.pl
  chmod +x ~/.developer-dashboard/cli/pjq/00-seed.pl
  printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard pjq alpha.beta

Each top-level dashboard command can also use an optional hook directory at
F<~/.developer-dashboard/cli/E<lt>commandE<gt>>. Executable files from that
directory run in sorted filename order before the real command starts,
non-executable files are skipped, and the captured stdout/stderr from the hook
files are accumulated into C<$ENV{RESULT}> as JSON for later hooks and the
final command. Directory-backed custom commands can use
F<~/.developer-dashboard/cli/E<lt>commandE<gt>/run> as the actual executable.
If a subcommand does not have a built-in implementation, the real command can
be supplied as F<~/.developer-dashboard/cli/E<lt>commandE<gt>> or
F<~/.developer-dashboard/cli/E<lt>commandE<gt>/run>.

If you want C<dashboard update>, provide it as a normal user command at
F<~/.developer-dashboard/cli/update> or
F<~/.developer-dashboard/cli/update/run>. Its hook files can live under
F<~/.developer-dashboard/cli/update> or
F<~/.developer-dashboard/cli/update.d>, and the real command receives the
final C<RESULT> JSON through the environment after those hook files run.
Each later hook also sees the latest rewritten C<RESULT> from the earlier hook
set, and Perl code can read that payload through C<Runtime::Result>.

Use C<dashboard version> to print the installed Developer Dashboard version.

The blank-container integration harness applies fake-project dashboard override
environment variables only after C<cpanm> finishes installing the tarball so
the shipped test suite still runs against a clean runtime.

=head2 First Run

Initialize the runtime:

  dashboard init

Inspect resolved paths:

  dashboard paths
  dashboard path resolve bookmarks_root
  dashboard path add foobar /tmp/foobar
  dashboard path del foobar

Custom path aliases are stored in the effective dashboard config root so shell
helpers such as C<cdr foobar> and C<which_dir foobar> keep working across
sessions. When a project-local F<./.developer-dashboard> tree exists, alias
writes go there first; otherwise they go to the home runtime. When an alias
points inside the current home directory, the stored config uses C<$HOME/...>
instead of a hard-coded absolute home path so a shared fallback runtime
remains portable across different developer accounts. Re-adding an existing
alias updates it without error, and deleting a missing alias is also safe.

Legacy C<Folder> compatibility also accepts the modern root-style names
through C<AUTOLOAD>, so older code can use either C<Folder-E<gt>dd> or
C<Folder-E<gt>runtime_root>, and likewise C<bookmarks_root> and
C<config_root>. Before C<Folder-E<gt>configure(...)> runs, those
runtime-backed names lazily bootstrap a default dashboard path registry from
C<$HOME> instead of dying.

Render shell bootstrap:

  dashboard shell bash

Resolve or open files from the CLI:

  dashboard of --print My::Module
  dashboard open-file --print com.example.App
  dashboard open-file --print path/to/file.txt
  dashboard open-file --print bookmarks welcome

Query structured files from the CLI:

  printf '{"alpha":{"beta":2}}' | dashboard pjq alpha.beta
  printf 'alpha:\n  beta: 3\n' | dashboard pyq alpha.beta
  printf '[alpha]\nbeta = 4\n' | dashboard ptomq alpha.beta
  printf 'alpha.beta=5\n' | dashboard pjp alpha.beta
  dashboard pjq file.json '$d'

Start the local app:

  dashboard serve

Open the root path with no bookmark path to get the free-form bookmark editor directly.

Stop the local app and collector loops:

  dashboard stop

Restart the local app and configured collector loops:

  dashboard restart

Create a helper login user:

  dashboard auth add-user <username> <password>

Remove a helper login user:

  dashboard auth remove-user helper

Helper sessions show a Logout link in the page chrome. Logging out removes both
the helper session and that helper account. Helper page views also show the
helper username in the top-right chrome instead of the local system account.
Exact-loopback admin requests do not show a Logout link.

=head2 Working With Pages

Create a starter page document:

  dashboard page new sample "Sample Page"

Save a page:

  dashboard page new sample "Sample Page" | dashboard page save sample

List saved pages:

  dashboard page list

Render a saved page:

  dashboard page render sample

Encode and decode transient pages:

  dashboard page show sample | dashboard page encode
  dashboard page show sample | dashboard page encode | dashboard page decode

Run a page action:

  dashboard action run system-status paths

Bookmark documents use the original separator-line format with directive
headers such as C<TITLE:>, C<STASH:>, C<HTML:>, C<FORM.TT:>, C<FORM:>, and
C<CODE1:>.

Posting a bookmark document with C<BOOKMARK: some-id> back through the root
editor now saves it to the bookmark store so C</app/some-id> resolves it
immediately.

The browser editor highlights directive sections, HTML, CSS, JavaScript, and
Perl C<CODE*> content directly inside the editing surface rather than in a
separate preview pane.

Edit and source views preserve raw Template Toolkit placeholders inside
C<HTML:> and C<FORM.TT:> sections, so values such as C<[% title %]> are kept
in the bookmark source instead of being rewritten to rendered HTML after a
browser save.

Template Toolkit rendering exposes the page title as C<title>, so a bookmark
with C<TITLE: Sample Dashboard> can reference it directly inside C<HTML:> or
C<FORM.TT:> with C<[% title %]>. Transient play and view-source links are
also encoded from the raw bookmark instruction text when it is available, so
C<[% stash.foo %]> stays in source views instead of being baked into the
rendered scalar value after a render pass.

Legacy C<CODE*> blocks now run before Template Toolkit rendering during
C<prepare_page>, so a block such as C<CODE1: { a => 1 }> can feed
C<[% stash.a %]> in the page body. Returned hash and array values are also
dumped into the runtime output area, so C<CODE1: { a => 1 }> both populates
stash and shows the legacy-style dumped value below the rendered page body.
The C<hide> helper no longer discards already-printed STDOUT, so
C<CODE2: hide print $a> keeps the printed value while suppressing the Perl
return value from affecting later merge logic.

Page C<TITLE:> values only populate the HTML C<E<lt>titleE<gt>> element. If a
bookmark should show its title in the page body, add it explicitly inside
C<HTML:>, for example with C<[% title %]>.

C</apps> redirects to C</app/index>, and C</app/E<lt>nameE<gt>> can load
either a saved bookmark document or a saved ajax/url bookmark file.

=head2 Working With Collectors

Initialize example collector config:

  dashboard config init

Run a collector once:

  dashboard collector run example.collector

List collector status:

  dashboard collector list

Collector jobs support two execution fields:

=over 4

=item *

C<command> runs a shell command string through C<sh -c>

=item *

C<code> runs Perl code directly inside the collector runtime

=back

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
      }
    ]
  }

Collector indicators follow the collector exit code automatically: C<0>
stores an C<ok> indicator state and any non-zero exit code stores C<error>.
When C<indicator.name> is omitted, the collector name is reused
automatically. When C<indicator.label> is omitted, it defaults to that same
name. Configured collector indicators are seeded immediately, so prompt and
page status strips show them before the first collector run. Before a
collector has produced real output it appears as missing. Prompt output
renders an explicit status glyph in front of the collector icon, so
successful checks show fragments such as C<✅🔑> while failing or not-yet-run
checks show fragments such as C<🚨🔑>.
The blank-environment integration flow also keeps a regression for mixed
collector health: one intentionally broken Perl collector must stay red
without stopping a second healthy collector from staying green in
C<dashboard indicator list>, C<dashboard ps1>, and C</system/status>.

=head2 Docker Compose

Inspect the resolved compose stack without running Docker:

  dashboard docker compose --dry-run config

Include addons or modes:

  dashboard docker compose --addon mailhog --mode dev up -d
  dashboard docker compose config green
  dashboard docker compose config

The resolver also supports old-style isolated service folders without adding
entries to dashboard JSON config. If
C<./.developer-dashboard/docker/green/compose.yml> exists in the current
project it wins; otherwise the resolver falls back to
C<~/.developer-dashboard/config/docker/green/compose.yml>.
C<dashboard docker compose config green> or
C<dashboard docker compose up green> will pick it up automatically by
inferring service names from the passthrough compose args before the real
C<docker compose> command is assembled. If no service name is passed, the
resolver scans isolated service folders and preloads every non-disabled folder.
If a folder contains C<disabled.yml> it is skipped. Each isolated folder
contributes C<development.compose.yml> when present, otherwise C<compose.yml>.

During compose execution the dashboard exports C<DDDC> as the effective
config-root docker directory for the current runtime, so compose YAML can keep using
C<${DDDC}> paths inside the YAML itself. Wrapper flags such as
C<--service>, C<--addon>, C<--mode>, C<--project>, and C<--dry-run> are
consumed first, and all remaining docker compose flags such as C<-d> and
C<--build> pass straight through to the real C<docker compose> command.
When C<--dry-run> is omitted, the dashboard hands off with C<exec> so the
terminal sees the normal streaming output from C<docker compose> itself
instead of a dashboard JSON wrapper.

=head2 Prompt Integration

Render prompt text directly:

  dashboard ps1 --jobs 2

Generate bash bootstrap:

  dashboard shell bash

=head2 Browser Access Model

The browser security model follows the legacy local-first trust concept:

=over 4

=item *

requests from exact C<127.0.0.1> with a numeric C<Host> of C<127.0.0.1> are treated as local admin

=item *

requests from other IPs or from hostnames such as C<localhost> are treated as helper access

=item *

helper access requires a login backed by local file-based user and session records

=item *

helper sessions are file-backed, bound to the originating remote address, and expire automatically

=item *

helper passwords must be at least 8 characters long

=back

This keeps the fast path for exact loopback access while making non-canonical or remote access explicit.

The editor and rendered pages also include a shared top chrome with share and
source links on the left and the original status-plus-alias indicator strip on
the right, refreshed from C</system/status>.
That top-right area also includes the local username, the current host or IP
link, and the current date/time in the same spirit as the old local dashboard chrome.
The displayed address is discovered from the machine interfaces, preferring a VPN-style address when one is active, and the date/time is refreshed in the browser with JavaScript.
The bookmark editor also follows the old auto-submit flow, so the form submits when the textarea changes and loses focus instead of showing a manual update button.

The default web bind is C<0.0.0.0:7890>. Trust is still decided from the request origin and host header, not from the listen address.

=head2 Runtime Lifecycle

The runtime manager follows the legacy local-service pattern:

=over 4

=item *

C<dashboard serve> starts the web service in the background by default

=item *

C<dashboard serve --foreground> keeps the web service attached to the terminal

=item *

C<dashboard stop> stops both the web service and managed collector loops

=item *

C<dashboard restart> stops both, starts configured collector loops again, then starts the web service

=item *

web shutdown and duplicate detection do not trust pid files alone; they validate managed processes by environment marker or process title and use a C<pkill>-style scan fallback when needed

=back

=head2 Environment Customization

After installing with C<cpanm>, the runtime can be customized with these environment variables:

=over 4

=item * C<DEVELOPER_DASHBOARD_BOOKMARKS>

Overrides the saved page or bookmark directory.

=item * C<DEVELOPER_DASHBOARD_CHECKERS>

Limits enabled collector or checker jobs to a colon-separated list of names.

=item * C<DEVELOPER_DASHBOARD_CONFIGS>

Overrides the config directory.

=back

Collector definitions come only from dashboard configuration JSON, so config
remains the single source of truth for path aliases, providers, collectors,
and Docker compose overlays.

=head2 Testing And Coverage

Run the test suite:

  prove -lr t

Measure library coverage with Devel::Cover:

  cpanm --local-lib-contained ./.perl5 Devel::Cover
  export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
  export PATH="$PWD/.perl5/bin:$PATH"
  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
  cover -report text -select_re '^lib/' -coverage statement -coverage subroutine

The repository target is 100% statement and subroutine coverage for C<lib/>.

The coverage-closure suite includes managed collector loop start/stop paths
under C<Devel::Cover>, including wrapped fork coverage in
C<t/14-coverage-closure-extra.t>, so the covered run stays green without
breaking TAP from daemon-style child processes.

=head2 Updating Runtime State

Run your user-provided update command:

  dashboard update

If F<./.developer-dashboard/cli/update> or
F<./.developer-dashboard/cli/update/run> exists in the current project it is
used first; otherwise the home runtime fallback is used. C<dashboard update>
runs that command after any sorted hook files from F<update/> or F<update.d>.

C<dashboard init> seeds three editable starter bookmarks when they are
missing: C<welcome>, C<api-dashboard>, and C<db-dashboard>.

=head2 Blank Environment Integration

Run the host-built tarball integration flow with:

  integration/blank-env/run-host-integration.sh

This integration path builds the distribution tarball on the host with
C<dzil build>, starts a blank container with only that tarball mounted into it,
installs the tarball with C<cpanm>, and then exercises the installed
C<dashboard> command inside the clean Perl container.

Before uploading a release artifact, remove older tarballs first so only the
current release artifact remains, then validate the exact tarball that will
ship:

  rm -f Developer-Dashboard-*.tar.gz
  dzil build
  tar -tzf Developer-Dashboard-0.94.tar.gz | grep run-host-integration.sh
  cpanm /tmp/Developer-Dashboard-0.94.tar.gz -v

The harness also:

- creates a fake project with its own F<./.developer-dashboard> runtime tree
- verifies the installed CLI works against that fake project through the mounted tarball install
- seeds a user-provided fake-project F<./.developer-dashboard/cli/update> command plus F<update.d> hooks inside the container so C<dashboard update> exercises the same top-level command-hook path as every other subcommand, including later-hook reads through C<Runtime::Result>
- verifies collector failure isolation with one intentionally broken Perl config collector and one healthy config collector, and confirms the healthy indicator still stays green after C<dashboard restart>
- starts the installed web service
- uses headless Chromium to verify the root editor, a saved fake-project bookmark page from the fake project bookmark directory, and the helper login page
- verifies helper logout cleanup and runtime restart and stop behavior

=head1 FAQ

=head2 Is this tied to a specific company or codebase?

No. The core distribution is intended to be reusable for any project.

=head2 Where should project-specific behavior live?

In configuration, saved pages, and user CLI extensions. The core should stay generic.

=head2 Is the software spec implemented?

The current distribution implements the core runtime, page engine, action runner, provider loader, prompt and collector system, web lifecycle manager, and Docker Compose resolver described by the software spec.

What remains intentionally lightweight is breadth, not architecture:

- provider pages and action handlers are implemented in a compact v1 form
- legacy bookmarks are supported, with Template Toolkit rendering and one clean sandpit package per page run so C<CODE*> blocks can share state within a bookmark render without leaking runtime globals into later requests

=head2 Does it require a web framework?

No. The current distribution includes a minimal HTTP layer implemented with core Perl-oriented modules.

=head2 Why does localhost still require login?

This is intentional. The trust rule is exact and conservative: only numeric loopback on C<127.0.0.1> receives local-admin treatment.

=head2 Why is the runtime file-backed?

Because prompt rendering, dashboards, and wrappers should consume prepared state quickly instead of re-running expensive checks inline.

=head2 How are CPAN releases built?

The repository is set up to build release artifacts with Dist::Zilla, including explicit C<provides> metadata generation, and upload them to PAUSE from GitHub Actions.

Runtime release metadata pins C<JSON::XS> explicitly in Dist::Zilla so built
tarballs declare the JSON backend dependency even if automatic prerequisite
scanning misses it during PAUSE installs.

=head2 What JSON implementation does the project use?

The project uses C<JSON::XS> for JSON encoding and decoding, including shell helper decoding paths.

=head2 What does the project use for command capture and HTTP clients?

The project uses C<Capture::Tiny> for command-output capture via C<capture>, with exit codes returned from the capture block rather than read separately. There is currently no outbound HTTP client in the core runtime, so C<LWP::UserAgent> is not yet required by an active code path.

=head1 SEE ALSO

L<Developer::Dashboard::PathRegistry>,
L<Developer::Dashboard::PageStore>,
L<Developer::Dashboard::CollectorRunner>,
L<Developer::Dashboard::Prompt>

=head1 AUTHOR

Developer Dashboard Contributors

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
