# ForgeOps::Tracker

Perl error reporting client for a [ForgeOps](../../) instance. Zero
non-core runtime dependencies: `HTTP::Tiny`, `JSON::PP`, `threads`, `threads::shared`,
`Thread::Queue`, `POSIX`, `Cwd`, `Sys::Hostname`, and `Carp` are all part of core Perl (5.14+).
`Plack` and `Dancer2` are only needed for their own optional integrations below.

## Installation

```bash
cpanm ForgeOps::Tracker
```

Installing straight from the mirror repo also still works, if you'd rather pin a specific commit
than a CPAN release:

```bash
cpanm https://github.com/Luke-Popwell/forge-ops-tracker-perl.git
```

That mirror is kept in sync automatically from `sdks/perl` in the main `forge_ops` repo (which is
private, so isn't itself something `cpanm` could ever install from directly); develop against that
repo, not this one. To build and run this SDK's own tests directly instead:

```bash
cd sdks/perl
cpanm --installdeps .
perl Makefile.PL && make test
```

## Configuration

Set a DSN (from a project's settings page in ForgeOps), either via the `FORGE_OPS_DSN`
environment variable or explicitly:

```perl
use ForgeOps::Tracker;

ForgeOps::Tracker::init(
    dsn         => 'https://<api_key>@your-forgeops-host/api/v1/events', # or leave unset to read FORGE_OPS_DSN
    release     => '...',
    environment => 'production',
);
```

Call `init()` once at startup. Any `Configuration` field can be overridden by name.

### PSGI / Plack

```perl
use Plack::Builder;

builder {
    enable '+ForgeOps::Tracker::Integrations::PSGI';
    $app;
};
```

The leading `+` matters: without it, Plack::Builder looks the name up under its own
`Plack::Middleware::*` namespace instead of taking it as an exact class name. Works under any
PSGI-speaking framework, not just plain PSGI apps: Dancer2 itself ultimately runs on PSGI, so
this middleware would also catch what escapes a Dancer2 app, though the dedicated Dancer2 plugin
below is the better fit there (it reports from inside Dancer2's own exception hook, with access to
Dancer2's request object, rather than the raw PSGI `$env`).

### Dancer2

```perl
use Dancer2;
use ForgeOps::Tracker::Integrations::Dancer2;   # that's it: no further wiring
```

Registers Dancer2's own `on_route_exception` hook, which fires for any exception a route throws
that reaches Dancer2's top-level handling, before Dancer2 renders its own error page. The hook only
observes; Dancer2's own error response still renders exactly as if this plugin weren't installed.

## What gets reported automatically, and what doesn't

**An exception that escapes a route needs no further wiring at all** under either integration
above. **An exception your own code catches and handles is different**: report it explicitly at
the catch site:

```perl
eval { charge_card($order) };
if ($@) {
    ForgeOps::Tracker::report($@, { order_id => $order->id });
}
```

### There's no process-wide "uncaught exception" fallback

There's deliberately no process-wide fallback hook here, and that's not an oversight. Perl's
`$SIG{__DIE__}` is the only language-level hook that fires on every `die`, but it fires for
**every** `die`, including one an enclosing `eval {}` goes on to catch and handle locally:
there's no way for a `__DIE__` handler to know, at the moment it's called, whether the exception
unwinding toward it will actually escape uncaught or not. Installing one here would report
exceptions your own code already handles, breaking the invariant this client otherwise holds to
throughout: an exception your own code catches and doesn't explicitly report is invisible to this
client. For a plain script with no framework, wrap your own top-level code instead:

```perl
eval { main() };
if ($@) {
    ForgeOps::Tracker::report($@);
    die $@; # still exit non-zero / print the real error, same as without this client installed
}
```

## Delivery: a real background thread

`DeliveryQueue` uses Perl's own `threads` + `Thread::Queue`: unlike a manual `fork()`-per-event
approach, `Thread::Queue` is purpose-built by the Perl core itself as a thread-safe hand-off
between a producer and a consumer thread. The worker thread starts lazily, on first push, not at
load time: a prefork Perl app server (Starman in prefork mode, or mod_perl2's prefork MPM) forks
worker processes *after* the application has already loaded, so a thread started eagerly at load
time simply wouldn't exist in a forked child.

## Backtrace parsing

Perl doesn't hand you a structured stack trace by default. `EventBuilder` parses two real shapes
instead: a `die` message Perl itself appended `" at FILE line N."` to (every `die` gets this unless the message already
ends in `"\n"`), and, when the caught error came from `Carp::confess`, the full
`"\tPACKAGE::sub(...) called at FILE line N"` chain confess produces for every frame on the stack.
For the fullest backtrace, raise with `Carp::confess`, not a plain `die`:

```perl
use Carp qw(confess);
confess("something went wrong") if $bad_thing;
```

If your own exception classes expose a `->trace` method returning a `Devel::StackTrace`-compatible
object (as `Throwable::Error` and similar frameworks do), that's used directly instead and is more
reliable than parsing any string.

## Source context

By default, each in_app backtrace frame (never a vendored/system library) is captured along with
the 5 lines of source on either side of the culprit line, read straight off disk at die/confess
time, so an issue's detail page can show the actual code that broke, not just a `file:line`
reference. This never applies to a frame outside `app_root`, and it fails silently (no context,
not an error) for any file that can't be opened for whatever reason.

This is a real, deliberate exception to "off by default is safer": literal source code is being
transmitted, not just a reference to it, and the real protection here is not this flag. Every
project on ForgeOps has its own setting (on by default, off durably and immediately once an org
owner turns it off, regardless of what any individual app's own `capture_source_context` is still
set to) that governs whether the server will ever actually store what an SDK sends, see the in-app
help docs. Use this option if you'd rather this client never even attempt the disk read in the
first place:

```perl
ForgeOps::Tracker::init(dsn => '...', capture_source_context => 0);
```

## PII scrubbing

The message, backtrace, and any context/tags you attach are scanned for likely personal data
(email addresses, formatted SSNs/credit cards, known API key/token formats, and anything under a
suspiciously-named key) and redacted before the
payload ever leaves this process. ForgeOps itself scrubs again on arrival regardless, so this is a
second, earlier layer, not the only one.

To disable it:

```perl
ForgeOps::Tracker::init(dsn => '...', scrub_pii => 0);
```

## Performance monitoring

Two more integrations, one per framework, time every request end to end and report it, bucketed
by transaction name, for a dashboard widget on a project's Performance page (so it can show which
parts of your app are actually slow, not just which ones raise). Counted in-process and flushed as
a small periodic aggregate on a background thread, the same delivery philosophy as error
reporting: a broken or unreachable tracker never affects the host app either way.

```perl
# PSGI / Plack
use Plack::Builder;
builder {
    enable '+ForgeOps::Tracker::Integrations::PSGI';            # error reporting
    enable '+ForgeOps::Tracker::Integrations::PSGIPerformance'; # performance monitoring
    $app;
};

# Dancer2
use Dancer2;
use ForgeOps::Tracker::Integrations::Dancer2;              # error reporting
use ForgeOps::Tracker::Integrations::Dancer2Performance;   # performance monitoring
```

The transaction name is the matched route pattern where one is available (Dancer2's own
`spec_route`, e.g. `GET /users/:id`), so a distinct user id doesn't explode into its own separate
transaction; plain PSGI has no route-matching concept of its own to read a pattern from, so that
integration reports the raw request path instead. A Dancer2 request that never matches any route
(a 404) isn't recorded at all: Dancer2's own `after_request` hook simply never fires for that case.

```perl
ForgeOps::Tracker::init(
    dsn                        => '...',
    track_performance          => 0,  # opt out entirely
    performance_flush_interval => 30, # default 60 seconds
);
```

Requires a ForgeOps plan that includes performance monitoring; on a plan that doesn't, the
periodic flushes are simply rejected server-side and dropped, exactly like any other delivery
failure.

## Running the tests

```bash
cd sdks/perl
cpanm --installdeps --with-recommends .   # pulls in Plack/Dancer2 for the integration tests too
prove -l t/
```
