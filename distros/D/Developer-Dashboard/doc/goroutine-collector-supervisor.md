# Collector Supervisor Process Launch

The collector supervisor is a long-lived watcher that monitors configured
collectors and restarts them when required. `RuntimeManager` now starts its
foreground helper through `Developer::Dashboard::GoRoutine::spawn` rather
than creating a child with Perl `fork`.

## Launch sequence

1. `RuntimeManager` returns the existing supervisor PID when one is already
   running, and does not launch a duplicate.
2. Otherwise it builds an argument vector for the private
   `collector-supervisor-foreground` helper and passes that vector directly to
   GoRoutine. No shell command string is evaluated.
3. Standard input is connected to the platform null device. Standard output
   and standard error are redirected to the collector log and its `.stderr`
   companion.
4. The returned process ID is written to the supervisor PID file and runtime
   state. File-open, write, close, and spawn failures are reported to the
   caller.
5. The helper reloads configured path aliases and saved pages, then runs the
   existing supervisor loop. On POSIX it detaches its session and configures
   its own log streams; on Windows session detachment is not attempted.

## Verification

`t/235-runtime-manager-goroutine-supervisor.t` checks that the launch routine
does not call Perl `fork`, delegates to GoRoutine, launches the helper using an
argument vector, redirects its streams, and records the returned PID. The
test is run in the dev Docker container alongside
`t/46-runtime-manager-supervisor.t` and
`t/530-runtimemanager-failure-injection-coverage.t`.

This change covers the collector supervisor start path only. Other production
and test `fork` call sites remain in scope for DKT-016 and must be migrated
with their own regression evidence before the overall replacement can be
considered complete.

## Shared worker state

`Developer::Dashboard::GoRoutine::share` exposes a C-backed shared Perl data
graph to `go` worker interpreters. The Dashboard integration includes nested
hashes and arrays, scalar references, repeated references, cycles, CODE
references, fd-backed filehandles and sockets, and blessed objects whose state
is held in ordinary Perl data structures. Normal Perl dereferencing and object
methods continue to work, and scalar updates plus hash/array structural
operations use the native graph lock. Opaque resources whose semantics live
only in module-private native pointers remain subject to their XS module's
thread-safety and cloning rules. This shared-state API is separate from
`spawn`, which keeps OS child-process identity and lifecycle semantics.

## Worker interpreter cloning on Windows

The XS worker launcher retains `CLONEf_KEEP_PTR_TABLE` so callback references
can be mapped into the cloned interpreter. On Windows builds whose Perl headers
define `CLONEf_CLONE_HOST`, it also requests that flag so the cloned interpreter
uses the host interpreter's clone semantics. The flag is compile-time guarded:
Perl builds that do not provide it continue to use the supported pointer-table
flag rather than failing to compile. `t/238-goroutine-routine-controls.t`
checks the clone call and guarded Windows branch. Native Windows runtime
behavior still requires the hosted Windows workflow for direct validation.

## POSIX web-service launch

The POSIX background web path also uses `Developer::Dashboard::GoRoutine::spawn`.
It starts the private `web-foreground` helper with an argument vector, null
stdin, and explicit dashboard stdout/stderr log paths. It records the listener
PID and endpoint only after the requested port accepts a connection. If the
readiness poll budget expires, it terminates and waits for the spawned child,
then reports the child status and both log paths rather than returning a
possibly dead PID as though startup succeeded. Windows retains its existing
native detached-launch path pending the hosted GoRoutine validation.

The focused test `t/235-runtime-manager-goroutine-supervisor.t` checks the
shell-free command, redirection, listener-state persistence, timeout
termination and wait. Run it with the checkout XS paths inside Docker:

```sh
d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/235-runtime-manager-goroutine-supervisor.t
```

## SSL frontend and shared client routines

SSL mode now starts a separate internal Starman backend by passing an argv
vector for the staged `web-ssl-backend-foreground` helper to GoRoutine's native
process API. The helper rebuilds the normal application from the layered
configuration and serves only the internal loopback endpoint. It is not
implemented by running Starman from a GoRoutine thread because Starman's
prefork worker model requires an independent OS process.

The public SSL frontend handles each accepted socket in a GoRoutine worker. It
shares the fd-backed socket and the minimal server/daemon data needed by the
request handler; it does not share the application object graph. Shutdown
cancels active routines, waits for them to unwind, reports handler and socket
close errors, then terminates and waits for the backend process. The backend
child is reaped exactly once even when a signal handler and normal cleanup both
request shutdown.

`t/17-web-server-ssl.t` covers the shell-free backend argv, process-group
launch, signal cleanup, HTTP redirect, TLS proxy, and live client behavior. Run
it with the current XS build inside Docker:

```sh
d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/17-web-server-ssl.t
```
