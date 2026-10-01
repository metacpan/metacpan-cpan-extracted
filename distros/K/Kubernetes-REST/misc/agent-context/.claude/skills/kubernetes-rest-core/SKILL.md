---
name: kubernetes-rest-core
description: Load before editing anything under lib/Kubernetes/ — the request pipeline and its async seam, the bytes-vs-characters encoding contract, path building, the resource map, the mock harness.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Kubernetes::REST — Distribution Internals

Consumer-facing usage (`list`/`get`/`create`/`watch`/`log`, connecting, CRDs) lives in
skill `perl-kubernetes-rest`. The typed objects this client returns come from `IO::K8s` —
skill `perl-io-k8s-kubernetes-classes`. This skill is about *changing* the distribution.

The division of labour matters: **this distribution owns HTTP, URLs and streaming;
IO::K8s owns the objects.** Field names, types and required-ness are never decided here.
A bug that looks like "the field is missing" is usually an IO::K8s bug and belongs on
that repo's board.

## The three-step pipeline

Every API method is built on the same three steps, and they exist as separate methods so
that a different transport can slot in at step 2 without touching 1 or 3:

1. `_prepare_request` — endpoint + path, query parameters, headers, `Authorization:
   Bearer` (only when a token is present — client-cert auth has none), JSON body.
2. `$self->io->call($req)` / `call_streaming($req, $cb)` / `call_duplex($req, %cbs)`.
3. `_check_response` (throws a `Kubernetes::REST::APIError` on >= 400) then `_inflate_object` / `_inflate_list` /
   `_process_watch_chunk` / `_process_log_chunk`.

`_request` is the convenience wrapper (prepare + call) used by the sync CRUD methods.

### The public seam is an API contract

`build_path`, `prepare_request`, `check_response`, `inflate_object`, `inflate_list`,
`process_watch_chunk` and `process_log_chunk` are thin public wrappers around the
underscore methods. They exist for **async wrappers — `Net::Async::Kubernetes` drives its
own event loop through them** and never calls `list`/`get`/`watch`.

`prepare_discovery_requests` and `absorb_discovery` (k51) are the discovery half of the
seam. With `resource_map_from_cluster` on, the first name resolution otherwise reads
discovery through the synchronous `io`, blocking an async client's event loop.
`prepare_discovery_requests` returns the `GET /api` and `GET /apis` requests (with the
aggregated-discovery `Accept` header) unsent; `absorb_discovery` takes the responses
back. Two aggregated documents (`APIGroupDiscoveryList`) become the cached catalog and it
returns true; a legacy document returns false and caches nothing — legacy discovery needs
a request per group/version, which only the synchronous path makes. An HTTP error status
dies with a `Kubernetes::REST::APIError` like the synchronous read, context
`discovery GET /apis` (k59).

Changing the signature or return shape of any of these nine breaks a downstream
distribution that has no way of knowing. Treat them as published API: additive changes
only, and a `Changes` bullet either way. The underscore versions are free to move as long
as the wrappers keep their shape.

## Encoding contract — bytes on the wire, characters in objects

This is the invariant most likely to be broken by an innocent-looking change; 1.106 was
almost entirely about repairing it.

- `_json` is built with `utf8 => 1, canonical => 1, convert_blessed => 1`. `utf8 => 1`
  makes `encode` emit **UTF-8 bytes**, which is what `HTTP::Message->content` requires
  and what IO::K8s already assumes. Dropping it makes every request body with a non-ASCII
  character die with "HTTP::Message content must be bytes".
- An IO backend receives `$req->content` already encoded and must put it on the wire
  unchanged. It must hand `$res->content` and every streaming chunk back as the bytes it
  received — undoing `Content-Encoding` (gzip) but **not** the charset. With LWP that
  means `decoded_content(charset => 'none')`; plain `decoded_content()` decodes a second
  time and produces silent mojibake on any non-ASCII value.
- `_check_response` decodes the error body leniently (`Encode::FB_DEFAULT`) — a truncated
  or non-UTF-8 body must not turn a useful API error into an encoding croak.
- `log()` returns **bytes** in both modes on purpose: container output is not guaranteed
  to be UTF-8 or even text. Callers decode when they know better.

The contract is documented in `Kubernetes::REST::Role::IO` for third-party backends and
pinned by `t/24_encoding.t`, which asserts both shipped backends inflate identical
objects from identical bytes.

## Path building from class metadata

`_build_path` asks the IO::K8s class, it does not consult a table: `api_version()`,
`kind()`, and `does('IO::K8s::Role::Namespaced')`. An `api_version` containing `/` means
a grouped API (`/apis/apps/v1/…`); no slash means core (`/api/v1/…`).

