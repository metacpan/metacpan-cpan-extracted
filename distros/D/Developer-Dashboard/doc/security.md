# Security

## Current Baseline

Developer Dashboard now applies these runtime protections in the active codebase:

- automatic local-admin trust requires the connection to arrive from a loopback address: any numeric `127.0.0.0/8` literal (the whole /8, not just `127.0.0.1`) or the IPv6 loopback forms `::1` / `0:0:0:0:0:0:0:1`
- on such a loopback connection the request host must itself be trusted before admin is granted: a numeric loopback literal, an absent host, a well-known localhost alias (`localhost`, `localhost.localdomain`, `localhost6`, `localhost6.localdomain6`), or a host explicitly listed under `web.ssl_subject_alt_names`; any other hostname stays helper-tier even when it resolves to loopback, which blocks DNS-rebinding admin elevation
- the loopback auto-admin shortcut is disabled entirely behind the built-in SSL front-proxy, where every backend connection arrives from the proxy's loopback socket and can no longer prove the real client is local; an explicit helper login is required instead
- loopback detection validates each IPv4 octet against the real `0-255` range, so malformed literals such as `127.0.0.999` are never classified as loopback
- home-runtime directories under `~/.developer-dashboard` are created and tightened to `0700`
- home-runtime files under `~/.developer-dashboard` are written and tightened to `0600`, while owner-executable scripts stay at `0700`
- helper access requires a stored helper account
- helper usernames are restricted to safe filename characters
- helper passwords must be at least 8 characters long
- helper user files and helper session files are written with `0600` permissions
- helper sessions are bound to the originating remote address
- helper sessions expire automatically after 12 hours
- session cookies use `HttpOnly` and `SameSite=Strict`
- HTTP responses add `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, and `Cache-Control: no-store`
- state-changing requests (`POST`, `PUT`, `DELETE`, `PATCH`) are refused with an empty-bodied `403` when `Origin` or `Referer` names anything other than this dashboard or a trusted local alias; the check runs before trust-tier classification, so it covers the loopback-admin shortcut, an ambient helper session cookie, and valid machine credentials alike, and a request carrying neither header is allowed because non-browser clients send neither
- that `Origin` check cannot defend a `GET`, so the same choke point additionally refuses, **on every method**, any request the browser labelled `Sec-Fetch-Site: cross-site` or `same-site` unless the accompanying `Origin`/`Referer` names this dashboard or a trusted local alias
- every page-derived value placed inside a quoted HTML attribute (the page chrome's play, source, and share URLs, the bookmark editor's form action, nav ids, and the host link) is escaped in attribute context, so both quote characters are neutralised and a bookmark id cannot terminate an attribute and inject markup
- generated saved-bookmark links percent-encode every path segment of the bookmark id (URL-context output encoding, with `/` separators kept raw), so ids carrying `#`, `?`, `%`, spaces, or quote characters stay valid, reachable URLs and reach the attribute escaper already inert; the server decodes the path exactly once, keeping the encode/decode round trip symmetric

## Cross-Site Request Defense

The dashboard's automatic loopback-admin tier authorizes on the remote address
alone. There is no cookie in that decision, so `SameSite=Strict` protects
nothing there: any page the operator happens to visit can aim a request at
`127.0.0.1` and it arrives already authorized. Two independent checks close
that, and both sit at one choke point that runs *before* trust-tier
classification, so no tier can be reached without passing them.

The first is the `Origin`/`Referer` comparison, which covers the
state-changing methods. Browsers unconditionally attach `Origin` to a
cross-site state-changing request, so a foreign value there is proof of an
attack.

The second is fetch metadata, and it exists because the first one cannot
defend a `GET`. Browsers omit `Origin` on same-origin GETs and an attacker
page can drop its `Referer` with a referrer policy, so on a `GET` there is
frequently nothing to compare. `GET` is not a safe method on this product:
`/ajax/<file>` runs an operator-written saved handler as a child process, and
the route accepts `GET`. Without the second check an `<img src="http://127.0.0.1:7890/ajax/deploy?...">`
on any page the operator visits executes that handler blind, with
attacker-chosen parameters.

