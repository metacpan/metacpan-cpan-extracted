---
name: kubernetes-rest-core
description: "Kubernetes::REST distribution internals for contributors — the request/response pipeline and its public seam for async wrappers, the bytes-vs-characters encoding contract, path building from IO::K8s class metadata, the resource map, ensure() race handling, the v0 AUTOLOAD compatibility layer, the mock test harness and the one-package-per-file rule. Load before editing anything under lib/Kubernetes/."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Kubernetes::REST — Distribution Internals

Consumer-facing usage (`list`/`get`/`create`/`watch`/`log`, connecting, CRDs) lives in
skill `perl-kubernetes-rest`. The typed objects this client returns come from `IO::K8s` —
skill `perl-kubernetes-classes`. This skill is about *changing* the distribution.

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
3. `_check_response` (croak on >= 400) then `_inflate_object` / `_inflate_list` /
   `_process_watch_chunk` / `_process_log_chunk`.

`_request` is the convenience wrapper (prepare + call) used by the sync CRUD methods.

### The public seam is an API contract

`build_path`, `prepare_request`, `check_response`, `inflate_object`, `inflate_list`,
`process_watch_chunk` and `process_log_chunk` are thin public wrappers around the
underscore methods. They exist for **async wrappers — `Net::Async::Kubernetes` drives its
own event loop through them** and never calls `list`/`get`/`watch`.

Changing the signature or return shape of any of the seven breaks a downstream
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

`resource_map_from_cluster` defaults to **1**: the map is fetched lazily from the
cluster's `/openapi/v2` and, if that fails, falls back to `IO::K8s->default_resource_map`
with a `carp` — a failed fetch degrades, it does not die. `fetch_resource_map` skips
`*List` kinds, prefers non-alpha/beta versions when a kind appears more than once, and
special-cases the two groups whose IO::K8s namespace does not follow `Api::`:
`apiextensions.k8s.io` → `ApiextensionsApiserver::…`, `apiregistration.k8s.io` →
`KubeAggregator::…`.

Tests set `resource_map_from_cluster => 0`, which is why the mock harness never needs an
`/openapi/v2` fixture.

## `ensure()` — the idempotency seam

`ensure` is get-then-create-or-update, and every branch of its race handling is
deliberate: 404 on the initial get falls through to create; 409 on create re-fetches and
updates; 409 on update re-fetches `resourceVersion` and retries once. Two kinds are
special-cased because the server rejects a plain update: `PersistentVolumeClaim` (spec
immutable — existing PVC returned unchanged) and `Job` (immutable spec — active or
succeeded returned unchanged, failed deleted and recreated).

`ensure_only` additionally *deletes* anything matching the label selector in the given
kinds/namespaces that is not in the set. `undef` inside `namespaces` means cluster-scoped.
It is a pruning operation against a live cluster — changes here need a test that pins
what is *not* deleted, not only what is.

## The v0 compatibility layer

`Kubernetes::REST::V0Group` + 17 one-line subclasses (`::Core`, `::Apps`, …) translate the
0.01/0.02 method names (`ListNamespacedPod`) onto the v1 API via `AUTOLOAD`, parsing
`{Action}{Namespaced?}{Resource}{ForAllNamespaces|Status?}` and dispatching to
`list`/`get`/`create`/`update`/`delete`/`patch`/`watch`. Every call carps unless
`$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}` is set.

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

`Kubernetes::REST::Error` / `::RemoteError` belong to the same layer: v1 croaks, it does
not throw structured exceptions. `RemoteError` inherits from `Error`, so `Error.pm` cannot
load it — code that *throws* one must `use Kubernetes::REST::RemoteError` itself.

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
  stripped — `GET /api/v1/namespaces` → `t/mock/get_api_v1_namespaces.json`. Query strings
  are stripped for matching. A miss returns a 404 Status body, so a missing fixture looks
  like a real "not found"; `MOCK_DEBUG=1` prints the key being looked up.
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
