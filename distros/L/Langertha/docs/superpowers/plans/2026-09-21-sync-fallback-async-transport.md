# Sync-fallback async transport — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. This is behavior-relevant Langertha core — the executor is `langertha-worker`.

**Goal:** Give the async `_f` path a synchronous LWP fallback so `IO::Async` + `Net::Async::HTTP` can drop to `recommends` without changing the `_f` API.

**Architecture:** A tiny sync HTTP backend (`Langertha::Request::SyncHTTP`) satisfies the existing `do_request` contract over `LWP::UserAgent` and returns an already-complete `Future` (no event loop needed — `Future::AsyncAwait` resolves an already-done `await` synchronously). A shared role (`Langertha::Role::AsyncHTTP`) centralizes backend selection (injected → Net::Async::HTTP → sync shim) and is composed by both `Role::Chat` and `Role::Runtime::MetricsPoll`, ending today's duplicated `_async_*` builders.

**Tech Stack:** Perl, Moose / Moose::Role, `Future`, `Future::AsyncAwait`, `LWP::UserAgent` (sync + fallback), `Net::Async::HTTP` + `IO::Async` (optional async), `Test2::Bundle::More`.

**Spec:** `docs/superpowers/specs/2026-09-21-sync-fallback-async-transport-design.md` (read it — this plan argues from it).

## Global Constraints

- **Moose everywhere**; every class ends with `__PACKAGE__->meta->make_immutable`. Every `.pm` has a `# ABSTRACT:` line.
- **Naming** (`.perlcriticrc`, enforced on `dzil test`): packages CamelCase, subs/vars snake_case, no ambiguous single-letter vars (`$x`, `$obj`). Use `$response`, `$request`, `$chunk`, `$data`.
- **The `do_request` contract** (both backends satisfy it verbatim):
  `do_request( request => $http_request [, on_header => sub { my ($response) = @_; ...; return sub { my ($data) = @_; ... } } ) → Future` that resolves to an `HTTP::Response`. HTTP error statuses (4xx/5xx) **resolve** with the response (they do not fail the future); the caller checks `$response->is_success`.
- **Verify recursively:** `prove -lr t/` (never `prove -l t/`) or `dzil test`. Live tests (`t/8*`) skip without keys — say so.
- **No release:** `dzil build`/`dzil test` fine; `dzil release` forbidden.
- Commits: getty-git-commit-style, `--signoff`, end with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `Langertha::Request::SyncHTTP` — non-streaming request

**Files:**
- Create: `lib/Langertha/Request/SyncHTTP.pm`
- Test: `t/45_sync_http.t`

**Interfaces:**
- Consumes: an injected `user_agent` (an `LWP::UserAgent` or any object with `->request($http_request [, $content_cb])`).
- Produces: `Langertha::Request::SyncHTTP->new( user_agent => $ua )`, method `do_request( request => $req ) → Future` resolving to the `HTTP::Response` returned by `$ua->request($req)`.

- [ ] **Step 1: Write the failing test**

```perl
#!/usr/bin/env perl
# ABSTRACT: Langertha::Request::SyncHTTP satisfies the do_request contract over LWP, sync
use strict; use warnings;
use Test2::Bundle::More;
use HTTP::Response;
use HTTP::Request;
use Langertha::Request::SyncHTTP;

# Mock UA: no content callback -> returns a canned HTTP::Response
{
  package MockUA;
  use Moose;
  has calls => (is => 'ro', default => sub { [] });
  sub request {
    my ($self, $request, $content_cb) = @_;
    push @{$self->calls}, $request;
    my $response = HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/plain' ], 'hello');
    return $response;
  }
  __PACKAGE__->meta->make_immutable;
}

my $client = Langertha::Request::SyncHTTP->new( user_agent => MockUA->new );
my $future = $client->do_request( request => HTTP::Request->new(GET => 'http://x/') );
isa_ok($future, 'Future', 'do_request returns a Future');
ok($future->is_ready, 'future is already complete (no loop needed)');
my $response = $future->get;
is($response->code, 200, 'resolves to the HTTP::Response');
is($response->decoded_content, 'hello', 'body present');

done_testing;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `prove -lv t/45_sync_http.t`
Expected: FAIL — `Can't locate Langertha/Request/SyncHTTP.pm`.

- [ ] **Step 3: Write minimal implementation**