`Sec-Fetch-Site` is the header that closes it. The browser sets it itself and
it is a forbidden header name, so page script can neither forge nor suppress
it. The policy is:

- `cross-site` and `same-site` are treated as foreign on **every** method
- `same-origin` (the dashboard's own page) and `none` (a typed URL, a
  bookmark, or browser start-up) pass
- a foreign label is still served when the accompanying `Origin`/`Referer`
  names this dashboard or a trusted local alias, which keeps the
  `localhost`/`127.0.0.1` pair working — one host to the loopback trust model,
  two sites to the browser
- a request carrying no `Sec-Fetch-Site` at all is unaffected, which is what
  keeps `curl`, registered `x-dd-api-key` machine consumers, and browsers too
  old to send fetch metadata working exactly as before

This is deliberately stricter than the usual Fetch Metadata Resource Isolation
Policy, which carves out top-level cross-site navigations
(`Sec-Fetch-Mode: navigate` with a `GET`). That carve-out is unsafe here,
because a navigation is enough to execute a saved handler — `window.open` on
an `/ajax` path is the same attack as the `<img>` tag. The cost of the
stricter rule is that following a link into the dashboard *from another site*
returns `403`; entering by typed URL or bookmark, which is how the dashboard is
actually opened, reports `Sec-Fetch-Site: none` and is unaffected.

The Dancer2 adapter has to forward `Sec-Fetch-Site` in its header normalizer
alongside `Origin` and `Referer`. Without that forwarding the backend check is
correct but never sees the header on an installed server, so the defense
silently does nothing outside the unit tests.

## OWASP Gate

Developer Dashboard now treats OWASP as a full security gate, not a
baseline-only checklist.

The shipped OWASP compliance SOW now records the chapter-by-chapter evidence
matrix and the current claim boundary. Use that record when deciding whether a
public statement should stay at `OWASP-aligned` / `OWASP-gated` or can safely
move to a stronger blanket compliance claim.

The repository security review is aligned to OWASP ASVS 5.0.0 across the
full chapter set:

- V1 Architecture, Design and Threat Modeling
- V2 Authentication
- V3 Session Management
- V4 Access Control
- V5 Validation, Sanitization and Encoding
- V6 Stored Cryptography
- V7 Error Handling and Logging
- V8 Data Protection
- V9 Communication
- V10 Malicious Code
- V11 Business Logic
- V12 Files and Resources
- V13 API and Web Service
- V14 Configuration

Every change must complete a V1 through V14 applicability review. If one
chapter is not relevant to the change, that should be stated explicitly rather
than skipped implicitly.

The practical repo policy is:

- ASVS Level 2 rigor is the default floor for release-worthy runtime, browser,
  auth, API, packaging, and workflow changes
- Level 3 review is mandatory when a change touches higher-trust boundaries
  such as authentication, session handling, cryptographic handling, release
  signing, or externally callable API routes

The same gate is also cross-mapped to the OWASP Top 10 2021 categories:

- `A01` Broken Access Control
- `A02` Cryptographic Failures
- `A03` Injection
- `A04` Insecure Design
- `A05` Security Misconfiguration
- `A06` Vulnerable and Outdated Components
- `A07` Identification and Authentication Failures
- `A08` Software and Data Integrity Failures
- `A09` Security Logging and Monitoring Failures
- `A10` Server-Side Request Forgery

For this repository, route, auth, session, Ajax, static-file, command
execution, packaging, and workflow changes must always be checked against at
least `A01`, `A03`, `A05`, `A07`, `A08`, and `A09`.

The current shipped status record does not yet authorize an unqualified public
`OWASP compliant` claim. The stronger claim stays blocked until the matrix,
repo-side evidence, and the remaining governance and release gates are all
closed together.

## Repository Hygiene

The active tree outside the read-only older reference tree is kept free of:

- company-specific product names listed in the repo rules
- embedded sensitive material
- literal password examples in user-facing documentation

That older reference tree remains read-only reference material and is not modified or committed as part of the active runtime.

## Dependency Advisory Floors

