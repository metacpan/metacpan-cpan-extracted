# ADR 0037 — `connect_address` pins an engine's connection to a caller-checked address; the host name stays authoritative for Host, SNI and the certificate check, and whatever cannot pin refuses

- Status: accepted
- Date: 2026-09-30
- Tags: security, http, async, transport, dns-rebinding, tls
- Cross-links: ADR 0027, ADR 0028, ADR 0036
- karr: k375 (from langertha-raider #119)

## Context

langertha-raider (#119, `provider --provider HOST`) checks the addresses an endpoint host resolves
to against a policy (loopback, private, link-local, cloud metadata) before it builds an engine for
that endpoint. The engine then resolved the name again at connect time. A DNS answer that changes
between the check and the connect (DNS rebinding) sends the request — and the engine's credential —
to an address nobody checked.

Core builds two transports: sync LWP (with the sync fallback of ADR 0027) and Net::Async::HTTP
(with the per-hop loop of ADR 0036). Neither offered a supported way to connect to a given address
while still verifying TLS against the host name. raider's own manifest fetcher
(`Langertha::Raider::Provider::Fetch`) already does this for Net::Async::HTTP, outside core.

## Decision

1. **One engine attribute, `connect_address`** (`Maybe[Str]` on `Role::HTTP`, next to `url`): a
   single IPv4 or IPv6 address, validated at construction (no brackets, port or scope suffix). It
   pins every request the engine's own transports send to the host of `url` — any port, http or
   https. The lazy default `url` of cloud engines counts. The `Host` header, TLS SNI and the
   certificate name check keep using the host name; certificate verification stays as the client is
   configured. Pinning changes only where the TCP connection goes.
2. **Net::Async::HTTP:** each hop of the ADR 0036 loop passes `host => $address` and `port` as the
   connection target, and for https `SSL_hostname` / `SSL_verifycn_name` set to the host name (no
   SNI when the host is itself an address). An `on_ready` check runs on every connection, new or
   pooled: the peer must be the pinned address and, for https, the certificate chain must have
   verified and the certificate must match the host name (`tls_identity_error`;
   `SSL_verify_mode => 0` skips both checks, `SSL_verifycn_scheme => 'none'` only the name). A refused connection fails the
   request with category `connect_address` before anything is written, and is closed once idle so a
   queued request cannot hang on it.
3. **Sync LWP:** the engine's `Langertha::HTTP::UserAgent` carries `connect_host` /
   `connect_address`. For the length of one pinned request it wraps
   `LWP::Protocol::http::_extra_sock_opts`, `LWP::Protocol::https::_extra_sock_opts` and
   `LWP::Protocol::http::_check_sock`; the wraps act only for this agent's protocol object and the
   pinned host. They add `PeerAddr` and `PeerHost` (plus the TLS names for https), and
   `_check_sock` verifies the peer — and, when `verify_hostname` is on (LWP's default), the
   certificate chain and name via the same `tls_identity_error` — before the request is written,
   cached sockets included. As a backstop, LWP's `Client-Peer` is compared afterwards, and a response
   from a connection that never passed the check is refused (LWP's own internal error responses
   pass).
4. **Redirects:** the ADR 0036 policy takes the pinned host and refuses a hop from it to any other
   host (the 3xx comes back with a `Client-Warning` naming `connect_address`); a hop on the same host,
   any port, stays pinned. The address was checked for this host only.
5. **Refuse, never silently unpin:** an injected `user_agent` that is not a
   `Langertha::HTTP::UserAgent` with the same pin croaks at construction; an injected async client of
   another class, the sync shim over an unpinned agent, a Net::Async::HTTP with a proxy, a request
   passed as `uri =>`, and a request LWP would send through a proxy all fail instead of going out.
6. **Derived engines on the same host carry the pin** (`OpenAI->whisper`, `Ollama->openai`,
   `LMStudio->openai` / `->anthropic`, via `_connect_address_for($url)`), including a same-host url
   the caller passes.

## Rationale

- **One address with an implied host cannot be misused** the way a host map or a resolver callback
  can: no host name to mistype, no sync/async split in a callback, no callback returning a name.
  The per-hop re-check a callback would allow is replaced by refusing cross-host redirects, which is
  what raider's own fetcher does.
- **Only the TCP destination changes.** A pinned and an unpinned request to the same name differ
  only in where the socket goes; TLS policy is not touched, so pinning cannot weaken it.
- **Check the connection, not just the connect arguments.** Net::Async::HTTP pools connections by
  `address:port`, and an LWP `conn_cache` by `host:port`; a reused connection bypasses whatever was
  passed at connect time. The `on_ready` / `_check_sock` checks see every connection that would
  carry the request, and run before the credential is written.
- **LWP has no per-agent socket-address hook.** `_extra_sock_opts` is LWP's documented subclass
  override point; wrapping it (and `_check_sock`) for one request, gated on the agent, is the least
  invasive option — no global implementor swap, no copied LWP code — and the pre-send check turns an
  internals change into a loud failure.
- **Fail loud** (house rule 10): an engine that silently connects unpinned would be worse than one
  that refuses.

## Consequences

- A pinned engine cannot follow a redirect to another host; configure the target URL with its own
  checked address.
- The sync pin depends on LWP internals (checked against LWP 6.83 and LWP::Protocol::https 6.17),
  guarded by the pre-send `_check_sock` check, the `Client-Peer` backstop and
  `t/45_connect_address.t`.
- ADR 0036's "injected clients keep their own redirect behaviour" does not hold under a pin: there an
  injected client that cannot pin is refused.
- Two engines pinning different names to one address on a shared, injected Net::Async::HTTP: a
  request that lands on a pooled connection verified for the other name is refused, not retried on a
  new connection (the refused connection is closed once idle). One client per engine avoids it; the
  engines' own default clients are per engine.
- Not pinned: image URLs fetched for inlining (they are user content on other hosts; the
  `inline_image_url_filter` is the SSRF control there — except on the sync fallback, which fetches
  through a copy of the engine's agent), Langfuse ingestion, and a SOCKS proxy (it fails the peer
  check rather than working).
- Tests: `t/45_connect_address.t` (a name that does not resolve, pinned to 127.0.0.1, on sync LWP, the
  sync fallback and Net::Async::HTTP; chat, streaming, list_models, the probe, the metrics scrape;
  redirects; refusals) and `t/lib/Test/LocalTLSDaemon.pm` (a forked https server with a throwaway CA:
  right name accepted, wrong name refused, the shared-client reuse case).
