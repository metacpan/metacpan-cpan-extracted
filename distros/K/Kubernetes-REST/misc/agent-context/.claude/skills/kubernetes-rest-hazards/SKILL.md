---
name: kubernetes-rest-hazards
description: Load before touching the deprecated v0 layer, an error path, the discovery protocol, the mock harness or the duplex methods — the mechanism behind each trap.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Kubernetes::REST — the traps

The prohibitions live in `.claude/rules/kubernetes-rest-rules.md`; this skill carries the
mechanism behind them — what actually happens, and what breaks when it changes. The
architecture around them is in `kubernetes-rest-core`.

## The deprecated v0 layer

`Kubernetes::REST::V0Group` + 17 one-line subclasses (`::Core`, `::Apps`, …) translate the
0.01/0.02 method names (`ListNamespacedPod`) onto the v1 API via `AUTOLOAD`, parsing
`{Action}{Namespaced?}{Resource}{ForAllNamespaces|Status?}`. A trailing `Status` is a
subresource suffix only when what precedes it is a real Kind: `Read*Status` gets with
`subresource => 'status'` (k62), `Replace*Status` dispatches to `update_status` and
`Patch*Status` to `patch_status` (k65 — else the status write hits the main endpoint,
where the server drops it and still answers 2xx). A Kind whose own name ends in `Status`
(`ComponentStatus`, the only built-in one, checked against the Kinds IO::K8s ships) is kept
whole (k66). Otherwise dispatch goes to
`list`/`get`/`create`/`update`/`delete`/`patch`/`watch`. Every call carps unless
`$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}` is set. `list`, `get`, `watch`, `delete` and
`patch` croak on arguments they do not take, so `_dispatch` passes each only its own keys
and the other v0 parameters stay ignored (k49, k58, k61).

Two traps live here:

- **The bareword collision.** Each v0 accessor in `Kubernetes::REST` shares its name with
  the class it wraps, so once `Kubernetes::REST` is loaded, `Kubernetes::REST::Core->new`
  resolves against the *sub*, not the class, and calls it with no invocant. `_v0_group`
  is therefore a plain function that returns the class name when `$self` is undefined,
  putting the `->new` back on the class the caller aimed at. Do not "clean up" `_v0_group`
  into a method.
- The 1002 old `Call::*` classes and 10 v0-only helpers no longer ship here — they are
  tombstoned in the separate **Kubernetes-REST-Deprecated** distribution. This layer is
  the last thing keeping the v0 names alive and can go once no downstream code uses them.

`Kubernetes::REST::Error` / `::RemoteError` belong to the same layer, not to v1.
`RemoteError` inherits from `Error`, so `Error.pm` cannot load it — code that *throws*
one must `use Kubernetes::REST::RemoteError` itself.

## Errors — APIError or plain croak

`Kubernetes::REST::APIError` carries the Status body's fields, but it stringifies to the
message the plain croak had, **at the caller's line**: `throw` trusts the throwing package
through `@CARP_NOT`. A Moo lazy builder between the caller and the check breaks that chain
(its calling frame is `Method::Generate::Accessor::_Generated`), which is why
`_fetch_openapi_spec` is a method, not a builder. A warning that has to be raised inside a
builder — the legacy discovery skip runs in `_discovery`'s (k63) — goes through
`_carp_past_builders`, which trusts those generated frames for that one `carp` only.

The client's own discovery read never dies as an APIError: it is caught
(`_discovery_error`) and embedded. A message that embeds a caught error as its reason —
the unknown-resource croak, the Unstructured `_build_path` croak, `fetch_resource_map`,
the fallback carp, the legacy discovery skip — goes through `_error_reason`, which drops
the error's own trailing location, so the message names one line (k59).

