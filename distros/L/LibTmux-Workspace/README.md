<!-- libtmux-logo -->
<div align="center">
  <picture>
    <source srcset="assets/logo.svg" type="image/svg+xml">
    <img src="assets/logo.png" width="128" height="128" alt="libtmux for Perl workspace">
  </picture>
</div>
<!-- /libtmux-logo -->

<div align="center">

# LibTmux-Workspace

</div>

LibTmux-Workspace validates, plans, and loads JSON workspaces through public
[LibTmux core APIs](https://libtmux.org/en/perl/latest/reference/libtmux-server/).
Describe sessions, windows, pane commands, layout, working directories, and
environment; inspect the plan before applying it.

[CLI example](#validate-plan-and-load-a-workspace) ·
[Perl example](#load-and-inspect-from-perl) ·
[Documentation](https://libtmux.org/en/perl/) ·
[Guide](https://libtmux.org/en/perl/latest/workspace/source-guide/) ·
[API reference](https://libtmux.org/en/perl/latest/workspace/reference/libtmux-workspace/) ·
[CPAN](https://metacpan.org/dist/LibTmux-Workspace) ·
[POD](https://metacpan.org/pod/LibTmux::Workspace)

## Install

Install the published distribution and packaged CLI; cpm installs core too:

```console
$ cpm install \
    --global \
    LibTmux::Workspace
```

Requires Perl 5.44, the versioned core distribution, and its Linux x86_64 LP64
and tmux 3.3a–3.8 environment. It adds no non-core runtime dependency and does
not require async. Read the
[installation guide](https://github.com/libtmux/libtmux-perl/blob/master/docs/installation.md)
for interpreter, installer, and source setup. The `0.x` API and workspace
behavior can change between releases; consult `Changes` before upgrading.

## Validate, plan, and load a workspace

The packaged [examples/workspace.json](examples/workspace.json) creates two
windows and three panes. Its commands run Perl directly:

<!-- example: packages/workspace/examples/workspace.json -->
```json
{
  "schema": "libtmux.workspace/v1",
  "environment": {"PROJECT": "api"},
  "sessions": [{
    "name": "perl-workspace",
    "windows": [{
      "name": "editor",
      "layout": "even-horizontal",
      "panes": [
        {"command": ["perl", "-e", "while (<STDIN>) { print }"]},
        {"command": ["perl", "-e", "while (<STDIN>) { print }"], "horizontal": true}
      ]
    }, {
      "name": "logs",
      "panes": [{"command": ["perl", "-e", "while (<STDIN>) { print }" ]}]
    }]
  }]
}
```

From this distribution directory, validate the file and inspect its plan:

```console
$ libtmux-workspace validate examples/workspace.json
```

```console
$ libtmux-workspace plan examples/workspace.json
```

Load it on an explicit socket. An unused path starts a new server:

```console
$ libtmux-workspace load examples/workspace.json \
    --socket-path "${TMPDIR:-/tmp}/libtmux-perl-workspace-$$.sock" \
    --existing skip
```

Validation and planning perform no tmux I/O. Loading leaves the workspace
running. Repeating the command with the same socket and `skip` preserves the
entire existing session. The default policy reports a conflict; it never
silently replaces another session.

## Load and inspect from Perl

Run [examples/load.pl](examples/load.pl) to plan, load, inspect the graph,
repeat with `skip`, and remove the session it created:

```console
$ perl examples/load.pl "${TMPDIR:-/tmp}/libtmux-perl-workspace-$$.sock"
```

<!-- example: packages/workspace/examples/load.pl -->
```perl
use v5.44;
use FindBin;
use LibTmux::Server;
use LibTmux::Workspace;

my $socket = shift @ARGV // die "Usage: $0 SOCKET_PATH [TMUX]\n";
my $tmux   = shift @ARGV // 'tmux';
my $server = LibTmux::Server->new(
    socket_path => $socket,
    executable  => $tmux,
    config_file => '/dev/null',
);

# example: begin plan
open my $in, '<:raw', "$FindBin::Bin/workspace.json" or die $!;
my $json = do { local $/; <$in> };
close $in or die $!;
my $workspace = LibTmux::Workspace->from_json($json);
my $plan      = $workspace->plan;
say 'planned sessions: ', scalar $plan->{sessions}->@*;
die 'plan must not mutate' if $plan->{mutates};

# example: end plan
my ($session, $failure);
try {
    # example: begin load
    my $report   = $workspace->load(server => $server);
    my $snapshot = $server->snapshot;
    $session = $snapshot->sessions->one({name => 'perl-workspace'});
    my $windows = $session->window_links;
    say 'loaded windows: ', $windows->count;
    my $editor = $windows->one({window => {-is => {name => 'editor'}}})->window;
    say 'editor panes: ', $editor->panes->count;

    # example: end load
    die 'workspace structure differs'
        unless $windows->count == 2 && $editor->panes->count == 2;

    # example: begin repeat
    my $again = $workspace->load(server => $server, existing => 'skip');
    say 'skipped existing sessions: ', scalar $again->{skipped}->@*;

    # example: end repeat
    die 'repeat did not skip' unless $again->{skipped}->@* == 1;
    die 'environment was not inherited'
        unless $server->get_environment(session => $session, name => 'PROJECT')
        eq 'api';
}
catch ($error) { $failure = $error }
if ($session) {
    try { $server->kill_session(session => $session) }
    catch ($cleanup) {
        warn "session cleanup failed: $cleanup\n";
        $failure //= $cleanup;
    }
}
die $failure if defined $failure;
say 'workspace plan, load, repeat: ok';
```

The program reports one planned session, two loaded windows, two editor panes,
and one skipped session. It uses installed modules and its adjacent JSON file;
it needs no Python or author fixture.

## Handle conflicts and partial effects

The [`Workspace`](https://libtmux.org/en/perl/latest/workspace/reference/libtmux-workspace/)
library checks all session-name conflicts before creating anything. `skip`
preserves whole existing sessions; it does not reconcile their pane count or
layout. Working directories and environment inherit through the configured
levels, and layout is applied after splitting.

A failed load records completed steps, the failed step, dispatch uncertainty,
and the original typed cause. Rollback can affect only sessions proven created
by that load. `report` preserves typed cleanup failures with target identities;
`report_data` makes a detached JSON-safe diagnostic export.

The CLI exits with 0 for success, 2 for usage/configuration, 3 for load failure,
and 4 for conflict. Pane commands use literal `command` arrays or an explicit
`shell_command`. The versioned `libtmux.workspace/v1` format is not tmuxp's
schema; tmuxp catalog import is separate work.

Read the [workspace guide](https://libtmux.org/en/perl/latest/workspace/source-guide/)
and installed `perldoc LibTmux::Workspace` documentation. Each native archive
includes this README, its logo assets, and the complete examples.