Some dependencies are pinned to a minimum version purely because of a published
advisory, not because the product needs a feature from that release. Those
floors are declared in `cpanfile`, `Makefile.PL`, and `dist.ini` together, and
both `t/108-cpan-security-metadata.t` and `t/15-release-metadata.t` assert all
three copies so the declarations cannot drift apart.

Two rules make this policy work:

- A floor is declared even when the product never calls the module itself. The
  declared dependency chain is what an installer resolves, so a module that is
  only ever loaded transitively still has to carry its floor, or a vulnerable
  version satisfies the distribution. The same applies to a module the coding
  rules forbid the product from using directly: being unused in the source is
  not a reason to let a vulnerable version resolve.
- For a module the product does not call, raising the floor is the only control
  available. There is no source-level fix to write and no call site to harden,
  so the version boundary is the whole mitigation and has to be enforced by the
  metadata rather than by code review.

Each advisory-driven floor is backed by an executable proof rather than by a
version string alone. `t/108-cpan-security-metadata.t` builds a fixture of the
module at a genuinely affected version and requires `script/cpan-audit-project`
to report that exact advisory identifier. A floor that drifted to a version with
no real advisory behind it would fail that proof.

When raising a floor, audit the newly resolved chain rather than assuming it is
safe: a higher floor can pull in additional distributions, and a floor set above
a module's newest release would make the distribution uninstallable.

### Auditing the transitive closure, not the named dependencies

The floor list used to be derived from the modules `cpanfile` names, while the
real exposure comes from the transitive closure of what those modules require in
turn. Two distributions reached the resolved chain that way and were caught only
by manual audit, both pulled in by `libwww-perl`'s own runtime requirements and
neither named in `cpanfile`: `HTTP::Date`, and `HTML::Parser` under the names
`HTML::Entities` and `HTML::HeadParser`.

Scanning what happens to be installed cannot catch this class. A resolver always
takes the newest release, so the installed versions look clean while the declared
floors still permit a vulnerable one. The question that has to be asked is the
one an installer answers: what is the *lowest* release the declared chain still
allows?

`script/cpan-audit-declared-chain` asks exactly that. It reads the declared
runtime requirements, walks every runtime requirement reachable from them using
the metadata that is written next to each installed distribution, resolves the
lowest release each distribution's accumulated floor still permits, and reports
any that falls inside a published advisory range. It shares the reviewed
advisory disposition list with the installed-distribution gate, and it fails
closed: a library root it cannot walk, a missing advisory database, or a single
distribution metadata file it cannot read or parse all exit non-zero rather than
reporting a clean chain it never established. The last of those matters as much
as the others, because a dropped metadata file shrinks the closure, and a
smaller closure is precisely what hides a finding — a partial walk that reports
"no distribution permits a vulnerable version" is the same false clean this gate
was built to end.

The gate runs as its own continuous-integration step against the isolated
dependency root the build resolves, and
`t/109-declared-chain-advisory-closure.t` pins both its contracts and its
detection behaviour against a synthetic chain built in the shape of the original
defect. That gate is deliberately live: the advisory database moves, so a newly
published advisory against any distribution in the closure is a real finding,
and the answer is to raise that distribution's floor or record a reviewed
disposition for the advisory.

### Which library root each gate may be pointed at

The two gates answer different questions, and pointing one of them at the wrong
library root produces an answer that is entirely correct and entirely not about
this product.

`script/cpan-audit-project` inventories the distributions installed in a root
and reports advisories against them. That is a statement about the product only
when the root holds the product's dependencies and nothing else. Pointed at a
shared CPAN tree — the one a developer machine accumulates across every project
it has ever built — it reports that tree faithfully, and a reader takes it as
product exposure because nothing in the output says otherwise.

So the gate states the root it is auditing, and refuses a root outside the
repository working tree with **exit status 3**, deliberately distinct from `0`
clean, `1` a disposition guard fired, and `2` a usage error. Collapsing "wrong
subject" into "finding" is what let the misreading spread: a red gate reads as a
blocker regardless of what it measured. The refusal names the gate that does
answer the question for a shared tree.