Everything else croaks with a plain string: invalid arguments, a name nothing resolves,
and the watch `410` — an `ERROR` event inside a stream the server answered with 200,
answered with a re-list. An option key a method does not take croaks through
`_croak_unknown_args` before any request (`delete`, `ensure_only`, `log`,
`absorb_discovery`, `list`, `get`, `watch` since k58, and `patch`, `patch_status`,
`ensure_crd`, `port_forward`, `exec`, `attach` since k61); `ensure` croaks on anything
after its object. The allowed keys are exactly what the method reads; with an object,
`delete` takes only `propagationPolicy` and `patch`/`patch_status` only `patch` and
`type` — the object names itself. `get` keeps `subresource`, which works (`status`
answers with the object); `name`/`subresource` on `list`/`watch` croak — they made the
request a GET of one object, read as an empty list or a typeless event. `delete` sends
`propagationPolicy` as the `DeleteOptions` query parameter (k49).

## Discovery and the resource map

With `resource_map_from_cluster` on, the first name resolution would otherwise read the
discovery documents through the synchronous `io` — blocking an async client's event loop.
`prepare_discovery_requests` returns the `GET /api` and `GET /apis` requests (with the
aggregated-discovery `Accept` header) unsent; `absorb_discovery` takes the responses back.
Two aggregated documents (`APIGroupDiscoveryList`) become the cached catalog and it
returns true; a legacy document returns false and caches nothing — legacy discovery needs
a request per group/version, which only the synchronous path makes, and a cluster older
than 1.27 answers with legacy discovery (design D11). An HTTP error status dies with a
`Kubernetes::REST::APIError` like the synchronous read, context `discovery GET /apis`
(k59).

`_resource_map_from_catalog` skips `*List` kinds, gives a Kind to the version the cluster
marks preferred (D17), records only classes IO::K8s actually ships (D12/D13 — a foreign
CRD group resolves through `with` providers, AutoGen and the Unstructured fallback
instead), and special-cases the two groups whose IO::K8s namespace does not follow
`Api::`: `apiextensions.k8s.io` → `ApiextensionsApiserver::…`, `apiregistration.k8s.io` →
`KubeAggregator::…`. `/openapi/v2` is downloaded only by `schema_for`/`compare_schema`,
and handed to the inner IO::K8s for AutoGen once it exists.

Most tests set `resource_map_from_cluster => 0` and need no discovery responses; the
discovery tests register them with `add_response`.

## How the mock harness answers

- Fixture lookup: `lc(method) . path`, slashes → underscores, collapsed, leading one
  stripped — `GET /api/v1/namespaces` → `t/mock/get_api_v1_namespaces.json`. The query
  string is **part of the key**: a request with parameters only matches a response
  registered with the same query, exactly as `_prepare_request` renders it (keys sorted) —
  `add_response('GET', "$path?labelSelector=app=demo", ...)`. That is how tests tell
  selector queries apart (`t/47_ensure_only.t`); file fixtures in practice serve only
  query-less requests. The recorded `requests` (method, path, content) carry the path
  **without** its query, and the streaming lookups (`add_watch_events`, `add_log_lines`)
  strip it too. A miss returns a 404 Status body, so a missing fixture looks like a real
  "not found"; `MOCK_DEBUG=1` prints the key being looked up.
- Programmatic responses (`add_response`, `add_watch_events`, `add_log_lines`) take
  precedence over files — prefer them for new behaviour and reserve `t/mock/*.json` for
  recorded cluster shapes.
- **The mock encodes with `utf8 => 1`** so it hands back bytes like a real backend. A mock
  that returns characters makes the encoding tests pass for the wrong reason.

## The duplex methods croak by design

`port_forward`, `exec` and `attach` build a WebSocket-upgrade request
(`Sec-WebSocket-Protocol: v4.channel.k8s.io`) and hand it to `$io->call_duplex`. **Neither
shipped backend implements `call_duplex`** — LWP and HTTP::Tiny are sync-only, so these
methods croak with "IO backend does not support …" by design. `Net::Async::Kubernetes`
provides the duplex transport. Their tests therefore assert argument validation and
request shape, not a round trip.