```perl
package Langertha::Request::SyncHTTP;
# ABSTRACT: Synchronous LWP-backed HTTP client satisfying the async do_request contract

use Moose;
use Future;
use Carp qw( carp );

has user_agent => ( is => 'ro', required => 1 );

sub do_request {
  my ( $self, %args ) = @_;
  my $request   = $args{request};
  my $on_header = $args{on_header};

  # (streaming branch added in Task 2)

  my $response = $self->user_agent->request($request);
  return Future->done($response);
}

__PACKAGE__->meta->make_immutable;

1;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `prove -lv t/45_sync_http.t` — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/Langertha/Request/SyncHTTP.pm t/45_sync_http.t
git commit --signoff -m "$(printf 'feat: add Langertha::Request::SyncHTTP (sync do_request over LWP)\n\nReturns Future->done(HTTP::Response); no event loop.\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 2: `SyncHTTP` — streaming via LWP content callback

**Files:**
- Modify: `lib/Langertha/Request/SyncHTTP.pm` (the `do_request` streaming branch)
- Test: `t/45_sync_http.t` (add streaming case)

**Interfaces:**
- Produces: `do_request( request => $req, on_header => sub { my ($response) = @_; return sub { my ($data) = @_; ... } } )` — `on_header` is called once with the `HTTP::Response`; its returned sub receives each body chunk as LWP reads it, then `undef` once at end; the future resolves to the response.

- [ ] **Step 1: Write the failing test** (append to `t/45_sync_http.t`, before `done_testing`)

```perl
# Streaming mock UA: invokes the content callback per chunk, LWP-style ($data, $response)
{
  package MockStreamUA;
  use Moose;
  has chunks => (is => 'ro', default => sub { [qw(foo bar baz)] });
  sub request {
    my ($self, $request, $content_cb) = @_;
    my $response = HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/event-stream' ]);
    $content_cb->($_, $response) for @{$self->chunks};   # LWP: ($data, $response, $protocol)
    return $response;
  }
  __PACKAGE__->meta->make_immutable;
}

my @seen; my $header_response; my $end_seen = 0;
my $sclient = Langertha::Request::SyncHTTP->new( user_agent => MockStreamUA->new );
my $sfuture = $sclient->do_request(
  request   => HTTP::Request->new(GET => 'http://x/stream'),
  on_header => sub {
    my ($response) = @_;
    $header_response = $response;
    return sub { my ($data) = @_; defined $data ? push(@seen, $data) : $end_seen++ };
  },
);
ok($sfuture->is_ready, 'streaming future already complete');
is($header_response->code, 200, 'on_header got the response');
is_deeply(\@seen, [qw(foo bar baz)], 'chunks delivered incrementally, in order');
is($end_seen, 1, 'end-of-body signalled once with undef');
is($sfuture->get->code, 200, 'future resolves to the response');
```

- [ ] **Step 2: Run test to verify it fails**

Run: `prove -lv t/45_sync_http.t` — Expected: FAIL on the streaming assertions (no `on_header` handling yet; chunks not delivered).

- [ ] **Step 3: Write the streaming branch** (replace the `# (streaming branch added in Task 2)` comment)

```perl
  if ($on_header) {
    my $chunk_handler;
    my $response = $self->user_agent->request($request, sub {
      my ( $data, $resp ) = @_;
      $chunk_handler ||= $on_header->($resp);
      $chunk_handler->($data) if $chunk_handler;
    });
    $chunk_handler->(undef) if $chunk_handler;   # match the async end-of-body signal
    return Future->done($response);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `prove -lv t/45_sync_http.t` — Expected: PASS (both non-streaming and streaming).

> **Verification note for the executor:** confirm against real `LWP::UserAgent` that the content callback receives `($data, $response, $protocol)` and that `request` still returns the `HTTP::Response` when a content callback is given (it does; the body is not stored on the response). If a real streaming provider is available, add a `t/8*` live check; otherwise the mock is the contract.

- [ ] **Step 5: Commit**

```bash
git add lib/Langertha/Request/SyncHTTP.pm t/45_sync_http.t
git commit --signoff -m "$(printf 'feat: SyncHTTP streaming via LWP content callback\n\nBridges LWP per-chunk callback to the on_header/chunk-sub contract.\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 3: `Langertha::Role::AsyncHTTP` — backend selection + warn-once

**Files:**
- Create: `lib/Langertha/Role/AsyncHTTP.pm`
- Test: `t/46_async_http_selection.t`

