<!-- libtmux-logo -->
<div align="center">
  <picture>
    <source srcset="assets/logo.svg" type="image/svg+xml">
    <img src="assets/logo.png" width="128" height="128" alt="libtmux for Perl">
  </picture>
</div>
<!-- /libtmux-logo -->

<div align="center">

# LibTmux-Async

</div>

LibTmux-Async runs tmux operations as Futures using the public
[LibTmux core](https://github.com/libtmux/libtmux-perl/tree/master/packages/core)
model. Submit independent operations concurrently, query their captured results
locally, and explicitly await executor cleanup.

[Run the example](#create-a-session-and-run-concurrent-operations) ·
[Cancellation](#cancel-work-and-finish-cleanup) ·
[Documentation](https://libtmux.org/en/perl/) ·
[Guide](https://libtmux.org/en/perl/latest/guides/async/) ·
[API reference](https://libtmux.org/en/perl/latest/reference/libtmux-async-server/) ·
[CPAN](https://metacpan.org/dist/LibTmux-Async) ·
[POD](https://metacpan.org/pod/LibTmux::Async)

## Install

Install the published distribution; cpm installs its core dependency too:

```console
$ cpm install \
    --global \
    LibTmux::Async
```

Requires Perl 5.44, Future 0.54, IO::Async 0.805,
IO::Async::Loop::Ppoll 0.10, and IO::Ppoll 0.14 or newer. IO::Ppoll includes
an XS extension. Linux x86_64 LP64 and tmux 3.3a–3.8 are supported; CI tests
the tmux endpoints. Read the
[installation guide](https://github.com/libtmux/libtmux-perl/blob/master/docs/installation.md)
for interpreter, compiler, and source installation setup. The `0.x` API can
change between releases; consult `Changes` before upgrading.

## Create a session and run concurrent operations

[examples/concurrent.pl](examples/concurrent.pl) uses installed modules. It
creates and removes its own session on the explicit socket, preserves other
sessions, and leaves the caller's event loop alive.

```console
$ perl examples/concurrent.pl "${TMPDIR:-/tmp}/libtmux-perl-async-$$.sock"
```

<!-- example: packages/async/examples/concurrent.pl -->
```perl
use v5.44;
use IO::Async::Loop::Ppoll;
use Future;
use LibTmux::Async::Server;

my $socket = shift @ARGV // die "Usage: $0 SOCKET_PATH [TMUX]\n";
my $tmux   = shift @ARGV // 'tmux';

# example: begin connect
my $loop   = IO::Async::Loop::Ppoll->new;
my $server = LibTmux::Async::Server->new(
    loop           => $loop,
    socket_path    => $socket,
    executable     => $tmux,
    config_file    => '/dev/null',
    max_concurrent => 2,
    max_queue      => 8,
);

# example: end connect
my ($session, $failure);
try {
    my $created = $server->new_session(
        name    => 'perl-async',
        command => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    $loop->await($created);
    $session = $created->get;

    # example: begin concurrent
    my $capture = $server->snapshot;
    my $version = $server->cmd('display-message', '-p', '#{version}');
    $loop->await(Future->needs_all($capture, $version));
    my $snapshot = $capture->get;
    my $panes    = $snapshot->sessions->one({name => 'perl-async'})
        ->window_links->one->window->panes->where({active => true});
    say 'async active panes: ', $panes->count;
    say 'tmux version: ',       $version->get->stdout;

    # example: end concurrent
    die 'async session missing pane' unless $panes->count == 1;

    # example: begin batch
    my $batch = $server->batch(
        [
            ['display-message', '-p', 'first'],
            ['display-message', '-p', 'second'],
        ]
    );
    $loop->await($batch);
    my $results = $batch->get;
    for my $entry ($results->@*) {
        die $entry->{error} if defined $entry->{error};
        print $entry->{result}->stdout;
    }

    # example: end batch
    die 'batch order changed'
        unless $results->[0]{result}->stdout eq "first\n"
        && $results->[1]{result}->stdout eq "second\n";
}
catch ($error) {
    $failure = $error;
    $session //= $error->created if $error isa LibTmux::X::Creation;
}
if ($session) {
    try {
        my $removed = $server->kill_session(session => $session);
        $loop->await($removed);
        $removed->get;
    }
    catch ($cleanup) {
        warn "session cleanup failed: $cleanup\n";
        $failure //= $cleanup;
    }
}

# example: begin close
my $closed = $server->close;
$loop->await($closed);
try { $closed->get }
catch ($cleanup) {
    warn "executor cleanup failed: $cleanup\n";
    $failure //= $cleanup;
}
die $failure if defined $failure;
say 'async operations and cleanup: ok';

# example: end close
```

The output includes `async active panes: 1`, the connected tmux version,
`first` then `second`, and `async operations and cleanup: ok`.
[`Future->needs_all`](https://metacpan.org/pod/Future#needs_all)
lets independent acquisition and display requests overlap. `batch` preserves
request order and returns a `{result, error}` entry for each independent
command. Each ordinary operation yields one core value, including one `undef`
for a void method.

## Cancel work and finish cleanup

Cancelling an operation Future requests cleanup and suppresses later command
continuations. It does not undo accepted effects. Only successful completion
of the Future from
[`close`](https://libtmux.org/en/perl/latest/reference/libtmux-async-server-close/)
proves executor-owned processes and pipes have finished. Keep driving the loop
through that Future; cancelling a close observer cannot cancel private cleanup.
Closing preserves a borrowed tmux server.

The standalone
[lifecycle program](https://github.com/libtmux/libtmux-perl/blob/master/examples/async-lifecycle.pl)
adds failure and cancellation paths against an existing explicit socket. It
preserves the original operation failure and reports cleanup failure separately.
See the [async guide](https://libtmux.org/en/perl/latest/guides/async/) for all
three tested modes.

## Choose bounds and caller syntax

Construct `IO::Async::Loop::Ppoll` explicitly and pass it to
[`Server->new`](https://libtmux.org/en/perl/latest/reference/libtmux-async-server-new/).
`max_concurrent` bounds active subprocesses; `max_queue` bounds waiting
requests. Other loop backends are rejected before dispatch. A command timeout
excludes queue delay and the total duration of a multi-command operation.

`Future::AsyncAwait` is optional caller syntax. Core and workspace remain
usable without Future, IO::Async, or IO::Ppoll. Installed documentation is
available with `perldoc LibTmux::Async::Server` and
`perldoc LibTmux::Async::Transport`. Persistent control and
streaming APIs remain deferred; see the
[architecture](https://github.com/libtmux/libtmux-perl/blob/master/docs/architecture.md).
