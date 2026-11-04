# Architecture

The SDK uses one `IO::Async::Loop`. Public asynchronous operations return
`Future`; `Future::AsyncAwait` is optional. Constructors do no network I/O.

## Components

| Package | Responsibility |
| --- | --- |
| `Discord::Client` | Client setup, event callbacks and shutdown |
| `Discord::Client::REST` | HTTP requests, JSON, rate limits and errors |
| `Discord::Client::Gateway` | Connections, heartbeats, Resume and reconnects |
| `Discord::Client::Gateway::Shards` | Shards in one process, sharing an Identify scheduler |
| `Discord::Client::Commands` | Local declarations, handler lookup and explicit deployment |
| `Discord::Client::Interaction` | Response methods, acknowledgement state and deadlines |
| `Discord::Client::Interactions` | Handler dispatch, duplicate detection and cancellation |
| `Discord::Client::HTTPInteractions` | Signed HTTP requests, inline replies and PSGI |
| `Discord::Client::Interaction::Verifier` | Ed25519 signatures and timestamp checks |
| `Discord::Client::Intents` | Named Gateway intent values |
| `Discord::Client::UI` | Hashrefs for buttons and modal fields |
| `Discord::Client::Cache` | Optional bounded resource snapshots |
| `Discord::Client::Model` and its subclasses | Resource accessors and REST operations |
| `Discord::Client::Error` and `Discord::Client::REST::Error` | Sanitized failure details |

REST, Gateway and HTTP Interactions can be used independently.
`Gateway::Session`, `Gateway::WebSocket`, `Gateway::IdentifyLimiter` and
`REST::RateLimiter` are internal packages under `Discord::Client`.

## Data and lifecycle

Payloads retain unknown fields. IDs are strings. Models and caching are optional;
neither performs automatic resource fetching. UI helpers only construct payloads.

The caller may supply and run the loop. `Client->run` runs it for a standalone
bot. Shutdown cancels pending work and removes owned resources. Injected REST
clients and transports remain caller-owned; an injected Gateway is closed by
the client.

Handlers return their Futures so the SDK can track completion, report failures
and cancel work on shutdown. Pending handlers do not pause heartbeats.
Synchronous blocking work still blocks the shared loop.

Commands are deployed explicitly. REST retries received 429 responses within
its retry limit; it does not retry uncertain network failures.
Queues, active handlers and cache storage have configurable limits.
Gateway dispatch updates Client state and admits interactions before queuing
application event callbacks. Application queue overflow cannot discard these
SDK operations; interaction admission retains its separate dispatcher limits.
HTTP delivery separates running work, completed response storage and retained
IDs. Response eviction retains IDs to prevent duplicate side effects; admission
failures before handler execution can be retried.

Tests use fake transports and controlled clocks, plus local HTTP/TLS servers.
Normal tests require no Discord credentials. The SDK does not provide voice or
audio, a full guild/member cache, or coordination across processes.
