# ADR 0036 — One Langertha-owned redirect policy keeps engine credentials on their origin, on every backend core builds

- Status: accepted
- Date: 2026-09-30
- Tags: security, http, async, transport, redirect, credentials
- Cross-links: ADR 0027, ADR 0028, ADR 0032, ADR 0014
- karr: k374 (from langertha-raider #119)

## Context

An engine carries its credential on every request: `Authorization: Bearer` (the OpenAI family),
`x-api-key` (the Anthropic family), `x-goog-api-key` or `?key=` (Gemini), `?key=` on AKI's
native GETs, and so on. The GET requests core sends — `list_models`, the capability probe
(`probe_model_capabilities_f`, ADR 0032), the metrics scrape (ADR 0014), Gemini's
`cachedContent` reads — are followed across redirects by the HTTP client, and neither client
keeps the credential on its origin:

- **LWP** (sync, and the sync fallback of ADR 0027): 6.83 strips only `Authorization` on a
  cross-origin redirect, older releases strip nothing. `x-api-key` and every other auth header
  went to the new host. Reproduced (raider #119): `Engine::Anthropic->new(url => 'https://a',
  api_key => 'k')->list_models` against a 307 to `https://b` — `b` received `x-api-key: k`.
- **Net::Async::HTTP 0.50** builds a fresh GET from the `Location` and sends no request headers
  (so it also *lost* the credential on a same-origin redirect), but keeps the `Location` query as
  sent. A server that echoes the request URI into `Location` (`return 301 https://new$request_uri`)
  therefore received Gemini's / AKI's `?key=` — on both transports. A relative `Location` on an
  https request was resolved as `http://`.
- Neither client follows a redirect of a POST (chat), so request bodies (AKI's key-in-body, the
  conversation) never travel; the exposure is the GET side.

The two clients disagree with each other and across versions, so "trust the client" gives no
guarantee core can document.

## Decision

1. **One policy module, `Langertha::HTTP::Redirect`, decides every redirect hop** on the backends
   core builds, sync and async alike:
   - only GET/HEAD are followed, only on 301/302/303/307/308, and never from https to http; the
     original request method is checked by the policy itself, not left to the client's
     `requests_redirectable`;
   - **same origin** (scheme, host, port — default ports normalized): the request continues
     unchanged, credential included (this also fixes the async same-origin loss);
   - **another origin**: only representation headers go along (a keep-list: `Accept*`,
     `Content-Type`, `Content-Language`, `User-Agent`), userinfo is dropped from the new URL, and
     every query value the chain carried as a credential is removed (values collected from the
     chain's credential-named query parameters and auth-header values, Bearer token without its
     scheme), while the target's own query stays byte for byte (presigned URLs keep working);
   - if a credential value would still appear anywhere in the new URL (the path, say), the
     redirect is not followed; a refused redirect is returned as the 3xx it was, with a
     `Client-Warning` naming the policy.
2. **Sync:** the engine's default `user_agent` is a `Langertha::HTTP::UserAgent`, an
   `LWP::UserAgent` subclass (MooseX::NonMoose, the `Request::HTTP` precedent) whose `redirect_ok`
   applies the policy to LWP's referral request. That covers every direct `user_agent->request`
   call site without touching them.
3. **Async:** Net::Async::HTTP is called with `max_redirects => 0`, and `_async_do_request_f`
   follows each hop through the policy, re-running the per-request checks (timeout, body cap, the
   connect-module check of ADR 0027 k353) on each hop. A streaming `on_header` sees only the
   response the chain ends on.
4. **Injected clients keep their own behaviour.** A plain `LWP::UserAgent` passed as `user_agent`,
   or an async client that is not Net::Async::HTTP, is not wrapped or warned about; the POD says
   so and names `Langertha::HTTP::UserAgent` as the way to get the policy.

## Rationale

- **Keep-list, not deny-list.** Dropping every header except known representation headers needs
  no list of credential header names that must grow with each new engine; an auth header of any
  name, in any case, stays behind.
- **Credentials matched by value.** An echoed key is caught under any parameter name and in any
  position, and nothing else in the target's query is touched.
- **Strip per hop rather than refuse cross-origin redirects.** Refusing would break keyless setups
  (a self-hosted server redirecting to another host or port); following manually on sync would
  have meant `simple_request` at every call site and broken mock/subclassed agents in tests and in
  users' code.
- **One module, two thin adapters.** The policy is testable without a network and identical on
  both transports; the adapters are LWP's documented `redirect_ok($referral, $response)` hook and
  a hop loop over `max_redirects => 0`.
- **Not wrapping injected agents** follows the `Content::Image` precedent (k325): reblessing a
  caller's object is worse than documenting that it keeps its own policy; deliberate setups
  (proxies, custom TLS) would trip a warning.

## Consequences

- An http→https redirect on the same host counts as another origin: the credential is dropped
  (a GET behind such a 301 gets a 401 — configure the https URL). The key already travelled in
  plain text on the first hop; the policy does not bless that.
- https→http is refused on sync even with LWP older than 6.83. `Content::Image`'s sync fetch, which
  clones the engine's agent, inherits the policy.
- A redirect chain can take up to (hops + 1) × timeout on the async side (the timeout applies per
  hop). Sync follows up to LWP's 7 hops, async up to the client's configured `max_redirects`
  (read from Net::Async::HTTP 0.50's private field, with a fallback) — a split that predates this.
- A credential only counts as one in the query when its parameter name is credential-shaped
  (`key`, `api_key`, `token`, …, anchored so `pageToken` is not one); a key under an odd name
  (`?k=`) is caught only by value from the chain's auth headers.
- Test: `t/45_redirect_credentials.t` — policy unit tests plus two local daemons (origin A
  answers 307 to origin B) on sync LWP, the sync fallback shim and Net::Async::HTTP, for Anthropic,
  OpenAI and Gemini, the probe and the metrics scrape.

## Future work

- Run the sync hop loop in Langertha for *any* LWP agent (disable LWP's own redirects for the
  request, follow via the policy), which would make the policy independent of the agent's class
  and could retire the subclass. Not needed for the default configuration.

## Update (k375 — a pinned engine refuses to leave its host; ADR 0037)

`guard_referral` / `next_request` take an optional pinned host. With `connect_address` set
(ADR 0037), a hop from the pinned host to any other host is refused — the address was checked for
that host only — and the 3xx comes back with a `Client-Warning` naming `connect_address`; a
same-host hop on any port stays pinned and still has its credentials handled as above. Decision 4
("injected clients keep their own behaviour") does not hold under a pin: an injected client that
cannot pin is refused rather than left to its own redirect behaviour.
