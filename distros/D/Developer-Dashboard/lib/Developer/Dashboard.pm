package Developer::Dashboard;

use strict;
use warnings;

our $VERSION = '3.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Developer::Dashboard - a local home for development work

=head1 VERSION
3.04

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

The home runtime is now hardened to owner-only access by default. Directories
under F<~/.developer-dashboard> are kept at C<0700>, regular runtime files are
kept at C<0600>, and owner-executable scripts stay owner-executable at
C<0700>. Run C<dashboard doctor> to audit the current home runtime plus any
older dashboard roots still living directly under C<$HOME>, or
C<dashboard doctor --fix> to tighten those permissions in place. The same
command also reads optional hook results from
F<~/.developer-dashboard/cli/doctor.d> so users can layer in more
site-specific checks later.

Frequently used built-in commands such as C<jq>, C<yq>, C<tomq>, C<propq>,
C<iniq>, C<csvq>, C<xmlq>, C<of>, C<open-file>, and C<ticket> are staged
privately under F<~/.developer-dashboard/cli/dd/> and dispatched by
C<dashboard> without polluting the global PATH. That keeps dashboard-owned
built-ins separate from user commands and hooks under
F<~/.developer-dashboard/cli/>. Compatibility aliases C<pjq>, C<pyq>,
C<ptomq>, and C<pjp> still normalize to the renamed commands when they are
invoked through C<dashboard>.

It provides a small ecosystem for:

=over 4

=item *

saved and transient dashboard pages built from the original bookmark-file shape

=item *

bookmark-file syntax compatibility using the original
C<:--------------------------------------------------------------------------------:> separator plus directives such as
C<TITLE:>, C<STASH:>, C<HTML:>, and C<CODE1:>

=item *

Template Toolkit rendering for C<HTML:>, with access to C<stash>, C<ENV>, and
C<SYSTEM>

=item *

bookmark C<CODE*> execution with captured C<STDOUT> rendered into the page and
captured C<STDERR> rendered as visible errors

=item *

per-page sandpit isolation so one bookmark run can share runtime
variables across C<CODE*> blocks without leaking them into later page runs

=item *

old-style root editor behavior with a free-form bookmark textarea when no path is provided

=item *

file-backed collectors and indicators

=item *

prompt rendering for C<PS1> and the PowerShell C<prompt> function

=item *

project/path discovery helpers

=item *

a lightweight local web interface

=item *

action execution with trusted and safer page boundaries

=item *

config-backed providers, path aliases, and compose overlays

=item *

update scripts and installable runtime packaging

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

C</app/nav/foo.tt/edit>

=item *

C</app/nav/foo.tt/source>

=back

The bookmark editor can save those nested ids directly, for example
C<BOOKMARK: nav/foo.tt>. Raw TT/HTML fragment files under C<nav/> also work
without bookmark wrappers, for example:

  [% index = '/app/index' %]
  <a href=[% index %]>[% index %]</a>

