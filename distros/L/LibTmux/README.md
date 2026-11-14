<!-- libtmux-logo -->
<div align="center">
  <picture>
    <source srcset="assets/logo.svg" type="image/svg+xml">
    <img src="assets/logo.png" width="128" height="128" alt="libtmux for Perl">
  </picture>
</div>
<!-- /libtmux-logo -->

<div align="center">

# LibTmux

</div>

LibTmux is a Perl tmux client library for creating sessions, arranging
windows, sending input, capturing output, and filtering observed graphs.
Its runtime uses the Perl standard library. It requires Perl 5.44 and
Linux x86_64 LP64, including WSL; tmux 3.3a–3.8 is supported.

[Quick start](#create-and-inspect-a-session) ·
[Filter records](#reuse-a-filter-with-ordinary-hash-records) ·
[Documentation](https://libtmux.org/en/perl/) ·
[Guide](https://libtmux.org/en/perl/latest/guides/) ·
[API reference](https://libtmux.org/en/perl/latest/reference/) ·
[CPAN](https://metacpan.org/dist/LibTmux) ·
[POD](https://metacpan.org/pod/LibTmux)

## Install

Install the published distribution with Perl 5.44 and cpm on `PATH`:

```console
$ cpm install \
    --global \
    LibTmux
```

The [installation guide](https://github.com/libtmux/libtmux-perl/blob/master/docs/installation.md)
covers prerequisites and source installation. The `0.x` API can change between
releases; consult `Changes` before upgrading.

## Create and inspect a session

Run [examples/quickstart.pl](examples/quickstart.pl) from this directory after
installation. An unused socket starts a new server; an existing server keeps
all sessions except the one the example creates and removes.

```console
$ perl examples/quickstart.pl "${TMPDIR:-/tmp}/libtmux-perl-$$.sock"
```

<!-- example: packages/core/examples/quickstart.pl -->
```perl
use v5.44;
use LibTmux::Server;

my $socket = shift @ARGV // die "Usage: $0 SOCKET_PATH [TMUX]\n";
my $server = LibTmux::Server->new(
    socket_path => $socket,
    executable  => shift(@ARGV) // 'tmux',
    config_file => '/dev/null',
);
my ($session, $snapshot, $failure);
try {
    $session = $server->new_session(
        name    => 'perl-quickstart',
        command => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    my $editor = $session->window_links->one->window;
    $server->rename_window(window => $editor, name => 'editor');
    $server->split_pane(
        pane       => $editor->panes->one,
        horizontal => true,
        command    => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    $server->new_window(
        session => $session,
        name    => 'logs',
        command => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    $snapshot = $server->snapshot;
}
catch ($error) {
    $failure = $error;
    $session //= $error->created if $error isa LibTmux::X::Creation;
}
if ($session) {
    try { $server->kill_session(session => $session) }
    catch ($cleanup) {
        warn "session cleanup failed: $cleanup\n";
        $failure //= $cleanup;
    }
}
die $failure if defined $failure;

# The captured graph remains readable after its live session has gone.
for my $link ($snapshot->session_by_id($session->id)->window_links->@*) {
    my $count = $link->window->panes->count;
    say $link->window->name, ': ', $count, $count == 1 ? ' pane' : ' panes';
}
```

Expected output:

```text
editor: 2 panes
logs: 1 pane
```

[`Server`](https://libtmux.org/en/perl/latest/reference/libtmux-server/) owns
explicit commands. Captured
[`Snapshot`](https://libtmux.org/en/perl/latest/reference/libtmux-snapshot/)
values and their relationships remain readable after cleanup. The example
imports only installed modules and needs no author fixture or Python.
The [longer workflow](examples/workflow.pl) adds layout selection, input,
capture, environment, compiled filters, and native query verification.
MetaCPAN also renders the released
[`Server` POD](https://metacpan.org/pod/LibTmux::Server) and
[`Filter` POD](https://metacpan.org/pod/LibTmux::Filter).

## Filter panes with ordinary Perl

The longer workflow filters its captured editor panes with a
[`Selection`](https://libtmux.org/en/perl/latest/reference/libtmux-selection/):

<!-- example: packages/core/examples/workflow.pl#filter -->
```perl
my $snapshot = $server->snapshot;
my $panes =
    $snapshot->windows->one({name => 'editor'})
    ->panes->where({width => {-gte => 1}})
    ->grep(sub ($pane) { $pane->height > 0 });
my @ids    = map { $_->id } $panes->@*;
my $active = $panes->one({active => true});
say 'editor panes: ',          scalar @ids;
say 'active pane belongs to ', $active->window->name;

```

`where` and `grep` return new selections in every calling context and preserve
order and duplicates. `grep` passes exactly one entity in scalar context and
localizes `$_`. `one` rejects absence and ambiguity; `one_or_undef` permits
absence. Use `exists` or `count` to test membership. An empty selection is
still a true reference.

## Reuse a filter with ordinary hash records

[`Filter`](https://libtmux.org/en/perl/latest/reference/libtmux-filter/) also
works without a tmux server. Run [examples/filters.pl](examples/filters.pl):

```console
$ perl examples/filters.pl
```

<!-- example: packages/core/examples/filters.pl#records -->
```perl
my $filter = LibTmux::Filter->new(
    entity => 'pane',
    where  => {
        active          => true,
        current_command => {-in  => [qw(perl vim)]},
        width           => {-gte => 80},
    },
);
my @records = (
    {id => '%1', active => true,  current_command => 'perl', width => 120},
    {id => '%2', active => false, current_command => 'perl', width => 120},
    {id => '%3', active => true,  current_command => 'vim',  width => 40},
);
my @matches = grep { $filter->matches($_) } @records;
say 'matching records: ', join ', ', map { $_->{id} } @matches;

```

It selects `%1`. The complete program also round-trips the filter through
versioned JSON. Schemas validate all criteria before evaluation, including on
empty inputs; arbitrary keys never become arbitrary method calls.

## Navigate links and handle failures

A physical window can belong to several sessions.
[`WindowLink`](https://libtmux.org/en/perl/latest/reference/libtmux-windowlink/)
owns its session-relative index and active state. `Pane->window` always means
the captured physical window. A new snapshot observes later state; existing
handles retain their original graph.

Failures are typed [exceptions](https://libtmux.org/en/perl/latest/reference/libtmux-x/)
with causes and bounded process diagnostics. Command failures never become
empty selections. Captured targets retain server-generation protection;
raw IDs deliberately address current resources.

Read the [filtering guide](https://libtmux.org/en/perl/latest/guides/filtering/),
[graph guide](https://libtmux.org/en/perl/latest/guides/graph/),
and [error guide](https://libtmux.org/en/perl/latest/guides/errors/).
Installed POD is available with `perldoc LibTmux::Server` and
`perldoc LibTmux::Selection`.

## Add async execution or workspace loading

[LibTmux-Async](https://github.com/libtmux/libtmux-perl/tree/master/packages/async)
adds Future-returning operations.
[LibTmux-Workspace](https://github.com/libtmux/libtmux-perl/tree/master/packages/workspace)
loads JSON through these public core APIs. Core loads neither distribution.
Persistent control and streaming APIs are deferred.

Each native archive owns its metadata, test requirements, README, license,
logo assets, and consumer examples. The
[repository examples runner](https://github.com/libtmux/libtmux-perl/blob/master/examples/README.md)
verifies them against owned real tmux servers and installed artifacts.
