# ADR 0027 — Synchronous LWP fallback for the async `_f` transport; IO::Async + Net::Async::HTTP become recommends

- Status: accepted
- Date: 2026-09-21
- Tags: transport, async, dependencies, cpan, roles, http
- karr: #188

## Context

ADR 0026 declared `IO::Async` and `Net::Async::HTTP` as explicit `requires` of core: they had
always been used directly by the async `_f` path but reached the dependency closure only
transitively via `Net::Async::MCP`, which the Raider extraction dropped. Declaring them was the
correct fix at that moment — but it also froze a heavy async stack into every install, including
installs that never call a `_f` method.

Only the async path needs them. The **synchronous** path (`simple_chat`, `chat`,
`execute_streaming_request`) already runs over `LWP::UserAgent` via `Langertha::Role::HTTP` and
touches neither module. The async seam itself was already thin and duck-typed on one contract —
`_async_http->do_request( request => $req [, on_header => sub {...}] ) → Future<HTTP::Response>`,
where 4xx/5xx **resolve** the future (the caller checks `is_success`), consumed non-streaming at
`Role::Chat` and streaming via the `on_header`→chunk-sub form. Both `Role::Chat` and
`Role::Runtime::MetricsPoll` carried a private, undocumented copy of the same
`_async_loop`/`_async_http` lazy builders (`Net::Async::HTTP->new`, `$loop->add($http)`), and
because those were plain Moose attributes with open `init_arg`, a client was already injectable —
only the default builder was hardcoded to the async stack.

## Decision

Give the `_f` path a synchronous fallback so `IO::Async` and `Net::Async::HTTP` can move from
`requires` to `recommends`, without changing the `_f` API.

