# Base::FS peer marker leak on SIGKILL

Defect surfaced while building "resource services spawn via preload" in
Test2-Harness2 (worktree `preload_rework`). Not caused by that work — a
pre-existing IPC::Manager defect that the new feature exercises harder
than anything else does.

This document is a hand-off for a follow-up agent.

> **Driver in use.** Test2-Harness2 defaults to
> `IPC::Manager::Client::ConnectionUnix` (per-peer SOCK_STREAM sockets
> on disk). The defect therefore lives in `Base::FS` (the shared base
> class for `ConnectionUnix`, `AtomicPipe`, and `MessageFiles`), not in
> `JSONFile`. JSONFile has a structurally identical bug; the fix
> approach below is essentially the same as JSONFile would need.
> Address the FS layer first since that is what's exercised in
> production.

> **Earlier-doc note.** An earlier version of this doc also tracked a
> "second `sync_request` on a reused handle returns empty" defect.
> That claim has been invalidated by reproduction work: three
> independent reproductions all show consecutive `sync_request` calls
> returning identical populated data, and
> `IPC::Manager::Test::test_intercept_errors`
> (`lib/IPC/Manager/Test.pm:1103-1121`) already exercises four
> consecutive `sync_request` calls and passes in CI. The misdiagnosis
> in Test2-Harness2 was probably the C3 race ("empty Daemon row after
> reload", since fixed) being mistaken for a dispatcher defect.

The downstream consumer is at
`/home/exodist/projects/Test2/Test2-Harness/.claude/worktrees/preload_rework/`
on branch `preload_rework`. Useful reference points there:

- `lib/Test2/Harness2.pm` — `_handle_resource_service_started`,
  `_spawn_service_via_preload`, `request_handler_status`.
- `lib/Test2/Harness2/Role/ResourceServiceHost.pm` —
  `_start_service_entry`, `track_resource_service`,
  `handle_resource_service_exit`.
- `lib/Test2/Harness2/PreloadService.pm` —
  `request_handler_spawn_service`, `_post_jump_spawn_service`,
  `restartable` (returns 0 today).
- `t/AI/integration/resource_via_preload_restart.t` lines 21-36 — quotes
  the actual production error verbatim: "IPC::Manager::Base::FS::init
  croaks 'UNIX Socket or marker file already exists'". Currently works
  around the defect by avoiding the failure-path assertions.

When this fix is in IPC::Manager and a release lands, the harness side
will flip `Test2::Harness2::PreloadService::restartable` to return 1
(currently `0`) so a preload that exits unexpectedly is restarted
automatically. Without this fix, the next start crashes on
`<peer-id> UNIX Socket or marker file already exists`.

## Symptom

A client that registered through any `Base::FS` driver (`ConnectionUnix`,
`AtomicPipe`, `MessageFiles`) and then died ungracefully (SIGKILL,
segfault, OOM, parent-exit cascade — anything that bypasses Perl's
`DESTROY`) leaves its on-disk artifacts behind:

- `$ROUTE/{on_disk_name}` — socket file (ConnectionUnix) or directory
  (AtomicPipe) for the peer
- `$ROUTE/{on_disk_name}.pid` — pidfile carrying the dead pid
- `$ROUTE/{on_disk_name}.name` — sidecar (for hashed names)
- `$ROUTE/{on_disk_name}.resume` — resume buffer (if any)
- `$ROUTE/{on_disk_name}.stats` — stats sidecar

The next process that tries to register with the same peer name croaks:

    <peer-id> UNIX Socket or marker file already exists at
        .../IPC/Manager/Base/FS.pm line 209

The harness then either falls back to standalone spawn (silently losing
preload-mediated semantics) or aborts the respawn entirely, depending on
caller.

## Why it happens

- `init()` at `lib/IPC/Manager/Base/FS.pm:189-219` croaks when the
  on-disk path for `$self->{+ID}` already exists (line 209):

      else {
          croak "${id} ${pt} already exists" if -e $path;
          $self->make_path($path);
          $self->_write_name_file;
      }

  `path_type` is driver-specific ("UNIX Socket or marker file" for
  ConnectionUnix; "AtomicPipe directory" for AtomicPipe; etc).

- The only path that removes the on-disk artifacts is
  `post_disconnect_hook()` at `Base/FS.pm:284-289`, which calls
  `remove_tree($path, ...)` — reached only through a clean
  `IPC::Manager::Client::disconnect()` call (and via `DESTROY`, which
  is bound to `disconnect()`). SIGKILL skips both, so all five
  artifacts persist.

- `peer_left()` on `Base::FS` is inherited from
  `IPC::Manager::Client.pm:48` as a no-op:

      sub peer_left            { }

  Consequence: even though `IPC::Manager::Role::Service` *does* call
  `$client->peer_left($peer)` for every peer that disappears from
  `peer_delta` (see `lib/IPC/Manager/Role/Service.pm:512-517`), the FS
  drivers don't reap anything in response. (`AtomicPipe` does override
  `peer_left` — see "Reference" below — but its override is scoped to
  the Atomic::Pipe state, not the FS-layer on-disk peer artifacts. The
  FS artifacts still leak.)