On a page like C</app/index>, the direct C<nav/*.tt> files are loaded in
sorted filename order, rendered through the normal page runtime, and inserted
above the page body. Non-C<.tt> files, subdirectories under C<nav/>, and junk
files that do not look like TT or HTML fragments are ignored by that shared
nav renderer.

Under C<DD-OOP-LAYERS>, the shared nav renderer now scans every inherited
F<dashboards/nav/> layer from F<~/.developer-dashboard> down to the current
directory, keeps parent-only fragments visible, and lets a deeper layer
replace the same C<nav/E<lt>nameE<gt>.tt> id without losing the rest of the
shared nav set. Template includes used by those bookmarks follow the same
layered bookmark lookup path.

Shared nav fragments and normal bookmark pages both render through Template
Toolkit with C<env.current_page> set to the active request path, such as
C</app/index>. The same path is also available as
C<env.runtime_context.current_page>, alongside the rest of the request-time
runtime context. Token play renders for named bookmarks also reuse that saved
C</app/E<lt>idE<gt>> path for nav context, so shared C<nav/*.tt> fragments do
not disappear just because the browser reached the page through a transient
C</?mode=render&token=...> URL.
Shared nav markup now wraps horizontally by default and inherits the page
theme through CSS variables such as C<--panel>, C<--line>, C<--text>, and
C<--accent>, so dark bookmark themes no longer force a pale nav box or hide
nav link text against the background.

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

Run C<dashboard serve --ssl> to enable HTTPS with a generated self-signed
certificate under F<~/.developer-dashboard/certs/>, then open:

  https://127.0.0.1:7890/

When SSL mode is on, plain HTTP requests on that same host and port are
redirected to the equivalent C<https://...> URL before the dashboard route
runs. The generated certificate now carries browser-correct SAN coverage for
C<localhost>, C<127.0.0.1>, and C<::1>, automatically includes the concrete
C<--host HOST> bind target when that host is not a wildcard listen address, and
also includes any extra names or IPs listed under
C<web.ssl_subject_alt_names> in F<config/config.json>. Older dashboard certs are
rotated forward automatically when they no longer match that expected profile.
Browsers still show the normal self-signed certificate warning until you trust
the generated certificate locally.

Run C<dashboard serve --no-editor> or C<dashboard serve --no-endit> to keep
the browser in read-only mode. That hides the Share, Play, and View Source
links, blocks bookmark editor and source routes with C<403>, blocks
bookmark-save POST requests even if someone tries to hit them directly, and
persists the mode so later C<dashboard restart> runs stay read-only until you
switch it back with C<dashboard serve --editor>.

Run C<dashboard serve --no-indicators> or C<dashboard serve --no-indicator> to
clear the whole top-right browser chrome area. That hides the browser-only
indicator strip, username, host or IP link, and live date-time line without
changing C</system/status> or terminal prompt output such as C<dashboard ps1>,
and persists the mode until C<dashboard serve --indicators> turns it back on.

For example, if you want the same dashboard cert to work for one local
C</etc/hosts> alias and one LAN IP, keep the runtime config like this:

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

=over 4

=item *

numeric loopback and loopback-only hostnames such as C<localhost> do not
require a password when the request still originates from loopback

=item *

configured loopback aliases listed under C<web.ssl_subject_alt_names> are also
treated as local-admin when they still arrive from loopback

=item *

helper access is for everyone else, including non-loopback IPs and other
machines on the network

=item *

helper logins let you share the dashboard safely without turning every browser
request into full local-admin access

=back

In practice that means the developer at the machine gets friction-free local
admin access, while shared or forwarded access is forced through explicit
helper accounts.
If no helper user exists yet in the active dashboard runtime, outsider requests return
C<401> with an empty body and do not render the login form at all.
When a saved C<index> bookmark exists, opening C</> now redirects straight to
C</app/index> so the saved home page becomes the default browser entrypoint.
When no saved C<index> bookmark exists yet, C</> still opens the free-form
bookmark editor.
If a user opens an unknown saved route such as C</app/foobar>, the browser now
opens the bookmark editor with a prefilled blank bookmark for that requested
path instead of showing a 404 error page.
When helper access is sent to C</login>, the login form now keeps the original
requested path and query string in a hidden redirect target. After a
successful helper login, the browser is sent back to that saved route, such as
C</app/index>, instead of being dropped at C</>.

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
Configured collector indicators now prefer the configured icon in both places,
and when a collector is renamed the old managed indicator is cleaned up
automatically so the prompt and top-right browser strip do not show both the
old and new names at the same time. Those managed indicator records now also
preserve a newer live collector status during restart/config-sync windows, so
a healthy collector does not flicker back to C<missing> after it has already
reported C<ok>.
If C<indicator.icon> contains Template Toolkit syntax such as C<[% a %]>, the
collector runner now treats collector C<stdout> as JSON, decodes it through
C<JSON::XS>, exposes hash keys as direct template variables plus C<data>, and
persists the rendered icon as the live indicator value. Invalid JSON or TT
render failures are explicit collector errors: the collector C<stderr> records
the template problem and the indicator stays red instead of silently falling
back.

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

=head1 MODULE NAMESPACING

All project modules are scoped under the C<Developer::Dashboard::> namespace
to prevent pollution of the CPAN ecosystem. Core helper modules are available
under this namespace:

=over 4

=item * Developer::Dashboard::File

File I/O helpers with alias support for older bookmark compatibility.

=item * Developer::Dashboard::Folder

Folder path resolution and discovery with runtime registry support.

=item * Developer::Dashboard::DataHelper

JSON encoding and decoding helpers for older bookmark code.

=item * Developer::Dashboard::Zipper

Token encoding and Ajax command building for transient URL construction.

=item * Developer::Dashboard::Runtime::Result

Hook result environment variable decoding and access for command runners.

=back

Project-owned modules now live only under the C<Developer::Dashboard::>
namespace so the distribution does not pollute the CPAN ecosystem with
generic package names.

=head2 Main Concepts

=over 4

=item * Path Registry

C<Developer::Dashboard::PathRegistry> resolves the runtime roots that
everything else depends on, such as dashboards, config, collectors,
indicators, CLI hooks, logs, and cache.

=item * File Registry

C<Developer::Dashboard::FileRegistry> resolves stable file locations on top of
the path registry so the rest of the system can read and write well-known
runtime files without duplicating path logic.

=item * Page Model

C<Developer::Dashboard::PageDocument> and C<Developer::Dashboard::PageStore>
implement the saved and transient page model, including bookmark-style source
documents, encoded transient pages, and persistent bookmark storage.

=item * Page Resolver

C<Developer::Dashboard::PageResolver> resolves saved pages and provider pages
so browser pages and actions can come from both built-in and config-backed
sources.

=item * Actions

C<Developer::Dashboard::ActionRunner> executes built-in actions and trusted
local command actions with cwd, env, timeout, background support, and encoded
action transport, letting pages act as operational dashboards instead of static
documents.

=item * Collectors

C<Developer::Dashboard::Collector> and
C<Developer::Dashboard::CollectorRunner> implement file-backed prepared-data
jobs with managed loop metadata, timeout/env handling, interval and cron-style
scheduling, process-title validation, duplicate prevention, and collector
inspection data. This is the prepared-state layer that feeds indicators,
prompt status, and operational pages.

=item * Indicators and Prompt

C<Developer::Dashboard::IndicatorStore> and C<Developer::Dashboard::Prompt>
expose cached state to shell prompts and dashboards, including compact versus
extended prompt rendering, stale-state marking, generic built-in indicator
refresh, and page-header status payloads for the web UI.

=item * Web Layer

C<Developer::Dashboard::Web::DancerApp>,
C<Developer::Dashboard::Web::App>, and
C<Developer::Dashboard::Web::Server> provide the browser interface on port
C<7890>, with Dancer2 owning the HTTP route table while the web-app service
handles page rendering, login/logout, helper sessions, and the
exact-loopback admin trust model.

=item * Open File Commands

C<dashboard of> and C<dashboard open-file> resolve direct files, C<file:line>
references, Perl module names, Java class names, and recursive file-pattern
matches under a resolved scope so the dashboard can shorten navigation work
across different stacks.

=item * Data Query Commands

C<dashboard jq>, C<dashboard yq>, C<dashboard tomq>, and C<dashboard propq>
parse JSON, YAML, TOML, and Java properties input, then optionally extract a
dotted path and print a scalar or canonical JSON, giving the CLI a small
data-inspection toolkit that fits naturally into shell workflows.

=item * Private CLI Helper Assets

Private F<~/.developer-dashboard/cli/dd/> helper files provide the built-in
command behaviour without installing generic command names into the global
PATH. Query, open-file, ticket, path, and prompt commands keep dedicated
helper bodies, while the remaining built-ins stage thin wrappers that hand off
to a shared private C<_dashboard-core> runtime.

Only C<dashboard> is intended to be the public CPAN-facing command-line
entrypoint. The real built-in command bodies live outside F<bin/dashboard>
under F<share/private-cli/>, then stage into F<~/.developer-dashboard/cli/dd/>
on demand. Generic helper names such as C<ticket>, C<of>, C<open-file>,
C<jq>, C<yq>, C<tomq>, C<propq>, C<iniq>, C<csvq>, C<xmlq>, C<path>, and
C<paths> are intentionally kept out of the installed global PATH to avoid
polluting the wider Perl and shell ecosystem while still keeping
dashboard-owned commands separate from user commands under
F<~/.developer-dashboard/cli/>. While those staged helpers run, their process
title is normalized to the public C<developer-dashboard ...> form so C<ps>
output shows the user-facing command instead of the staged helper path.

C<dashboard ticket> creates or reuses a tmux session for the requested ticket
reference, seeds C<TICKET_REF> plus dashboard-friendly branch aliases into that
session environment, and attaches to it through a dashboard-managed private
helper instead of a public standalone binary.

=item * Runtime Manager

C<Developer::Dashboard::RuntimeManager> manages the background web service and
collector lifecycle with process-title validation, C<pkill>-style fallback
shutdown, and restart orchestration, tying the browser and prepared-state
loops together as one runtime.

=item * Update Manager

C<Developer::Dashboard::UpdateManager> runs ordered update scripts and
restarts validated collector loops when needed, giving the runtime a
controlled bootstrap and upgrade path.

=item * Docker Compose Resolver

C<Developer::Dashboard::DockerCompose> resolves project-aware compose files,
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

=item * C<DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS>

Allow browser execution of transient C</?token=...>, C</action?atoken=...>,
and older C</ajax?token=...> payloads. The default is off, so the web UI only
executes saved bookmark files unless this is set to a truthy value such as
C<1>, C<true>, C<yes>, or C<on>.

=back

=head2 Transient Web Token Policy

Transient page tokens still exist for CLI workflows such as C<dashboard page encode>
and C<dashboard page decode>, but browser routes that execute a transient payload
from C<token=> or C<atoken=> are disabled by default.

That means links such as:

=over 4

=item * C<http://127.0.0.1:7890/?token=...>

=item * C<http://127.0.0.1:7890/action?atoken=...>

=item * C<http://127.0.0.1:7890/ajax?token=...>

=back

return a C<403> unless C<DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS> is enabled.
Saved bookmark-file routes such as C</app/index> and
C</app/index/action/...> continue to work without that flag. Saved bookmark
editor pages also stay on their named C</app/E<lt>idE<gt>/edit> and
C</app/E<lt>idE<gt>> routes when you save from the browser, so editing an
existing bookmark file does not fall back to transient C<token=> URLs under the
default deny policy.

C<Ajax> helper calls inside saved bookmark C<CODE*> blocks should use
an explicit C<file =E<gt> 'name.json'> argument. When a saved page supplies that
name, the helper stores the Ajax Perl code under the saved dashboard ajax tree and emits a
stable saved-bookmark endpoint such as
C</ajax/name.json?type=text>. Those saved Ajax handlers
run the stored file as a real process, defaulting to Perl unless the file
starts with a shebang, and stream both C<stdout> and C<stderr> back to the
browser as they happen. That keeps bookmark Ajax workflows usable even while
transient token URLs stay disabled by default, and it means bookmark Ajax code
can rely on normal C<print>, C<warn>, C<die>, C<system>, and C<exec> process
behaviour instead of a buffered JSON wrapper.
Saved bookmark Ajax handlers also default to C<text/plain> when no explicit
C<type =E<gt> ...> argument is supplied, and the generated Perl wrapper now
enables autoflush on both C<STDOUT> and C<STDERR> so long-running handlers
show incremental output in the browser instead of stalling behind process
buffers.
If a saved handler also needs refresh-safe process reuse, pass
C<singleton =E<gt> 'NAME'> in the C<Ajax> helper. The generated url then carries
that singleton name, the Perl worker runs as C<dashboard ajax: NAME>, and the
runtime terminates any older matching Perl Ajax worker before starting the
replacement stream for the refreshed browser request. Singleton-managed Ajax
workers are also terminated by C<dashboard stop> and C<dashboard restart>, and
the bookmark page now registers a C<pagehide> cleanup beacon against
C</ajax/singleton/stop?singleton=NAME> so closing the browser tab also tears
down the matching worker instead of leaving it behind.
If C<code =E<gt> ...> is omitted, C<Ajax(file =E<gt> 'name')> targets the
existing executable at C<dashboards/ajax/name> instead of rewriting it.
Static files referenced by saved bookmarks are resolved from the effective
runtime public tree first and then from the saved bookmark root. The web layer
also provides a built-in C</js/jquery.js> compatibility shim, so bookmark pages
that expect a local jQuery-style helper still have C<$>, C<$(document).ready>,
C<$.ajax>, jqXHR-style C<.done(...)> / C<.fail(...)> / C<.always(...)>
chaining, the C<method> alias used by modern callers, and selector
C<.text(...)> support even when no runtime file has been copied into
C<dashboard/public/js> yet.

Saved bookmark editor and view-source routes also protect literal inline
script content from breaking the browser bootstrap. If a bookmark body
contains HTML such as C</script>, the editor now escapes the inline JSON
assignment used to reload the source text, so the browser keeps the full
bookmark source inside the editor instead of spilling raw text below the page.
Bookmark rendering now emits saved C<set_chain_value()> bindings after
the bookmark body HTML, so pages that declare C<var endpoints = {}> and then
call helpers from C<$(document).ready(...)> receive their saved C</ajax/...>
endpoint URLs without throwing a play-route JavaScript C<ReferenceError>.
Bookmark pages now also expose
C<fetch_value(url, target, options, formatter)>,
C<stream_value(url, target, options, formatter)>, and
C<stream_data(url, target, options, formatter)> helpers so a bookmark can bind
saved Ajax endpoints into DOM targets without hand-writing the fetch and
render boilerplate. C<stream_data()> and C<stream_value()> now use
C<XMLHttpRequest> progress events for browser-visible incremental updates, so
a saved C</ajax/...> endpoint that prints early output updates the DOM before
the request finishes. Those helpers support plain text, JSON, and HTML output
modes, and the saved Ajax endpoint bindings now run after the page declares
its endpoint root object, so C<$(document).ready(...)> callbacks can call
helpers such as C<fetch_value(endpoints.foo, '#foo')> on first render.

=head2 User CLI Extensions

Unknown top-level subcommands can be provided by executable files under
the current working directory's F<./.developer-dashboard/cli> first, then the
nearest git-backed project runtime F<./.developer-dashboard/cli> when it is a
different directory, and then F<~/.developer-dashboard/cli>. For example,
C<dashboard foobar a b> will exec the first matching
F<cli/foobar> with C<a b> as argv, while preserving stdin, stdout, and
stderr.

A direct custom command can also be stored as an executable
F<cli/E<lt>commandE<gt>.pl>, F<cli/E<lt>commandE<gt>.go>,
F<cli/E<lt>commandE<gt>.java>, F<cli/E<lt>commandE<gt>.sh>,
F<cli/E<lt>commandE<gt>.bash>, F<cli/E<lt>commandE<gt>.ps1>,
F<cli/E<lt>commandE<gt>.cmd>, or F<cli/E<lt>commandE<gt>.bat>, and
C<dashboard E<lt>commandE<gt>> resolves the same logical command name to
those files.

Concrete source-backed examples:

  dashboard hi
  dashboard foo

If F<cli/hi.go> is executable, C<dashboard hi> runs it through C<go run>.
If F<cli/foo.java> is executable, C<dashboard foo> compiles it with C<javac>
into an isolated temp directory and then runs the declared main class with
C<java>.

If a user mistypes a command, dashboard now prints an explicit unknown-command
error together with the closest matching public command before the usual usage
summary. The same guidance also applies to dotted skill commands, so
C<dashboard alpha-skill.run-tset> suggests the nearest installed dotted skill
command instead of only dumping generic help.

C<DD-OOP-LAYERS> is now the runtime contract for the whole local ecosystem.
Starting at F<~/.developer-dashboard> and walking down through every parent
directory until the current working directory, every existing
F<.developer-dashboard/> layer participates. The deepest layer stays the write
target and the first lookup hit, but bookmarks, C<nav/*.tt>, config,
collectors, indicators, auth/session state lookups, runtime
F<local/lib/perl5>, and custom CLI hooks are all inherited across the full
chain instead of only a single project-or-home split.

Per-command hook files can live under either
F<./.developer-dashboard/cli/E<lt>commandE<gt>> or
F<./.developer-dashboard/cli/E<lt>commandE<gt>.d> in every inherited layer
from F<~/.developer-dashboard> down to the current directory. Executable files
in those directories are run in sorted filename order within each layer, with
the layers themselves running top-down from home to the deepest current layer,
non-executable files are skipped, and each hook now streams its own
C<stdout> and C<stderr> live to the terminal while still accumulating those
channels into C<RESULT> as JSON. If that JSON grows too large for a safe
C<exec()> environment, C<dashboard> spills it into C<RESULT_FILE> and
C<Developer::Dashboard::Runtime::Result> reads the same logical payload from
there so later hooks and the final command still see the same result set
without tripping C<Argument list too long>. Built-in commands such as C<dashboard jq>
use the same hook directory. A
directory-backed custom command can provide its real executable as
F<~/.developer-dashboard/cli/E<lt>commandE<gt>/run>, and that runner receives
the final C<RESULT> plus C<LAST_RESULT> environment variables. After each hook
finishes, the updated C<RESULT> JSON is written back into the environment
before the next sorted hook starts, and C<LAST_RESULT> is rewritten to the
structured result for the hook that just ran, so later hook scripts can react
to earlier hook output and also inspect the immediate previous hook in a stable
shape. C<LAST_RESULT> carries C<file>, C<exit>, C<STDOUT>, and C<STDERR>.
Only an explicit C<[[STOP]]> marker in one hook's C<stderr> stops the
remaining hook files for that command. A non-zero exit code alone is still
recorded, but it does not skip later hooks. Executable F<.go> hook files and
direct F<.go> custom commands run through C<go run>. Executable F<.java>
hook files and direct F<.java> custom commands are compiled with C<javac>
into an isolated temp directory and then run through C<java> using the
declared main class from the source file.

Perl hook code can use C<Runtime::Result> to decode C<RESULT> safely, read the
immediate C<last_result>, and inspect per-hook C<stdout>, C<stderr>, exit
codes, or the last recorded hook entry.
If a Perl-backed command wants a compact final summary after its hook files
run, it can also call C<Developer::Dashboard::Runtime::Result-E<gt>report()> to print a simple
success/error report for each sorted hook file.

=head3 Layered Env Files

Environment files are part of the same C<DD-OOP-LAYERS> contract.
When C<dashboard ...> runs, it loads every participating plain-directory env
file and runtime-layer env file from root to leaf before command hooks,
custom commands, or built-in helpers execute.

That ordered runtime pass loads, when present:

=over 4

=item *

F<E<lt>rootE<gt>/.env>

=item *

F<E<lt>rootE<gt>/.env.pl>

=item *

each deeper ancestor directory F<.env>

=item *

each deeper ancestor directory F<.env.pl>

=item *

each participating F<.developer-dashboard/.env>

=item *

each participating F<.developer-dashboard/.env.pl>

=back

Deeper files win because later layers overwrite earlier keys. Plain F<.env>
files must contain explicit C<KEY=VALUE> lines, and the load order at one
directory is always F<.env> first and then F<.env.pl>. Plain F<.env> parsing
ignores blank lines, whole-line C<#> comments, whole-line C<//> comments, and
C</* ... */> block comments that can span multiple lines. Plain F<.env>
values also support:

=over 4

=item *

leading C<~> expansion to C<$HOME>

=item *

C<$NAME> expansion from the current effective environment

=item *

C<${NAME:-default}> expansion with a fallback value

=item *

C<${Namespace::function():-default}> expansion through a static Perl function

=back

Expansion can see system env keys, values loaded from earlier layers, and
values assigned by earlier lines in the same F<.env> file. Missing functions,
malformed lines, malformed keys, and unterminated block comments fail
explicitly instead of being skipped silently. Executable logic can live in
F<.env.pl>, which is run directly and may set C<%ENV> programmatically.

Skill-local env files are loaded only when a skill command or skill hook is
actually running. A normal non-skill command inherits only the root-to-leaf
runtime env chain. A skill command inherits that same runtime chain first and
then loads each participating skill root from the base installed skill layer
to the deepest matching child skill layer, applying:

=over 4

=item *

F<E<lt>skill-rootE<gt>/.env>

=item *

F<E<lt>skill-rootE<gt>/.env.pl>

=back

This means a deeper skill env can override a shared runtime key, but that
override stays isolated to the skill execution path and does not leak into
unrelated commands.

Perl code can inspect where a dashboard-managed env key came from with
C<Developer::Dashboard::EnvAudit>.

Single-key lookup:

  use Developer::Dashboard::EnvAudit;

  my $entry = Developer::Dashboard::EnvAudit->key('FOO');

That returns either C<undef> for normal system env keys or a hashref like:

  {
      value   => 'bar',
      envfile => '/full/path/to/.env',
  }

Full inventory lookup:

  my $all = Developer::Dashboard::EnvAudit->keys;

The audit records only dashboard-loaded env keys. System-provided keys that
did not come from a dashboard-managed F<.env> or F<.env.pl> file are left
untracked on purpose.

For example, a layered F<.env> file can now look like:

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

Java class names such as C<com.example.App> or C<javax.jws.WebService>

=item *

recursive regex searches inside a resolved directory alias or path

=back

Without C<--print>, C<dashboard of> and C<dashboard open-file> now behave like
the older picker workflow again: one unique match opens directly in
C<--editor>, C<VISUAL>, C<EDITOR>, or C<vim> as the final fallback, and
multiple matches render a numbered prompt. At that prompt you can press Enter
to open all matches with C<vim -p>, type one number to open one file, type comma-separated
numbers such as C<1,3>, or use a range such as C<2-5>. Scoped searches also
rank exact helper/script names before broader regex hits, so
C<dashboard of . jq> lists C<jq> and C<jq.js> ahead of C<jquery.js>. Every
scoped search token is treated as a case-insensitive regex, so
C<dashboard of . 'Ok\.js$'> matches C<ok.js> but not C<ok.json>.

Java class lookup first checks live F<.java> files under the current project,
workspace roots, and C<@INC>-adjacent source trees. If no live source file
exists, it also searches local source archives such as F<-sources.jar>,
F<-src.jar>, F<src.zip>, F<war>, and F<jar> files under the current roots,
F<~/.m2/repository>, Gradle caches, and C<JAVA_HOME>. When a local archive
still does not provide the requested class, the helper can fetch a matching
Maven source jar, cache it under
F<~/.developer-dashboard/cache/open-file/>, and then open the extracted Java
source.

=head2 Data Query Commands

These built-in commands parse structured text and can then either extract a
dotted path or evaluate a Perl expression against the decoded document through
C<$d>:

=over 4

=item *

C<dashboard jq [path] [file]> for JSON

=item *

C<dashboard yq [path] [file]> for YAML

=item *

C<dashboard tomq [path] [file]> for TOML

=item *

C<dashboard propq [path] [file]> for Java properties

=back

If the selected value is a hash or array, the command prints canonical JSON.
If the selected value is a scalar, it prints the scalar plus a trailing
newline.

The file path and query text are order-independent, and C<$d> selects the
whole parsed document. For example, C<cat file.json | dashboard jq '$d'> and
C<dashboard jq file.json '$d'> return the same result. If the query text uses
C<$d> inside a Perl expression, the command evaluates that expression against
the decoded document. For example, C<echo '{"foo":[1],"bar":[2]}' | dashboard
jq 'sort keys %$d'> prints C<["bar","foo"]>. The same contract applies to
C<yq>, C<tomq>, C<propq>, C<iniq>, C<csvq>, and C<xmlq>.

C<xmlq> follows the same decoded-data model as the other query commands. XML
elements decode into nested hashes and arrays, repeated sibling tags become
arrays, attributes live under C<_attributes>, and mixed text lives under
C<_text>. That means C<printf '<root><value>demo</value></root>' | dashboard
xmlq root.value> prints C<demo>, while C<dashboard xmlq feed.xml '$d'> prints
the full decoded XML tree as canonical JSON.

=head1 MANUAL

=head2 Installation

Bootstrap a blank Alpine, Debian, Ubuntu, Fedora, or macOS machine from a checkout with:

  ./install.sh

F<install.sh> is a checkout-only bootstrap helper. It ships in the source tree
and release tarball so operators can run it explicitly from a checkout or
extracted tarball, but CPAN and C<cpanm> do not install it as a global
command. When the installer is streamed through C<sh> without a checkout,
such as C<curl ... | sh>, it falls back to embedded Debian-family,
Alpine, and Homebrew package manifests instead of assuming repo-local
F<aptfile>, F<apkfile>, F<dnfile>, and F<brewfile> files exist on disk.

That installer reads the repo-root F<aptfile> on Debian-family hosts and runs
C<apt-get update> plus C<apt-get install -y> for the listed packages, reads
the repo-root F<apkfile> on Alpine hosts and runs
C<apk add --no-cache> for the listed packages, reads the repo-root
F<dnfile> on Fedora hosts and runs C<dnf install -y> for the listed
packages, reads the repo-root
F<brewfile> on macOS and runs C<brew install> for the listed packages,
verifies that C<node>, C<npm>, and C<npx> are available from those
bootstrap packages before finishing the install, or falls back to the embedded
copies of those package lists when the script is streamed without the checkout
files, installs Debian-family Node tooling in a conflict-aware order by
bringing in C<nodejs> first and only attempting the distro C<npm> package if
C<npm> and C<npx> are still missing, prints a visible install progress board
before doing any system changes, prints that full checklist once and then only
emits step transitions so the active pointer does not appear duplicated in
interactive terminals, explains that any upcoming C<sudo> prompt is asking for
the user's operating-system account password only for package-manager work,
bootstraps user-space Perl
tooling under F<~/perl5> with
C<cpanm --notest --local-lib-contained "$HOME/perl5" local::lib App::cpanminus>,
appends exactly one C<local::lib> bootstrap line to F<~/.bashrc>,
F<~/.zshrc>, or F<~/.profile> depending on the active shell, keeps bash
login shells wired by bridging F<~/.profile> to F<~/.bashrc>, prefers
Homebrew Perl on macOS when C<brew --prefix perl> exposes a brewed
interpreter, bootstraps a user-space C<perlbrew> Perl on Debian-family,
Alpine, or Fedora hosts when the system Perl is older than the required
C<5.38>, installs C<App::perlbrew> into F<~/perl5/bin> first if the package manager did not
already put C<perlbrew> on C<PATH>, keeps that local C<perlbrew> and
C<patchperl> toolchain pinned to the private F<~/perl5/lib/perl5> include path
while the rescue build runs, fetches the C<App::perlbrew> tarball with
C<curl> before the local install so Alpine does not emit the noisy
C<IO::Socket::IP> warning during that bootstrap step, uses
C<perlbrew --notest install perl-5.38.5> so blank-machine bootstrap does not
stall in upstream Perl core test failures, updates the selected shell rc file
itself with the needed C<PERLBREW_HOME> and rescue-Perl C<PATH> lines instead
of leaving a manual F<~/.profile> editing step behind or sourcing perlbrew's
bash-only startup file under generic C<sh>, appends the matching
C<eval "$(".../dashboard" shell bash|zsh|sh)"> bootstrap so C<d2>, prompt
integration, and completion come up automatically in future shells, re-enters
an activated shell automatically at the end of a terminal-backed streamed
install so C<dashboard>, C<d2>, prompt integration, and completion are live
immediately instead of leaving the user at a dead prompt, falls back to
printing the exact shell file it updated plus the exact C<. "<rc-file>">
command the user should run only when the installer cannot safely take over a
terminal, never probes F</dev/tty> during a piped C<curl ... | sh> run so
non-interactive installs stay quiet, installs Developer Dashboard into the user account with
C<cpanm --notest Developer::Dashboard>,
and then runs C<dashboard init> so the runtime exists immediately after
installation.

Useful bootstrap examples:

  ./install.sh
  SHELL=/bin/zsh ./install.sh
  DD_INSTALL_CPAN_TARGET=./Developer-Dashboard-X.XX.tar.gz ./install.sh

Install from CPAN with:

  cpanm --notest Developer::Dashboard

Or install from a checkout with:

  perl Makefile.PL
  make
  make test
  make install

=head2 Local Development

Build the distribution:

  rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
  dzil build

The release gather rules exclude local coverage output such as F<cover_db>, so
covered runs before C<dzil build> do not leak Devel::Cover artifacts into the
shipped tarball.
Release hygiene now also requires that this cleanup leaves exactly one
unpacked C<Developer-Dashboard-X.XX/> build directory and exactly one matching
C<Developer-Dashboard-X.XX.tar.gz> artifact after the build.
The built distribution also ships a plain F<README> companion so CPAN and
kwalitee consumers still receive a top-level readme without re-including the
checkout-only documentation set.

Run the CLI directly from the repository:

  perl -Ilib bin/dashboard init
  perl -Ilib bin/dashboard auth add-user <username> <password>
  perl -Ilib bin/dashboard version
  perl -Ilib bin/dashboard of --print My::Module
  perl -Ilib bin/dashboard open-file --print com.example.App
  printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard jq alpha.beta
  printf 'alpha:\n  beta: 3\n' | perl -Ilib bin/dashboard yq alpha.beta
  mkdir -p ~/.developer-dashboard/cli/update.d
  printf '#!/usr/bin/env perl\nuse Developer::Dashboard::Runtime::Result;\nprint Developer::Dashboard::Runtime::Result::stdout(q{01-runtime});\nprint $ENV{RESULT} // q{}\n' > ~/.developer-dashboard/cli/update
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

  mkdir -p ~/.developer-dashboard/cli/jq.d
  printf '#!/usr/bin/env perl\nprint "seed\\n";\n' > ~/.developer-dashboard/cli/jq.d/00-seed.pl
  chmod +x ~/.developer-dashboard/cli/jq.d/00-seed.pl
  printf '{"alpha":{"beta":2}}' | perl -Ilib bin/dashboard jq alpha.beta

Dashboard-managed built-in helpers are different from user commands. All
built-in helper assets are always staged only under
F<~/.developer-dashboard/cli/dd/>. Dedicated helper bodies are used for
C<jq>, C<yq>, C<tomq>, C<propq>, C<iniq>, C<csvq>, C<xmlq>, C<of>,
C<open-file>, C<ticket>, C<path>, C<paths>, and C<ps1>, while the remaining
built-in commands stage thin wrappers that delegate into the shared private
C<_dashboard-core> runtime. Under C<DD-OOP-LAYERS>, layered lookup still
applies to user-provided commands and hook directories, but C<dashboard init>
does not copy those built-in helpers into child project layers.

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
F<~/.developer-dashboard/cli/update/run> in any inherited layer, with the
deepest matching layer winning the final command path. Its hook files can live
under F<update/> or F<update.d>, and the real command receives the final
C<RESULT> and C<LAST_RESULT> payloads through the environment after those hook
files run. Each later hook also sees the latest rewritten C<RESULT> from the
earlier hook set, the immediate previous hook through C<LAST_RESULT>, and an
explicit C<[[STOP]]> marker in one hook's C<stderr> skips the remaining hook
files before control returns to the real update command. Perl code can read
those payloads through C<Runtime::Result>.

Use C<dashboard version> to print the installed Developer Dashboard version.

The blank-container integration harness applies fake-project dashboard override
environment variables only after C<cpanm> finishes installing the tarball so
the shipped test suite still runs against a clean runtime.
That same blank-container path now also verifies web stop/restart behavior in a
minimal image where listener ownership may need to be discovered from F</proc>
instead of C<ss>, including a late listener re-probe before
C<dashboard restart> brings the web service back up.

=head2 First Run

Initialize the runtime:

  dashboard init

Inspect resolved paths:

  dashboard paths
  dashboard path resolve bookmarks_root
  dashboard path add foobar /tmp/foobar
  dashboard path del foobar
  dashboard which jq
  dashboard which layered-tool
  dashboard which nest.level1.level2.here
  dashboard which --edit jq