The resource segment comes from `resource_plural()` when the class defines it, otherwise
from a small pluralisation heuristic (`…ss|sh|ch|x|z` → `es`, consonant + `y` → `ies`,
else `s`). **A CRD whose plural does not follow those rules must define
`resource_plural`** — that is the intended escape hatch, not a reason to grow the
heuristic. A class without `api_version` croaks with instructions to override it.

Subresource paths are the resource path plus a suffix: `/log`, `/exec`, `/attach`,
`/portforward`.

## The resource map

`resource_map_from_cluster` defaults to **1**: the map is built lazily from the cluster's
aggregated discovery (`GET /api` + `GET /apis`, design D11; a cluster older than 1.27
answers with legacy discovery and gets a request per group/version; one answering an
error status is skipped with a `carp`, a 404 silently, k63), cached per instance
in `_discovery` and dropped by `invalidate_discovery`. If reading it fails, the map falls
back to `IO::K8s->default_resource_map` with a `carp` — a failed fetch degrades, it does
not die; that carp names the caller's line through `_carp_past_builders` (k64).
`_resource_map_from_catalog` skips `*List` kinds, gives a Kind to the version the
cluster marks preferred (D17), records only classes IO::K8s actually ships (D12/D13 — a
foreign CRD group resolves through `with` providers, AutoGen and the Unstructured fallback
instead), and special-cases the two groups whose IO::K8s namespace does not follow
`Api::`: `apiextensions.k8s.io` → `ApiextensionsApiserver::…`, `apiregistration.k8s.io` →
`KubeAggregator::…`. `/openapi/v2` is downloaded only by `schema_for`/`compare_schema`,
and handed to the inner IO::K8s for AutoGen once it exists.

The map is always the client's own hash: `resource_map`'s coerce copies a passed map and
the built-in fallback alike, because the inner IO::K8s merges the `with` providers into
that hashref in place (k57). `_resource_map_built` tells a built map from a passed one:
`invalidate_discovery` and `absorb_discovery` rebuild only a built map, so a caller's
`'+My::Class'` entries survive (k51, k52).

Most tests set `resource_map_from_cluster => 0` and need no discovery responses; the
discovery tests register them with `add_response`.

## `ensure()` — the idempotency seam

`ensure` is get-then-create-or-update, and every branch of its race handling is
deliberate: 404 on the initial get falls through to create; 409 on create re-fetches and
updates; 409 on update re-fetches `resourceVersion` and retries once. Two kinds are
special-cased because the server rejects a plain update: `PersistentVolumeClaim` (spec
immutable — existing PVC returned unchanged) and `Job` (immutable spec — active or
succeeded returned unchanged, failed deleted with `propagationPolicy => 'Background'`,
so its Pods go with it, and recreated).

`ensure_only` additionally *deletes* anything matching the label selector in the given
kinds/namespaces that is not in the set. `undef` inside `namespaces` means cluster-scoped.
It prunes with `propagationPolicy => 'Background'` unless given another one (a pruned Job
takes its Pods, as with `kubectl delete`), and an option key it does not take croaks
before anything is applied (k53). It is a pruning operation against a live cluster —
changes here need a test that pins what is *not* deleted, not only what is.

## The v0 compatibility layer

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

`Kubernetes::REST::Error` / `::RemoteError` belong to the same layer, not to v1 (see
below). `RemoteError` inherits from `Error`, so `Error.pm` cannot load it — code that
*throws* one must `use Kubernetes::REST::RemoteError` itself.

## Errors

An HTTP error status dies with a `Kubernetes::REST::APIError` (k50), thrown by
`_check_response` — so from every checked response, the `/openapi/v2` fetch (k55) and the
discovery reads (k59) included. It carries `code` (`is_not_found`, `is_conflict`), the
Status body's `reason`/`message`/`details`, the decoded `body`, `context` and `response`, and
stringifies to the message the plain croak had, at the caller's line: `throw` trusts the
throwing package through `@CARP_NOT`. A Moo lazy builder between the caller and the check
breaks that chain (its calling frame is `Method::Generate::Accessor::_Generated`), which
is why `_fetch_openapi_spec` is a method, not a builder. A warning that has to be raised
inside a builder — the legacy discovery skip runs in `_discovery`'s (k63) — goes through
`_carp_past_builders`, which trusts those generated frames for that one `carp` only.

The client's own discovery read never dies as an APIError: it is caught
(`_discovery_error`) and embedded. A message that embeds a caught error as its reason —
the unknown-resource croak, the Unstructured `_build_path` croak, `fetch_resource_map`, the
fallback carp, the legacy discovery skip — goes through `_error_reason`, which drops the
error's own trailing location, so the message names one line (k59).