`DD_CPAN_AUDIT_ALLOW_EXTERNAL_ROOT=1` is the explicit opt-in for a root that is
genuinely isolated but lives outside the checkout, such as one built inside a
container. The default has to be refusal rather than a warning, because a
warning above two dozen advisory lines is not read.

Isolation is tested as "inside the repository working tree" rather than as
purity of the closure. The stricter-sounding rule — that the root may contain
only distributions in the declared runtime closure — is wrong here: an isolated
root built by `cpanm --installdeps --local-lib-contained` also carries toolchain
and test distributions, so that rule would refuse the very root continuous
integration audits. A guard that red-lines CI is worse than the misreading it
set out to prevent.

To judge the product against a shared tree, use
`script/cpan-audit-declared-chain`, whose subject is the declared runtime
closure and which ignores everything outside it. `t/110-cpan-audit-root-isolation.t`
pins all three cases — refusal, opt-in, and the in-tree root CI uses — and pins
this documentation against the script, because what produced the original
misreading was an operator following instructions that named the refused
invocation.

The cost of not having this is measured: the gate was run against
`$HOME/perl5/lib/perl5` and exited 88 with twenty-four advisories across seven
distributions, not one of them a declared runtime dependency. Three separate
rounds read that as a release blocker, and one filed it as a priority-2 security
defect, while the product's own position was clean across the 81 distributions
in its declared closure.

## CI Action Pinning

Every third-party GitHub Action is pinned by full 40-character commit SHA, never
by a floating tag, and each pin carries a trailing `# vX.Y.Z` comment naming the
upstream release it resolves to. `t/34-scorecard-guardrails.t` asserts both
halves: the SHA form for each action, and the absence of any floating tag across
every workflow. The comment exists so a reviewer can tell what a 40-hex pin is
without a network round-trip; because a comment can drift from the SHA beside it,
the comment is documentation and the SHA is the control.

A proposed bump is verified against the upstream tag before it is taken, rather
than trusted because an automated dependency PR proposed it. Resolving the
upstream `refs/tags/vX.Y.Z` must return exactly the SHA the bump introduces; a
pin that does not resolve to the named release is rejected regardless of where
the change came from.

That rule is enforced by `script/audit-action-pins`, which the test workflow runs
on every push. For each pinned action it reads the `action.yml` the pinned commit
actually carries and resolves the tag named in the comment, failing the build
when a pin declares a runtime below `node24` or when its comment names a tag that
resolves to a different commit. It separates "this pin is wrong" from "this run
could not find out" and exits non-zero for both, so an audit that could not run
never reads as an audit that passed. `t/142-action-pin-provenance.t` covers that
decision logic against fixtures, without a network.

The enforcement exists because the documentation above was already policy and
was still violated. Three pins carried comments written from intent rather than
resolved from the tag: `actions/checkout` was annotated `# v5.2.2` — a tag that
has never existed upstream — over a commit that is really v4.2.2, and
`shogo82148/actions-setup-perl` was annotated `# v1.32.0` over v1.31.3. All were
`node20` actions. GitHub force-runs `node20` actions on `node24`, which
`actions/checkout` survives and `actions-setup-perl` v1.31.3 does not: it fails
with `Error: unable to get latest version`. The `Setup Perl` step therefore
failed on every CI run for ten days, skipping the suite, the coverage gate and
both dependency audits, while the guardrail test read the comments and certified
the migration as complete. A version floor read from a comment cannot detect a
comment that lies, which is why the resolving check is a separate gate.

