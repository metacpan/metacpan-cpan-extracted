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

## Identifying users

```perl
ForgeOps::Tracker::report($@, {}, { id => $user->id, email => $user->email });
```

Or `set_user(%user)` to attach it for the rest of this process rather than passing it to every
`report()` call by hand, e.g. from your own PSGI middleware or a Dancer2 `hook before` (there's no
automatic PSGI/Dancer2 auth detection yet, so this is manual either way):

```perl
ForgeOps::Tracker::set_user(id => $user->id, email => $user->email);
ForgeOps::Tracker::set_user(); # clear it, e.g. once a request finishes
```

A plain package variable, the same "shared-nothing between requests" reasoning `sdks/php`'s own
static property already documents: a typical Perl PSGI deployment (Starman, uWSGI, mod_perl's own
prefork MPM) is one process per worker, forked fresh before serving any request, so this is safely
request-scoped there without needing a thread-local. Request-handling code under a threaded or
event-loop-based PSGI server should `local`-ize `$ForgeOps::Tracker::current_user` directly
instead of calling `set_user`, the same way Dancer2 itself already uses `local` for its own
per-request state. `id`/`email`/`username` are all independently optional. Shows up on an issue's
own detail page, and as its own affected-users count alongside the regular event count.

## Breadcrumbs

A small, bounded trail of recent events attached to whatever `report()` sends next, so an issue's
detail page can show what led up to it, not just the moment it happened:

```perl
ForgeOps::Tracker::add_breadcrumb('charging card', category => 'payment', data => { order_id => $order->id });
```

`category` and `level` default to `'custom'`/`'info'`; `data` is any small hashref of extra detail.
Only the 30 most recent are kept (`max_breadcrumbs`), oldest dropped first; turn it off with
`track_breadcrumbs => 0`. `message` and `data` are PII-scrubbed like the rest of the payload;
`category`, `level`, and `timestamp` are structured values and never touched. Omitted from the
payload entirely when the trail is empty.

The PSGI and Dancer2 integrations record one automatically: a `controller` breadcrumb per request
(`GET /users/:id` for Dancer2, the route pattern; the raw path for plain PSGI, which has no route
concept), added by `Integrations::PSGIPerformance` / `Integrations::Dancer2Performance` when you
use them, and by `Integrations::Dancer2` itself for a request that raised (Dancer2's own
`after_request` hook never fires for one, confirmed directly). Both error-reporting integrations
also clear the trail at the start of every request: a prefork worker serves many requests in a row
from one process, so without that one request's trail would leak into the next. Anywhere else
(a cron script, a queue worker) call `ForgeOps::Tracker::clear_breadcrumbs()` yourself at the start
of each unit of work.

Stored in a plain package array (`@ForgeOps::Tracker::current_breadcrumbs`), the same
one-process-per-worker reasoning `set_user` documents; under a threaded or event-loop-based PSGI
server, `local`-ize that array instead.

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
second, earlier layer, not the only one. The user attached via `report`'s third argument or
`set_user` above is a deliberate exception: it's never scrubbed, since redacting it would defeat
the whole point of identifying users in the first place.

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

## Distributed tracing

A slow request's own breakdown: which pieces of your code (or calls you wrap) the time went to,
shown as a span tree on ForgeOps. On by default with `PSGIPerformance` or `Dancer2Performance`
enabled: each starts a trace per request (root span named like the performance transaction) and,
once the request finishes, sends it only when it took at least `trace_capture_threshold` seconds
(1 by default), so fast requests cost nothing on the wire. Delivered on the same background thread
and bounded queue as error reports. Traces are per service; nothing is propagated across services.

There is no automatic database or outbound HTTP span (no DBI or HTTP::Tiny hook in this client), so
the request itself is the only automatic span; add the rest by hand:

```perl
my $order = ForgeOps::Tracker::span('charge card', sub { $gateway->charge($id) },
    kind => 'service', data => { order_id => $id });
ForgeOps::Tracker::span('fetch rates', sub { $http->get($url) }, kind => 'http');

# Something you timed yourself (kind is one of controller/service/database/redis/http/job/other;
# $started_at is Time::HiRes::time):
ForgeOps::Tracker::record_span('SELECT orders', 'database', $started_at, $duration_ms);
```

`span` nests under whichever span is open, returns what the code returned (list or scalar context),
records even when the code dies (re-raising unchanged), and just runs the code outside a trace. To
trace something that is not a request, call `ForgeOps::Tracker::start_trace()` and
`finish_trace($name, $started_at, $duration_ms)` yourself. A trace holds at most 500 spans. Configure
with `track_tracing => 0` and `trace_capture_threshold => 2.5`.

## Custom metrics and infrastructure monitoring

Two explicit calls (nothing is automatic, so there is no `track_metrics` option): a business event you
name yourself, and a reading from one of your own hosts.

```perl
ForgeOps::Tracker::capture_metric('signup');          # value defaults to 1: a bare counter
ForgeOps::Tracker::capture_metric('payment', 49);     # a real magnitude; it may be negative (a refund)

ForgeOps::Tracker::capture_infrastructure_metric('cpu', 0.42);                    # hostname defaults to server_name
ForgeOps::Tracker::capture_infrastructure_metric('disk', 0.81, hostname => 'db-1');
ForgeOps::Tracker::flush_metrics();                                                # optional: send right now
```

Each capture is buffered and flushed as one batch every `metric_flush_interval` /
`infrastructure_metric_flush_interval` seconds (60 by default) on a background thread, and once more
from an `END` block when the program ends normally, so a short-lived cron script that captures a few
readings and falls off the end needs nothing more (a test runs exactly that in a child `perl`); call
`flush_metrics()` if it might exit another way (`POSIX::_exit`). Every entry is stored as it was
captured (a signup is a row, not a running total), so a count or sum you compute later is exact. Both
are a no-op when the client isn't enabled for the environment.

A failed delivery keeps every entry for the next flush, and an entry captured while a delivery is in
flight is kept too (the Ruby gem's own buffer loses it; a test pins this with a gated delivery on a
second thread). The buffer holds at most 1000 entries per kind and drops further ones until a flush
succeeds, since a plan without the feature rejects every flush and would otherwise grow it for as long
as the process lives. A NaN, infinite or non-numeric value is dropped at capture. Requires a ForgeOps
plan that includes custom metrics / infrastructure monitoring.

## Running the tests

```bash
cd sdks/perl
cpanm --installdeps --with-recommends .   # pulls in Plack/Dancer2 for the integration tests too
prove -l t/
```