**Interfaces:**
- Requires (from the consumer): `user_agent` (Role::HTTP provides it).
- Produces: attributes `_async_loop` (lazy → `IO::Async::Loop`, built only on the real-async path) and `_async_http` (lazy, injectable). Selection in `_build__async_http`: injected value wins (never runs the builder); else `Net::Async::HTTP` if loadable (build loop, add client); else `Langertha::Request::SyncHTTP` + one `carp` per process.

- [ ] **Step 1: Write the failing test**

```perl
#!/usr/bin/env perl
# ABSTRACT: Role::AsyncHTTP picks injected > Net::Async::HTTP > sync shim (warn once)
use strict; use warnings;
use Test2::Bundle::More;

{
  package FakeEngine;
  use Moose;
  with 'Langertha::Role::AsyncHTTP';
  has user_agent => (is => 'ro', default => sub { bless {}, 'FakeUA' });
  __PACKAGE__->meta->make_immutable;
}

# injected client wins
{
  my $injected = bless {}, 'MyClient';
  my $engine = FakeEngine->new( _async_http => $injected );
  is($engine->_async_http, $injected, 'injected _async_http is used verbatim');
}

# no Net::Async::HTTP -> sync shim + exactly one warning
{
  local @INC = (sub {
    my (undef, $file) = @_;
    die "blocked\n" if $file eq 'Net/Async/HTTP.pm';
    return;
  }, @INC);
  my @warnings; local $SIG{__WARN__} = sub { push @warnings, "@_" };
  my $engine = FakeEngine->new;
  isa_ok($engine->_async_http, 'Langertha::Request::SyncHTTP', 'falls back to sync shim');
  my $engine2 = FakeEngine->new;
  $engine2->_async_http;
  is(scalar(grep { /synchronous/i } @warnings), 1, 'warns exactly once per process');
}

done_testing;
```

- [ ] **Step 2: Run to verify it fails** — `prove -lv t/46_async_http_selection.t` → FAIL (`Can't locate Langertha/Role/AsyncHTTP.pm`).

- [ ] **Step 3: Implement the role**

```perl
package Langertha::Role::AsyncHTTP;
# ABSTRACT: Async HTTP backend selection (injected > Net::Async::HTTP > sync LWP fallback)

use Moose::Role;
use Carp qw( carp );

requires 'user_agent';

my $WARNED = 0;

has _async_loop => ( is => 'ro', lazy_build => 1 );
sub _build__async_loop {
  require IO::Async::Loop;
  return IO::Async::Loop->new;
}

has _async_http => ( is => 'ro', lazy_build => 1 );
sub _build__async_http {
  my ($self) = @_;
  if ( eval { require Net::Async::HTTP; 1 } ) {
    my $http = Net::Async::HTTP->new;
    $self->_async_loop->add($http);
    return $http;
  }
  unless ($WARNED) {
    $WARNED = 1;
    carp "Net::Async::HTTP not available; Langertha is running HTTP synchronously "
       . "(no concurrency). Install Net::Async::HTTP + IO::Async for real async.";
  }
  require Langertha::Request::SyncHTTP;
  return Langertha::Request::SyncHTTP->new( user_agent => $self->user_agent );
}

1;
```

Add `=attr _async_http` / `=attr _async_loop` POD documenting them as the injection seam and the `do_request` contract, plus a note that the sync fallback is sequential/blocking.

- [ ] **Step 4: Run to verify it passes** — `prove -lv t/46_async_http_selection.t` → PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/Langertha/Role/AsyncHTTP.pm t/46_async_http_selection.t
git commit --signoff -m "$(printf 'feat: add Role::AsyncHTTP backend selection with sync fallback\n\nInjected > Net::Async::HTTP > Langertha::Request::SyncHTTP; warn once.\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 4: Compose `Role::AsyncHTTP` into `Role::Chat`; prove sync `chat_f`

**Files:**
- Modify: `lib/Langertha/Role/Chat.pm` — remove the local `_async_loop`/`_async_http` attributes + builders (Chat.pm:366–387), add `with 'Langertha::Role::AsyncHTTP';` in the role-composition (match the existing `with map {...} qw(...)` style if present, else a plain `with`). Update the `_f` POD (line ~145) to state the sync-fallback + sequential-degradation.
- Test: `t/47_chat_f_sync_fallback.t`