Runtime declarations are part of this review. Every pinned action now declares
`node24`, so the jobs no longer set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24`,
GitHub's transitional shim for rerouting `node20` actions. Steps that handle
credentials — the GHCR login in particular — are held on `node24`-native release
lines, and `t/34-scorecard-guardrails.t` gates those version floors rather than
only the pin format.

## Release Provenance

A `vX.XX` tag push publishes the distribution tarball, its SHA-256 checksum, and
a detached GPG signature. Those three assets prove integrity and authorship, but
they say nothing about *where the artifact came from*, so the release also
carries SLSA build provenance generated by `actions/attest-build-provenance`.

The provenance is published as a release asset, not only recorded in GitHub's
attestation store. That distinction is load-bearing rather than stylistic:
tooling that scores provenance — OpenSSF Scorecard's `Signed-Releases` check
among it — recognises provenance solely by a release asset whose name ends in
`.intoto.jsonl`, and treats an attestation held only in the attestation store as
absent. Two assets are published per release: the `.intoto.jsonl` DSSE envelope,
which is the shape provenance tooling consumes, and the full `.sigstore.json`
bundle, which is the only one of the two carrying the certificate chain and
transparency-log entry needed to verify that provenance offline.

Provenance is generated in a **separate job** from the one that builds the
artifact, and the separation is the security control rather than an
organisational convenience. Producing an attestation requires `id-token: write`,
which is what allows a job to mint an OpenID Connect token asserting this
repository's identity. The build job runs the full test suite, the coverage
pass, and `dzil build` — the largest body of executable project code in the
pipeline, plus every CPAN dependency it pulls in — so granting it OIDC would put
the repository's identity behind all of that code. The provenance job instead
runs no project code at all: it re-downloads the artifact GitHub actually
published, verifies it against the published checksum with `sha256sum --check
--strict` before putting its name to it, attests it, and attaches the result.
Attesting the published bytes rather than a local rebuild also makes the
attestation describe what consumers really download; a mismatch fails the
release instead of producing provenance for an artifact nobody received.

Running no project code has one consequence worth stating explicitly, because it
is easy to reintroduce: the provenance job checks nothing out, so its working
directory holds no git remotes, and every `gh` call in it must name its
repository with `--repo`. `gh` resolves the base repository from `--repo` first,
then the `GH_REPO` environment variable, and only then from git remotes, where it
fails as `no git remotes found`; it never reads Actions' `GITHUB_REPOSITORY`. An
unqualified `gh release upload` therefore fails *after* the attestation has been
minted, which would leave the attestation recorded in the store but never
attached — provenance that looks generated and scores nothing.

`t/34-scorecard-guardrails.t` gates this structurally, parsing the workflow as
YAML rather than pattern-matching it: the build job must not hold `id-token` or
`attestations` permissions, the provenance job must hold both at job level and
must depend on the build job, the provenance job's steps must verify the
checksum and must not invoke `prove`, `dzil`, or `cpanm`, and — folding backslash
continuations first, so a flag on a later line still counts — the job must check
nothing out while every `gh` invocation in it selects its repository explicitly.
Those assertions exist so a later change cannot quietly collapse the two jobs
back into one, or silently strip the repository selector that the absent checkout
makes mandatory.

## Verification

Run these checks:

```bash
dashboard doctor
dashboard doctor --fix
prove -lr t
```

For security-sensitive changes, the local verification loop must also include
the OWASP-driven repo audit commands from `SECURITY_CHECKS.md`, including the
auth/session, redirect, traversal, command-execution, header, and raw-SQL grep
checks plus the focused web and SSL regressions.

Recent repo audit summary:

- no obvious new raw SQL execution path was found
- no obvious missing auth gate was found on the main protected web surfaces
- no obvious unsafe open redirect was found outside the existing sanitized
  local redirect flow
- no obvious directory traversal hole was found in the current static-file
  and saved-file route surfaces from the grep review
- the current gap was process, not a discovered exploit: the formal OWASP gate
  was narrower than the repo’s actual security posture, so the gate itself has
  now been widened

## Private Reporting

The published root security policy lives in [`SECURITY.md`](../SECURITY.md) and
currently directs private reports to:

- `security@manif3station.local`
- `https://github.com/manif3station/developer-dashboard/security/advisories`

That root file now also documents the coordinated-disclosure timing contract:

- acknowledge vulnerability reports within 3 business days
- send a status update within 14 days
- aim for a 90-day disclosure window unless impact or remediation needs require
  a different schedule

The repository also treats the live OpenSSF Scorecard report as a security and
release gate. Run:

```bash
bash -ic "scorecard --repo=github.com/manif3station/developer-dashboard"
```

before closing a task that changes repository policy, workflows, releases, or
security posture.