Everything else croaks with a plain string: invalid arguments, a name nothing resolves,
and the watch `410` — an `ERROR` event inside a stream the server
answered with 200, answered with a re-list. An option key a method does not take croaks
through `_croak_unknown_args` before any request (`delete`, `ensure_only`, `log`,
`absorb_discovery`, `list`, `get`, `watch` since k58, and `patch`, `patch_status`,
`ensure_crd`, `port_forward`, `exec`, `attach` since k61); `ensure` croaks on anything
after its object. The allowed keys are exactly what the method reads; with an object,
`delete` takes only `propagationPolicy` and `patch`/`patch_status` only `patch` and `type`
— the object names itself. `get` keeps `subresource`, which works (`status` answers with the
object); `name`/`subresource` on `list`/`watch` croak — they made the request a GET of
one object, read as an empty list or a typeless event. `delete` sends `propagationPolicy`
as the `DeleteOptions` query parameter (k49).

## One package per file, one `$VERSION` everywhere

`our $VERSION` appears in **every** `.pm` and in both `bin/` scripts, all identical. That
is correct: the `[@Author::GETTY]` bundle only narrows `version_finder` to `:MainModule`
for `no_cpan` dists, and this one ships to CPAN, so every package needs its own version
for PAUSE indexing. Never bump by hand — `RewriteVersion`/`BumpVersionAfterRelease` own it.

The corollary is a hard rule: **one `package` per file.** Those plugins rewrite only the
*first* `our $VERSION` per file, so a second package in a file silently keeps the version
it was written with — five packages here sat at 1.003 until 1.106 while the metadata
reported the release version. `t/25_one_package_per_file.t` pins both properties.

Every `.pm` also needs a `# ABSTRACT:` line; PodWeaver builds NAME from it.

## A new file has to be `git add`ed to exist

`[@Author::GETTY]` gathers through `Git::GatherDir`, and its `include_untracked` defaults
to false. An untracked file is therefore absent from `dzil build`, from the release test
gate and from the CPAN tarball — while `prove -lr t/` runs it and passes. Nothing warns:
the release simply never saw the test. `git add` a new test or module the moment you
create it.

## The test harness

`t/lib/Test/Kubernetes/Mock.pm` exports `mock_api`, `live_api`, `is_live`. `mock_api`
builds a real `Kubernetes::REST` with a mock IO backend consuming
`Kubernetes::REST::Role::IO` — the pipeline under test is the real one, only transport is
replaced.

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
- Live tests require `TEST_KUBERNETES_REST_KUBECONFIG` — deliberately long, so no one
  points the suite at production by accident. `TEST_KUBERNETES_REST_CONTEXT` picks the
  context; `t/record_fixtures.pl` re-records fixtures from a live cluster.

## Kubeconfig and CLI

`Kubernetes::REST::Kubeconfig` parses the YAML and resolves cert data (inline base64 or a
file path) for the CA, client cert and client key independently. Inline base64 data is
decoded and passed to `Server` as an in-memory PEM string (`ssl_ca_pem`/`ssl_cert_pem`/
`ssl_key_pem`); a plain path is passed through as-is (`ssl_ca_file`/`ssl_cert_file`/
`ssl_key_file`). No temp file is written for inline data — the built `api` stays usable
after the `Kubeconfig` object is dropped. (Earlier versions wrote inline certs to temp
files tied to the `Kubeconfig` object's lifetime; that was removed because
`IO::Socket::SSL` doesn't accept scalar-ref cert files, and `t/14_kubeconfig.t` pins the
in-memory-PEM behavior surviving kubeconfig destruction — don't reintroduce temp files.)
It also handles `exec` credential plugins and in-cluster service-account config.

The CLI layer is `MooX::Cmd` + `MooX::Options`: `Kubernetes::REST::CLI` with
`CLI::Cmd::{Get,Create,Delete,Raw}`, plus the standalone `CLI::Watch`. Shared
`--kubeconfig`/`--context` options and the lazy `api` live in `CLI::Role::Connection`.
Entry points are `bin/kube_client` and `bin/kube_watch`. CLI JSON output sets `utf8` —
without it non-ASCII values trigger "Wide character in print".

## Duplex subresources

`port_forward`, `exec` and `attach` build a WebSocket-upgrade request
(`Sec-WebSocket-Protocol: v4.channel.k8s.io`) and hand it to `$io->call_duplex`. **Neither
shipped backend implements `call_duplex`** — LWP and HTTP::Tiny are sync-only, so these
methods croak with "IO backend does not support …" by design. `Net::Async::Kubernetes`
provides the duplex transport. Their tests therefore assert argument validation and
request shape, not a round trip.