- Worse: `peers()` at `Base/FS.pm:312-334` enumerates every directory
  entry under `$ROUTE` (skipping sidecars and the caller's own dir)
  and only filters via `check_path` — which, for ConnectionUnix
  (`ConnectionUnix.pm:36`), is `-S $_[1] || -f $_[1]`, i.e. "does the
  socket file or marker file exist on disk". The pidfile is not
  consulted. A dead peer's socket file still satisfies `check_path`,
  so `peers()` reports it as live, `peer_delta()` never marks it as
  gone, and `peer_left()` is never invoked for it. The cleanup hook is
  unreachable for the case it most needs to handle.

## Reference: AtomicPipe peer eviction (partial pattern)

`lib/IPC/Manager/Client/AtomicPipe.pm:112-137` shows a related pattern
that reaps stale entries from the in-memory Atomic::Pipe state:

    sub peer_left {
        my $self = shift;

        my $p = $self->{+PIPE} or return 0;
        my $state = $p->{Atomic::Pipe::STATE()} or return 0;

        my %tags;
        $tags{$_} = 1 for keys %{$state->{parts}   // {}};
        $tags{$_} = 1 for keys %{$state->{buffers} // {}};

        my $removed = 0;
        for my $tag (keys %tags) {
            my ($pid) = split /:/, $tag, 2;
            next unless $pid && $pid =~ m/^-?\d+$/;
            next if $self->pid_is_running($pid);
            delete $state->{parts}->{$tag};
            delete $state->{buffers}->{$tag};
            $removed++;
        }

        return $removed;
    }

Note: this only cleans Atomic::Pipe state tags; it does NOT remove the
on-disk FIFO/dir or pidfile. The defect documented here is upstream of
this code — `peer_left` is never even called for the SIGKILL'd peer.

Two principles from the AtomicPipe shape worth borrowing for the FS
fix:

1. The hook opportunistically sweeps every stale entry it can identify,
   not just the peer it was told about. That is the right shape —
   peer_delta callbacks fire on changes, so each fire is a good moment
   to do a cheap scan.
2. It uses `pid_is_running` (from `IPC::Manager::Util`), which returns
   1 (ours), -1 (running but not ours), or 0 (gone). Only reap entries
   whose pid is genuinely gone — never reap "running but not ours" pids
   (could be a foreign pid that happens to overlap a stale pidfile).

## Catch: peers() must surface the loss before peer_left fires

The fix needs to address both sides:

- Make `peers()` filter out peers whose on-disk pidfile carries a dead
  pid.
- Implement `peer_left()` (or a periodic sweep) to actually remove the
  on-disk artifacts (`$path`, `.pid`, `.name`, `.resume`, `.stats`) for
  stale-pid peers.

Filtering `peers()` alone isn't enough: the on-disk tree still grows,
and the `croak "${id} ${pt} already exists"` at line 209 still fires on
respawn because `init()` does a direct `-e $path` check.

## Suggested fix

All three pieces live in `lib/IPC/Manager/Base/FS.pm` so every FS-based
driver inherits the cleanup.

### (a) Reap-and-replace in init()

Around `Base/FS.pm:208-212`, before the croak, attempt to reap when
the existing artifacts belong to a dead pid:

```perl
else {
    if (-e $path) {
        my $existing_pid = 0;
        if (open(my $fh, '<', $self->peer_pid_file($id))) {
            chomp(my $p = <$fh>);
            close $fh;
            $existing_pid = $p if defined $p && $p =~ m/^[0-9]+\z/;
        }
        if ($existing_pid && !$self->pid_is_running($existing_pid)) {
            # Stale registration from a SIGKILL'd predecessor; reap.
            $self->_reap_peer_artifacts($id);
        }
        else {
            # Either no pidfile (corruption — bail loudly), or pidfile
            # carries a live pid (legitimate collision — refuse).
            croak "${id} ${pt} already exists";
        }
    }
    $self->make_path($path);
    $self->_write_name_file;
}
```

`_reap_peer_artifacts` unlinks `$path` (via `remove_tree` for dir-typed
drivers, `unlink` for socket-typed drivers — drive off `path_type` or
add a driver method) plus the four sidecars (`.pid`, `.name`,
`.resume`, `.stats`).

### (b) Implement peer_left()

```perl
sub peer_left {
    my $self = shift;
    # Opportunistically sweep every stale entry we can identify, not
    # just the one we were told about. Cheap: one readdir + N stats.
    my $removed = 0;
    my $route   = $self->{+ROUTE};
    opendir(my $dh, $route) or return 0;
    for my $file (readdir($dh)) {
        next if $file =~ m/^(\.|_)/;
        next if $file =~ m/\.(?:pid|name|resume|stats)$/;
        next if $file eq $self->on_disk_name($self->{+ID});

        my $pidfile = File::Spec->catfile($route, "$file.pid");
        next unless -f $pidfile;
        open(my $fh, '<', $pidfile) or next;
        chomp(my $pid = <$fh>);
        close $fh;
        next unless defined $pid && $pid =~ m/^[0-9]+\z/;
        next if $self->pid_is_running($pid);

        $self->_reap_peer_artifacts_by_on_disk($file);
        $removed++;
    }
    closedir $dh;
    return $removed;
}
```

`_reap_peer_artifacts_by_on_disk` is the on-disk-name variant of
`_reap_peer_artifacts` (the public version takes a peer id; this one
takes the already-hashed on-disk name so we don't need to reverse the
hash).

### (c) Filter peers()

Change `Base/FS.pm:312-334` to skip entries whose pidfile carries a
dead pid:

```perl
sub peers {
    my $self = shift;
    my $my_on_disk = $self->on_disk_name($self->{+ID});

    my @out;
    opendir(my $dh, $self->{+ROUTE}) or die "Could not open dir: $!";
    for my $file (readdir($dh)) {
        next if $file eq $my_on_disk;
        next if $file =~ m/^(\.|_)/;
        next if $file =~ m/\.(?:pid|name|resume|stats)$/;

        my $path = File::Spec->catdir($self->{+ROUTE}, $file);
        next unless $self->check_path($path);

        # New: skip peers whose pidfile carries a dead pid. peer_left
        # will reap them on the next service tick.
        my $pidfile = File::Spec->catfile($self->{+ROUTE}, "$file.pid");
        if (-f $pidfile) {
            if (open(my $fh, '<', $pidfile)) {
                chomp(my $pid = <$fh>);
                close $fh;
                next if defined $pid && $pid =~ m/^[0-9]+\z/
                     && !$self->pid_is_running($pid);
            }
        }

        push @out => $self->_real_name_for_on_disk($file);
    }
    closedir $dh;
    return sort @out;
}
```

This change alone is enough to make `peer_delta` notice a SIGKILL'd
peer departure, which then triggers `peer_left` (your new
implementation) to clear the on-disk artifacts. The init-side fix in
(a) is still wanted as a defense-in-depth measure for the window where
the role-loop hasn't yet ticked.

**Do all three** — they're cheap and each addresses a different
window:
- (a) heals on the next registration attempt regardless of role-loop
  timing.
- (b) keeps the on-disk tree tidy under steady-state load.
- (c) makes `peer_delta` accurate so `peer_left` actually fires.

## Tests

Add unit tests under `t/unit/Base/FS.t` (or whichever existing FS test
file is the right home):

1. **SIGKILL repro / reap-and-replace.** Spawn a child that registers a
   ConnectionUnix peer with a known id, then `kill 'KILL', $$;` itself
   before disconnecting. From the parent, wait for `waitpid` to confirm
   the child is gone, then open a fresh peer with the same id. Assert
   registration succeeds (no `already exists` croak). Assert the
   original child's on-disk artifacts are gone.

2. **peer_left sweep.** Two registered peers A and B, B SIGKILL'd.
   From peer A's service loop, trigger one peer_delta tick (or call
   `peer_left` directly). Assert B's on-disk artifacts have been
   reaped from `$ROUTE`.

3. **Foreign-pid safety.** Synthesize a peer directory + pidfile with
   a pid that is running but is not any IPC::Manager process (e.g. the
   test harness's `$$`). Attempt registration with that id. Assert the
   croak still fires — we do NOT reap "running but not ours" pids.

4. **peers() filters dead pids.** Register two peers, SIGKILL one,
   call `peers()` from a third client; assert only the live peer
   appears in the list.

5. **Repeat at least #1 for AtomicPipe** to confirm the FS-layer fix
   carries through. The fix lives in `Base::FS`, so all FS drivers
   should benefit uniformly.

## Cross-distribution check

CLAUDE.md notes that `IPC-Manager-Client-SharedMem` lives at
`../IPC-Manager-Client-SharedMem/`. SharedMem subclasses
`IPC::Manager::Client` directly (not `Base::FS`), so the fix here does
not affect it. If you choose to factor the pidfile-based liveness
check into the `Client` base class as a helper, audit SharedMem to
make sure it inherits cleanly.

## Severity

Blocking for any caller that needs robustness across abnormal client
death. Test2-Harness2 will flip `PreloadService::restartable` to `1`
once this is fixed; without it, every preload that dies abnormally
poisons subsequent spawns through the same daemon. Production users
running `yath start` daemons over long periods will hit this any time
a preload or via-preload service crashes.

## Hand-off

When this fix is in IPC::Manager and a release is cut, follow up in
the Test2-Harness2 worktree:

1. Flip `restartable` in `lib/Test2/Harness2/PreloadService.pm` from
   `0` to `1`.
2. Drop the `restartable => 1` override and the SIGKILL workaround in
   `t/AI/integration/resource_via_preload_restart.t`.
3. Add an integration test that SIGKILLs a via-preload resource
   service and asserts the harness's `restart_resource_service` path
   successfully re-registers the peer.
4. Bump the IPC::Manager prereq in `cpanfile`.