1. **A synchronous HTTP backend** — `Langertha::Request::SyncHTTP` — satisfies the exact
   `do_request` contract over an injected `user_agent` (an `LWP::UserAgent`) and returns
   `Future->done($response)`. No event loop: an already-complete `await` resolves synchronously,
   so the whole `_f` chain runs sync and the caller's `->get` returns immediately. Its streaming
   branch bridges LWP's per-chunk content callback (`($data, $response, $protocol)`, live-verified
   against LWP::UserAgent 6.83) to the `on_header`→chunk-sub contract, ending with the `undef`
   end-of-body signal — so `_process_stream_buffer` and the chunk callbacks fire as on the async
   path: incrementally (LWP calls back per socket read, so TTFT is real) but blocking. On the
   non-streaming path error parity is automatic: LWP accumulates error bodies on the response and
   the future resolves with it, matching `Net::Async::HTTP` (`fail_on_error` defaults false — also
   live-verified, at 0.50) and the existing `Role::HTTP` error-body handling.

   On the streaming path parity is **not** automatic and the shim enforces it explicitly (amended
   after the k188 final review, which reproduced both gaps against a local `HTTP::Daemon`):
   - LWP runs the content callback only for a success response (`LWP::Protocol::collect`), and
     never for its internal error responses (connection refused, DNS, timeout) or an empty body.
     `Net::Async::HTTP` calls `on_header` for every response and feeds it the body, error bodies
     included. So after the request the shim calls `on_header` once if LWP never did, hands the
     chunk-sub the accumulated body, then `undef` — the caller's `is_success` check then croaks
     `streaming request failed: <status line>` identically on both backends. This parity covers
     HTTP error *statuses*; a transport-level failure (e.g. connection refused) still words
     differently — LWP synthesizes `500 Can't connect …`, `Net::Async::HTTP` fails with the socket
     error. Both fail loudly; only the text differs.
   - LWP catches a die in the content callback (and a mid-body read failure) and records it as
     `X-Died` on a response that still looks successful. The shim captures the original exception
     (or the `X-Died` text) and **fails** the future with it, sending no `undef` end signal —
     a truncated stream is never resolved as success. On `Net::Async::HTTP` the same die fails
     that request's future with the original exception too (karr #194): `chat_stream_realtime_f`
     catches it in its chunk-sub, so it never unwinds out of the event loop, and stops delivering.
     It must not stop the transfer from inside that chunk-sub: the cancel closes the connection
     while `Net::Async::HTTP` is still inside its read handler, the rest of an already-read burst
     then lands on a connection with no request left, and the library dies with "Spurious
     on_read of connection while idle", again out of the loop. So the cancel runs on the next loop
     iteration (`$loop->later`), and the future fails once the transfer has ended; if the response
     completed within that read there is nothing to cancel. A client whose futures carry no loop
     is drained instead, and so is one whose `loop` has no `later` (another event system's loop);
     the chunk-callback exception is checked before the request future's own state, so it wins
     over any later transport failure on either path (karr #199).
     Cancelling a `Net::Async::HTTP` request closes its connection. With the library default
     `pipeline => 1` a concurrent request on the same engine was pipelined behind the aborted one
     on that keep-alive connection and failed with `Connection closed`; since karr #199 the
     client Langertha builds sets `pipeline => 0`, so a queued request waits in the client's
     queue and gets a fresh connection when the aborted one closes. `max_connections_per_host`
     stays at the library default of 1 (overridable through `NET_ASYNC_HTTP_MAXCONNS`): LLM
     requests are long and a pipelined request waits behind the stream anyway (HTTP/1.1
     answers pipelined requests in order), so
     dropping pipelining costs no concurrency Langertha had — at most one extra round trip per
     queued request — and cancelling a *queued* request no longer closes the connection under
     the running stream. Raising the connection limit would be a new concurrency promise and is
     left to an injected client. An injected client keeps its own settings.
   Both are covered by `t/45_sync_http_real_lwp.t`, a real LWP (and `Net::Async::HTTP`) against a
   forked local daemon, including sync/async parity on a 4xx with a body; the `Net::Async::HTTP`
   chunk-sub die by `t/45_async_http_stream_die.t`, in three framings (paced chunks, a chunked
   burst and a `Content-Length` body in one read), each followed by a request on the same engine.
   The pipelining case, and connection reuse after an abort, are covered by
   `t/45_async_http_keepalive.t` against the shared test daemon's `keep_alive` mode (the default
   mode sends `Connection: close` on every response and cannot exercise either); the two
   injected-client edges by `t/45_stream_abort_client_future.t`.

2. **One shared selection seam** — `Langertha::Role::AsyncHTTP` — owns the `_async_http` /
   `_async_loop` attributes and the backend choice, ending the duplication: an injected
   `_async_http` wins verbatim (bring-your-own-client is now a supported feature, not an accident of
   private attributes); else `Net::Async::HTTP` if `eval { require }` succeeds (build `_async_loop`,
   add the client — today's behaviour); else the `SyncHTTP` shim plus one warning per process
   (reported at the caller's `_f` call site; a `Net::Async::HTTP` that is installed but fails to
   load is reported with its load error rather than as "not available").
   `_async_loop` is built **only** on the `Net::Async::HTTP` path; the sync path never creates an
   event loop.

3. **Both consumers compose the role.** `Role::Chat` and `Role::Runtime::MetricsPoll` drop their
   local builders and `with 'Langertha::Role::AsyncHTTP'`. MetricsPoll's synchronous wrappers
   (`poll_metrics`, `export_otlp`) block with `$future->get` alone, which drives the loop the
   pending future belongs to (an `IO::Async::Future` awaits its own loop; Future::AsyncAwait builds
   the returned future from the first pending one it awaited) — so an injected client on the
   caller's own loop works too, and no private loop is ever created. On the sync fallback the
   future is already ready, keeping IO::Async out of the sync path there too.

4. **Dependencies.** `IO::Async` and `Net::Async::HTTP` (and `IO::Async::SSL`) become
   `recommends`; `LWP::UserAgent` and `LWP::Protocol::https` are explicit `requires` (the sync
   transport and the fallback both need them). A clean `cpanm Langertha` installs a working,
   sync-capable core; async users add the recommends (or `cpanm --with-recommends`).

## Rationale

The value object + shared role is the same seam-consolidation pattern the codebase already uses for
wire translation (ADR 0001) and observability (ADR 0014): a duck-typed contract that had two
hardcoded copies becomes one injectable, documented backend selector with a value-object client
behind it. Because every `await` on an already-complete future resolves without a loop, the sync
shim needs no reactor and no threads — the degradation is purely sequential/blocking, and nothing
downstream (`Response`, `tool_calls`, streaming chunks, timing) can tell the difference. Making the
two async modules `recommends` reverses ADR 0026's dependency line deliberately, now that the code
no longer forces them: the honest declaration is "core is sync-capable; async is optional".

Full loop-agnosticism (AnyEvent/Mojo as the *loop*, real concurrency on a non-IO::Async reactor) is
out of scope; the inject-your-own-`_async_http` seam this ADR formalizes is the hook a future
loop-adapter layer would build on.

## Consequences

- A clean install with neither async module works: `_f` methods run synchronously (sequential,
  blocking) and warn once per process. Real concurrency requires the recommends or an injected
  client. This degradation is documented in the `_f` POD, the `_async_http` attribute POD, and the
  `SyncHTTP` POD.
- The private `_async_http` / `_async_loop` attributes are now a documented, supported injection
  point (their names are unchanged — surgical, no rename, no public alias).
- `Role::Runtime::MetricsPoll`'s sync wrappers no longer spin a private IO::Async loop; they
  block with `->get` on whatever loop the pending future belongs to, and create none on the sync
  backend.
- Reverses ADR 0026's `requires` on `IO::Async` + `Net::Async::HTTP` (relates to 0026); the
  `do_request` resolve-on-error contract is unchanged and now honoured by two backends.

## Future work

- A pluggable event-loop adapter layer (AnyEvent/Mojo) that gives real concurrency on a non-
  IO::Async reactor — deferred; it would consume the `_async_http` injection seam formalized here.

## Update (k274 — inline-image fetches on the `_f` paths use the selected backend)

A URL-sourced `Content::Image` that an engine must inline (Gemini, Ollama native, LM Studio
native, and the `_content_inline_images_only` engines) was fetched with a private blocking
`LWP::UserAgent` while the request body was built — on the `_f` paths too, stalling the IO::Async
loop that knarr/skeid serve concurrent requests from. `chat_f`, `chat_stream_realtime_f` and
`chat_with_tools_f` now prefetch those images through the engine's `_async_http` (so injected
client > Net::Async::HTTP > the `SyncHTTP` shim over the engine's `user_agent`, the same selection
as the chat request) with `Content::Image->ensure_base64_f`, all concurrently via `needs_all`,
before the synchronous build; the bytes are cached on the image, so the serializers do no I/O. A
failed fetch fails the Future with the error the sync path croaks. The sync methods keep their own
LWP fetch. The async fetch carries no 30 s timeout of its own: it inherits the backend's, like the
chat request.

## Update (k276 — the async inline-image fetch times out)

Revises the last sentence of the k274 update: Net::Async::HTTP sets no timeout by default, so an
image host that accepts and never answers stalled the `_f` call forever. Each prefetch now races
`inline_image_fetch_timeout` (a `Role::Chat` attribute, default 30 s, like the sync fetch; `0`
disables it) with `Future->wait_any` against `delay_future` on the backend's loop (`async_loop`).
On timeout the call fails with the engine-named inline-image error (`… timed out after Ns`), no
chat request is sent, and the losing fetch is cancelled (Net::Async::HTTP closes its connection);
a fetch that wins cancels its timer. With no loop (the `SyncHTTP` shim, an injected client without
`loop`) the race is skipped and the client's own timeout applies — for the shim, the engine
`user_agent`'s. The chat request itself still has no timeout on Net::Async::HTTP. The attribute is
separate from `user_agent_timeout` because that one bounds a whole LLM request (often minutes) and
has no default.
k279: the sync request build passes the same attribute to `ensure_base64(timeout => N)` (LWP; `0` keeps LWP's 180 s default, as LWP cannot run untimed); direct callers keep 30 s.

## Update (k278 — `user_agent_timeout` bounds async requests too)

Revises the k276 sentence "the chat request itself still has no timeout on Net::Async::HTTP".
`user_agent_timeout` used to reach only the LWP user agent, so on Net::Async::HTTP a provider that
accepts and never answers (or stops mid-stream) left the Future pending forever, inside the loop
knarr/skeid/raider serve everything else from. Every async request core sends (`chat_f`,
`chat_stream_realtime_f`, `chat_with_tools_f`, `Langertha::Chat`, `MetricsPoll`, and the public
`async_request_f` of ADR 0028) now goes through one private helper, `_async_do_request_f`, which —
when the attribute is set and the backend `isa Net::Async::HTTP` — passes it as Net::Async::HTTP's
own per-request option, so no extra timer race is needed (the library already cancels and closes
the connection):

- **plain request → `timeout`** (total time). For a non-streaming LLM reply the server is silent
  until it is done, so total and inactivity are practically the same.
- **streaming (`on_header`) → `stall_timeout`** (no byte for N s, reset on every read/write). A
  long but steady stream is legitimate; a total cap would cut off long generations.

The failure is rewritten to `<engine class>: request to <url> timed out after Ns` (streaming:
`streaming request … timed out after Ns without data (Stalled while …)`), keeping Net::Async::HTTP's
category (`timeout` / `stall_timeout`) as the second failure value; the URL loses query string,
fragment and userinfo (Gemini carries its key in `?key=`). Other failures pass through unchanged. A
caller's own `timeout` / `stall_timeout` option to `async_request_f` wins. The `SyncHTTP` shim is
untouched (the timeout is already on its `user_agent`), and an injected client of another class
keeps its own timeout — core does not guess at its option names.

**No default on async.** LWP's default is 180 s, but it is an *inactivity* timeout (per socket
read), and the async backend has run without any timeout since it existed. A 180 s default would
start failing long silent requests (non-streamed reasoning models, background Responses calls,
knarr proxying them) that work today, on upgrade and without a code change. Unset therefore stays
"no timeout" on Net::Async::HTTP; the sync/async parity is: same attribute, same number, applied on
both backends when the user sets it. `0` also means no async timeout (Net::Async::HTTP would treat
`0` as "fail immediately"). Content::Image prefetches keep their own `inline_image_fetch_timeout`
(k276), which is not routed through the helper.

## Update (k353 — connect-time modules are checked before Net::Async::HTTP gets the request)

Net::Async::HTTP 0.50 loads some modules only when it opens a connection:
`IO::Async::Internals::Connector` for every connection (through `IO::Async::Loop->connect`), and
`IO::Async::SSL` (with IO::Socket::SSL, Net::SSLeay and the system libssl) for SSL. It counts the
connection against the host (`get_connection` pushes it into the host's list) *before*
`connect_connection` loads them. When the load dies, the `on_error` cleanup never runs, so the dead
connection keeps the host's slot. With `max_connections_per_host` at the default of 1, every later
request to that host then waits forever, even after the module can load again. This was reproduced
on Net::Async::HTTP 0.50 / IO::Async 0.805 against the local test daemon, and first seen in
langertha-raider (raider k107).

Core checks for this failure before the request instead of recovering from it afterwards:

- **`Langertha::HTTP::ConnectCheck::connect_error($uri [, $ssl])`**, an internal module, requires
  the connector (and `IO::Async::SSL` >= 0.12 when the connection is SSL). It returns `undef`, or a
  one-line error naming the module, the first line of its load error and why it is needed. Only
  scheme, host and port name the target, because a query string or userinfo can carry a key.
- **`_async_do_request_f` (k278) runs the check on the Net::Async::HTTP backend only**, before
  `do_request`, and fails the Future with `<engine class>: <error>` and the category `connect`.
  The check therefore covers every async request core sends (`chat_f`, streaming, `chat_with_tools_f`,
  `Langertha::Chat`, MetricsPoll, Langfuse, the public `async_request_f` of ADR 0028). The `SyncHTTP`
  shim and an injected client of another class are not checked: this failure belongs to
  Net::Async::HTTP only.
- **`Content::Image` runs the same check itself** before its inline-image fetch, because that fetch
  (k274) calls the engine's Net::Async::HTTP directly and bypasses `_async_do_request_f`.
- **SSL rule: `$ssl //= scheme eq 'https'`.** A caller's `SSL` request option wins over the
  scheme. Net::Async::HTTP 0.50's `_do_request` derives `SSL` from the scheme but passes the
  caller's options after it, so `http` with `SSL => 1` connects with SSL and `https` with
  `SSL => 0` connects without. Deriving the rule from the scheme alone would miss the first case, and
  that case is the leak path again. `t/45_async_http_connect_modules.t` pins both directions against
  the daemon.

After the first successful load, a module stays in `%INC`, so a request pays a few microseconds
for the check.

**Assumption.** `IO::Async::Internals::Connector` is a *private* IO::Async module name. The check
hard-codes it and assumes `IO::Async::Loop` keeps loading it lazily under that name on connect,
which is true for IO::Async 0.805. If IO::Async renames it, every request fails with a module that
cannot load, and `ConnectCheck` must follow the rename.

**When it goes away.** The check exists only because of the slot leak. Once a Net::Async::HTTP
release frees the host's slot when a connect-time load dies, the check can be removed. That upstream
bug is to be reported separately. langertha-raider carries its own `Langertha::Raider::ConnectCheck`
(raider k107), which it can drop once it requires the core release that ships this. Calling core's
module instead would need a public hook (ADR 0028), because `ConnectCheck` is internal.
Not covered: `Net::Async::SOCKS` (loaded only with `socks_params`, which core never sets), and an
http→https redirect that Net::Async::HTTP follows by itself. The image path follows redirects hop by
hop, so each hop there is checked. Test: `t/45_async_http_connect_modules.t` (a real Net::Async::HTTP
against the local daemon, with an `@INC` blocker). It hung on the second request before the fix.

## Update (k374 — redirects follow one Langertha-owned policy on both backends; ADR 0036)

Backend parity now includes redirects. Neither client kept an engine credential on its origin
(LWP 6.83 forwards `x-api-key`; both forward an echoed `?key=`), and they disagreed on same-origin
hops. The default `user_agent` is now `Langertha::HTTP::UserAgent` (policy in `redirect_ok`), and
`_async_do_request_f` calls Net::Async::HTTP with `max_redirects => 0` and follows each GET/HEAD hop
through `Langertha::HTTP::Redirect`. That also closes the gap noted in the k353 Update above: an
http→https redirect is now a hop core follows itself, so the connect-module check runs on it.
Injected clients keep their own redirect behaviour. Decision and rationale: ADR 0036.