Custom path aliases are stored in the effective dashboard config root so shell
helpers such as C<cdr foobar> and C<which_dir foobar> keep working across
sessions. When a project-local F<./.developer-dashboard> tree exists, alias
writes go there first; otherwise they go to the home runtime. Under
C<DD-OOP-LAYERS>, that write stays local to the deepest participating layer:
adding one child-layer alias does not copy inherited parent C<config.json>
domains into the child file. The child layer keeps only its own new delta and
still inherits the rest from home and parent layers at read time. When an
alias points inside the current home directory, the stored config uses
C<$HOME/...> instead of a hard-coded absolute home path so a shared fallback
runtime remains portable across different developer accounts. Re-adding an
existing alias updates it without error, and deleting a missing alias is also
safe.

C<cdr> now follows a two-stage path flow instead of only jumping to one alias
or one top-level project name. If the first argument resolves as a saved alias
and there are no later arguments, C<cdr alias> still goes straight there. If
the first argument resolves as a saved alias and more arguments remain,
C<cdr> enters the alias root, then searches every directory under that root
with AND-matched regex keywords taken from the remaining arguments. One match
means C<cd> into that directory; multiple matches mean print the full list and
stay at the alias root. If the first argument is not a saved alias, C<cdr>
treats every argument as an AND-matched regex search beneath the current
directory. One match means C<cd> there; multiple matches mean print the list
and leave the current directory unchanged. C<which_dir> follows the same
selection logic but only prints the chosen target or match list instead of
changing directory. Unreadable subdirectories are skipped explicitly during
that search so one protected tree does not abort the whole lookup.

Both C<cdr> and C<which_dir> therefore use regex narrowing arguments, not
quoted substring tokens.

Examples:

  cdr foobar
  cdr foobar alpha foo bar
  cdr foobar 'alpha-foo$'
  cdr alpha red
  which_dir foobar alpha

Use C<Developer::Dashboard::Folder> for runtime path helpers. It resolves the
same runtime, bookmark, config, and configured alias names exposed by
C<dashboard paths>, including names such as C<docker>, without relying on
unscoped CPAN-global module names.

If you need the whole C<dashboard paths> payload in Perl, call
C<Developer::Dashboard::Folder-E<gt>all> or
C<Developer::Dashboard::PathRegistry-E<gt>all_paths> instead of rebuilding the
hash by hand. If you need a fresh path registry object from that public Folder
inventory, call C<Developer::Dashboard::PathRegistry-E<gt>new_from_all_folders>.
If you need a collector store from the same Folder-derived runtime roots, call
C<Developer::Dashboard::Collector-E<gt>new_from_all_folders>.

The hashed C<state_root>, C<collectors_root>, C<indicators_root>, and
C<sessions_root> paths live under the shared temp state tree, not inside the
layered runtime config tree. If a reboot or temp cleanup removes one of those
hashed state roots, the path registry recreates it automatically the next time
dashboard code resolves the path and rewrites the matching F<runtime.json>
metadata file before collectors, indicators, or sessions use it again.

Use C<dashboard which E<lt>targetE<gt>> to inspect what C<dashboard> would
execute before you run it. The command prints one
C<COMMAND /full/path> line for the resolved file and then one
C<HOOK /full/path> line for each participating hook in runtime execution
order. That works for built-in helpers such as C<jq>, layered custom commands
such as C<layered-tool>, single-level skill commands such as
C<example-skill.somecmd>, and multi-level nested skill commands such as
C<nest.level1.level2.here>. If you add C<--edit>, C<dashboard which> skips the
inspection output and re-enters C<dashboard open-file> with the resolved
command file path so the normal editor-selection behavior is reused.

Render shell bootstrap for bash, zsh, POSIX sh, or PowerShell:

  dashboard shell bash
  dashboard shell zsh
  dashboard shell sh
  dashboard shell ps

Audit runtime permissions:

  dashboard doctor
  dashboard doctor --fix

Resolve or open files from the CLI:

  dashboard of --print My::Module
  dashboard open-file --print com.example.App
  dashboard open-file --print javax.jws.WebService
  dashboard of --print . 'Ok\.js$'
  dashboard open-file --print path/to/file.txt
  dashboard open-file --print bookmarks api-dashboard

Query structured files from the CLI:

  printf '{"alpha":{"beta":2}}' | dashboard jq alpha.beta
  printf 'alpha:\n  beta: 3\n' | dashboard yq alpha.beta
  printf '[alpha]\nbeta = 4\n' | dashboard tomq alpha.beta
  printf 'alpha.beta=5\n' | dashboard propq alpha.beta
  dashboard jq file.json '$d'

Start the local app:

  dashboard serve

Open the root path with no bookmark path to get the free-form bookmark editor directly. If you start the web service with C<dashboard serve --no-editor> or C<dashboard serve --no-endit>, the browser stays read-only instead and direct editor/source routes are blocked. If you start it with C<dashboard serve --no-indicators> or C<dashboard serve --no-indicator>, the right-top browser chrome is cleared while normal page rendering still works.

Stop the local app and collector loops:

  dashboard stop

Interactive terminal runs now print a task board on C<stderr> first, then
mark each stop step as it finishes so the command does not appear hung while
the runtime waits for managed shutdown.

Restart the local app and configured collector loops:

  dashboard restart

Interactive terminal runs now print the full restart task board on C<stderr>,
mark the active step with a yellow C<->, mark completed steps with a green
C<[OK]>, mark failed steps with a red C<[X]>, and keep the final JSON result
on C<stdout>.

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

C<dashboard page render> now uses the same page-runtime preparation path as
the browser route, so saved bookmark TT such as C<[% title %]> and
C<[% stash.foo %]> is rendered there too instead of only working under
C</app/E<lt>idE<gt>>.

Encode and decode transient pages:

  dashboard page show sample | dashboard page encode
  dashboard page show sample | dashboard page encode | dashboard page decode

Run a page action:

  dashboard action run system-status paths

Bookmark documents use the original separator-line format with directive
headers such as C<TITLE:>, C<STASH:>, C<HTML:>, and C<CODE1:>.

Posting a bookmark document with C<BOOKMARK: some-id> back through the root
editor now saves it to the bookmark store so C</app/some-id> resolves it
immediately.

The browser editor now renders syntax-highlight markup again, but keeps that
highlight layer inside a clipped overlay viewport that follows the real
textarea scroll position by transform instead of via a second scrollbox.
That restores the visible highlighting while keeping long bookmark lines,
full-text selection, and caret placement aligned with the real textarea.

Edit and source views preserve raw Template Toolkit placeholders inside
C<HTML:> sections, so values such as C<[% title %]> are kept in the bookmark
source instead of being rewritten to rendered HTML after a browser save.
Template Toolkit rendering exposes the page title as C<title>, so a bookmark
with C<TITLE: Sample Dashboard> can reference it directly inside C<HTML:>
with C<[% title %]>. Transient play and view-source links are also encoded
from the raw bookmark instruction text when it is available, so
C<[% stash.foo %]> stays in source views instead of being baked into the
rendered scalar value after a render pass.

Earlier C<CODE*> blocks now run before Template Toolkit rendering during
C<prepare_page>, so a block such as C<CODE1: { a => 1 }> can feed
C<[% stash.a %]> in the page body. Returned hash and array values are also
dumped into the runtime output area, so C<CODE1: { a => 1 }> both populates
stash and shows the bookmark-style dumped value below the rendered page body.
The C<hide> helper no longer discards already-printed STDOUT, so
C<CODE2: hide print $a> keeps the printed value while suppressing the Perl
return value from affecting later merge logic.

Page C<TITLE:> values only populate the HTML C<E<lt>titleE<gt>> element. If a
bookmark should show its title in the page body, add it explicitly inside
C<HTML:>, for example with C<[% title %]>.

C</apps> redirects to C</app/index>, and C</app/E<lt>nameE<gt>> can load
either a saved bookmark document or a saved ajax/url bookmark file.

=head2 Working With Collectors

Ensure the home config file exists without seeding collectors:

  dashboard config init

If F<config/config.json> is missing, that command creates it as:

  {}

It does not inject an example collector, and if the file already exists it is
left untouched.

List collector status:

  dashboard collector list

Inspect collector logs:

  dashboard collector log
  dashboard collector log shell.example

C<dashboard collector log> prints the known collector log streams.
C<dashboard collector log E<lt>nameE<gt>> prints one collector transcript.
If a configured collector has not run yet, the command prints an explicit
no-log message instead of blank output.
Collector status timestamps and collector log headers use the machine's local
system time with an explicit numeric timezone offset such as C<+0100>, so the
visible timestamps line up with cron scheduling on the same machine instead of
looking one hour behind during daylight-saving transitions.

Collector jobs support two execution fields:

=over 4

=item *

C<command> runs a shell command string through the native platform shell:
C<sh -lc> on Unix-like systems and PowerShell on Windows

=item *

C<code> runs Perl code directly inside the collector runtime

=back

The built-in C<housekeeper> collector is always present even when
F<config/config.json> is otherwise empty. It runs every C<900> seconds with
Perl C<code> instead of a shell command, so it does not depend on C<PATH>
resolution. That collector removes stale hashed runtime state roots from the
shared temp tree under F</tmp/E<lt>userE<gt>/developer-dashboard/state/> and
removes older C<developer-dashboard-ajax-*> temp files plus
C<dashboard-result-*> runtime result temp files left behind in F</tmp/>. It
also rotates collector log transcripts when a collector defines C<rotation>
or C<rotations>. C<lines> keeps the trailing line count, while C<minute>,
C<minutes>, C<hour>, C<hours>, C<day>, C<days>, C<week>, C<weeks>,
C<month>, and C<months> keep only log entries newer than the requested
retention window. Run it on demand with:

  dashboard housekeeper
  dashboard collector run housekeeper

If you need different cadence or behavior, define your own collector named
C<housekeeper> in config. That override now inherits the built-in C<code> and
C<cwd> defaults, so changing only C<interval> or adding C<indicator>
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
Under C<DD-OOP-LAYERS>, a deeper child layer no longer pins an inherited
collector indicator at that default C<missing> placeholder just because the
child runtime has its own F<.developer-dashboard/> folder. If the child layer
does not override that collector config and only has the placeholder state,
dashboard now falls back to the nearest inherited real collector state such
as a parent-layer C<ok> result instead of turning the same indicator red.
The top-right browser status strip now uses that same configured icon instead
of falling back to the collector name, and stale managed indicators are
removed automatically if the collector config is renamed. The browser chrome
now uses an emoji-capable font stack there as well, so UTF-8 icons such as
C<🐳> and C<💰> remain visible instead of collapsing into fallback boxes.
For TT-backed collector icons, a collector such as C<./foobar> can print
C<{"a":123}> on C<stdout>; the runner decodes that JSON into Perl data and
renders C<[% a %]> into the live icon C<123>. Later config-sync passes keep
the configured C<icon_template> metadata and the already-rendered live
C<icon>, so commands such as C<dashboard indicator list> and C<dashboard ps1>
do not revert the persisted icon back to raw C<[% ... %]> text between runs.
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
  dashboard docker list
  dashboard docker list --disabled
  dashboard docker list --enabled
  dashboard docker disable green
  dashboard docker enable green

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
To toggle that marker without creating or deleting the file manually, use
C<dashboard docker disable E<lt>serviceE<gt>> or
C<dashboard docker enable E<lt>serviceE<gt>>. The toggle writes to the
deepest runtime docker root, so a child project layer can locally disable an
inherited home service by creating
C<./.developer-dashboard/docker/E<lt>serviceE<gt>/disabled.yml> and can
re-enable it again by removing that same local marker.
To inspect the effective marker state without walking the folders manually,
use C<dashboard docker list>. Add C<--disabled> to show only disabled
services or C<--enabled> to show only enabled services.

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

C<dashboard ps1> now follows the original F<~/bin/ps1> shape more closely: a
C<(YYYY-MM-DD HH:MM:SS)> timestamp prefix, dashboard status and ticket info, a
bracketed working directory, an optional jobs suffix, and a trailing
C<🌿branch> marker when git metadata is available. If the ticket workflow
seeded C<TICKET_REF> into the current tmux session, C<dashboard ps1> also
reads it from tmux when the shell environment does not already export it.