**Interfaces:**
- Consumes: `Role::AsyncHTTP` (`_async_http`, `do_request` contract). No API change to `chat_f`/`simple_chat_f`/streaming.

- [ ] **Step 1: Write the failing test** — a mock engine composing `Role::Chat`, driven with the async stack blocked from `@INC`, asserting `chat_f` works and no IO::Async is loaded.

```perl
#!/usr/bin/env perl
# ABSTRACT: chat_f resolves over the sync fallback without IO::Async/Net::Async::HTTP
use strict; use warnings;
use Test2::Bundle::More;

BEGIN {
  # Block the async stack for this process before anything loads it.
  unshift @INC, sub {
    my (undef, $file) = @_;
    die "blocked: $file\n" if $file =~ m{^(Net/Async/HTTP|IO/Async)};
    return;
  };
}

# A minimal OpenAI-shape engine is the realistic driver. The executor picks the
# lightest real engine that composes Role::Chat and can be pointed at a canned
# response (e.g. inject _async_http with a SyncHTTP over a mock UA that returns a
# valid chat-completions JSON body), OR uses an existing mock engine from t/64.
# Assert: chat_f(...)->get returns a Langertha::Response with the expected content,
# and IO::Async was never loaded.

# ... construct engine with an injected SyncHTTP over a mock UA returning a canned
#     chat-completions response ...
# my $response = $engine->chat_f( messages => [{ role => 'user', content => 'hi' }] )->get;
# isa_ok($response, 'Langertha::Response');
# like("$response", qr/expected/, 'content came back over the sync path');
ok(!$INC{'IO/Async/Loop.pm'}, 'IO::Async::Loop never loaded on the sync path');

done_testing;
```

> The executor fleshes out the engine construction using the same canned-response technique as `t/64_tool_calling_ollama_mock.t` / `t/lib/Test/MockMCP.pm`, injecting `_async_http => Langertha::Request::SyncHTTP->new(user_agent => $mock_ua)` where `$mock_ua->request` returns a canned chat-completions `HTTP::Response`. Keep it a non-live unit test.