Generate shell bootstrap:

  dashboard shell bash
  dashboard shell zsh
  dashboard shell sh
  dashboard shell ps

The generated shell helper keeps the same bookmark-aware C<cdr>, C<dd_cdr>,
C<d2>,
and C<which_dir> functions across all supported shells. C<cdr> first tries a
saved alias, then falls back to an AND-matched directory search beneath the
alias root or the current directory depending on whether that first argument
was a known alias. One match changes directory, multiple matches print the
list, and C<which_dir> prints the same selected target or match list without
changing directory. Bash still uses C<\j> for job counts, zsh refreshes
The shell-smoke regression coverage also compares those printed paths by
canonical identity, so macOS C</var/...> and C</private/var/...> aliases do
not fail equivalent C<pwd> / C<which_dir> checks. Bash still uses C<\j> for
job counts, zsh refreshes
C<PS1> through a C<precmd> hook with C<${#jobstates}>, POSIX C<sh> falls back
to a prompt command that does not depend on bash-only prompt escapes, and
PowerShell installs a C<prompt> function instead of using the POSIX C<PS1>
variable.

C<d2> is the short shell shortcut for C<dashboard>, so after loading the
bootstrap you can run C<d2 version>, C<d2 doctor>, or
C<d2 docker compose ps> without typing the full command name each time.

The same generated bootstrap also wires live tab completion for C<dashboard>
and C<d2>. Bash registers C<_dashboard_complete>, zsh registers
C<_dashboard_complete_zsh>, and PowerShell registers
C<Register-ArgumentCompleter> for both command names. Completion candidates
come from the live runtime instead of a hardcoded shell list, so built-in
commands, layered custom CLI commands, and installed dotted skill commands
all show up in suggestions. For bash, the generated helper captures
completion payloads first instead of relying on process substitution, which
keeps completion responsive on macOS and inside packaged install-test shells.
The generated bootstrap also wires C<cdr>,
C<dd_cdr>, and C<which_dir> completion. The first argument suggests saved
aliases plus matching directory names beneath the current directory, and later
arguments suggest matching directory basenames beneath the resolved alias root
or current directory without crashing when one subtree is not readable.

For the POSIX shell bootstrap, the generated helper now decodes its JSON
payloads through the same Perl interpreter that generated the shell fragment
instead of a bare C<perl -MJSON::XS ...> call. That keeps C<cdr> and
C<which_dir> stable on macOS installs where C</usr/bin/perl> and a user-local
C<~/perl5> XS stack do not belong to the same Perl build. The generated
C<d2> shortcut re-enters the C<dashboard> script directly instead of
hardcoding the current Perl binary path, so the shortcut still works when the
bootstrap is loaded by a shell whose preferred Perl lives somewhere else.

On Windows, C<dashboard shell> auto-selects PowerShell by default, and
interpreter-backed runtime entrypoints such as collector C<command> strings,
trusted command actions, saved Ajax files, custom CLI commands, hook files,
and update scripts now resolve C<.ps1>, C<.cmd>, C<.bat>, and C<.pl>
runners without assuming C<sh> or C<bash>. That keeps Strawberry Perl installs
usable without requiring a Unix shell just to load the dashboard runtime.

The repository-only Windows verification assets follow the same layered
approach: fast forced-Windows unit coverage in C<t/>, a real Strawberry Perl
host smoke in the source checkout, and a host-side rerun helper that delegates
to the QEMU launcher for release-grade Windows compatibility claims. The
supported baseline on Windows is PowerShell plus Strawberry Perl. Git Bash is
optional. Scoop is optional. They are setup helpers, not runtime requirements
for the installed C<dashboard> command. In the Dockur-backed path, the launcher
stages the Strawberry Perl MSI from the Linux host into the OEM bundle and can
keep multiple retained Windows guests alive on configurable host web/RDP ports
while it reruns the same smoke.

=head2 Browser Access Model

The browser security model follows the original local-first trust concept:

=over 4

=item *

requests from loopback with a loopback host, such as C<127.0.0.1>, C<::1>, or C<localhost>, are treated as local admin

=item *

requests from loopback with a hostname listed under C<web.ssl_subject_alt_names> are also treated as local admin

=item *

requests from non-loopback IPs are treated as helper access

=item *

outsider requests return C<401> without a login page until at least one helper user exists

=item *

after a helper user exists, outsider requests receive the helper login page

=item *

helper access requires a login backed by local file-based user and session records

=item *

helper sessions are file-backed, bound to the originating remote address, and expire automatically

=item *

helper passwords must be at least 8 characters long

=back

This keeps the fast path for loopback-local access while making non-loopback or shared access explicit.

The editor and rendered pages also include a shared top chrome with share and
source links on the left and the original status-plus-alias indicator strip on
the right, refreshed from C</system/status>.
That top-right area also includes the local username, the current host or IP
link, and the current date/time in the same spirit as the old local dashboard chrome.
The displayed address is discovered from the machine interfaces, preferring a VPN-style address when one is active, and the date/time is refreshed in the browser with JavaScript.
C<dashboard serve --no-indicators> and C<dashboard serve --no-indicator> clear that whole top-right browser-only area without changing the terminal prompt or C</system/status>.
The bookmark editor also follows the old auto-submit flow, so the form submits when the textarea changes and loses focus instead of showing a manual update button.
For saved bookmark files, that browser save posts back to the named
C</app/E<lt>idE<gt>/edit> route and keeps the Play link on
C</app/E<lt>idE<gt>> instead of a transient C<token=> URL, so updates still
work while transient URLs are disabled.
Bookmark parsing also treats a standalone C<---> line as a section
break, preventing pasted prose after a code block from being compiled into the
saved C<CODE*> body.
Saved bookmark loads now also normalize malformed bookmark icon bytes from older files before the
browser sees them. Broken section glyphs fall back to C<◈>, broken item-icon
glyphs fall back to C<🏷️>, and common damaged joined emoji sequences such as
C<🧑‍💻> are repaired so edit and play routes stop showing Unicode replacement
boxes from older bookmark files.

The default web bind is C<0.0.0.0:7890>. Trust is still decided from the request origin and host header, not from the listen address.

C<DD-OOP-LAYERS> comparisons normalize canonical path identities, so symlinked
aliases such as macOS C</var/...> versus C</private/var/...> do not break
layer discovery, deepest-layer writes, or layered bookmark/nav lookup.
The CLI path helpers follow the same portability rule: commands such as
C<dashboard path project-root> may surface the canonical filesystem path, and
the supported contract treats macOS aliases such as C</var/...> and
C</private/var/...> as the same project root instead of different repos.
The same portability rule now also applies to the shell-helper and
C<locate_dirs_under> regression suites, so equivalent temp roots are compared
by real path identity instead of raw string spelling.

=head2 Runtime Lifecycle

The runtime manager follows the older local-service pattern:

=over 4

=item *

C<dashboard serve> starts the web service in the background by default

=item *

C<dashboard serve> starts the configured collector loops alongside the web
service, so a plain serve keeps collectors and the web runtime under the same
lifecycle action

=item *

C<dashboard serve --foreground> keeps the web service attached to the terminal

=item *

C<dashboard serve --ssl> enables HTTPS in Starman with the generated local
certificate and key, keeps that certificate on a browser-correct SAN profile
covering localhost, loopback IPs, the concrete non-wildcard bind host, and any
configured C<web.ssl_subject_alt_names>, regenerates older dashboard certs when
they are stale, redirects non-HTTPS requests to the matching C<https://...>
URL, and reuses the saved SSL setting on later C<dashboard restart> runs unless
you override it

=item *

C<dashboard serve --no-editor> and C<dashboard serve --no-endit> keep the
browser in read-only mode by hiding Share, Play, and View Source chrome,
denying C</app/E<lt>idE<gt>/edit>, C</app/E<lt>idE<gt>/source>, and
bookmark-save POST routes with C<403>, and persisting that read-only flag for
later C<dashboard restart> runs until C<dashboard serve --editor> turns it back
off

=item *

C<dashboard serve --no-indicators> and C<dashboard serve --no-indicator> keep
normal page rendering and left-side page chrome intact while clearing the
whole top-right browser-only chrome area, including the status strip,
username, host or IP link, and live date-time line, and persisting that flag
for later C<dashboard restart> runs until C<dashboard serve --indicators>
turns it back off

=item *

C<dashboard serve logs> prints the combined Dancer2 and Starman runtime log
captured in the dashboard log file, C<dashboard serve logs -n 100> starts from
the last 100 lines, and C<dashboard serve logs -f> follows appended output live

=item *

C<dashboard serve workers N> saves the default Starman worker count and starts
the web service immediately when it is currently stopped; C<--host HOST> and
C<--port PORT> can steer that auto-start path, and both
C<dashboard serve --workers N> and C<dashboard restart --workers N> can still
override the worker count for one run

=item *

C<dashboard stop> stops both the web service and managed collector loops and,
on an interactive terminal, prints the full stop task board on C<stderr>
before work starts so each shutdown step becomes visible instead of silent
waiting

=item *

C<dashboard restart> stops both, starts configured collector loops again, then
starts the web service, and only reports success after the replacement
collector loops and web runtime become visible and survive a short post-ready
confirmation window, with the web side still holding a live managed pid and
an accepting listener on the requested port; on an interactive terminal it
also prints the full restart task board on C<stderr>, marks the active step
with a yellow C<->, marks completed steps with a green C<[OK]>, marks failed
steps with a red C<[X]>, and leaves the final JSON result on C<stdout>

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

=item * C<DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS>

Allows browser execution of transient C</?token=...>, C</action?atoken=...>,
and older C</ajax?token=...> payloads. The default is off, so the web UI only
executes saved bookmark files unless this is set to a truthy value such as
C<1>, C<true>, C<yes>, or C<on>.

=back

Collector definitions come only from dashboard configuration JSON, so config
remains the single source of truth for path aliases, providers, collectors,
and Docker compose overlays.

=head2 Testing And Coverage

Run the test suite:

  prove -lr t

Measure library coverage with Devel::Cover:

  cpanm --notest --local-lib-contained ./.perl5 Devel::Cover
  export PERL5LIB="$PWD/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
  export PATH="$PWD/.perl5/bin:$PATH"
  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
  PERL5OPT=-MDevel::Cover prove -lr t
  cover -report text -select_re '^lib/' -coverage statement -coverage subroutine

The repository target is 100% statement and subroutine coverage for C<lib/>.
GitHub workflow coverage gates must match the C<Devel::Cover> C<Total> summary
line by regex rather than one fixed-width spacing layout, because runner or
module upgrades can change column padding without changing the real
C<100.0 / 100.0 / 100.0> result.

The coverage-closure suite includes managed collector loop start/stop paths
under C<Devel::Cover>, including wrapped fork coverage in
C<t/14-coverage-closure-extra.t>, so the covered run stays green without
breaking TAP from daemon-style child processes.
The C<t/07-core-units.t> collector loop guard treats both
C<HARNESS_PERL_SWITCHES> and C<PERL5OPT> as valid C<Devel::Cover> signals,
because this machine uses both launch styles during verification.
The runtime-manager coverage cases also use bounded child reaping for stubborn
process shutdown scenarios, so C<Devel::Cover> runs do not stall indefinitely
after the escalation path has already been exercised.
The focused skill regression in C<t/19-skill-system.t> now also exercises
C<PathRegistry::installed_skill_docker_roots()> directly, including the
default enabled-only view and the explicit C<include_disabled =E<gt> 1> path,
so skill docker layering changes do not silently pull the C<lib/> total below
the required C<100.0 / 100.0 / 100.0>.
The packaged C<t/09-runtime-manager.t> fallback assertions also stub ambient
managed-web discovery explicitly, so tarball and PAUSE installs do not get
contaminated by unrelated live dashboard-shaped processes already running on
the host.
Release kwalitee is also a hard tarball-level gate. After C<dzil build>, run:

  prove -lv t/36-release-kwalitee.t

That gate analyzes the built C<Developer-Dashboard-X.XX.tar.gz> with
C<Module::CPANTS::Analyse> and fails unless every reported kwalitee indicator
passes. It also fails if stale unpacked C<Developer-Dashboard-X.XX/> build
directories remain beside the current tarball, so artifact cleanup is now an
enforced release invariant instead of a manual habit. Do not trust
source-tree kwalitee probes for this repository; use the built tarball
because that is the artifact PAUSE and CPANTS actually inspect. The CPANTS
modules used by this gate stay release-only and must not leak into the
generated install-time test prerequisites for blank-environment C<cpanm>
verification.
Tests that depend on a missing or empty environment variable now establish that
state explicitly inside the test file, rather than assuming the parent shell
or install harness starts clean.

From a source checkout, for fast saved-bookmark browser regressions, run the
dedicated smoke script:

  integration/browser/run-bookmark-browser-smoke.pl

That host-side smoke runner creates an isolated temporary runtime, starts the
checkout-local dashboard, loads one saved bookmark page through headless
Chromium, and can assert page-source fragments, saved C</ajax/...> output, and
the final browser DOM. With no arguments it runs the built-in Ajax
C<foo.bar> bookmark case. For a real bookmark file, point it at the saved file
and add explicit expectations:

  integration/browser/run-bookmark-browser-smoke.pl \
    --bookmark-file ~/.developer-dashboard/dashboards/test \
    --expect-page-fragment "set_chain_value(foo,'bar','/ajax/foobar?type=text')" \
    --expect-ajax-path /ajax/foobar?type=text \
  --expect-ajax-body 123 \
  --expect-dom-fragment '<span class="display">123</span>'

For C<api-dashboard> import regressions against a real external Postman
collection, run the generic Playwright repro with an explicit fixture path:

  API_DASHBOARD_IMPORT_FIXTURE=/path/to/collection.postman_collection.json \
  prove -lv t/23-api-dashboard-import-fixture-playwright.t

That browser test injects the external fixture into the visible
C<api-dashboard> import control and verifies that the collection appears in the
Collections tab, opens from the tree, and persists to
F<config/api-dashboard/E<lt>collection-nameE<gt>.json> without baking
fixture-specific branding into the repository.

For oversized C<api-dashboard> imports that need to stay browser-verified
above the saved-Ajax inline payload threshold, run:

  prove -lv t/25-api-dashboard-large-import-playwright.t

The main C<t/22-api-dashboard-playwright.t> browser flow now also waits for
the saved collection JSON itself to contain the newly created request before
it drives the later export/import/reload path, so that coverage proves real
disk-backed collection persistence instead of only optimistic browser state.

That Playwright test imports a deliberately large Postman collection through
the visible browser file input and verifies that the browser still reports a
successful import instead of failing with an C<Argument list too long>
transport error.

For the tabbed C<api-dashboard> browser layout, run the dedicated Playwright
coverage:

  prove -lv t/24-api-dashboard-tabs-playwright.t

That browser test verifies the top-level Collections and Workspace tabs, the
collection-to-collection tab strip inside the Collections view, and the inner
Request Details, Response Body, and Response Headers tabs below the response
C<pre> box so the bookmark remains usable in constrained browser widths.

For C<sql-dashboard> browser coverage, run:

  prove -lv t/27-sql-dashboard-playwright.t

That browser test creates a profile through the visible bookmark UI, runs
programmable SQL through a fake runtime-local C<DBI> stack under
F<.developer-dashboard/local/lib/perl5>, verifies the shareable URL state,
and checks the schema table-tab browser.

For deep real SQLite browser coverage, run:

  PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi \
  prove -lv t/31-sql-dashboard-sqlite-playwright.t

That browser matrix runs 51 real SQLite cases against the visible SQL
workspace, including blank-user profile save and reload, merged workspace
layout, saved-SQL collection flow, schema browsing, invalid SQL and attrs
errors, shared-URL restoration, and file-permission checks.

For optional docker-backed MySQL, PostgreSQL, MSSQL, and Oracle browser
coverage, run:

  PERL5LIB=/tmp/sql-lib/lib/perl5:/tmp/sql-lib/lib/perl5/x86_64-linux-gnu-thread-multi \
  prove -lv t/32-sql-dashboard-rdbms-playwright.t

That browser file covers real MySQL, PostgreSQL, MSSQL, and Oracle services
through Docker using official C<mysql:5.7>, C<postgres:16>,
C<mcr.microsoft.com/mssql/server:2022-latest>, and
C<gvenzl/oracle-xe:21-slim-faststart> fixtures on this host. It intentionally
skips unless C<DBI> plus the relevant C<DBD::mysql>, C<DBD::Pg>,
C<DBD::ODBC>, or C<DBD::Oracle> driver is already installed in the active
Perl environment. For MSSQL and Oracle on this host, the test also expects
the user-space native client libraries to be exposed through C<PERL5LIB>,
C<LD_LIBRARY_PATH>, and, for Oracle, C<ORACLE_HOME>. Those drivers are not
shipped as base runtime prerequisites.

From a source checkout, for Windows-targeted changes, also run the Strawberry
Perl smoke on a Windows host:

  powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz

Before calling a release Windows-compatible from the source checkout, also run
the same smoke through the host-side Windows VM helper:

  WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
  integration/windows/run-host-windows-smoke.sh

That helper keeps the Windows VM path rerunnable by loading a reusable env
file, rebuilding the latest tarball when needed, and then delegating to the
checked-in QEMU launcher. The supported baseline on Windows is PowerShell plus
Strawberry Perl. Git Bash is optional. Scoop is optional. They are setup
helpers only. In the Dockur-backed path, the launcher can resolve the latest
64-bit Strawberry Perl MSI from Strawberry Perl's official C<releases.json>
feed so the env file does not need a pinned installer URL for every rerun.
That same Windows guest smoke can install the tarball with C<cpanm --notest>
for third-party dependency setup while still running the full Developer
Dashboard CLI, collector, Ajax, web, and browser smoke afterward.

=head2 Updating Runtime State

Run your user-provided update command:

  dashboard update

If F<./.developer-dashboard/cli/update> or
F<./.developer-dashboard/cli/update/run> exists in the current project it is
used first; otherwise the home runtime fallback is used. C<dashboard update>
runs that command after any sorted hook files from F<update/> or F<update.d>.

C<dashboard init> seeds two editable starter bookmarks when they are
missing: C<api-dashboard> and C<sql-dashboard>.

Re-running C<dashboard init> keeps an existing
F<~/.developer-dashboard/config/config.json> intact. If the file is missing,
init creates it as C<{}>. The command refreshes dashboard-managed helpers in
F<~/.developer-dashboard/cli/dd/> and seeds starter bookmarks that are not
already present.

Starter bookmark refresh is non-destructive too. If a saved
C<api-dashboard> or C<sql-dashboard> page still matches the last recorded
dashboard-managed shipped copy, C<dashboard init> refreshes it to the
current shipped seed. If the saved page has diverged from that managed
digest, init treats it as a user edit and leaves it alone. The refresh bridge
also recognizes known older dashboard-managed C<sql-dashboard> digests from
runtimes that predate the seed manifest, so one stale shipped copy on an
upgraded machine is refreshed instead of looking stuck on older browser UI.

When C<dashboard init> refreshes a dashboard-managed helper or shipped
starter file, it compares the existing content against the shipped content by
MD5 inside Perl first. If the content already matches, init skips the copy
instead of rewriting the file unnecessarily.

When bookmark C<HTML:> or shared C<nav/*.tt> fragments hit a Template Toolkit
syntax error, render mode now shows a visible C<runtime-error> block instead
of leaking the raw C<[% ... %]> source into the browser or
C<dashboard page render> output.

Home helper staging is non-destructive too. C<dashboard init> may add or
update dashboard-managed built-in helpers only under
F<~/.developer-dashboard/cli/dd/>. User commands and hook directories stay in
F<~/.developer-dashboard/cli/> and in child-layer
F<./.developer-dashboard/cli/> roots, and init must not overwrite or delete
those user-space files while refreshing the home-only dd namespace.

The public C<dashboard> entrypoint also stays thin for all built-in commands.
It only stages and execs helper assets from F<share/private-cli/>: dedicated
helper bodies for C<dashboard jq>, C<dashboard yq>, C<dashboard of>,
C<dashboard open-file>, C<dashboard ticket>, C<dashboard path>,
C<dashboard paths>, and C<dashboard ps1>, plus thin wrappers for the
remaining built-ins that hand off to the shared private
C<_dashboard-core> runtime. The shipped starter bookmark source lives under
F<share/seeded-pages/>, and the shipped helper scripts live under
F<share/private-cli/>, so neither bookmark bodies nor helper script bodies
are embedded directly in the command script.
Installed copies resolve the same seeded pages and helper assets from the
distribution share directory, so C<dashboard init> works after a C<cpanm>
install and not just from a source checkout. Those helper-backed built-ins
also rewrite their live process title to C<developer-dashboard ...>, so
process listings stay aligned with the public command names instead of
exposing the staged helper path.
When C<dashboard> re-execs a Perl-backed helper or hook, it also forces the
same active dashboard F<lib/> root into that child Perl process. That keeps
thin switchboard handoff on the current checkout code instead of drifting onto
an older installed C<Developer::Dashboard> copy that may also be visible in
C<PERL5LIB>.

The seeded C<api-dashboard> bookmark now behaves like a local Postman-style
workspace. It keeps multiple request tabs in browser-local state, supports
import and export of Postman collection v2.1 JSON through the Collections
tab, saves created, updated, and imported collections as Postman collection
JSON under the runtime F<config/api-dashboard/E<lt>collection-nameE<gt>.json>
path, reloads every stored collection when the bookmark opens, keeps the
active collection, request, and tab reflected in the browser URL for
direct-link and back/forward navigation, renders Collections and Workspace as
top-level tabs for narrower browser layouts, renders stored collections as
click-through tabs instead of one long vertical stack, shows a request-specific
token form above the editor whenever the selected request uses
C<{{token}}> placeholders, carries those token values across matching
placeholders in other requests from the same collection, resolves those token
values into the visible request URL, headers, and body fields, renders a
hide/show C<Request Credentials> section in the workspace with
Postman-compatible C<Basic>, C<API Token>, C<API Key>, C<OAuth2>,
C<Apple Login>, C<Amazon Login>, C<Facebook Login>, and C<Microsoft Login>
presets, hydrates imported Postman C<request.auth> data back into that
credentials panel, exports saved request auth back into valid Postman JSON,
and applies the configured auth to outgoing headers or query strings when the
request is sent. The OAuth-style provider presets fill common authorize/token
URLs, but the actual access token and client details remain values the user
enters for that request. The bookmark also tightens project-local
F<config/api-dashboard> to C<0700> and each saved collection JSON file there
to C<0600>, because saved request auth can include secrets inside the Postman
collection JSON. It renders Request Details, Response Body, and Response
Headers as inner workspace tabs below the response C<pre> box, defaults
Response Body back to the active tab after each send, previews JSON, text,
PDF, image, and TIFF responses appropriately, and sends requests through its
saved Ajax endpoint backed by C<LWP::UserAgent>. HTTPS endpoints also require
the packaged C<LWP::Protocol::https> runtime prerequisite, so clean installs
can test normal TLS APIs without browser CORS rules. Oversized collection
saves now spill the saved Ajax request payload through temp files instead of
overflowing C<execve> environment limits, and the bookmark rejects empty
C<200> save/delete responses instead of claiming success when nothing was
persisted.

C<dashboard cpan E<lt>Module...E<gt>> installs optional Perl modules into the
active runtime-local F<./.developer-dashboard/local> tree and appends matching
C<requires 'Module';> lines to F<./.developer-dashboard/cpanfile>. The command
stays implemented in the C<dashboard> entrypoint rather than introducing a
separate SQL or CPAN manager product module, and saved Ajax workers infer the
same runtime-local C<local/lib/perl5> path directly from the active runtime
root. When the requested modules include C<DBD::*>, the command also installs
and records C<DBI> automatically so generic database driver requests work with
a single command.

The seeded C<sql-dashboard> bookmark is a file-backed SQL workspace built
inside the bookmark runtime itself rather than as a separate product module.
It stores connection profiles under
F<config/sql-dashboard/E<lt>profile-nameE<gt>.json>, keeps that
F<config/sql-dashboard> directory owner-only at C<0700>, writes each saved
profile JSON file owner-only at C<0600>, stores saved SQL collections under
F<config/sql-dashboard/collections/E<lt>collection-nameE<gt>.json> with the
same owner-only C<0700> / C<0600> directory and file permissions, keeps the
active top-level tab, portable C<connection> id, selected collection,
selected saved SQL item, selected schema table, and current SQL in the
browser URL instead of a saved SQL file, and treats SQL collections and
connection profiles as separate concepts so the same saved SQL can run
against different connections. Share URLs only carry the DSN-plus-user
connection id without a password; if another machine already has a matching
saved profile with a saved password, the bookmark reruns the shared SQL
there, otherwise it opens a draft connection profile built from that
connection id so the other user can add any required local credentials and
run it. Passwordless profiles such as SQLite may keep the user blank, and a
matching blank-user shared route auto-runs without inventing a password
warning when the DSN does not need one. The profile editor now renders the
driver field as a dropdown of installed C<DBD::*> modules, shows
driver-specific connection guidance beside that dropdown, seeds a usable DSN
template for SQLite, MySQL, PostgreSQL, MSSQL/ODBC, and Oracle when the DSN
is blank, and rewrites only the C<dbi:E<lt>DriverE<gt>:> DSN prefix when you
switch drivers. The main browser flow now merges collections and editing into
one C<SQL Workspace> tab with a phpMyAdmin-style master-detail layout with
two inner workspace tabs: C<Collection> and C<Run SQL>. The C<Collection>
view keeps collection tabs and the saved SQL list together in the left
navigation rail, while C<Run SQL> keeps the editor plus results together on
the right and leaves that runner view active by default because it is the
main operator path. The active saved SQL name stays visible while you work,
and saving a different SQL name into the same collection adds a second saved
SQL entry instead of overwriting the selected one. The workspace editor now
keeps the SQL textarea as the primary focus with content-based auto-resize,
uses one quiet action row under the editor instead of a loud toolbar,
removes the redundant in-workspace schema button in favour of the top
C<Schema Explorer> tab, and moves saved-SQL deletion to a compact inline
C<[X]> control beside each saved query so the list stays visually tied to
its collection. The bookmark still renders profile tabs and schema tabs,
executes SQL through generic C<DBI>, and uses DBI metadata calls such as
C<table_info> and C<column_info> for the schema browser. Schema Explorer now
also gives the table list a live filter box, renders human type labels and
positive length labels from the DBI metadata instead of leaking raw numeric
type codes, lets the user copy a table name directly, and adds a C<View
Data> action that jumps back to C<Run SQL> with a ready C<select * from
E<lt>tableE<gt>> query for the selected table. The core browser workflow is
now live verified against SQLite, MySQL, PostgreSQL, MSSQL via
C<DBD::ODBC>, and Oracle via C<DBD::Oracle>. Schema browse keeps reading
C<table_info> / C<column_info> rows directly and must not call C<execute()>
on those metadata handles, because ODBC drivers such as MSSQL can fail with
C<SQL-HY010> on that misuse. Saved dashboard pages override shipped seeded
pages, so an older F<~/.developer-dashboard/dashboards/sql-dashboard> copy
can still shadow a newer shipped fix after upgrade; when SQL Dashboard
behaviour looks stale, use C<dashboard page source sql-dashboard> to confirm
which page source is live before debugging the browser route. It preserves
programmable statement blocks through C<SQLS_SEP> and
C<INSTRUCTION_SEP>, including C<STASH>, C<ROW>, C<BEFORE>, and C<AFTER>
hooks, so result rows can still be transformed locally before rendering into
derived HTML, links, or button-like actions. Its saved Ajax endpoints run
through singleton workers. No
C<DBD::*> driver ships in the base tarball by default; install only the one
you need with C<dashboard cpan DBD::Driver> or user-space
C<cpanm --notest -L ~/perl5 DBD::Driver>, and the bookmark will return explicit
install guidance when a selected driver is missing. The repository also ships
a dedicated SQL dashboard support guide with the verification matrix and
per-database notes for that workspace.

=head2 Skills System

Extend dashboard with isolated skill packages:

Install a skill from either a Git repository URL or a local checked-out skill
repository:

  dashboard skills install browser
  dashboard skills install foo/bar
  dashboard skills install git@github.com:user/example-skill.git
  dashboard skills install https://github.com/user/example-skill.git
  dashboard skills install /absolute/path/to/example-skill
  dashboard skills install --ddfile

Bare one-word skill names are expanded against the official
C<https://github.com/manif3station/> GitHub base, so
C<dashboard skills install browser> clones
C<https://github.com/manif3station/browser>. Two-part C<owner/repo>
shorthand is expanded against GitHub too, so
C<dashboard skills install foo/bar> clones C<https://github.com/foo/bar>.
Full URLs such as C<https://github.com/user/example-skill.git> and
C<git@github.com:user/example-skill.git> are used exactly as supplied.

Git sources are cloned. Direct local checked-out directories are synced in
place instead of recloned, using C<rsync> when it is available and the
built-in Perl tree-copy fallback when it is not. That means
C<dashboard skills install> also acts as reinstall and update for an already
installed skill. A direct local directory is only accepted when it is a
checked-out Git repository with a F<.git/> directory plus a F<.env> file that
declares C<VERSION=...>; otherwise the install is rejected. The installed
copy lives in its own isolated skill root under the deepest participating
C<DD-OOP-LAYERS> runtime. In a home-only session that is
F<~/.developer-dashboard/skills/E<lt>repo-nameE<gt>/>. In a deeper project
layer that already has its own F<.developer-dashboard/>, the install target
becomes
F<E<lt>that-layerE<gt>/.developer-dashboard/skills/E<lt>repo-nameE<gt>/>.
Plain C<dashboard skills install> now requires either one explicit source
argument or the special C<--ddfile> flag; calling it with no source and no
C<--ddfile> returns a usage error instead of guessing.
Developer Dashboard does not merge the skill's C<cli/>, C<dashboards/>,
C<config/>, C<ddfile>, C<ddfile.local>, C<aptfile>, C<apkfile>, C<dnfile>, C<brewfile>,
C<package.json>, C<cpanfile>, C<cpanfile.local>, or Docker files into the
normal runtime folders.

C<dashboard skills install --ddfile> reads dependency manifests from the
current directory instead of taking one explicit skill source. If F<ddfile>
exists there, each listed source installs into the base home-layer skills root
at F<~/.developer-dashboard/skills/E<lt>repo-nameE<gt>/> even when the command
is run inside a deeper child F<.developer-dashboard/> layer. If F<ddfile.local>
exists there, each listed source installs into the current directory's nested
F<skills/E<lt>repo-nameE<gt>/> tree instead. When both manifests are present,
the command processes F<ddfile> first and F<ddfile.local> second. Repeated
C<dashboard skills install --ddfile> runs also act as reinstall and refresh
for already-installed targets, just like repeated explicit
C<dashboard skills install E<lt>sourceE<gt>> runs.
Interactive C<dashboard skills install> runs also print a task board on
C<stderr>. When a skill ships dependency manifests such as F<package.json>,
the matching task updates to show the detected file path so a long-running
C<npm>, C<cpanm>, or package-manager step stays visible instead of looking
blind.

Installed dotted skill commands such as C<dashboard demo-skill.foo> now hand
control to the real skill command after hook processing instead of wrapping
the main command in an extra capture layer. That keeps interactive prompting
behavior intact for commands that print a prompt and then read from standard
input.

Skill lookup also follows C<DD-OOP-LAYERS>, but a same-named deeper skill is
now layered instead of flattening the whole repo. The home
F<~/.developer-dashboard/skills/E<lt>repo-nameE<gt>/> checkout is the base
layer, and any deeper
F<.developer-dashboard/skills/E<lt>repo-nameE<gt>/> checkout becomes an
inherited layer for that same skill. Runtime lookup walks those
participating skill layers for C<cli/E<lt>commandE<gt>>,
C<cli/E<lt>commandE<gt>.d>, C<dashboards/*>, C<dashboards/nav/*>,
C<config/config.json>, and C<perl5/lib/perl5>. If a child layer omits a file,
folder, or config key, lookup falls back to the base layer. If multiple
layers provide the same file or config key, the deepest layer still wins that
override.

List installed skills:

  dashboard skills list
  dashboard skills list -o json

The default output is a padded table with the columns C<Repo>, C<Enabled>,
C<CLI>, C<Pages>, C<Docker>, C<Collectors>, and C<Indicators>. The
C<Enabled> column prints the readable values C<enabled> or C<disabled> so the
table stays aligned and copied terminal output stays unambiguous.

Use C<-o json> when you want structured output. It returns a C<skills> array
where each item reports:

=over 4

=item *

repo name

=item *

installed path

=item *

C<enabled> as a JSON boolean

=item *

CLI command, page, docker service, collector, and indicator counts

=item *

JSON booleans for C<has_config>, C<has_ddfile>, C<has_aptfile>,
C<has_apkfile>, C<has_dnfile>, C<has_brewfile>, C<has_cpanfile>, and C<has_cpanfile_local>

=back

Inspect one installed skill:

  dashboard skills usage example-skill
  dashboard skills usage example-skill -o table

The default output is JSON. It returns the installed skill state even when the
skill is disabled, including:

=over 4

=item *

CLI commands plus whether each command has hooks and how many

=item *

bookmark pages and C<dashboards/nav/*> entries

=item *

docker service folders and the files inside each one

=item *

the merged config key such as C<_example-skill>

=item *

declared collectors, their repo-qualified names, and indicator metadata

=back

Update a skill to the latest version:

  dashboard skills update example-skill

Disable a skill without uninstalling it:

  dashboard skills disable example-skill

Disabling keeps the checkout in its current layered skills root but removes it
from normal runtime lookup. That means:

=over 4

=item *

C<dashboard E<lt>repo-nameE<gt>.E<lt>commandE<gt>> stop dispatching into that
skill

=item *

C</app/E<lt>repo-nameE<gt>> and C</app/E<lt>repo-nameE<gt>/E<lt>pageE<gt>>
stop serving that skill's pages

=item *

skill collectors, docker roots, config, and shared nav stop joining the
active runtime

=item *

C<dashboard skills list> and
C<dashboard skills usage E<lt>repo-nameE<gt>> still report the installed skill
so it can be inspected and re-enabled later

=back

Enable a previously disabled skill:

  dashboard skills enable example-skill

Enabling removes the local disabled marker and restores the skill to command
dispatch, browser routes, collector loading, docker lookup, config merge, and
shared nav rendering.

Execute a skill command:

  dashboard example-skill.somecmd arg1 arg2

The dotted form is the public route. If C<example-skill> is installed and
ships C<cli/somecmd>, C<dashboard example-skill.somecmd> resolves the correct
layered skill command. If the active child layer for that same repo omits
C<cli/somecmd>, the command falls back to the nearest inherited skill layer
that still provides it.

If the skill command itself lives below nested
C<skills/E<lt>repoE<gt>/.../skills/E<lt>repoE<gt>> trees, the same dotted
public form keeps walking those nested skill roots until it resolves the final
C<cli/E<lt>cmdE<gt>> file. For example:

  dashboard nest.level1.level2.here
  dashboard which nest.level1.level2.here

The first command executes the nested skill command. The second prints the
resolved nested C<cli/here> file plus any matching hook files that would run
before it.
Nested skill trees under C<skills/E<lt>repoE<gt>/cli/> stay reachable through
that same public dotted route, including multiple nested levels. For example,
if C<example-skill> ships C<skills/foo/skills/bar/cli/baz>, then
C<dashboard example-skill.foo.bar.baz> resolves the nested command through the
installed skill tree.
isolated skill root, runs sorted hooks from C<cli/somecmd.d/>, and then runs the
main command.

Uninstall a skill:

  dashboard skills uninstall example-skill

Each installed skill lives under
F<E<lt>participating-layerE<gt>/.developer-dashboard/skills/E<lt>repo-nameE<gt>/>
with:

=over 4

=item B<cli/>

Skill commands (executable scripts, never installed to system PATH)

=item B<cli/E<lt>cmdE<gt>.d/>

Hook files for commands (sorted pre-command hooks)

=item B<dashboards/>

Skill-shipped pages, including C<dashboards/index>

=item B<dashboards/nav/>

Skill nav fragments and bookmark pages loaded into
C</app/E<lt>repo-nameE<gt>> routes and into the shared nav strip rendered
above normal saved C</app/E<lt>pageE<gt>> routes such as C</app/index>

=item B<config/config.json>

Skill-local JSON config, merged into runtime config under
C<_E<lt>repo-nameE<gt>>. Any declared C<collectors> join the managed fleet
under repo-qualified names such as C<example-skill.status>

=item B<config/docker/>

Skill-local Docker Compose roots that participate in layered docker service lookup

=item B<state/>

Persistent skill state and data

=item B<logs/>

Skill output logs

=item B<ddfile>

Optional dependent skill list installed after package managers run

=item B<ddfile.local>

Optional local dependent skill list installed after C<ddfile> into the same
skills root as the current skill install target

=item B<aptfile>

Optional Debian-family system packages installed through
C<sudo apt-get install -y> after Dashboard checks each listed package and
keeps only the missing packages in the install request

=item B<brewfile>

Optional macOS Homebrew packages installed through C<brew install>

=item B<dnfile>

Optional Fedora system packages installed through
C<sudo dnf install -y> after Dashboard checks each listed package and keeps
only the missing packages in the install request

=item B<package.json>

Optional Node dependencies installed into C<$HOME/node_modules> by running
C<npx --yes npm install E<lt>dependency-spec...E<gt>> inside a private dashboard staging
workspace and then merging the resulting packages into
C<$HOME/node_modules>

=item B<cpanfile>

Optional shared Perl dependencies installed into C<~/perl5>

=item B<cpanfile.local>

Optional skill-local Perl dependencies installed into
C<E<lt>skill-rootE<gt>/perl5>

=back

Skills are completely isolated from the main dashboard runtime and from other
skills. Removing a skill is simple: C<dashboard skills uninstall E<lt>repo-nameE<gt>>
cleanly removes only that skill's directory.

Hook lifecycle details:

=over 4

=item *

hooks run in sorted filename order from C<cli/E<lt>commandE<gt>.d/>

=item *

each hook result is appended to C<RESULT>

=item *

the immediately previous hook payload is exposed through C<LAST_RESULT>

=item *

oversized hook payloads spill into C<RESULT_FILE> or
C<LAST_RESULT_FILE> before later skill hook or command execs would hit the
kernel arg/env limit

=item *

executable F<.go> hooks run through C<go run>

=item *

executable F<.java> hooks compile with C<javac> and then run through C<java>

=item *

later hooks are skipped only when a hook writes the explicit marker
C<[[STOP]]> to C<stderr>

=item *

ordinary non-zero exit codes are recorded but do not act like an implicit stop
request

=back

Skill fleet integration:

=over 4

=item *

collectors declared in a skill C<config/config.json> join the same managed
fleet used by the system config

=item *

C<dashboard serve>, C<dashboard restart>, and C<dashboard stop> manage those
skill collectors together with the system-owned collectors

=item *

skill collector names are normalized to
C<E<lt>repo-nameE<gt>.E<lt>collector-nameE<gt>> so collector process titles,
status rows, and indicator state stay unambiguous

=item *

indicator configuration attached to those skill collectors participates in the
normal prompt and browser status flow

=item *

disabled skills are excluded from that fleet until they are re-enabled

=back

Skill browser routes:

=over 4

=item *

C</app/E<lt>repo-nameE<gt>> renders C<dashboards/index>

=item *

C</app/E<lt>repo-nameE<gt>/E<lt>pageE<gt>> renders C<dashboards/E<lt>pageE<gt>>

=item *

C<dashboards/nav/*> is loaded into those skill app routes and into the shared
nav strip above normal saved C</app/E<lt>pageE<gt>> routes such as
C</app/index>, so every installed skill can contribute top-level nav at once

=item *

the older C</skill/E<lt>repo-nameE<gt>/bookmarks/E<lt>idE<gt>> route still works for direct bookmark rendering

=item *

disabled skills drop out of both the dedicated skill routes and the shared nav
strip until they are re-enabled

=back

Skill dependency and docker layering:

=over 4

=item *

if a C<ddfile> exists, each listed dependency is installed after package and
language dependency manifests through
C<dashboard skills install E<lt>dependencyE<gt>> while already-installed or
in-flight skills are skipped to avoid loops

=item *

if a C<ddfile.local> exists under an installed skill, each listed dependency
is then installed through C<dashboard skills install E<lt>dependencyE<gt>>
into the same skills root that owns the current installed skill, so
child-layer skill installs stay in that child layer and home-layer installs
stay in the home layer

=item *

if an operator runs C<dashboard skills install --ddfile> inside a directory
that contains F<ddfile>, every listed source is reinstalled or refreshed into
the base F<~/.developer-dashboard/skills/> root

=item *

if that same directory also contains F<ddfile.local>, every listed source is
then reinstalled or refreshed into the current directory's nested
F<skills/E<lt>repo-nameE<gt>/> tree after the global F<ddfile> pass completes

=item *

if an C<aptfile> exists on a Debian-family host, Dashboard checks each listed
package first and only prints and installs the packages that are still missing
through C<sudo apt-get install -y>

=item *

if an C<apkfile> exists on an Alpine host, Dashboard checks each listed
package first and only prints and installs the packages that are still missing
through C<sudo apk add --no-cache>

=item *

if a C<dnfile> exists on a Fedora host, Dashboard checks each listed package
first and only prints and installs the packages that are still missing through
C<sudo dnf install -y>

=item *

if a C<brewfile> exists on macOS, its package list is printed and then
installed through C<brew install>

=item *

if a C<package.json> exists, its Node dependencies are installed into
C<$HOME/node_modules> by running C<npx --yes npm install E<lt>dependency-spec...E<gt>>
inside a private dashboard staging workspace and then merging the resulting
packages into C<$HOME/node_modules>, so unrelated C<$HOME/package.json> files
do not break skill installs

=item *

if a C<cpanfile> exists, its Perl dependencies are installed into C<~/perl5>

=item *

if a C<cpanfile.local> exists, its Perl dependencies are installed into the
skill-local C<perl5/> tree

=item *

skill C<config/docker/...> roots participate in docker service discovery after
the home runtime docker config and before deeper project-layer overrides

=item *

disabled skills are skipped by docker root discovery until they are
re-enabled

=back

=head3 Skill Authoring

To build a new skill, start with a Git repository that contains C<cli/>,
C<config/config.json>, and optional C<dashboards/>, C<dashboards/nav/>,
C<state/>, C<logs/>, C<ddfile>, C<ddfile.local>, C<aptfile>, C<apkfile>,
C<dnfile>,
C<brewfile>, C<package.json>, C<cpanfile>, and C<cpanfile.local> files under the skill
root. Skill commands are file-based
commands run through the dotted
C<dashboard E<lt>repo-nameE<gt>.E<lt>commandE<gt>> form. Skill hook files live
under C<cli/E<lt>commandE<gt>.d/>, skill app pages render from
C</app/E<lt>repo-nameE<gt>> and C</app/E<lt>repo-nameE<gt>/E<lt>idE<gt>>, and
the older C</skill/E<lt>repo-nameE<gt>/bookmarks/E<lt>idE<gt>> route still
resolves direct bookmark renders. If C<config/config.json> declares
collectors, those collectors join the normal managed fleet under
repo-qualified names such as C<example-skill.status>, which means
C<dashboard serve>, C<dashboard restart>, and C<dashboard stop> treat them the
same way they treat system-owned collectors.

The repository also ships a dedicated skill authoring guide, and the installed
reference is available through the POD module
C<Developer::Dashboard::SKILLS>. Together they cover the isolated skill
layout, environment variables such as C<DEVELOPER_DASHBOARD_SKILL_ROOT>,
bookmark syntax like C<TITLE:>, C<BOOKMARK:>, C<HTML:>, and C<CODE1:>,
bookmark browser helpers such as C<fetch_value()>, C<stream_value()>, and
C<stream_data()>, underscored config merge keys such as C<_example-skill>,
C<aptfile -> apkfile -> dnfile -> brewfile -> package.json -> cpanfile -> cpanfile.local -> ddfile -> ddfile.local>
automatic dependency install order, the explicit
C<dashboard skills install --ddfile> operator order of
the deferred C<ddfile -> ddfile.local> pass, the shared C<~/perl5> versus skill-local
C<perl5/> split, the C<$HOME/node_modules> Node install target used by
C<package.json>,
the same-install-level dependency target used by skill-local F<ddfile.local>,
skill docker layering, and when to use dashboard-wide custom CLI hook folders such as
F<~/.developer-dashboard/cli/E<lt>commandE<gt>.d> instead of a skill-local
hook tree.

For operators rather than authors, C<dashboard skills list>,
C<dashboard skills usage E<lt>repo-nameE<gt>>,
C<dashboard skills disable E<lt>repo-nameE<gt>>, and
C<dashboard skills enable E<lt>repo-nameE<gt>> are the supported controls for
inventorying and toggling installed skills without deleting their isolated
runtime trees.

=head1 FAQ

=head2 Is this tied to a specific company or codebase?

No. The core distribution is intended to be reusable for any project.

=head2 Where should project-specific behavior live?

In configuration, saved pages, and user CLI extensions. The core should stay generic.

=head2 Is the software spec implemented?

The current distribution implements the core runtime, page engine, action runner, provider loader, prompt and collector system, web lifecycle manager, and Docker Compose resolver described by the software spec.

What remains intentionally lightweight is breadth, not architecture:

- provider pages and action handlers are implemented in a compact v1 form
- bookmark-file pages are supported, with Template Toolkit rendering and one clean sandpit package per page run so C<CODE*> blocks can share state within a bookmark render without leaking runtime globals into later requests

=head2 How is the browser UI served?

The browser UI runs as the dashboard web service you start with
C<dashboard serve>. Internally that service is a PSGI application served
through the shipped web runtime, while CLI-only commands continue to work
without keeping the browser service running.

=head2 Why does a custom hostname sometimes require login?

Only loopback-origin requests with a loopback hostname such as C<127.0.0.1>,
C<::1>, or C<localhost> receive automatic local-admin treatment. A custom alias
hostname also works as local admin when you list it under
C<web.ssl_subject_alt_names> and the request still arrives from loopback.

=head2 Why does a non-loopback host still get 401 without a login page?

Until at least one helper user exists, outsider access is disabled entirely.
That includes non-loopback IPs, forwarded hostnames, and any hostname that is
not loopback-local for the current request. Add a helper user first, then
outsider requests will receive the login page instead of the disabled-access
response.

=head2 Why is the runtime file-backed?

Because prompt rendering, dashboards, and wrappers should consume prepared state quickly instead of re-running expensive checks inline.

=head2 What JSON implementation does the project use?

The project uses C<JSON::XS> for JSON encoding and decoding, including shell helper decoding paths.

=head2 What does the project use for command capture and HTTP clients?

The project uses C<Capture::Tiny> for command-output capture via C<capture>,
with exit codes returned from the capture block rather than read separately.
It uses C<LWP::UserAgent> for real outbound HTTP in active runtime paths such
as the saved C<api-dashboard> request runner and the Java source lookup or
mirror path behind C<dashboard of> and C<dashboard open-file>.

=head1 SEE ALSO

L</Main Concepts>,
L</Working With Collectors>,
L</Runtime Lifecycle>,
L</Skills System>

=head1 AUTHOR

Developer Dashboard Contributors

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. The repository root C<LICENSE> file carries a
canonical GPL text for GitHub and Scorecard detection, and the alternative
Artistic text lives in C<LICENSE-Artistic-1.0-Perl>.

=cut