- [ ] **Step 2: Run to verify it fails** — FAIL (either the role isn't composed yet, or the local builders still force IO::Async).

- [ ] **Step 3: Make the change** — delete Chat.pm:366–387 (`has _async_loop`, `_build__async_loop`, `has _async_http`, `_build__async_http`), add `Langertha::Role::AsyncHTTP` to Role::Chat's composition, update the `_f` POD.

- [ ] **Step 4: Run to verify it passes** — `prove -lv t/47_chat_f_sync_fallback.t` → PASS; then `prove -lr t/` → all green (live tests skip without keys — record the counts).

- [ ] **Step 5: Commit**

```bash
git add lib/Langertha/Role/Chat.pm t/47_chat_f_sync_fallback.t
git commit --signoff -m "$(printf 'refactor: Role::Chat uses Role::AsyncHTTP (sync fallback)\n\nDrop the duplicated _async_loop/_async_http builders; chat_f/streaming run\nover the sync shim when Net::Async::HTTP is absent.\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 5: Compose `Role::AsyncHTTP` into `Role::Runtime::MetricsPoll`

**Files:**
- Modify: `lib/Langertha/Role/Runtime/MetricsPoll.pm` — remove its local `_async_loop`/`_async_http` builders (MetricsPoll.pm:~105–120), add `with 'Langertha::Role::AsyncHTTP';`. Keep `poll_metrics_f` / `poll_metrics` unchanged (they call `_async_http->do_request`).
- Test: `t/98_metrics.t` (extend) or a new `t/47_metrics_sync.t`

**Interfaces:** Consumes `Role::AsyncHTTP`; `poll_metrics`/`poll_metrics_f` unchanged.

- [ ] **Step 1: Write the failing test** — with the async stack `@INC`-blocked, `poll_metrics` (sync) returns parsed metrics over the shim, and IO::Async is not loaded. Use a mock UA returning a canned Prometheus text body.

```perl
# BEGIN { block Net/Async/HTTP + IO/Async as in Task 4 }
# construct the self-hosted engine with _async_http => SyncHTTP over a mock UA
# returning a canned /metrics body; assert poll_metrics returns the parsed structure
# and !$INC{'IO/Async/Loop.pm'}.
```

- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Make the change** (drop the local builders, compose the role).
- [ ] **Step 4: Run the metrics test + `prove -lr t/`** → green.
- [ ] **Step 5: Commit**

```bash
git commit --signoff -am "$(printf 'refactor: MetricsPoll uses Role::AsyncHTTP (sync fallback)\n\nDrop its duplicated _async_* builders; poll_metrics(_f) run over the shared\nbackend selection.\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 6: cpanfile → recommends; Changes; verify; ADR

**Files:**
- Modify: `cpanfile` — move `IO::Async` and `Net::Async::HTTP` from `requires` to `recommends`; keep `LWP::UserAgent`/`LWP::Protocol::https` as `requires`.
- Modify: `Changes` (one `{{$NEXT}}` entry).
- Create: `docs/adr/0027-sync-fallback-async-transport.md` (records the transport-selection seam + the ADR 0026 dependency reversal). Add its one-line entry to `CLAUDE.md`'s ADR list.

- [ ] **Step 1: cpanfile edit.** In `cpanfile`, ensure:

```perl
recommends 'IO::Async';
recommends 'Net::Async::HTTP';
```

and that neither remains under `requires`.

- [ ] **Step 2: `dzil build --notgz`** → confirm META shows both under `recommends`, not `runtime requires`; build succeeds.

- [ ] **Step 3: Changes entry** (rewrite, one topic):

```
    - The async _f methods gained a synchronous LWP fallback: when
      Net::Async::HTTP is not installed (and no client is injected), HTTP runs
      synchronously and returns an already-complete Future, so _f keeps working
      (sequentially, blocking) without an event loop. IO::Async and
      Net::Async::HTTP are now recommends, not requires. Backend selection
      (injected > Net::Async::HTTP > sync) lives in Langertha::Role::AsyncHTTP,
      composed by Role::Chat and Role::Runtime::MetricsPoll; the sync client is
      Langertha::Request::SyncHTTP, streaming included.
```

- [ ] **Step 4: Write ADR 0027** (format per skill `langertha-adr`): Context (0026 made them requires; only the async path needs them; sync path already LWP), Decision (the selection seam + sync shim + recommends), Consequences (clean install is sync-capable; async users add the recommends; sequential degradation documented), relates to ADR 0026. Add the `- **0027** — ...` line to CLAUDE.md's ADR list.

- [ ] **Step 5: Full verification + commit**

Run: `prove -lr t/` (green; live skips noted), `dzil build --notgz` (0.503), `perlcritic --profile .perlcriticrc lib/ bin/ maint/` (exit 0).

```bash
git add cpanfile Changes docs/adr/0027-sync-fallback-async-transport.md CLAUDE.md
git commit --signoff -m "$(printf 'feat: IO::Async + Net::Async::HTTP become recommends (sync fallback)\n\nRecord ADR 0027; Changes entry. Core installs sync-capable; async optional.\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

## Self-Review

**Spec coverage:** §3 selection seam → Task 3; §4 streaming bridge → Task 2; §5 warn-once → Task 3; §6 error parity → automatic (both backends return HTTP::Response; caller checks `is_success`) — verified in Tasks 1/4; §7 degradation POD → Tasks 3/4; §8 cpanfile → Task 6; §9 scope (Chat + MetricsPoll) → Tasks 4/5; §10 tests → each task's test; §11 decisions baked in (MetricsPoll in scope Task 5; existing attr names kept Tasks 3/4; warn once Task 3).

**Placeholder scan:** the two engine-construction test bodies (Tasks 4/5) are intentionally delegated to the executor with an exact technique reference (canned `HTTP::Response` via injected `SyncHTTP`, mirroring `t/64` + `t/lib/Test/MockMCP.pm`) rather than fabricated engine internals — the assertions and the injection shape are concrete; the executor wires the specific engine. All new production units (SyncHTTP, Role::AsyncHTTP) have full code.

**Type consistency:** `do_request(request =>, on_header =>) → Future<HTTP::Response>` is used identically in SyncHTTP (Tasks 1/2), the selection role (Task 3), and the consumers (Tasks 4/5). `_async_http` / `_async_loop` names match across role and consumers.

**Open verification points (flagged inline, not placeholders):** LWP content-callback signature `($data, $response, $protocol)` and that `request` returns the response when a content callback is passed (Task 2 note); confirm Net::Async::HTTP resolves (not fails) on 4xx/5xx as the current code assumes (Task 4 full-suite run covers the real path).
