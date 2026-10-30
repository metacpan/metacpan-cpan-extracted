# Problem 48: whole-dashboard performance investigation

## Length-prefixed config snapshot environment signature (2026-10-18)

The warmed NYTProf route profile attributed 4.03 ms of exclusive time across
100 calls to `Web::App::_config_snapshot_environment_signature`. Its only
consumer compares the value for equality before reusing a watcher-validated
configuration snapshot. A red-first Docker assertion required a versioned
internal representation and tests distinguished missing from empty selectors,
changed values, and delimiter-bearing values. The implementation replaces
construction of temporary nested arrays plus pretty JSON encoding with a
versioned, length-prefixed signature; the encoding preserves missing,
undefined, and defined values as separate states. `t/03-web-app.t` passes all
527 assertions, including the undefined-CWD path.

Nine alternating direct-method samples of 30,000 calls measured the prior JSON
signature at 112.282 ms median and the new signature at 83.792 ms (1.34x),
with the same configuration-selection inputs. This is a helper-level result;
seven alternating paired route-process samples then compared both signature
implementations on 200 iterations each with 20 saved-nav fragments, 100
skill-nav fragments, and 50 indicators. Every response was HTTP 200 with 19,341
bytes and the established SHA-256
`a3c1df9346d5b1c2942fbec1354e2dbb8dcc268e0e148107787197635a7ed331`. Current
and legacy medians were 0.349535 and 0.357139 ms/request (2.2% median
difference), but current was faster in only four of seven pairs and pair ratios
ranged from 0.89x to 1.06x. This is not stable evidence of a route-level gain.
The benchmark's `--legacy-config-snapshot-signature` switch preserves the old
JSON control for future paired runs.
The private signature is not a public JSON payload. The 50x-per-subroutine
objective remains open.

## Canonical saved-page id normalization fast path (2026-10-18)

Expected outcome: canonical flat ASCII ids keep their exact value and avoid
trim/prefix normalization; all other ids continue through the existing
normalizer unchanged. A red-first test initially failed both assertions that
the canonical case bypasses `_trim` while the prefixed/whitespace case still
uses it. The implementation now returns a string directly only for the narrow
`[A-Za-z0-9_.-]+` class. Nested ids, Unicode, undefined values, and every other
shape retain the prior path. Follow-up branch coverage added explicit
undefined and reference inputs after the first full gate identified the
reference guard as under-exercised. Docker tests `t/03-web-app.t` and
`t/676-problem48-page-id-benchmark.t` now pass 552 assertions.

Nine alternating 500,000-call helper samples measured 302.386 ms median for
the previous method and 204.613 ms for the optimized method (1.48x); this
microbenchmark is noisy and not the primary result. Three alternating pairs of
the 100-request saved-page route, with 20 saved-nav fragments, 100 literal
skill-nav fragments, and 50 indicators, returned byte-identical HTTP 200
responses (19,341 bytes, SHA-256
`a3c1df9346d5b1c2942fbec1354e2dbb8dcc268e0e148107787197635a7ed331`). Per-pair
old/current medians were 0.427339/0.393169, 0.422330/0.345271, and
0.365710/0.347531 ms/request; the medians of those values were 0.422330 and
0.347531 (1.21x). The helper optimization therefore improves this route
slightly, but does not establish a 50x per-subroutine result.

The complete Docker coverage gate was rerun after undefined and reference-id
fallback cases were added: 285 test files and 25,324 tests passed. Statement,
branch, condition, and subroutine coverage were each 100.0% across `lib/`
(51,685 detail rows; zero stale uncoverable annotations). Optional browser, Windows QEMU, CPANTS,
POD, and audit-tool checks were skipped because their optional dependencies or
runtime setup were unavailable. Test fixtures also emitted expected negative-
case diagnostics on stderr; test results remained successful.

The intermediate wrapper-helper implementation passed all 285 test files and
25,328 tests with 100.0% statement, branch, condition, and subroutine coverage
across `lib/` (51,695 detail rows; zero stale uncoverable annotations). That
gate caught a README/POD mismatch, which was fixed by the canonical sync script.
The final inline form then passed all 285 test files and 25,325 tests with
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(51,685 detail rows; zero stale uncoverable annotations).

## Navigation item array removal (2026-10-18)

The warmed route builds a final navigation section from already ordered saved
and skill fragments. A Docker benchmark compared the former two-element array
and `join` assembly with direct scalar concatenation plus the section wrapper;
both produced byte-identical output. Ten million calls measured 4.76 million
array/join assemblies per second and 8.00 million direct-scalar assemblies per
second (1.68x). Before implementation, a red-first test failed because the
optimized wrapper contract did not exist. The final implementation appends
fragments to one scalar and wraps inline, avoiding a new subroutine call.
`t/03-web-app.t` pins exact rendered markup. The full route returned the same
HTTP 200 response (19,341 bytes and the established SHA-256) at 0.342350
ms/request; that is within route noise and not a route-level gain claim. This
synthetic wrapper result does not establish 50x for every subroutine.

### Saved navigation fragment array removal (2026-10-18)

The saved-navigation cache-miss path also built an intermediate array before
joining the ordered fragment strings. A Docker regression now pins both the
exact response wrapper and the unwrapped fragment string stored in the cache.
An alternating 100,000-iteration microbenchmark over 20 identical fragments
measured 148.683 ms for array/push/join and 70.984 ms for scalar concatenation
(2.09x); output bytes were checked each iteration. The actual warmed route
returned the same HTTP 200 response, 19,341 bytes, and SHA-256 in both modes.
Separate nine-sample medians were 0.346990 ms/request with the array and
0.341589 ms/request with scalar accumulation (1.016x), too small to distinguish
from route noise. The array was removed as a low-risk allocation reduction,
but no route-level speedup is claimed.

The Docker full coverage gate was rerun after this change and passed all 285
test files and 25,326 tests. Statement, branch, condition, and subroutine
coverage remain 100.0% across `lib/` (51,685 detail rows; no stale
uncoverable annotations). Optional SPVM, browser, QEMU, CPANTS, POD, and audit
tool checks skipped because the corresponding optional runtime tools were not
available in the dev container.

## Operation-scoped `runtime_root` accessor cache (2026-10-18)

The warmed saved-page NYTProf report showed 100 calls to
`PathRegistry::runtime_root` and 600 calls to `runtime_layers` across 100
requests. The existing request scope already holds the immutable layer list,
but each `runtime_root` access still re-entered the accessor and copied that
list. A red-first Docker regression verified that repeated scoped calls use one
layer-list read while unscoped calls still observe changed results. The
implementation now stores only the deepest root in the existing operation
scope; it retains no cross-request cache. `t/97-pathregistry-coverage.t` passes
all 359 assertions.

Nine alternating Docker microbench samples of 500,000 reads measured the old
accessor body at 220.470 ms median and the scoped fast path at 128.106 ms
(1.72x), with exact path parity. Three paired saved-page route comparisons with
20 saved-nav fragments, 100 skill-nav fragments, and 50 indicators showed no
stable end-to-end improvement: per-process medians ranged from 0.344150 to
0.377309 ms/request and every response retained HTTP 200, 19,341 bytes, and
SHA-256 `a3c1df9346d5b1c2942fbec1354e2dbb8dcc268e0e148107787197635a7ed331`.
A follow-up alternating `all_paths` benchmark compared the old accessor body
inside the full path inventory and required exact canonical JSON parity. Nine
samples measured 0.347 ms before and 0.281 ms after (1.24x). That confirms a
gain in this aggregate path inventory, but the warmed browser route itself did
not measurably improve; neither result establishes a 50x route or all-subroutine
speedup.

## Native helper versus rewriting every module (2026-10-18)

The dashboard's current HTML attribute escaper was benchmarked in the Docker
development container against its pure-Perl pre-XS reference, with output and
UTF-8-flag parity required. Without the compiled extension, the production Perl
path measured 1.61x faster for a plain navigation identifier but 0.87x for a
quote-heavy value. After compiling the distribution's XS extension, the same
benchmark measured 1.82x and 4.52x respectively. These are two helper/input
cases, not measurements of every module or the whole application. They support
selective, profile-guided native code only; they do not support rewriting all
modules in XS or establish the 50x objective. The development container's
ordinary source-checkout benchmark does not load XS unless run with `-Mblib`.

The first in-container `make` compiled and linked the XS extension, then failed
while copying scripts because `PERL5LIB` selected a Storable build under
`/root/perl5` that did not match the container's `/usr/bin/perl` 5.40.1 ABI.
Re-running the same generated Makefile as `d2 docker compose exec dev make
PERL5LIB=` completed successfully, including script installation and POD
manification. This isolates that build failure to the container's injected
local-library path; it is not a source-level XS compilation error. The
targeted benchmark ran against the newly built extension, and the compiled-XS
suite `prove -Iblib/lib -Iblib/arch -lv t/665-problem48-xs-html-escape.t`
passed all 75 assertions, including UTF-8 and taint-preservation cases.

The same extension was then measured in the representative saved-page route
(20 saved-nav fragments, 100 skill-nav fragments, 50 indicators; HTTP 200 and
the existing 19,341-byte response hash). Three alternating invocations per
mode, each using a three-run median, measured Perl at 0.348980, 0.341609, and
0.347929 ms/request; XS measured 0.348010, 0.422699, and 0.349710. The
medians-of-medians are 0.347929 and 0.349710 ms/request respectively, so this
route shows no measurable benefit from the escaper's XS path. This is further
evidence to target native code only where the profiler shows a substantial
share of end-to-end work.

## Prefix/index parsing for browser host context (2026-10-18)

NYTProf showed the two host-normalization substitutions in
`Web::App::_top_context_html` taking about 14.7 ms across 703 calls in the
100-skill route profile. Characterization tests pin exact lowercase HTTP/HTTPS,
uppercase-scheme, unsupported-scheme, port, and path behavior before the
substitutions were replaced with fixed prefix checks and one `index` truncation.
An alternating Docker microbenchmark over six representative host strings and
250,000 calls per sample measured 108.739 ms for the regexes and 82.475 ms for
the prefix/index path (1.32x) with exact parity. The saved-page route retained
HTTP 200, the 19,341-byte response, and SHA-256
`a3c1df9346d5b1c2942fbec1354e2dbb8dcc268e0e148107787197635a7ed331`; its
0.346200 ms/request result is not attributed to this helper change. The
all-subroutine 50x objective remains open.

## Fresh NYTProf route map after host parsing (2026-10-18)

The warmed Docker route was rerun for 100 requests with 20 saved-nav fragments,
100 skill-nav fragments, and 50 indicators. The unprofiled median was
0.372620 ms/request and returned HTTP 200 with the same 19,341-byte response
hash recorded above. A separate NYTProf run preserved the same response and
measured 1.485679 ms/request under instrumentation. Its largest exclusive
dashboard totals were `_request_config_snapshot` (7.17 ms),
`PathRegistry::runtime_layers` (4.31 ms), `Web::App::dispatch_request`
(4.18 ms), and `PathRegistry::runtime_layer_root_for` (4.14 ms) across the
100-request run. `_top_context_html` was 1.20 ms exclusive, down from the
earlier 14.7 ms host-normalization attribution before the prefix/index change.
These instrumented rankings identify the next areas to inspect; they do not
justify changing freshness checks or runtime-layer invalidation without a
matched correctness and performance experiment.

## Fresh NYTProf map after environment-signature change (2026-10-18)

The current source was profiled again in Docker with 100 requests, 20 saved-nav
fragments, 100 literal skill-nav fragments, and 50 indicators. It returned the
same HTTP 200 response, 19,341 bytes, and SHA-256 recorded above. NYTProf
measured 1.661699 ms/request; this instrumented timing is diagnostic only. The
largest exclusive totals were `PathRegistry::_ensure_state_dir` (11.3 ms over
300 calls), `Web::App::_nav_items_html` (8.67 ms over 100 calls),
`Web::App::_render_page_html` (7.65 ms), `PathRegistry::state_base_root`
(4.82 ms), and `Web::App::_top_chrome_html` (4.48 ms). These overlapping
instrumented totals are rankings, not standalone request costs. The literal
skill-nav content and inventory counts each equal the 100 fixture skills
loaded while warming the cache; they do not represent repeated per-request
file reads. The profile points first to state-root validation and the cached
navigation-render path for additional controlled investigation. Their
permission checks, watcher freshness, and runtime-layer visibility remain
invariants; no checks are removed based on this profile alone.

## Per-subroutine v5.88 profile comparison (2026-10-18)

The same workload was profiled with the v5.88 source first on `@INC` and the
current `Watch` module supplied only as a compatibility dependency. Both
profiled routes returned the exact response hash above. The v5.88 profile used
10 measured requests and the current profile used 100, so their per-request
exclusive-time values are directional, not an alternating timing comparison.
For `_nav_items_html`, exclusive time fell from 32.8 ms/10 requests to 8.67
ms/100 (37.8x), while inclusive time fell from 1.11 s/10 to 18.7 ms/100.
For `_ensure_state_dir`, exclusive time fell from 53.5 ms/10 to 11.3 ms/100
(47.3x by request contribution); call counts fell from 12,600 to 300. Source
inspection confirms that function's body is unchanged between v5.88 and
current, so this reduction comes from eliminating redundant calls elsewhere,
not a faster invocation. Permission validation remains necessary. A
redesigned existing-directory fast-stat microbenchmark measured 157.667 ms
median per 100,000 current calls versus 155.346 ms for the candidate (1.015x);
that gain is within noise and is not sufficient to justify a production
replacement. These results leave the strict per-routine 50x target unproven.

## Rejected environment-signature memoization (2026-10-18)

The route profile ranked `_request_config_snapshot` highly, so repeated
`_config_snapshot_environment_signature` JSON construction was tested as a
Memoize-style candidate. Nine alternating Docker samples of 50,000 calls
measured the exact prior JSON implementation at 195.968 ms median and the
per-App cached implementation at 231.105 ms (0.85x, slower), with identical
signature output. The cache and its test were removed. That experiment
rejected caching; the later versioned length-prefixed change documented at the
top of this file is a separate representation change, not the rejected cache.

## Prompt-summary invalidation after status-route synchronization (2026-10-18)

A red-first Docker regression reproduced stale prompt text when `/system/status`
ran collector synchronization after the summary had been cached. The status
route could apply changed configured indicator data, but the next page render
then received an unchanged signal and reused the old summary. `_page_status_payload`
now invalidates the rendered summary whenever collector synchronization reports
changed data, regardless of which route performed the sync. The existing emoji
indicator assertion in `t/03-web-app.t` failed before this fix and passes after;
the focused `t/03`, `t/105`, and `t/668` suites pass 1,101 assertions. A fresh
nine-run saved-page benchmark measured 0.362170 ms/request with the exact same
HTTP 200 response body and SHA-256 as before. This change is correctness-first;
the small route timing variation is not claimed as a performance gain.

## Freshness-validated prompt-summary reuse (2026-10-18)

The refreshed route profile showed `IndicatorStore::list_indicators` called
once for each page request even when collector configuration and indicator
files were unchanged. `_prompt_summary` now asks the existing collector-sync
freshness path to validate before reusing its worker-local rendered summary.
Changed indicator files or collector configuration still rebuild the summary;
the persisted state remains authoritative. A red-first test caught that the
old path never requested freshness and verified that unchanged, changed, and
invalidated summary states behave correctly. Focused Docker suites pass 665
tests. In the matched 100-skill/20-saved-nav route with 50 indicators, the
cache-enabled median was 0.435739 ms/request versus 1.117690 ms/request when
summary reuse was disabled (2.56x), with exact 19,341-byte response parity and
SHA-256 `a3c1df9346d5b1c2942fbec1354e2dbb8dcc268e0e148107787197635a7ed331`.
NYTProf showed `list_indicators` calls dropping from 704 to 2 across the
profiled run; 900 of 900 measured requests reused the summary after freshness
validation. With the native watcher forced off, the portable validator also
preserved response bytes but measured 23.598 versus 22.815 ms/request over
three samples, so that Linux fallback comparison shows no speedup. The 50x
target for every routine remains unproven.

## Hoisted legacy Markdown separator pattern (2026-10-18)

The warmed saved-page route profile continued to rank legacy section parsing
among repeated costs. A test-first parser regression pins padded Markdown
separators with CRLF input and exact section bodies. The separator regexp is
now compiled once at module load instead of being constructed for each parser
call. An alternating Docker microbenchmark of 100,000 realistic two-section
parses across nine samples measured 637.245 ms with per-call compilation and
602.597 ms with the hoisted pattern (1.06x), with canonical parsed-output
parity. The focused PageDocument and saved-page route suites pass 188 tests;
the 100-skill/20-saved-nav route returned the same HTTP 200 response hash at
0.342340 ms/request. That end-to-end result is within normal variation and is
not attributed to this helper change. This small parser gain does not satisfy
the 50x target for every subroutine; Problem 48 remains open.

## Avoid full page-hash allocation for renderer mode (2026-10-18)

The refreshed NYTProf subroutine index counted 300 `PageDocument::as_hash`
calls over 100 warmed saved-page requests, including one call per request from
top-chrome mode selection. A red-first Docker regression replaced `as_hash`
with a failing stub and confirmed that top chrome depended on that full-hash
allocation. `PageDocument::mode` now exposes only the stored scalar and
`Web::App::_top_chrome_html` uses it, retaining the existing `edit` fallback.
The render-mode fixture confirms the Play button remains absent. Focused
PageDocument and web-app suites pass 629 assertions.

Nine alternating Docker samples of one million reads measured
`as_hash->{mode}` at 1,010.759 ms and `mode()` at 213.278 ms (4.74x), with
exact value parity. This helper benchmark does not demonstrate a 50x route or
all-subroutine improvement.

## Rejected saved-nav root-signature memoization (2026-10-18)

NYTProf ranked `_saved_nav_items_snapshot_state` as a route hotspot and showed
repeated JSON encoding of the ordered root list. A red-first test confirmed the
encoding happened even for a validated watcher cache hit. However, alternating
Docker microbenchmarks with 100 realistic roots and 1,000 calls per sample
measured 7.742 ms for JSON encoding versus 12.114 ms for a cached 100-root
comparison (0.64x). A length-framed joined-string alternative was slower still
(20.685 ms, 0.46x); after replacing repeated concatenation with `join`, it
measured 29.082 ms (0.29x). Both alternatives were semantically checked but
rejected. Their implementation and tests were removed, so production code
continues to use the original JSON signature. Profile ranking alone is not a
reason to retain a slower candidate.

## Rejected `_trim` boundary-check fast path (2026-10-18)

NYTProf showed repeated `_trim` calls in the saved-page parse/render path. A
candidate first checked whether either boundary contained whitespace, then ran
the existing substitutions only when needed. Exact output parity held for plain
ASCII, edge whitespace/newline, and Unicode no-break-space input, but nine
alternating Docker samples of 500,000 calls showed regressions: plain ASCII
184.710 ms to 321.447 ms (0.57x), edge whitespace 333.960 ms to 361.089 ms
(0.92x), and Unicode no-break-space 184.733 ms to 373.751 ms (0.49x). The
candidate was not added to production. Profile frequency alone did not justify
extra boundary scanning.

The subsequent clean Docker `dev` coverage gate passed all 285 test files and
25,242 tests. Statement, branch, condition, and subroutine coverage are each
100.0% across `lib/` (51,597 detail rows; no stale uncoverable annotations).
Optional browser, Windows, CPANTS, POD, and audit-tool checks remain separate.
`perldoc -T perlsec` still cannot render in this image because its POD text
formatter is absent; the installed `perlsec.pod` was read directly after the
gate. Problem 48 remains open because 50x for every subroutine and hosted
cross-platform results have not been established.

## Full Docker coverage gate and refreshed profile after flat-id validation (2026-10-18)

The clean Docker `dev` coverage gate completed after the canonical flat page-id
fast path was added. All 285 test files and 25,238 tests passed. Statement,
branch, condition, and subroutine coverage are each 100.0% across `lib/`
(51,588 detail rows; no stale uncoverable annotations). Some optional checks
remain skipped because their external tools or platforms are unavailable; this
Linux run does not establish cross-platform parity or the all-subroutine 50x
target. `perldoc -T perlsec` could not render because the image lacks a
Pod::Perldoc text formatter; the installed core `perlsec.pod` was read directly
after the gate instead.

A fresh NYTProf profile of the exact 100-skill/20-saved-nav route fixture kept
HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`, with
repeat parity. Instrumented latency was 1.966288 ms/request (diagnostic only).
Largest exclusive times were `PageDocument::_parse_legacy_sections` 6.83 ms,
`PathRegistry::_write_state_metadata` 5.24 ms, `Web::App::_top_chrome_html`
5.19 ms, `Web::App::_top_context_html` 5.08 ms,
`Web::App::_page_status_payload` 4.80 ms, and
`PageStore::_open_saved_page_at` 4.71 ms. These costs overlap callers and must
not be interpreted as unprofiled latency or summed. The profile provides
candidates for further red-first, parity-checked experiments; it does not
establish 50x performance for any routine. Problem 48 remains open.

## Full Docker coverage-gate recheck (2026-10-18)

After the fetch-metadata fast paths and their direct regression assertions,
`script/coverage-gate --database /tmp/p48-cover-db-20261018-fetch-fastpath`
passed all 285 test files and 25,233 tests. Statement, branch, condition, and
subroutine coverage are each 100.0% across `lib/` (51,573 detail rows, no stale
uncoverable annotations). Optional checks skipped because their tools are not
installed remain separate delivery items; this gate does not prove the
all-subroutine 50x performance target or cross-platform workflow results.

## Fresh NYTProf map after aggregate navigation caching (2026-10-18)

Reran the current 100-skill/20-saved-nav fixture under NYTProf in the Docker
`dev` service with 100 requests. It returned HTTP 200, 18,792 bytes, and the
expected response SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`; exact
repeat parity held. The instrumented run measured 1.548522 ms/request, which
is diagnostic only and must not be compared with unprofiled route medians.
Exclusive/inclusive totals were `_nav_items_html` 4.83/14.7 ms,
`_parse_legacy_sections` 2.37/3.14 ms, `_top_context_html` 1.17/2.31 ms, and
`PageStore::_assert_page_path_contained` 0.490/1.81 ms over the profile.
These values overlap through callers and profile instrumentation; they are
candidate rankings, not per-call speedup claims. The nav renderer remains the
next candidate for a narrowly scoped experiment, but watcher freshness,
layer ordering, dynamic-fragment request context, and secure path containment
must remain intact. The matched unprofiled route comparison remains
135.065870 ms/request on v5.88 versus 1.136279 ms/request currently (118.87x
for that fixture only); no conclusion about every subroutine follows. That
profile motivated the documented page-id accessor optimization below.

## Avoid full page-hash construction for identifier reads (2026-10-18)

The fresh profile ranked `_nav_items_html` as its largest exclusive renderer
cost. Its route-page and nav-page identifier reads used `as_hash`, which
constructs a new outer hash containing every page field just to fetch `id`.
A red-first Docker regression replaced `PageDocument::as_hash` with a failing
stub during the nav-route short circuit; it failed before the change. A
`PageDocument::id` accessor now returns only the stored identifier, and the
web renderer uses that accessor at its known-PageDocument call sites. The full
hash API remains unchanged. The PageDocument and web-app focused suites pass
625 assertions, including undefined ids and the no-full-hash nav path.

Nine alternating Docker samples of one million reads measured
`as_hash->{id}` at 902.120 ms median and `id()` at 162.422 ms (5.56x), with
identical consumed values. A fresh v5.88/current `/app/welcome` comparison with
100 skill-nav roots and 20 saved nav fragments, 100 requests per sample, and
nine samples preserved HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. v5.88
measured 58.338089 ms/request and current source 0.367992 ms/request (158.53x
for this exact fixture). This cumulative route result is not attributed solely
to the accessor and still does not prove 50x for every subroutine.

## Canonical flat saved-page id validation (2026-10-18)

A fresh NYTProf run after the `PageDocument::id` change ranked
`PageStore::_validated_page_id` at 4.52 ms exclusive over 300 calls, including
the repeated plain `welcome` id. The expected result was unchanged validation
and error behavior while bypassing prefix stripping and path-component
splitting for canonical single-segment ASCII ids only. Red-first Docker tests
made `_normalized_page_id` fail when `welcome` and `team-status_2.json` reached
that fallback; they failed before the production change. The method now returns
those canonical flat names directly. IDs with prefixes, separators, whitespace,
Unicode, refs, and invalid path components still use the established
normalization and validation path. `t/73-pagestore-coverage.t` passes 216
assertions, including traversal and platform-ambiguous cases.

Nine alternating Docker samples of one million `welcome` validations measured
879.049 ms for the prior normalization/validation path and 430.213 ms for the
canonical fast path (2.04x) with exact returned-value parity. This is a
small-name helper result, not a route-level or universal gain. The full Docker
coverage gate must be rerun after this source change; Problem 48 remains open.

## Current full-suite recheck (2026-10-17)

The latest complete `script/coverage-gate` run in the Docker `dev` container
passed all 285 test files and 25,229 tests. Statement, branch, condition, and
subroutine coverage is 100.0% across `lib/` (51,571 detail rows; no stale
uncoverable annotations). The final run included red-first coverage for both
undefined-input guards in the one-section parser. This Linux-container result
does not establish that the cross-platform hosted workflow has passed or that
Problem 48's universal 50x performance objective has been achieved.

## Single-section legacy parser fast path (2026-10-17)

The warmed saved-page NYTProf map continued to show
`PageDocument::_parse_legacy_sections` among repeated costs. The common legacy
document has one section and no legacy or Markdown separator, but the parser
still built the multi-part split list. A red-first Docker test first failed
because `_parse_single_legacy_section` did not exist. The parser now routes
only separator-free input through that helper; inputs containing either
separator retain the original multi-section implementation. Exact section
parity tests cover undefined input, whitespace trimming, multiline bodies,
unknown names, extended `CODE` numbers, and the existing separator cases.

An alternating Docker microbenchmark compared the previous split implementation
with the current parser on 500,000 calls per sample over nine samples. Six
representative inputs had exact output parity. The common `TITLE`/`HTML` case
measured 1,860.772 ms per 500,000 baseline calls and 993.799 ms for current
source (1.87x). This is one parser-helper workload, not a route-level or
universal subroutine gain. A warmed current 100-skill/20-saved-nav route rerun
returned HTTP 200 and the same 18,792-byte response SHA-256 and measured
0.340998 ms/request; that route run is not paired against a pre-change build, so
no route-level gain is attributed to this parser edit. Problem 48's universal
50x objective remains open.

## Source-only HTML fallback dispatch (2026-10-17)

The shared HTML escaper's source-only fallback called a second private Perl
routine after the public dispatcher had already been entered. A red-first
Docker regression replaced that helper with a failing stub and confirmed the
extra call. The fallback now performs the same undefined-input normalization
and three substitutions directly in the public routine; references still use
Perl stringification, and the compiled XS selection is unchanged. Both the
source-only and compiled-XS escaper tests preserve exact output.

Twenty-five alternating samples compared 500,000 ordinary-string calls to the
previous public fallback and the direct path, consuming returned lengths to
retain observable work. Medians were 175.998 ms and 135.123 ms (1.30x). This
applies only when XS is unavailable and is a local helper result, not a route
or all-subroutine speedup. The first full gate after this change found the
reference helper's defined-input branch uncovered. A direct defined-input
regression was added; the complete rerun then passed 285 files / 25,229 tests
with 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (51,571 detail rows, no stale uncoverable annotations). Problem 48's
50x-per-subroutine target remains open.

## Latest matched saved-page route recheck and normalization candidates (2026-10-18)

The current source was rerun in Docker with the same 100-skill/20-saved-nav
fixture used by the exact v5.88 comparison: 100 requests per sample over nine
samples. It returned HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`, with
exact repeat parity. The current median was 0.420060 ms/request versus the
recorded v5.88 median of 135.065870 ms/request (321.54x on this route fixture).
This cumulative route result is not attributed to the latest HTML fallback
change and does not prove a 50x speedup for every subroutine or platform.

NYTProf had ranked `PageStore::_normalized_page_id` at 24.4 ms over 900 calls
in an instrumented run. A source-only boundary-regex candidate was checked
against undefined, empty, canonical, `/app/`, repeated-slash, whitespace,
Unicode-whitespace, nested, and traversal inputs; it preserved output but
measured only 0.45x of the current function in 25 alternating 500,000-call
samples. A character-boundary candidate measured 1.00x in the same sample
shape. Neither candidate was integrated: their measurements show no useful
gain. More work is needed on this profiled hotspot; the universal 50x target
remains open.

An additional in-container candidate replaced the common one-section parser's
key/header regular expression with `index`/`substr` parsing while preserving
leading/trailing whitespace rules and the legacy key allowlist. Six cases
(TITLE, HTML, CODE, multiline body, unknown key, and whitespace around the
colon) produced exact parity before timing. Nine alternating samples of
500,000 calls measured 750.758 ms for the current parser and 802.494 ms for
the candidate (0.94x). The rewrite was rejected; the small helper's direct
string operations did not beat Perl's compiled regular expression. This is
another negative candidate result, not a production change or a universal
performance claim.

The current NYTProf pair also showed the fetch-metadata classifier spends time
lowercasing and trimming an empty value on requests without `Sec-Fetch-Site`.
The expected behavior is that absent, undefined, or reference-valued metadata
remains non-foreign. The Docker cross-site suite was extended first with those
direct assertions and passed before the implementation change. The classifier
now returns before normalization for those shapes; all 34 focused security
assertions still pass. Nine alternating direct samples of one million
headerless requests measured 370.968 ms in the old path and 298.395 ms in the
new path (1.24x). This is a small common-case gain and does not prove the
50x-per-subroutine target.

A further direct benchmark isolated the exact `same-origin` label, another
common browser value that is known not to be foreign. A test assertion was
added before the change; the implementation now returns before lowercasing
and trimming only for the exact `same-origin` and `none` strings. Mixed case,
whitespace-padded, same-site, and cross-site values continue through the
existing normalization/authorization path. The focused suite now passes 35
assertions. Nine alternating samples of one million exact same-origin calls
measured 830.125 ms before and 442.506 ms after (1.88x versus the preceding
headerless-only optimization). This is not a 50x claim.

## Builtin class and signature dispatch check (2026-10-17)

The repository's `class`/`field`/`method` benchmark was rerun in the dev
container on Perl 5.40.1 with 1,000,000 calls per sample and nine rotating
samples. All implementations returned the same accumulated value. Blessed
hash methods measured 82.585 ms median, signature methods 102.421 ms, and
builtin class/field methods 102.085 ms. The builtin class syntax measured
0.81x the speed of the existing blessed-hash method in this microbenchmark;
signature methods also measured 0.81x. These language features are therefore
not a general acceleration strategy for this workload, and no production
objects should be migrated on this evidence. This synthetic dispatch result
does not measure the Dashboard's full call paths or establish the required
50x improvement for every subroutine.

The same benchmark was repeated on 2026-10-18 with the same Perl/container,
one million calls, and nine rotating samples. Value parity held; medians were
85.389 ms for blessed hashes, 111.106 ms for signatures, and 102.217 ms for
builtin class/field methods (0.77x and 0.84x relative to the hash baseline).
This independently confirms that neither language feature accelerates this
dispatch workload; it is not a full-application comparison.

## Parallel and compiled-loop technology checks (2026-10-17)

The dev container did not include the optional MCE, Inline::C, or SPVM
research dependencies. They were installed only into the isolated container
prefix `/tmp/p48-local`, used for these measurements, and are not application
dependencies. MCE's ordered config-read benchmark returned exact payload/order
parity at 50, 250, and 1,000 independent files. With four workers, warmed MCE
medians were 1.497, 5.830, and 20.957 ms versus serial medians of 1.165, 5.069,
and 20.472 ms (0.78x, 0.87x, and 0.98x). Its cold first-map timings were slower
at every size. Parallel file/config loading is not justified by these results.

At the authentication PBKDF2 work factor of 210,000 rounds, all Perl, FFI,
Inline::C, and SPVM digests matched. Perl measured 279.373 ms, OpenSSL through
FFI::Platypus 30.320 ms (9.21x), and Inline::C/XS 30.139 ms (9.27x); Inline
compile time was 555.005 ms and excluded from the steady-state medians. SPVM's
compiled loop measured 530.277 ms (0.57x Perl speed), after 51.339 ms setup.
The existing FFI PBKDF2 adapter remains the useful native path; neither
parallelism nor SPVM adds a speed benefit for these tested workloads. These
specialized measurements do not demonstrate the required 50x for all
Dashboard subroutines.

## Current saved-page route profile (2026-10-17)

A fresh NYTProf run measured 20 warmed `/app/welcome` requests with 100
installed skill-nav fragments and five saved-nav fragments. It returned HTTP
200 with exact repeat parity (17,742 bytes; SHA-256
`c481093b9c88db29e384a545305c4fc02056feaf652682691a13a962939e1270`). The
instrumented run took 1.686 ms/request, which is diagnostic only and must not be
compared with unprofiled timings. The top exclusive-time routines were
`Web::App::_top_chrome_html` (3.67 ms total), `_page_status_payload` (2.95 ms),
`PageDocument::_parse_legacy_sections` (0.514 ms), `Cwd::abs_path` (0.505 ms),
and `Web::App::_nav_items_html` (0.358 ms). The profile included NYTProf's
generated `#line` warning for `PageRuntime.pm`; source attribution there is
imperfect. These hotspots guide subsequent parity-preserving experiments but
do not establish per-subroutine speedups.

## Validated skill-nav route inventory reuse (2026-10-17)

NYTProf showed that unchanged literal skill-nav pages avoided reparsing but
still recursively enumerated every `dashboards/nav` directory on every request.
`SkillDispatcher` now caches the sorted relative route inventory per nav root.
The cache validates high-resolution stat fingerprints for every visited
directory before reuse, so route creation, removal, and nested-directory
changes trigger a fresh scan. It is bounded to 128 roots, 4,096 directories,
8,192 files per root, and 256 KiB per inventory (32 MiB maximum by the stored
inventory-byte accounting); page path resolution and file containment checks
remain in the normal request path. The recursive scanner captures
before/after directory fingerprints and does not cache an unstable scan.

Red-first Docker tests showed two root scans on initial lookup, no additional
recursive scans on an unchanged repeat, and one rescan after a route was added
to a layered leaf root. Existing add/remove and content-edit tests continue to
verify freshness and byte-identical route output. The initial cache-capacity-
64 benchmark exceeded its root bound with the 100-skill fixture, causing FIFO
churn. The cache is now bounded to 128 roots. Stable inventories retain
validated relative route segments so internal nav loading does not split and
validate each discovered route again; `_page_location` still checks supplied
segments for traversal, separators, and control bytes, while browser-sourced
route ids continue through the shared PathRegistry validator.

A current-source Docker benchmark with 100 installed skill nav fragments, 100
requests, and 9 samples measured 3.794620 ms/request with inventory reuse; the
sequential cache-disabled control measured 7.907050 ms/request (2.08x). Both
returned the same response SHA-256. Recursive scans fell from 90,300 to 100.
The no-cache control invalidates each root before scanning it; the controls
were sequential, not alternating paired runs. This is a measured incremental
gain, not a 50x result.

The focused dispatcher and benchmark tests passed 295 assertions, including
the explicit 128-root eviction limit and trusted-fast-path/untrusted-route
traversal rejection. The final full Docker coverage gate passed all 285 test
files / 24,976 tests, with statement, branch, condition, and subroutine
coverage all at 100.0% across `lib/` (50,889 detail rows; no stale uncoverable
annotations). This coverage result does not close Problem 48's all-subroutine
50x objective.

## Literal skill-nav document reuse (2026-10-17)

The 100-installed-skill `/app/welcome` fixture still spent time rebuilding
unchanged raw navigation page documents. A bounded per-`SkillDispatcher` FIFO
cache now reuses only literal raw-nav page objects: the path is resolved and
high-resolution file metadata is checked on every request, while dynamic TT or
structured pages are still read and parsed each time. The cache is limited to
256 entries and 8 MiB. The web renderer treats cached literal page objects as
read-only. Red-first Docker regressions cover same-size edits, new and removed
nav routes, cache bounds/error states, and unchanged-document reuse.

Two paired current-source Docker comparisons (100 requests × 21 samples per
run) preserved HTTP 200, the exact 18,792-byte body, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`.
The mean of the two run medians was 4.754831 ms/request with reuse and 6.021790
ms/request without it (1.2665x). Across the two enabled runs, 200 skill-nav
content reads served 4,200 measured requests; the disabled controls read
420,600 times. A current NYTProf route profile also showed 20
`PageDocument::new` calls over 20 requests, versus 2,020 in the prior profile;
its instrumented wall time is not used as a speed claim. The earlier v5.88
measurement for the same route fixture was 53.166 ms/request, but was not
rerun in today's paired comparison; this context is not a fresh matched ratio.
The cache therefore establishes a modest incremental gain only. Problem 48's
50x requirement for every subroutine remains unmet and open.

The complete Docker coverage gate passed after adding explicit cases for
malformed FIFO eviction and replacement of a cached object with the wrong
dispatcher class: 285 test files, 24,910 tests, and 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (50,667 detail rows; no stale
uncoverable annotations). `perldoc -T perlsec` could not run because the dev
image lacks a loadable POD formatter; the relevant installed Perl 5.40
`perlsec.pod` sections were read directly. This verifies the current tests,
not the outstanding all-subroutine 50x requirement or cross-platform hosted
workflow results.

## 100-skill navigation scale profile (2026-10-16)

A warmed `/app/welcome` route with 20 saved nav fragments and 100 installed
skill nav fragments was measured first with the v5.88 library from `HEAD`,
then with the current source. Both runs returned HTTP 200 and the exact same
18,792-byte response hash
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`.
Across nine runs of 40 requests, v5.88 measured 53.166 ms/request and current
source measured 7.759 ms/request (6.85x). This larger fixture is slower than
the 50-skill case and remains far below 50x.

NYTProf on the current route attributed work to skill-page lookup and loading:
2,000 `_page_location` checks, 2,000 page-file opens, and 2,000
`PageDocument::new` calls across 20 requests (including one saved page per
request). Saved-nav candidate searches
were zero; the remaining reads are the 100 skill-owned fragments, which must
remain visible when files change. The profile also reports NYTProf's generated
`#line` warning for `PageRuntime.pm`, so its line totals are diagnostic only;
the unprofiled paired route timings are the accepted result. No cache or
parallel loader was added because its freshness/security cost has not yet been
shown to buy a material end-to-end gain. Problem 48 remains open.

## Cross-platform verification added (2026-10-16)

The previous GitHub test workflow ran only on Ubuntu x64, which could not
establish that optional native accelerators and their portable fallbacks work
on other operating systems or CPU architectures. A dedicated GitHub Actions
matrix runs the complete Perl suite on Linux x64/arm64, macOS Intel/arm64, and
Windows x64. A separate Windows ARM64 job verifies the runner and native Perl
architecture, installs `FFI::Platypus`, and runs the native filesystem watcher
regression. It does not claim full-suite support on Windows ARM64: the hosted
image's preinstalled Perl is below the project's Perl 5.38 minimum, and the
Perl setup action does not list that runner as supported. The workflow also
prints Perl's configuration so runtime architecture is visible. Hosted
workflow results are still required; local Docker coverage does not substitute
for those results.

## Load-scoped config-layer discovery (2026-10-16)

NYTProf showed repeated runtime-layer discovery in standalone config loads.
The expected behavior is one stable layer snapshot for a single
`Config::load_global` call, with a later call observing any filesystem changes.
The red-first Docker regression failed with five ancestry walks for one load;
the implementation now shares the existing operation-local runtime-layer
scope across config-root and skill-config lookups. It preserves an enclosing
request scope and does not retain the snapshot after the call. The freshness
test creates a new runtime layer after the first load and verifies that the
second load sees its config.

An alternating 21-run Docker comparison over four runtime layers and 25 skill
configs returned identical canonical JSON and reduced median time from 0.3175
to 0.2106 ms/load (1.51x); ancestry walks fell to one per load. This is a
synthetic config-load result, not a v5.88 comparison or an application-wide
gain. A separate direct experiment of a nested-loop alternative for
`_merge_named_hash_array` returned identical JSON but measured 0.990x the
existing implementation, so that candidate was rejected. The all-subroutine
50x target remains open.

The API-registry read path had the same repeated layer-resolution shape. A
red-first test observed four ancestry walks for one `api_registry` call; it
now observes one. Across the same four-layer/25-skill layout, 21 alternating
runs of 100 calls returned identical normalized API output and improved median
latency from 0.3728 to 0.2638 ms/load (1.41x). A new layer and `api.json`
created between calls were visible on the next call. This remains a synthetic,
subroutine-specific gain and does not close the 50x target.

After the config and API scope changes, the clean Docker coverage gate passed
281 files / 24,176 tests. Statement, branch, condition, and subroutine totals
were 100.0% across `lib/` (49,037 detail rows, no stale uncoverable
annotations). The required security regression trio also passed 466 tests;
Perl's core `perlsec.pod` was reviewed directly because the container lacks a
POD formatter. These gates validate the current code, not the open performance
target or release readiness.

## Current-checkout benchmark recheck (2026-10-15)

The existing Docker Template Toolkit benchmark was rerun with 21 alternating
samples, 1,000 request scopes per sample, five distinct-or-repeated renders per
scope, and exact rendered-body parity. The worker-local compiled-block cache
measured 0.0814 ms/render versus 0.2067 ms without reuse for repeated source,
and 0.0819 ms versus 0.2079 ms for five distinct sources (2.54x in both
workloads). The distinct sources recur across request scopes, confirming the
bounded worker cache's reuse across requests; this does not imply reuse for an
unseen source or establish whole-route performance.

Indicator listing was also measured in Docker with 21 alternating samples
and canonical JSON parity across two runtime layers. At 50 records, the
current path measured 1.278 ms versus 15.346 ms for the reconstructed legacy
path (12.01x); at 1,000 records, it measured 16.166 ms versus 240.010 ms
(14.84x). Root reuse explains nearly all of the gain: the current direct path
was only 1.03x and 1.04x faster than the intermediate root-reuse path,
respectively. These synthetic listing workloads are not dashboard-route or
per-subroutine comparisons. The all-subroutine 50x objective remains open.

The 5.95 tarball's blank-environment installation and integration gates are
complete: Docker cpanm installation passed all 277 bundled test files / 18,197
tests, and the documented blank-environment integration run passed.

The static-render and listing routines were rechecked on the current checkout
in Docker with exact output parity. Across 21 alternating runs of 1,000
renders, `PageRuntime::_render_templates`'s unchanged-body fast path took
0.00081 ms/render versus 0.07351 ms for the Template Toolkit compatibility
path (91.30x). This is a routine-specific microbenchmark, not a whole-route
comparison. Two-layer indicator listing across nine alternating runs measured
23.211 ms for the reconstructed legacy path versus 1.909 ms for the current
direct path at 50 indicators (12.16x), and 238.759 ms versus 16.372 ms at
1,000 (14.58x). The current direct path is not consistently faster than the
intermediate root-reuse path (0.96x at 50, 1.03x at 1,000). This confirms a
large win for static rendering and a workload-dependent list improvement; it
does not prove 50x against v5.88 for all subroutines.

## Problem 48 ASVS 5.0 applicability review (2026-10-15)

This review covers the performance work in the current Problem 48 change set,
not the repository's blanket compliance status. The relevant higher-trust work
is the OpenSSL PBKDF2 adapter and the native HTML escaper. Evidence includes
the full Docker suite and coverage gate, `t/651-crypto-pbkdf2-ffi.t`,
`t/665-problem48-xs-html-escape.t`, `t/667-problem48-collector-sync-roots.t`,
`t/668-problem48-status-response-cache.t`, and the web-security trio (466
assertions). ASVS Level 3 scrutiny was applied to authentication/cryptography
(V2/V6); other applicable chapters were reviewed at Level 2.

| Chapter | Applicability and evidence |
| --- | --- |
| V1 Architecture | Applicable: caches are bounded/scoped and preserve explicit freshness boundaries; direct route parity benchmarks and mutation tests. |
| V2 Authentication | Applicable, Level 3: PBKDF2 native adapter retains iteration count and Digest::SHA output; `t/651` checks native/Perl parity and unavailable/error paths. |
| V3 Session Management | No session lifecycle change; existing session and web-security tests pass in the complete suite. |
| V4 Access Control | No authorization rule change; protected-route/auth regressions remain green. |
| V5 Validation, Sanitization and Encoding | Applicable: XS escape paths preserve UTF-8/taint and match Perl output; `t/665` and static-file/security tests. |
| V6 Stored Cryptography | Applicable, Level 3: FFI inputs and OpenSSL ABI bounds are validated; native failure is visible; no reduced work factor or password-result cache. |
| V7 Error Handling and Logging | Applicable: failed native calls and filesystem I/O remain visible; warnings are fatal in tests; close and race failures have explicit assertions. |
| V8 Data Protection | Applicable: no cache persists credentials; status reuse retains high-resolution metadata checks and permission behavior is covered by existing tests. |
| V9 Communication | No transport/TLS behavior changed; `t/17-web-server-ssl.t` passed. |
| V10 Malicious Code | Applicable: XS is distribution-built C with no runtime compiler or shell execution; forbidden-import scan found no production imports/calls. |
| V11 Business Logic | Applicable: response reuse occurs only after unchanged config, inventory, and file-signature checks; changed persisted state is returned on the next request. |
| V12 Files and Resources | Applicable: paths derive from configured roots and discovered names; inventory changes, atomic replacement, missing roots, and I/O errors are tested. |
| V13 API and Web Service | Applicable: `/system/status` response caching preserves exact bytes and invalidates on persisted changes; web-security route tests passed. |
| V14 Configuration | Applicable: collector configuration signature invalidates cached work; current configuration remains authoritative and no new setting was introduced. |

Top 10 cross-check: A01/A07 access-control and identity rules were unchanged
and remain covered by auth tests; A02 cryptographic output and work factor
are pinned by `t/651`; A03 injection/encoding is covered by XS parity and web
tests; A04 design and A05 configuration by freshness/invalidations; A06/A08
dependency and build integrity by existing metadata/release tests; A09 by
visible error paths and logging tests; A10 SSRF is not newly applicable because
the changes add no network fetch or user-controlled destination. This is a
Problem 48 change review, not a claim that repository governance or release
gates are complete.

### Stable status-path string reuse (2026-10-15)

A current-checkout NYTProf profile ran 100 stable `/system/status` requests in
Docker with 50 configured collectors and exact 12,414-byte response parity.
The profile recorded 5,150 `Time::HiRes::stat` calls and 4,950
`File::Spec->catfile` calls for status paths. Per-file stat is required to
retain immediate visibility of external edits; repeatedly constructing the
same path string is not.

The red-first test in `t/667-problem48-collector-sync-roots.t` initially
observed 24 joins across two stable validations of 12 entries. The cache now
reuses path strings only when both ordered roots and the discovered directory
inventory match. A root or inventory change creates a new path map; file
metadata is still checked on every stable request. The focused Docker suites
pass 87 assertions, including malformed path-map recovery, file replacement,
inventory mutation, and missing-root cases.

For route-level impact, a 21-sample paired Docker run compared the production
path cache with an uncached control that discarded only the path-string map.
Each sample made 100 requests with 50 collectors; every route returned the
same 12,414-byte body. Median time changed from 72.341 ms per 100 requests to
66.347 ms (1.09x). This is a small incremental route gain, not an improvement
over v5.88 and not evidence for the full per-subroutine 50x objective.

Follow-up cache tests also cover absent and stale signatures and reject
malformed path lists. The full Docker coverage gate was rerun after these cases:
277 files and 23,938 tests passed, with statement, branch, condition, and
subroutine coverage all at 100.0% (48,462 detail rows; no stale uncoverable
annotations). This confirms coverage for the current tree; it does not change
the 1.09x route result or the still-open all-subroutine 50x objective.

After the gate, the `perldoc perlsec` frontend could not load a formatter in the
dev image, so the installed core `perlsec.pod` was read directly. The required
web security regression set passed 466 assertions across `t/08`, the static-file
suite, and `t/17`; repository scans were also run in Docker using `grep` because
the dev image does not contain `rg`.

## Saved-page profile and dashboard-root cache candidate rejected (2026-10-15)

A disposable Docker NYTProf run profiled 110 warm requests through the actual
`Web::App->handle('/app/welcome')` saved-page route with five saved nav
fragments. Each response returned 200, retained the page title and dynamic
stash marker, and measured 9,882 bytes. The profile attributed 11.068 ms over
1,540 executions (about 7.2 microseconds/execution under instrumentation) to
the `dashboards_roots` mapping statement. This identifies repeated path-list
construction, but does not imply the same wall-clock cost.

A red-first regression showed that the mapping statement ran twice for two
lookups within an explicit request scope. A request-local cache candidate made
it run once; focused Docker tests for PathRegistry, Web::App, and DancerApp
passed 813 assertions, including per-request cleanup and preservation of the
explicit bookmark-root override's directory-ensuring behavior. The paired
route benchmark then compared the candidate against the original implementation
over 21 alternating samples of 100 requests each, normalizing only the live
datetime field. Both paths returned equivalent route content; median latency
was 1.2397 ms/request uncached and 1.2368 ms/request cached (1.00x). Because
this is no meaningful end-to-end gain, the candidate and its tests were
removed. No dashboard-root cache is retained in production. The 50x target
remains open.

## Stable status validation path-join reuse (2026-10-15)

After validated response reuse, a source-bound NYTProf profile showed two
status-path joins for every discovered indicator: the directory-inventory
validation checked that each candidate file was in the persistent signature
cache, then active-collector validation rebuilt and checked the same paths.
The red-first Docker test reproduced 24 `File::Spec->catfile` calls for 12
entries. The validator now records whether each discovered name has a present
status file during its first pass and reuses that result for active jobs. It
still stats every cached candidate using the same high-resolution signature,
so external updates remain visible; it does not trade away freshness.

The focused Docker tests pass with exactly 12 joins for 12 fixture entries.
The matched 50-collector endpoint returned byte-identical 12,687-byte bodies
and measured 34.307 ms/request on v5.88 versus 0.437 ms/request on current
source (78.50x) across 31 samples. This is a route-specific measurement, not
evidence for the requirement that every subroutine improve by at least 50x.
The full Docker coverage gate passed statement, branch, condition, and
subroutine totals at 100.0% (48,438 detail rows, with no stale uncoverable
annotations). After that gate, `perldoc perlsec` rendered successfully and the
required web/security regression set passed 622 assertions across four files.

Security applicability review: V1, V7, V12, and V13 were relevant. The change
retains the existing filesystem roots and high-resolution signatures, closes a
directory handle on a read error, and reports close failures; the response is
reused only after freshness validation. No route, auth/session, input,
cryptographic, network, command-execution, or configuration behavior changed,
so V2-V6, V8-V11, and V14 were not newly applicable. The all-subroutine Problem
48 objective, packaging, image, and delivery gates remain open.

## Indicator ordering experiment (2026-10-14)

An isolated Docker sort benchmark compared the existing comparator, which
repeated method dispatch and hash lookups on every comparison, with a
decorate-sort-undecorate implementation. Coverage-driven direct tests were
added for each priority, collector-order, and name-fallback condition. In 30
alternating pairs on identical 5,000-record inputs, the final sort measured
16.240 ms for the legacy comparator and 10.763 ms for decorated sorting (1.51x)
with exact order parity. The optimized path applies at 32 or more records;
smaller lists retain the shared comparator.
Coverage reruns showed Perl's sort comparison schedule did not reliably
exercise every short-circuit pair. The tuple comparison is now a small private
function with direct deterministic tests for priority, two-collector ordering,
equal-order names, and mixed/unmanaged name fallbacks.

The complete two-layer listing benchmark, which also includes filesystem
discovery and file reads, measured 1.04x at 50 records, 1.14x at 1,000, and
1.06x at 5,000, with exact canonical JSON parity. The isolated sort gain does
not translate into a comparable end-to-end gain. Problem 48's all-subroutine
50x target remains open.

The final clean Docker coverage gate for this sort iteration passed 272 test
files / 23,628 tests, with 100.0% statement, branch, condition, and subroutine
coverage across `lib/` (47,832 detail rows and no stale uncoverable
annotations). Post-gate perlsec, the required 459-assertion web-security test
set, and changed-file syntax/POD checks passed. This verification does not
change the performance conclusion above.

## Required target

The objective is to accelerate every dashboard subroutine using MCE,
FFI::Platypus, Inline::C, XS, SPVM, Memoize, Perl's built-in `class` / `method`
and `field` syntax, and method/subroutine signatures, with a minimum 50x speedup
against Developer Dashboard 5.88. This investigation retains that full target;
it distinguishes measured results from unproven claims. Behavior, security,
output, authentication, and process-order contracts must remain unchanged.

## What the technologies do

`MCE` runs independent work in worker processes or threads; it cannot make an
arbitrary sequential subroutine parallel. `FFI::Platypus` binds typed native
functions and must handle ABI, integer widths, buffers, library lookup, and
platform availability explicitly.

Inline::C compiles embedded C and generates the Perl/XS binding; it is not an
independent native engine to stack on top of XS for extra speed. SPVM compiles
typed code and can bind native libraries, but Perl/SPVM crossings and data
conversion still cost time. `Memoize` applies only when cached results remain
valid for the cache lifetime; filesystem results need invalidation and password
derivations must not be cached. Perl's built-in `class` / `method` / `field`
declarations do not turn existing Perl routines into native code.

## Reproduction and baseline

The source checkout was exercised in an isolated Docker Compose test project.
The original five-run medians for `bin/dashboard version`, `paths`, and `ps1`
were 56.7 ms, 93.3 ms, and 109.5 ms. Profiles showed startup/module loading and
filesystem/environment discovery, not long CPU-bound batches suitable for
generic worker execution. A profiled web test passed 328 assertions, but its
profile is dominated by test harness activity and is not a production-route
benchmark.

NYTProf on the `version` path attributed 18.6 ms inclusive to loading
`Pod::Usage`, although version output does not render usage text. The entrypoint
now loads it only on usage-error paths. Five unprofiled Docker runs after that
change took 51.869, 49.571, 52.637, 48.534, and 46.985 ms (49.571 ms median);
NYTProf then showed `Pod::Usage` absent from the version path. Against the
earlier 56.7 ms median, this is about 1.14x, not 50x. This is a command-specific
measurement, not an application-wide claim.

A follow-up profile showed that this was not the whole startup cost:
`bin/dashboard` eagerly loaded `InternalCLI` before dispatch, which imported
`Platform`, and `PathRegistry` also imported `Platform`. The dashboard module
was then loaded only to read its version scalar, pulling in Handle and
FileRegistry. New red-first tests verified the import contracts and runtime
`%INC` state. The switchboard, PathRegistry, and InternalCLI now defer Platform
until platform-specific operations run; a dependency-light
`Developer::Dashboard::Version` supplies the CLI and public module version.
The regression and release-metadata suites passed 12 and 5,502 assertions in
Docker. After these changes, 15 Docker runs of `dashboard version` measured
33.889–41.006 ms (35.114 ms median), about 1.62x versus the original 56.7 ms
median. NYTProf contains no Platform, InternalCLI, Handle, or FileRegistry
entries for that command. This is a cumulative CLI improvement only and still
falls far short of 50x.

Additional NYTProf traces of the checkout's actual `paths` and `ps1` helper
entrypoints found `Cwd::cwd` reaching `Cwd::_backtick_pwd` and an external
`pwd` process on this Linux Perl build. Thirty-call Docker measurements were
2.939 ms per `Cwd::cwd` call versus 0.003 ms for validating `PWD` against the
current directory's `stat` device/inode. `PathIdentity::current_working_directory`
now returns an absolute `PWD` only when that identity check succeeds, retaining
logical symlink spellings; otherwise it preserves the old `Cwd::cwd` fallback.
The switchboard and all discovered production sites in path, file, ticket,
prompt, action, collector, Docker, update, skill install, folder, indicator,
web, environment, and handle code use the shared function where they previously
called `Cwd::cwd` or `Cwd::getcwd`. A red-first six-assertion test covers a
valid PWD without invoking fallback, a valid logical symlink, and absent,
relative, nonexistent, or different-directory PWD values. After this change,
15 Docker runs of `dashboard version` measured 31.560–37.133 ms (32.287 ms
median), versus 35.114 ms immediately before it and 56.7 ms for the recorded
5.88 baseline. This is approximately 1.76x cumulative, not 50x.

An isolated Dancer/PSGI `/system/status` profile with all account-name
environment variables unset attributed 69.7 ms per request (instrumented,
inclusive) to the status handler. Indicator list/state-root lookup dominated;
the `getpwuid` fallback ran 80 times across 20 requests. A red-first
regression now proves that `PathRegistry::_state_root_user` performs that
fallback once per unchanged environment on a registry instance, while still
noticing changes to any of the four supported environment variables. The
focused Docker test passed all 225 assertions. Repeating that same stripped
environment profile reduced the instrumented figure to 58.3 ms/request and
passwd fallback calls from 80 to 1 (about 33x fewer calls to the helper, but
only about 1.2x for the whole instrumented route). This is an edge-environment
measurement, not a typical-route or uninstrumented latency claim.

The first direct `app.psgi` probe exposed a real startup failure: its prompt
constructor omitted the required indicator store. A red-first Docker test
reproduced the failure; `app.psgi` now builds one `IndicatorStore` and shares
it with `Prompt`. The test loads the actual bootstrap and successfully
requests `/system/status` through its PSGI coderef.

That actual route profile then showed each `indicators_roots` lookup rewriting
the same `runtime.json` state metadata. A red-first regression first failed
because an identical second request resecured and rewrote the same file. The
writer now returns without a write only when `lstat` confirms an owner-owned,
regular, owner-only file with the exact expected JSON. Missing metadata is
recreated; changed content or loose permissions are repaired; symlinks and
non-regular files are refused with an explicit error. In Docker, the focused
PathRegistry test passed 235 assertions and the actual PSGI bootstrap/route
test passed 3 assertions. On the same 20-request actual `app.psgi` route
profile, inclusive status-handler time fell from 2.62 ms/request to 0.616
ms/request (about 4.25x); `_write_state_metadata` fell from 1.13 ms/call to
0.132 ms/call (about 8.6x). These are NYTProf-instrumented figures. An
unprofiled paired ABBA run compared the reconstructed legacy always-write
implementation with the verified writer in the same app process: 80 requests
each, exact status-body parity, 1.044 ms/request versus 0.587 ms/request
(about 1.78x). This comparison isolates the metadata-writer change; it is not
a v5.88 benchmark or proof of the project-wide 50x target.

The next profile of `paths` showed repeated state-root metadata writes from
`PathRegistry::all_paths`: it resolved `state_root` directly, then resolved it
again through the collector and indicator child getters. A red-first regression
test observed three writes; the aggregate now resolves one state root and
derives both child roots from it. The same profile showed the passwd fallback
loading `Platform` on an environment without `USER`/`LOGNAME`; the guarded
`getpwuid` call now stays inside PathRegistry. Tests verify passwd success,
missing-record and exception behavior, and that Platform remains unloaded.
After these changes, 15 Docker runs measured `version` at 31.486 ms median,
`paths` at 71.309 ms, and `ps1` at 83.641 ms. Against the recorded 5.88
baselines, these are approximately 1.80x, 1.31x, and 1.31x respectively. The
`paths` improvement from the immediately previous 77.195 ms median is modest;
these remain command-level observations, not a 50x per-subroutine proof.

Authentication's 210,000-round PBKDF2-HMAC-SHA256 loop was a clear native
boundary candidate. The Perl loop measured 278–300 ms (284 ms median). A single
OpenSSL `PKCS5_PBKDF2_HMAC` call through FFI measured 29.7–31.4 ms (29.9 ms
median), about 9.5x faster with exact digest parity.

## Implemented changes

The Dancer request adapter also had repeated accessor work on every backend
dispatch. A red-first test found 13 calls to acquire the active request, four
PSGI environment reads, and eight header reads (Host was fetched twice).
`_request_args` now captures the request and environment once. The first
paired Docker microbenchmark measured 5.568 versus 3.665 microseconds/call
(1.52x). Inspection of Plack's actual `headers()` implementation showed its
header map is made directly from the standard PSGI `HTTP_*` variables; an
isolated Docker probe confirmed all seven selected header values exactly match
`Plack::Request->header`. A second red-first test guards that equivalence,
explicitly rejects non-hash environments, and verifies the no-argument helper
path. `_request_headers` now reads only the seven fixed environment keys; the
request path still obtains one request, one environment, and one body, while
making zero header accessor calls. Five alternating Docker pairs of 200,000
calls each preserved canonical JSON payload parity and measured 5.167 versus
2.578 microseconds/call (2.00x). This is a single-helper microbenchmark, not an
end-to-end route gain or evidence of 50x acceleration across every routine.

`Developer::Dashboard::Crypto::PBKDF2` lazily resolves OpenSSL through
`FFI::CheckLib` and calls `PKCS5_PBKDF2_HMAC`. FFI::Platypus and FFI::CheckLib
are optional runtime recommendations, matching the tested Perl fallback;
missing FFI module files mark native acceleration unavailable, while errors
inside installed modules remain explicit. Authentication retains its
algorithm, salt, 210,000 rounds, key length, and stored hex format. Unsupported
byte inputs or missing compatible `libcrypto` use the existing Perl code;
native-call and output-buffer failures remain visible.

The entrypoint no longer eagerly imports `Pod::Usage`; the two usage-error
branches load it just before rendering. The CLI smoke test failed on this
contract before the change, then passed all 1,029 assertions in Docker after
the change.

## New architecture experiment: resident command context

The user asked for another route to the 50x target. A Docker experiment tested
whether reusing a warm Perl runtime and its validated path/configuration context
can remove enough repeated startup and discovery work. Ten fresh executions
of the current `dashboard paths -o json` command averaged 84.412 ms each. The
same real handler, run in a resident process while reconstructing its aliases
on every request, averaged 5.636 ms with byte-for-byte output parity. Reusing
the already-built path/config context, while still recomputing `all_paths` and
JSON on each request, averaged 1.018 ms. A full CLI result and the reused
context result matched exactly (981 bytes in this test runtime), for an
experiment-level 82.9x reduction versus the fresh CLI path.

That is a promising measured route to 50x for repeated path-list requests, not
a production claim yet. A second disposable Docker prototype added a compiled
C client and a resident Perl Unix-domain-socket server. Each measured request
included a separate C client process launch, socket connect/write/read/close,
and consuming the server response; 100 requests averaged 0.514 ms each. The
returned bytes matched `dashboard paths -o json` exactly. Compared with the
84.412 ms fresh CLI measurement, this prototype delivered an experiment-level
164x response reduction. Server startup and context construction are one-time
costs and were not included in the per-request figure.

These measurements are promising for repeated path-list requests, not a
production claim yet: they do not include per-request invalidation of
environment, cwd, layered config, new/deleted skills, and user-provided
`Folder.pm` methods. The alias reload cost itself was about 4.4 ms combined
(3.592 ms for configured aliases and 0.851 ms for skill Folder aliases) in the
test environment. Caching arbitrary Folder method results is not safe because
those methods can be user-defined and dynamic. The next experiment must
include a freshness protocol and exact output parity after mutations before
this can be considered an implementation candidate. Client transport is no
longer an unmeasured part of the path-list prototype.

A synthetic Docker mutation test found that integer-second `stat` timestamps
can miss a skill directory created in the same second. The prototype watcher
was changed to use `Time::HiRes::stat`; it then detected same-second config
replacement, new top-level and nested skills, a newly-created project runtime
layer, and an environment-value change. This establishes those specific
invalidation signals, not complete invalidation correctness: deletion, skill
disable markers, linked/symlinked layers, arbitrary files read by user
`Folder.pm`, cross-platform timestamp behavior, and end-to-end refreshed output
parity still need tests. The high-resolution watcher cost has not yet been
included in the 0.514 ms client measurement.

### PathRegistry freshness precondition for a resident cache (2026-10-14)

Before reusing path inventory across requests, the real registry must prove it
does not retain request-local skill listings or disable state. A freshness
regression was added to `t/97-pathregistry-coverage.t` for a single
PathRegistry instance: after an inventory scope ends, a later lookup must see
a newly created skill, a newly created `.disabled` marker, removal of that
marker, and deletion of the skill directory. The focused Docker test passed
all 293 assertions. The same Config and PathRegistry objects also read
replacement bytes from a skill config file and discover a newly installed
skill; a reused Config object followed a runtime symlink after it was
retargeted. This verifies current request-boundary freshness for those cases;
it does not validate a persistent process cache, arbitrary files consulted by
`Folder.pm`, or any 50× speedup. Those remain requirements for the resident
prototype.

The path CLI also loads user `Folder.pm` providers afresh and invokes their
listed methods for each operation. A Docker regression in
`t/90-cli-paths-coverage.t` calls the same provider through the same paths
object, changes an environment value read by its method, and confirms the next
enumeration returns the new target after its sidecar file, outside the skill
tree, is changed (33 top-level tests passed). This proves that dynamic
provider results can depend on files a watcher limited to skill/config roots
cannot observe, so method results cannot safely be treated as immutable cache
entries.

### Scope runtime-layer memoization to one operation (2026-10-14)

The red-first Docker test in `t/97-pathregistry-coverage.t` reproduced a
stale-layer bug: one PathRegistry object queried `runtime_layers`, then failed
to see a project `.developer-dashboard` directory created afterward. It also
reproduced stale inclusion after removal. The cause was a cwd-keyed
object-lifetime `_memoize` entry even though runtime roots depend on mutable
filesystem topology. `runtime_layers` now recomputes when no operation scope is
active; `all_paths` and `run_paths_command` retain only an operation-local
result. The same-object create/remove test and bounded repeated-read check pass
in Docker (298 assertions in `t/97-pathregistry-coverage.t`). This restores
freshness and preserves local reuse, but is not a 50× performance claim; the
resident-server design still needs its own invalidation and parity benchmark.

The full Docker suite then passed 265 files / 23,392 tests. A new clean
`script/coverage-gate` run passed 265 files / 23,330 tests and measured 100.0%
statement, branch, condition, and subroutine coverage across `lib/` (47,381
detail rows). The required web-update, static-file, and SSL security tests
passed as well. These are regression and coverage results; they do not show
that every subroutine is 50× faster.

### Matched per-routine v5.88 profile (2026-10-14)

To get a routine-level comparison rather than reuse historical command
medians, the checked-in v5.88 source at `a8d1fa2a4064640baba7a8ed7339462d9d3c3060`
and current helper were profiled with the same Docker Perl, cwd, HOME, and
empty runtime state. `paths -o json` output matched byte-for-byte. NYTProf
reported 59.4 ms for the v5.88 helper and 47.9 ms for the current helper
(1.24× overall); instrumentation time is not production latency. For
`Developer::Dashboard::PathRegistry::_path_identity`, exclusive time moved
from 2.37 ms over 133 calls to 90 μs over 103 calls. Per-call exclusive time
is approximately 17.8 μs versus 0.87 μs, around 20×, not 50×. The current
profile's other notable path routines also remain below the target. This
concrete profile covers only one command's call graph and is not evidence for
all 1,648 current named routines or anonymous closures.

To avoid paying for a recursive high-resolution scan on every request, a
separate Linux Docker prototype used libc `inotify` through FFI to watch 401
fixture directories. Polling the nonblocking event descriptor when no files
changed averaged 0.0010 ms/request; installing those 401 watches averaged
0.532 ms in a separate setup benchmark. It detected both a config-file
replacement and a newly created nested skill directory. A separate
high-resolution stat prototype scanning all 551 fixture entries took
6.755 ms/request; checking the cached list of 401 directory paths took 0.703
ms/request. This supports an
event-driven invalidation design on Linux, where the daemon performs a full
rescan only after a filesystem event. It does not establish safe production
watch installation/recovery, event-overflow handling, cross-platform watcher
support, or end-to-end command performance with the watcher enabled. The
0.0010 ms watcher probe must not be added arithmetically to the separate 0.514
ms socket result as though they were a combined benchmark.

The route is specifically a long-lived command runtime with request-scoped
environment/cwd, cached immutable module/config discovery, and explicit
invalidation; it is not indiscriminate `Memoize` of mutable filesystem data.
The existing CLI remains unchanged while this architecture is evaluated.

### Cold-process launch floor recheck (2026-10-14)

To check whether further in-process tuning can satisfy a 50x public-command
target, an alternating Docker control launched 25 fresh `bin/dashboard
version` processes and 25 fresh bare Perl processes using the same interpreter.
The medians were 32.424 ms and 1.263 ms respectively (dashboard range
30.815–39.976 ms; Perl range 1.034–1.427 ms). The recorded v5.88 dashboard
median is 56.7 ms, so 50x would require 1.134 ms total. Even the bare Perl
launch median exceeds that budget before command code runs. This falsifies a
50x cold-process `version` result under this runtime model; a resident/native
entry path is required even for that command-level target. It does not prove
or replace the requested per-subroutine measurements, and the resident route
still needs safe mutation invalidation and complete output-parity evidence.

## Security verification notes

The container's Perl 5.40.1 `perlsec` guidance was reviewed with `pod2text`
after the focused test gate. The current FFI adapter validates scalar inputs,
rejects byte strings it cannot safely downgrade, bounds lengths and iteration
counts to OpenSSL's signed-int ABI, retains the buffers through the synchronous
native call, and surfaces native failures. The adapter introduces no shell
execution or user-controlled executable/path operation. The mandated web
security trio passed in Docker: 3 files / 459 tests. The required repository
security scans have now been run; they found forbidden-library references only
in guard tests/docs plus the stale HTTP::Tiny manifest entry, which is now
removed. The full ASVS V1–V14 applicability review remains outstanding, as do
packaging and release gates.

## Requested-technology evidence and limits

### Current 50-skill `paths` profile (2026-10-13)

A fresh Docker NYTProf run of `paths -o json` used 50 installed skills, each
with a valid path-alias config; the output was checked to include the final
skill alias. The current checkout library was first in `@INC`. The request took
15.1 ms inclusive under profiling. `PathRegistry::nested_skill_entries` ran
once (2.27 ms inclusive); `Config::_skill_path_alias_entries` took 3.93 ms
inclusive across 50 skill config reads. `PathRegistry::_ancestor_runtime_layers`
ran 16 times, 15 calls originating in `runtime_layer_root_for`, for 1.00 ms
inclusive total. These are instrumented figures, not end-to-end wall-clock
benchmarks. The repeated ancestry discovery is a possible optimization target,
but caching it across security checks could hide newly created runtime layers;
no cache was introduced without a request-scoped freshness proof. This profile
does not change the 50x-per-subroutine status.

### Refreshed 50-skill `paths` profile after inventory changes (2026-10-14)

A new Docker NYTProf trace ran the checked-out `share/private-cli/paths -o
json` against 50 synthetic installed skills, each with one valid
`path_aliases` config; the 2,969-byte response included the generated aliases.
The largest measured line totals were 3.341 ms for the PathIdentity import
boundary, 2.937 ms for Config's JSON import boundary, and 2.032 ms across 50
config-file path constructions. The 50 top-level marker checks totaled
0.520 ms; 100 config JSON decode lines totaled 0.285 ms. These are
NYTProf-instrumented exclusive line timings, not unprofiled wall-clock
latencies, and include one-time module initialization. They point away from
the just-optimized marker check as the next target. The next candidate to
evaluate is whether parallel config loading with MCE becomes beneficial at
larger skill counts; the existing 50-file benchmark found MCE overhead larger
than the work. The 15-pair scaling run preserved exact order and included cold
worker startup for each count, but excluded MCE module import, so cold-path
cost is understated. Cold ratios versus serial were 0.21x, 0.90x, 0.97x, and
0.89x for 50/250/1,000/5,000 files. Warm ratios were 0.92x, 1.18x, 1.13x,
and 1.18x. This does not justify adding MCE to the current path command.

| Approach | Evidence | Current result |
| --- | --- | --- |
| NYTProf | Profiles of CLI paths and `t/90-cli-paths-coverage.t` | Used to identify startup/module-load work and path routines; test profiles include harness costs. |
| MCE | Synthetic jobs and on-disk skill-config scaling | Ten synthetic independent 300 ms jobs: 3.001 s sequential versus 0.906 s with four workers. A 15-pair ordered-parity benchmark measured 50/250/1,000/5,000 configs: cold worker-startup ratios versus serial were 0.21x / 0.90x / 0.97x / 0.89x; warmed ratios were 0.92x / 1.18x / 1.13x / 1.18x. MCE module import was excluded. Cold one-shot MCE was slower at all tested sizes, while warmed gains stayed below 1.2x; no production integration is justified. |
| FFI::Platypus | OpenSSL PBKDF2 | Implemented; 284 ms Perl median versus 29.9 ms FFI median, about 9.5x for that routine. |
| Inline::C / XS | Inline wrapper invoking the same OpenSSL API; Inline generates XS glue | Digest parity passed. Warmed averages: FFI 32.4 ms, Inline::C/XS 31.0 ms. About 4% difference, not an additional 50x; no duplicate backend retained. |
| SPVM | Boundary-call probe and benchmark-only PBKDF2 loop compiled wholly inside SPVM | The boundary-call probe preserved 30,000-iteration digest parity but was 0.22x the `Digest::SHA` XS speed. A reproducible five-run Docker benchmark then compared the complete 210,000-round PBKDF2 loop: output matched the Perl reference exactly, but SPVM took 522.992 ms versus Perl's 284.853 ms (0.54x); SPVM load/compile added 48.842 ms outside the timed median. The full-loop fixture is slower and remains benchmark-only; no SPVM backend is retained. |
| Memoize | Reviewed against profiles and current PathRegistry caches | No evidence justifies caching mutable filesystem results or secrets. Existing registry caches use explicit object/runtime keys. |
| Built-in class/method/field and signatures | Container Perl is 5.40.1 | No speed evidence for a repository-wide migration. `class` is experimental and emits warnings on this runtime, conflicting with warnings-as-errors. Converting packages and APIs is not a mechanical optimization. |

### Tiny accessor versus native-call boundary (2026-10-14)

A three-second Docker `Benchmark` comparison checked whether the native FFI
boundary can accelerate a minimal accessor-shaped operation. The Perl
`PathRegistry::home` method produced 12.43 million calls/second; FFI
`getenv("HOME")` produced 5.58 million calls/second (about 2.23× slower),
with the returned strings checked for exact equality before timing. This is a
boundary-cost probe, not an implementation comparison of the two methods:
the Perl accessor returns a constructor-captured field while `getenv` reads
process environment. It demonstrates that wrapping trivial operations in FFI
does not inherently speed them up; the result cannot substitute for
per-subroutine measurements.

### Aggregate-scoped path identity reuse (2026-10-14)

The current NYTProf trace showed repeated path normalization while building
the aggregate `all_paths` result. A red-first regression failed before the
change when two identical paths in an explicit cache scope caused two
`PathIdentity::_path_identity` executions; it also verified that calls after
the scope remain fresh and that `all_paths` opens the scope itself. The
implementation now memoizes exact input spellings only while `all_paths` is
running, then discards the hash on return. The focused Docker test passed all
281 assertions. A 51-pair alternating Docker benchmark preserved exact
1,171-byte JSON output and measured 0.576 ms without reuse versus 0.424 ms with
reuse (1.36x for the aggregate). This is a sub-millisecond, aggregate-only
gain, not a whole-command or all-subroutine result. The full Docker gate must be
rerun after this source change.

## Alternative compiler route evaluated

The CPAN `B::C` backend emits C representations of Perl's internal runtime
structures to avoid reparsing program source at startup; its own documentation
states that this does not improve program runtime execution speed. `B::CC`
translates Perl ops to C but documents semantic differences in loop control,
range context, and arithmetic, and is not a behavior-preserving whole-project
optimization path. Neither satisfies the per-subroutine 50x requirement.

`XS::JIT` was checked as a more recent alternative. It compiles supplied C
functions into XS at runtime; it does not translate existing Perl subs. Its
published example reports 1.36x runtime improvement over Inline::C for a
synthetic loop, not 50x, and still requires hand-written C implementations.
No compiler dependency or generated native artifact is added to the product.
These alternatives reinforce that a resident runtime is currently the only
measured route above 50x for a repeated real CLI request; the production
freshness and compatibility work remains open.

The synthetic MCE readiness model is not the application: collector startup
checks each process before starting the next. Parallel startup could start
later processes before detecting an earlier failure, changing rollback and
fail-fast behavior.

The v5.88 `HEAD` tree contains 1,624 named `sub` declaration lines under
`lib/Developer/Dashboard`; the current worktree contains 1,648 by the same
source-line count. This is not an AST inventory and excludes anonymous
closures. A literal “50x for every subroutine” claim requires a reproducible
input and a before/after benchmark for each one, including getters, mutators,
filesystem operations, process/network waits, and error paths. Existing
profiles do not establish such a claim; applying parallelism, caching, or
native boundaries indiscriminately would add overhead or change semantics for
many routines.

There is a measured startup floor too: a bare `perl -e 1` process took
1.032–1.268 ms in the same Docker image. Fifty times faster than the original
56.7 ms version-command median would require about 1.134 ms total, leaving only
about 0.1 ms above the fastest bare interpreter launch for the whole command.
Current `dashboard version` measures 35.114 ms, so the requested 50x result is
not achieved. This does not disprove 50x for a selected CPU-heavy routine, but
PBKDF2 currently shows 9.5x and the objective requires every routine.

## Docker verification

### Fresh-process recheck (2026-10-12)

After two warm-up runs per command, 15 measured executions in the isolated
Docker benchmark service completed successfully. Fresh-process medians were
36.379 ms for `dashboard version`, 82.020 ms for `dashboard paths -o json`,
and 90.429 ms for `dashboard ps1`. Every measured command exit status was
checked; stdout was discarded only to keep terminal rendering out of the
timing. This confirms that the current CLI remains far from a 50x improvement
against the recorded 5.88 baselines. The earlier resident/socket figures are
separate prototypes and must not be presented as current production timings.

### Fresh cold-start replay (2026-10-13)

The same three checkout commands were measured again inside the Docker bench
service under a disposable `HOME`, with two warm-ups and ten timed executions
per command. Exit status was checked for every run and output was captured so
terminal rendering did not affect the measurement. Median process times were
33.622 ms for `version`, 77.291 ms for `paths -o json`, and 82.907 ms for
`ps1 --no-indicators`. Against the recorded 5.88 medians (56.7, 93.3, and
109.5 ms), the current results are about 1.69x, 1.21x, and 1.32x faster.
Variation from the prior run does not establish any new optimization; the
measured checkout remains far below the 50x objective. This benchmark is
separate from the experimental resident-runtime request measurements below.

### Resume verification (2026-10-13)

After the configuration issue was cleared, the three cold-start commands were
rerun in a fresh D2-managed bench container with a disposable home, two warmups,
and ten measured executions per command. Every process exit status was checked
and child stdout was redirected so output volume did not distort timing. Median
times were 34.328 ms (`version`), 80.291 ms (`paths -o json`), and 80.052 ms
(`ps1 --no-indicators`). Against the recorded v5.88 medians (56.7, 93.3, and
109.5 ms), that is approximately 1.65x, 1.16x, and 1.37x faster. The refreshed
measurements confirm the current cold-start path still misses the requested
50x target; no resident-runtime prototype numbers are substituted for these
production entrypoint timings.

### Switchboard import refinement (2026-10-13)

The switchboard imported `Config` without using it and loaded `IO::Handle`,
`IO::Select`, `IPC::Open3`, and `Symbol` before knowing whether any executable
hook needed them. Red-first Docker regressions failed against all five eager
imports. The unused import was removed and hook dependencies are now required
only inside hook execution. The focused 21-test lazy-load suite and the
1,029-assertion CLI smoke suite passed in Docker, including hook
ordering/streaming behavior. A paired 25-run Docker microbenchmark used the
same `do`-based command harness for both cases; the control preloaded all five
modules and the candidate left them unloaded for `version`. Medians were
33.104 ms and 31.520 ms respectively (about 1.05x). This isolates a small
startup cost; it is not a substitute for the requested 50x result or the cold
`bin/dashboard` process benchmark.

### Path CLI deferred imports (2026-10-13)

The current checkout's NYTProf profile for `path project-root` showed import
initializers for `Developer::Dashboard::Config` and
`Developer::Dashboard::FileRegistry` even though that verb only needs the path
registry. A red-first subprocess assertion in `t/652-performance-lazy-loading.t`
failed because both modules appeared in `%INC` before dispatch. The path CLI
now requires them only for verbs that read or modify configured aliases;
`path project-root` and `path locate` skip them. The focused lazy-load and path
CLI suites passed 55 tests in Docker. An alternating 25-run fresh-Perl-process
benchmark of `Developer::Dashboard::CLI::Paths::run_paths_command(path,
project-root)` compared the candidate to a control that preloaded both
modules. Medians were 30.372 ms and 36.041 ms respectively (about 1.19x).
Captured output and stderr checks remained clean. This is a command-specific
startup improvement; it does not establish a 50x speedup for the path CLI,
much less for all subroutines.

### Path option-parser deferral (2026-10-13)

A corrected NYTProf trace called the checked-out path dispatcher directly for
`path project-root`. It showed `Getopt::Long` initialization on that path even
though this verb does not parse flags. A red-first subprocess test in
`t/652-performance-lazy-loading.t` failed because `Getopt/Long.pm` was in
`%INC`; the path dispatcher now loads the parser through a shared helper only
when an option-bearing verb uses it. Docker verification passed the lazy-load
and path suites (57 tests). An alternating 25-run process benchmark compared
the path dispatcher to an otherwise identical process that preloaded
`Getopt::Long`: 28.863 ms versus 32.937 ms (about 1.14x). Output and stderr
were captured, and all child exit statuses were checked. This measurement is
limited to `path project-root`, not a claim for other routines.

### Full coverage recheck (2026-10-13)

After the lazy path imports and documentation updates, the canonical coverage
gate ran in the isolated D2 container with a fresh database under `/tmp`. It
passed all 263 test files and 23,532 tests. The library coverage report showed
100.0% statement, branch, condition, and subroutine coverage across `lib/`
(46,890 detail rows, no stale uncoverable annotations). Environment/tooling
checks emitted explicit skips. This confirms the current coverage gate only;
it does not close the 50x-per-subroutine objective or the remaining security,
integration, packaging, image, and delivery gates.

### Cumulative project-root benchmark (2026-10-13)

To measure the combined path changes against their prior setup behavior, a
Docker ABBA harness launched 20 fresh Perl processes in each mode. Both modes
built the same path registry and called the same project-root handler; the
control also loaded `Getopt::Long`, constructed `FileRegistry` and `Config`,
and produced byte-identical captured output. The current path averaged 26.852
ms median; the pre-change setup control averaged 35.489 ms (about 1.32x). This
is a reproducible, command-specific gain; it is not a comparison of every
subroutine or proof of the requested 50x target.

### Rejected PathRegistry import-deferral experiment (2026-10-13)

NYTProf showed one-time module initializers on the lightweight path command, so
a red-first test briefly checked whether `PathRegistry` could defer
`Digest::MD5`, `Errno`, `File::Path`, `Fcntl`, and `Scalar::Util`. Focused tests
passed after the imports were moved to their call sites, but an interleaved
Docker benchmark did not show a speed gain: six 25-process batches measured a
median of 358.5 ms per 25 candidate runs and 360 ms per 25 control runs, about
1.00x. Several modules were already loaded transitively by other path-command
dependencies. The code change and its temporary test assertions were removed;
this experiment is recorded to avoid treating import deferral without an
observed end-to-end gain as progress toward the 50x target.

### Canonical path-output option parser (2026-10-13)

A fresh NYTProf trace included about 5.2 ms in the option helper for
`paths -o json`, but profiling alone could not distinguish parser-module
initialization from profiler overhead. A red-first Docker subprocess test
required the canonical output-option forms to avoid loading Getopt::Long; the
complete path inventory action now does so, while unrecognized and abbreviated
syntax falls back to Getopt::Long. Docker tests verify the supported spellings,
positional argument preservation, fallback parsing, clean diagnostics, and
byte-identical output for the complete action. An in-process benchmark of
100,000 parses measured 130.4 ms with the local parser and 1,604.1 ms with
Getopt::Long (about 12.3x for parsing itself). A paired 20-cycle Docker ABBA
comparison later measured `paths -o json` at 67.578 ms median with the
canonical fast parser versus 72.113 ms through the equivalent Getopt::Long
abbreviation fallback (about 1.07x), with exact 981-byte output parity. This
is a modest command-specific gain, not evidence of the 50x all-subroutine
objective.

### Current path-helper NYTProf map (2026-10-12)

The public switchboard intentionally `exec`s the staged helper, so profiling
`bin/dashboard` as one NYTProf process leaves an incomplete profile at that
handoff. Profiling the source helper entrypoint `share/private-cli/paths`
directly produced a complete trace. In the current runtime, path discovery
iterated 303 runtime-root entries, checked 97 skill disable markers, queued 32
top-level skill roots, and examined 152 nested skill directories. The
configuration helper also loaded JSON support twice through separate
import-time paths. Those are call-count observations from the trace, not
standalone time measurements; NYTProf instrumentation changes wall time.

The skill-directory scan is behaviorally sensitive: path listing dynamically
loads user-provided `Folder.pm` files and calls their methods, so caching
method results without a complete dependency/invalidation contract could make
aliases stale or change user code behavior. This is why the resident-runtime
experiment must separate safe module/runtime reuse from unsafe caching of
dynamic skill results.

A red-first micro-optimization experiment also memoized the derived
`skills_roots` list per PathRegistry runtime-root set. Its focused contract
passed, but alternating in-process Docker batches were noisy and did not
establish a stable end-to-end benefit; the implementation and test were
removed. Rebuilding this small list is not currently justified as a retained
optimization. The larger measured opportunity remains avoiding cold Perl
startup, while preserving per-request filesystem and user-module semantics.

### Current request profile (2026-10-12)

A fresh NYTProf run of the real `share/private-cli/paths -o json` handler in the
isolated Docker bench executed 20,899 statements and 10,600 subroutine calls
across 41 source files. The profiled request took 60.8 ms inclusive / 52.5 ms
inside the measured program body; this is an instrumented trace, not an
unprofiled latency measurement. `PathRegistry.pm` accounted for 14.1 ms
exclusive (27.4% of measured program time), followed by `Config.pm` at 4.72 ms
(9.1%) and `CLI/Paths.pm` at 2.72 ms (5.3%). Its most-called material costs
included 74 `_same_or_descendant_path` calls at 2.03 ms exclusive / 2.72 ms
inclusive, 804 directory-iteration opcodes at 1.75 ms, and 167
`validated_path_segments` calls at 1.63 ms. Several one-time import initializers
also cost 2–4 ms each. These values show both cold-load and repeated filesystem
work; they must not be added to the separate resident-runtime prototype
measurements. The resident path must preserve these checks or prove equivalent
behavior with mutation tests before bypassing them.

Focused command:

```sh
d2 docker compose --service bench -f /tmp/d2-problem48-bench.yml \
  --project-name dd-problem48-bench run --rm bench sh -c \
  'export PERL5LIB=/bench-perl/lib/perl5/x86_64-linux-gnu-thread-multi:/bench-perl/lib/perl5; cd /checkout; prove -lv t/651-crypto-pbkdf2-ffi.t t/82-auth-coverage.t t/09-runtime-manager.t t/15-release-metadata.t'
```

The focused functional/auth/runtime/release-metadata run passed 6,010 tests
across four files in Docker. `t/05-cli-smoke.t` passed 1,029 tests after the
lazy-load optimization. The temporary Compose file and dependency mount are
investigation fixtures only; neither is part of the distribution.

### Optional-FFI coverage-gate correction (2026-10-13)

The full run exposed a test-harness failure when the optional FFI modules were
not on the Docker image's default `@INC`: the test skipped its native checks,
then unconditionally required `FFI::CheckLib` for a later mock. The fixture now
skips only checks that need an absent module; module initialization failures
remain visible, and missing-module fallback coverage still runs. Focused Docker
runs passed both without the optional module mount and with the native test
modules mounted. The final stable-tree coverage gate passed 263 test files /
23,539 tests; all four `lib/` metrics are 100.0% (46,943 detail rows, no stale
uncoverable annotations). This closes the current coverage gap only; the cold
CLI remains around 1.2–1.8x versus v5.88, far below the 50x target.

## Current status

The latest full Docker coverage gate, rerun after the aggregate-scoped identity
change (2026-10-14), passed 264 files / 23,292 tests. The canonical four-metric
report is 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (47,360 detail rows; no stale uncoverable annotations). Nine
environment/tooling-dependent tests were skipped with explicit reasons:
cpan-audit, operator-local tool specs, Windows QEMU, two browser-loopback
checks, CPANTS kwalitee, Test::Pod, a Docker-daemon guard, and the optional
SPVM fixture. The SPVM fixture separately passed all five assertions in the
benchmark container with SPVM installed. The required post-gate `perldoc
perlsec` check also completed successfully in the same scoped Docker Compose
project.

The request-scoped installed-skill directory inventory change is covered by
that gate; the matched profile and narrow benchmark above show only a 1.29x
gain for the measured paired-inventory operation. Earlier evidence includes
about 9.5x for the PBKDF2 routine, but no evidence establishes 50x for every
subroutine or for the whole dashboard. The Problem 48 target therefore remains
open. Full ASVS 5.0 applicability review, integration-plan completion,
dependency/release checks, aligned release metadata, clean/build,
blank-container tarball installation, Docker image build, final artifact audit,
and the remaining release workflow gates have not been completed for this
problem.

### Exact-path ancestry fast path (2026-10-12)

A red-first `t/195-pathidentity-coverage.t` regression found that
`_same_or_descendant_path($path, $path, ...)` performed two `abs_path` calls
for identical nonempty strings. The helper now returns true before either
filesystem lookup after validating the required mode argument. Docker showed
the regression fail first with two calls, then pass with zero, while different
string spellings continue through canonical, symlink-aware resolution. This
removes redundant work for this exact hot-path case; it is not a measured 50×
result or a material whole-command timing claim.

### Runtime-layer ancestry stop-path reuse (2026-10-13)

The measured `paths` trace attributed 2.03 ms exclusive time to 74 calls of
`_same_or_descendant_path`, with repeated path canonicalization in the layer
walk among the candidates for reduction. A red-first `t/97-pathregistry-coverage.t`
instrumentation test observed three calls through `_path_identity` for the
project stop path. Hoisting that path's canonical identity and taking an exact
string-equality exit reduced the count to one; the test failed at three before
the hoist and at two before the exact-match fast path, then passed at one.
This demonstrates fewer filesystem canonicalization calls for that fixture,
not a measured wall-clock ratio or a 50x result. Symlink-equivalent but
differently-spelled paths still use canonical identity comparison.

### Verification refresh (2026-10-13)

Inside the isolated Docker bench, two warm-ups and ten measured cold starts per
command yielded medians of 33.622 ms (`version`), 77.291 ms (`paths -o json`),
and 82.907 ms (`ps1 --no-indicators`). Relative to the recorded v5.88 baseline
medians (56.7, 93.3, 109.5 ms), these are 1.69x, 1.21x, and 1.32x. The full
non-instrumented suite passed 263 files / 23,556 tests after enabling the
documented Compose init reaper and dropping DAC bypass capabilities. The
coverage gate then passed twice; the clean second run began with a clean
database deletion and passed 263 files / 23,494 tests with all four `lib/`
metrics at 100.0% and 46,837 detail rows, without stale uncoverable
annotations. Seven platform/tool-dependent files
skipped with reasons. The ticket-only environment was kept free of the
workspace-only UTF-8 locale after the full suite exposed that compatibility
regression. These gates improve confidence in the current checkout but do not
close the stated 50x target or the remaining release/security/integration
gates.

### Built-in signature and class-field microbenchmarks (2026-10-13)

To validate whether modern Perl syntax itself can close the performance gap,
an isolated D2 Docker container (Perl 5.40.1) ran parity-checked, alternating
benchmarks with 20 cycles of one million calls per variant. A closure using
`feature 'signatures'` was statistically indistinguishable from the equivalent
manual `@_` unpacking: medians were 0.094025 s and 0.094165 s (1.001x). An
experimental built-in `class` with a `field :param` and `method` getter was
slower than the same hash-backed Perl getter: 0.149127 s versus 0.125507 s
(0.842x legacy/class ratio). Both produced identical results. The earlier
single-batch signature result suggesting a 1.35x gain was not repeatable and
is superseded by this alternating run. No syntax migration is justified as a
performance optimization by these measurements; the `class` migration would
also require resolving the existing experimental-feature and compatibility
constraints. These microbenchmarks do not change the all-routine 50x status.

### Prompt capture-module deferral (2026-10-13)

The prompt dependency path showed `Capture::Tiny` was loaded on ordinary
prompt startup even though prompt-only indicator refresh returns before
running the Git capture code, and tmux capture is guarded by `TMUX`. A red-first
Docker regression put a stub `Capture::Tiny` earlier in `@INC` that dies when
loaded; ordinary `dashboard ps1 --no-indicators` failed on that import. The
prompt helper now requires it only for tmux ticket lookup, and
`IndicatorStore` requires it only after the prompt-only return, before a full
project/Git refresh. The prompt loader, CLI smoke, and IndicatorStore suites
passed 1,322 tests in Docker, including existing tmux and Git behavior tests.
An alternating 25-cycle fresh-process comparison of the public command
measured a 71.498 ms median with lazy loading and 78.034 ms with
`Capture::Tiny` force-loaded via `PERL5OPT` (about 1.09x). This is an observed
prompt-command gain, not a 50x result across all routines.

### Path-only Config view for prompt and path CLI (2026-10-13)

The prompt helper and path CLI created a `FileRegistry` solely to construct
`Config`. Inspection showed these configuration reads and path-alias
operations resolve via `PathRegistry`; `Config` does not access its `files`
member. A red-first Docker regression blocked `FileRegistry` and failed on
`dashboard paths -o json`. `Config->for_path_config` now returns a path-bound
view without importing or constructing `FileRegistry`; both the prompt and
path CLI use it. Focused prompt-loader, Config, and path CLI Docker tests passed
361 assertions, including collector/alias parity and missing-path validation.
An alternating 25-cycle fresh-process comparison measured
`dashboard paths -o json` at 64.636 ms with `FileRegistry` unloaded and
72.077 ms with its module force-loaded (about 1.12x). That control isolates
module-load cost rather than reproducing the complete old implementation. The
result is command-specific and far short of the all-subroutine 50x target.

The first full Docker coverage run found one stale test double in
`t/43-explicit-coverage-qa.t`: it stubbed `Config->new` but not the new
`Config->for_path_config` constructor. The fixture now supplies the matching
path-config stub. The complete Docker gate then passed 263 files / 23,544 tests;
all four `lib/` metrics are 100.0% (46,954 detail rows, no stale uncoverable
annotations). The container's Perl 5.40.1 `perlsec` documentation was run and
reviewed after the gate. This coverage and security review do not establish the
50x-per-subroutine target, which remains open.

### Paths helper library-root startup (2026-10-13)

The warm NYTProf HTML profile still placed several milliseconds in module
initialization, including `FindBin` on the short `paths` helper. The public
switchboard already overwrites and passes `DEVELOPER_DASHBOARD_REPO_LIB` before
execing a private helper. A red-first subprocess assertion failed because
`share/private-cli/paths` imported `FindBin` even when that path was present.
The helper now adds the supplied library root directly and requires FindBin
only for standalone fallback execution. Docker regressions verify no FindBin
load on the switchboard path, working fallback behavior, no warnings, and
byte-identical JSON output. An alternating 100-pair cold-helper-process
benchmark measured 26.963 ms with the FindBin fallback and 24.782 ms with the
supplied root (about 1.09x). This is a helper-process microbenchmark, not an
end-to-end public-command result or a 50x claim.

### Final coverage and Perl security recheck (2026-10-13)

After the paths-helper change and the `t/15-release-metadata.t` wording
correction, the canonical Docker coverage gate passed 263 files / 23,551 tests.
All four `lib/` metrics are 100.0% (46,954 detail rows, no stale uncoverable
annotations). `perldoc perlsec` was run after this final gate. Optional tooling,
browser-loopback, QEMU, and Docker-daemon checks reported explicit skips; those
skipped checks are not represented as executed. The 50x-per-subroutine goal and
integration, packaging, image-build, and delivery gates remain open.

### Prompt helper library-root startup (2026-10-13)

NYTProf placed about 2.4 ms inclusive in FindBin initialization during a
`ps1 --no-indicators` helper run. The public switchboard already provides the
repository library path, so a red-first Docker regression verified that the
prompt helper can use it directly while preserving its standalone FindBin
fallback and prompt output (apart from the live timestamp). An alternating
25-pair cold-helper benchmark measured 33.364 ms with the supplied path and
33.671 ms with the fallback (about 1.01x). This confirms output parity and a
small dispatch-path saving, not a meaningful overall speedup or progress to
the 50x-per-subroutine requirement.

### Prompt option parser startup (2026-10-13)

The same NYTProf profile placed about 0.9 ms exclusive in Getopt::Long
initialization, plus time in its callbacks and import machinery. A red-first
Docker assertion confirmed that the prompt helper loaded Getopt::Long even for
the canonical flags emitted by its generated shell bootstrap. The helper now
parses exact canonical prompt options locally and requires Getopt::Long only
for unsupported or abbreviated forms. Docker tests cover string, integer,
boolean, invalid, and abbreviated input while checking output and warnings.
Alternating 40-pair cold-process medians were 29.338 ms on the canonical path
and 33.174 ms with Getopt::Long preloaded (about 1.13x). This control measures
module initialization avoided by the canonical path, not a 50x command or
routine speedup.

An end-to-end public-command check then ran
`bin/dashboard ps1 --no-indicators --cwd /` in 30 alternating pairs with a
disposable home. Median wall times were
65.535 ms on the canonical path and 72.307 ms with Getopt::Long preloaded via
`PERL5OPT` (about 1.10x), with successful exit status each time. This public
measurement confirms the module-load reduction survives switchboard dispatch;
it is still a small command-specific gain, not 50x or evidence for every
subroutine.

### Batched installed-skill layer discovery (2026-10-13)

A preliminary `ps1` NYTProf trace in the disposable bench container (its image
HOME, not a hermetic skill fixture; Compose did not mount the host home) showed
`_skill_config_entries` resolving each of 30 installed skills with a separate
`skill_layers` scan; `runtime_roots` was called 40 times in that path. The
synthetic benchmark below uses its own temporary home.
`PathRegistry::installed_skill_entries` now groups skill roots and all of each
skill's layers in one inventory pass, and Config uses it for both collector
and API-key metadata while retaining the prior merge order and disabled-layer
rules. Red-first layer-inventory tests cover deepest-root selection,
home-to-project order, inherited disable masking, and `include_disabled`; a
Config regression fails if per-skill rescanning returns.
Focused Docker tests pass. A synthetic Docker benchmark used 50 skill configs
across four runtime layers, checked byte-equivalent serialized results, and
measured 15 alternating pairs: legacy repeated lookup median 4.431 ms versus
grouped lookup 3.409 ms (about 1.30x). This measures that metadata-discovery
routine on synthetic files, not the full CLI or the requested 50x-per-routine
target.

The same comparison for layered skill API records also preserved exact
serialized output over 50 skills/four layers and 15 alternating pairs: 4.891 ms
for the repeated per-skill lookup versus 3.786 ms grouped (about 1.29x). The
Config, PathRegistry, and core-module Docker suites pass 540 assertions after
both readers were switched to the grouped inventory. These metadata-path gains
remain far short of the whole-dashboard 50x requirement.

### Reuse nested-skill chains during alias reads (2026-10-13)

A corrected checkout NYTProf run of `paths -o json` showed read-side nested
skill-alias discovery was resolving each discovered entry's write location by
walking the same skill chain again. `nested_skill_entries` can now optionally
return the validated chain's safe config write location, and Config reuses it
while merging nested alias overrides. The normal write-location API still
resolves its own chain, and the resolver validates every segment and chain
relationship before deriving a target. Red-first Docker tests cover global
fallback, git-managed parent behavior, exact path parity, and Config's
no-second-resolution contract. Additional cases reject malformed and
mismatched pre-resolved chains. Four focused Docker suites pass 564 tests.

A synthetic Docker benchmark created 50 skills in two runtime layers, each
with a nested child, and compared the former discovery-plus-per-entry-resolver
path to discovery with the precomputed chain. Canonically serialized results
were identical over 30 alternating pairs; medians were 4.216 ms versus 2.347
ms (about 1.80x) for this routine. It is not a whole-command benchmark, a
v5.88 comparison, or proof of the requested 50x speedup.
The post-change checkout NYTProf call trace confirms that nested alias reads
now enter `_skill_config_write_location_from_chain` during the discovery pass;
the read path no longer calls the public chain-resolving method for each entry.

### Share installed-skill config inventory for path aliases (2026-10-13)

The next call-count regression test found `Config::path_aliases` loading
`_skill_config_entries` once through `merged()` and again for the
skill-qualified alias view. Config now creates that inventory once and passes
it to both readers. `load_global`, `merged`, `_skill_path_aliases`, and
`_skill_config_fragments` validate optional shared-entry inputs; malformed
options and rows fail visibly. The red-first Docker regression observed two
`installed_skill_entries` calls before the change and one after it. Five
focused Docker suites pass 360 tests.

A synthetic Docker fixture with 50 skills across home and project runtime
layers compared the former two-inventory path with the shared path over 30
alternating pairs. Both produced identical canonical JSON; median times were
4.304 ms and 2.342 ms respectively (about 1.84x) for this alias-resolution
routine. This does not prove a 50x whole-dashboard or every-subroutine speedup;
the requested objective remains open.

### Normalize runtime-layer candidate paths once (2026-10-13)

The fresh 50-skill checkout NYTProf profile showed 74 calls to
`PathIdentity::_same_or_descendant_path` during a single `paths -o json`
request. `runtime_layer_root_for` was canonicalizing the same candidate once
per runtime root. A red-first Docker test with two configured roots plus the
home fallback failed with three candidate resolutions instead of one. The
method now resolves the candidate lazily once, keeps independently resolved
root identities, and compares them through an extracted identity-only helper.
Exact raw-path matches still return before filesystem resolution. Five focused
Docker suites pass 438 tests.

A 100-pair Docker microbenchmark checked an unrelated candidate against five
roots and preserved the selected-root result: medians were 0.059 ms in the
former per-root normalization flow and 0.042 ms after the change (about 1.41x).
This is a small helper-level gain, not a 50x claim. New profiling and the full
coverage gate remain pending after the current changes settle.

### Merge only the skill path-alias config domain (2026-10-13)

`Config::path_aliases` does not consume unrelated skill config fields, but the
former path loaded and recursively merged each complete config before
extracting aliases. The new `_skill_path_alias_entries` uses the same grouped
installed-skill/layer inventory and asks `_skill_config_hash` to merge only
`path_aliases`; global and repo configs are merged without the irrelevant
underscored skill fragments. A red-first Docker assertion caught recursive
merging of an unrelated field and now verifies it is absent while preserving
the exact qualified alias output. Seven focused Docker suites pass 676 tests.

A synthetic fixture with 50 skills in two runtime layers and 80 unrelated
config fields ran 30 alternating pairs and preserved byte-identical canonical
alias JSON. Median times were 22.262 ms before and 9.774 ms after (about
2.28x) for this routine. This is not a 50x whole-dashboard or every-subroutine
claim; more profiling and the full coverage/release gates remain pending.

### Full Docker verification recheck (2026-10-13)

The first isolated full run lacked a reaping init process, so five
process-descendant tests failed. Those same five files passed 277/277 tests
when rerun with Compose `init: true`; the subsequent full run reached 99.9%
branch and 99.9% condition coverage. The uncovered paths were malformed
shared-config inventory validation and nested-skill write-location/disabled
state conditions in Config and PathRegistry. Red-first assertions were added
to the existing Config and nested-alias tests. The final Compose-init full
gate passes 263 files / 23,604 tests and reports 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,304 detail rows; no stale
uncoverable annotations). Tool-dependent browser, Windows-QEMU, kwalitee,
CPAN-audit, and Docker-daemon checks report their documented skips in this
container. This closes the current coverage gate, not the 50x performance
objective or the remaining release gates.

### Carry validated skill ancestry during nested discovery (2026-10-13)

The next corrected checkout NYTProf profile showed 12.1 ms inclusive and
3.60 ms exclusive in `nested_skill_entries`; repeated segment validation for
each discovered chain prefix accounted for a measurable part of the cost. A
red-first Docker assertion recorded each discovered name being validated more
than once. Discovery now validates each segment once, carries the nearest
git-free parent and its depth to child nodes, builds the same write-location
shape from that state, and iterates the breadth-first queue by index instead
of shifting it. The strict public resolver retains its independent validation
for untrusted input. The test compares inventory results with that resolver
for global fallback, git-managed parents, deeper chains, and rejected control
characters. The focused Docker suites pass 301 tests across three files.

On 50 synthetic skills with a nested child each, 30 alternating Docker pairs
preserved identical canonical JSON and measured 5.407 ms for the prior
discovery-plus-strict-resolver path versus 2.048 ms with propagated state
(about 2.64x). A fresh NYTProf trace, with `/checkout/lib` explicitly first in
the runtime path and verified report source links, measured
`nested_skill_entries` at 6.89 ms inclusive / 1.06 ms exclusive. The earlier
trace measured 12.1 / 3.60 ms respectively. NYTProf instrumentation changes
timing; the synthetic timing is a routine-level result, not a whole-command
result or a v5.88 comparison. Problem 48's 50x-per-subroutine objective remains
unmet.

### Share nested inventory for path and Folder aliases (2026-10-13)

A fresh `paths -o json` profile showed both Config's nested alias reader and
Folder.pm alias discovery calling `nested_skill_entries`, scanning the same
tree twice. A red-first Docker test counted two calls before the change. The
path command now builds one nested inventory and passes it to both readers.
Entries requested with `include_disabled` carry disabled state through nested
descendants; Config continues reading the explicit include-disabled inventory,
while Folder providers filter disabled entries as before. The shared API
rejects malformed/unknown options visibly. Five focused Docker suites pass 354
tests. The verified post-change checkout NYTProf profile records one
`nested_skill_entries` call in `paths -o json`, compared with two before the
shared-inventory change; this confirms the scan reduction, not a wall-clock
ratio.

An isolated Docker fixture with 50 skills and one nested child per skill ran
30 alternating pairs. The combined configured-alias plus Folder-alias flow
produced identical canonical JSON in both modes; medians were 4.355 ms with
separate discovery and 3.317 ms with one shared inventory (about 1.31x). This
measures alias discovery on a synthetic tree, not cold CLI startup or all
dashboard routines. The 50x-per-subroutine objective remains unmet.

### Scope runtime-layer candidates to aggregate path output (2026-10-13)

The fresh 50-skill NYTProf profile showed 15 calls to
`_ancestor_runtime_layers` from `runtime_layer_root_for` in one `paths`
request. A red-first assertion in `t/97-pathregistry-coverage.t` failed with
16 walks before the change. `all_paths` now scopes the candidate-root list to
its own call; it is discarded on return, and a regression proves a later
lookup finds a project `.d2` layer created afterwards. Focused Docker path and
config suites pass 537 tests. In a 15-lookup benchmark, every lookup selected
the same project root; medians were 1.162 ms without the scope and 0.305 ms
with it (about 3.81x). The post-change 50-skill NYTProf trace made five total
ancestry walks, four from `runtime_layer_root_for`, versus 16 before. The
instrumented command totals varied and are not claimed as an end-to-end gain.
This optimization does not establish 50x for all subroutines.

### Public-helper 50-skill startup profile (2026-10-13)

The earlier manual profile omitted the repository-library environment passed by
the public switchboard and therefore measured the helper's standalone
`FindBin` fallback. A corrected Docker trace ran the staged helper with
`DEVELOPER_DASHBOARD_REPO_LIB=/checkout/lib`, created 50 valid skill alias
configs, and verified the emitted JSON contained the final skill alias. The
profiled `run_paths_command` took 16.2 ms inclusive. The `use
Developer::Dashboard::PathRegistry` compile/import boundary took 11.6 ms
inclusive (4.57 ms exclusive); `installed_skill_entries` took 2.91 ms
inclusive, and the 50 `_skill_config_hash` calls took 1.87 ms inclusive.
NYTProf changes timing, so these are hotspot rankings rather than wall-clock
claims. Table-rendering startup is not the dominant cost. The next cold-start
investigation should focus on the PathRegistry load boundary or the measured
resident-runtime route, not the already-removed standalone FindBin fallback.

### Defer table-rendering imports from JSON-only paths (2026-10-13)

The JSON `paths` route had no table output but `CLI::Paths` imported
`CLI::TableHelpers` at compile time, including its Exporter and formatting
dependencies. A red-first Docker subprocess regression failed on that import
being present. The helper now builds the same PathRegistry inputs directly and
requires TableHelpers only in human/table branches. The paired Docker probe
confirms JSON mode excludes the renderer, table mode loads it and preserves
the `Path`/`Value` headings, and standalone fallback output remains
byte-identical. Thirty alternating cold launches measured 29.030 ms median
with lazy loading versus 29.210 ms with TableHelpers forced eager (~1.006x).
This is negligible and is logged as import hygiene, not as a meaningful speed
gain. It does not address the 50x target; further work should target routines
identified as material by profiling.

### Deterministic FFI-path coverage (2026-10-13)

The repository coverage run showed `Crypto::PBKDF2.pm` at 63.4% total because
the benchmark image lacks the optional FFI modules and therefore never enters
the native path. The adapter itself is part of the Problem 48 accelerator, so
the test now supplies a fake `FFI::CheckLib`, `FFI::Platypus`, and buffer
boundary without installing those packages. Its function callback computes
the reference PBKDF2-HMAC-SHA256 digest using `Digest::SHA`, allowing exact
parity checks while also driving the native adapter's buffer and error logic.
The Docker test passes 54 assertions; a dedicated Devel::Cover database reports
100.0% statement, branch, condition, and subroutine coverage for the adapter.
The fake validates contract and control-flow behavior, not real ABI binding;
the separate OpenSSL integration test remains conditional on actual FFI and
libcrypto. The subsequent full Docker gate passed 263 files / 23,272 tests and
reports 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (47,329 detail rows; no stale uncoverable annotations). `perldoc
perlsec` completed successfully in the benchmark container. Coverage is
verified for this worktree; the all-routine 50x requirement remains open.

### Share top-level skill directory reads per paths command (2026-10-14)

The matched 50-skill NYTProf profile showed the paths command independently
enumerating the same top-level skill directories for `installed_skill_roots`
and `installed_skill_entries`: 1.29 ms and 2.38 ms inclusive respectively.
The PathRegistry now shares only the sorted directory-name listing within one
`run_paths_command`. Disabled markers are still checked at each use, and the
scope is discarded at command return. Red-first Docker coverage observed two
`skills_roots` calls before the change and one afterward; it also creates a
skill after the scope and confirms a later inventory discovers it. Four
focused suites passed 5,860 assertions. A two-layer, 50-skill paired-inventory
benchmark preserved exact canonical output and measured 1.465 ms without the
scope versus 1.136 ms with it (1.29x). A matched NYTProf run moved command time
from 15.9 ms to 14.9 ms under instrumentation. This is a narrow scan reduction,
not a 50x speedup claim.

### Avoid a duplicate disabled-marker stat (2026-10-14)

During nested-skill inventory with `include_disabled`, the top-level skill
discovery checked each `.disabled` marker and queue construction checked the
same marker again. A red-first test in `t/97-pathregistry-coverage.t` verifies
that one inventory examines the marker once, while empty inputs remain safe.
The implementation skips filtering markers when disabled skills are
explicitly included and checks each root once when building the traversal
queue. Docker benchmarks preserved exact output: 51 paired runs over 50
skills measured 0.599 ms before versus 0.496 ms after (1.21x); 31 paired runs
over 250 skills measured 3.089 ms versus 2.585 ms (1.19x). This narrow
inventory optimization remains far below the 50x target. The full test gate
passed 264 files / 23,296 tests and reported 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,375 detail rows). Nine
optional or environment-dependent tests skipped with explicit reasons.
Post-gate `perldoc perlsec` succeeded. These gates validate this iteration,
not the 50x objective or remaining release/delivery gates.

### Latest full gate after MCE benchmark addition (2026-10-14)

The full Docker test gate passed 265 files and 23,316 tests. Statement, branch,
condition, and subroutine coverage each measured 100.0% across `lib/` (47,375
detail rows, without stale uncoverable annotations). Nine optional or
environment-dependent test files reported explicit skips; three MCE-specific
assertions also skipped because MCE is optional and absent from the standard
gate image. The focused MCE-enabled Docker test passed all 11 assertions.
Post-gate `perldoc perlsec` succeeded (29,990 bytes). This gate does not meet
the 50× performance target.

### Repeated native/SPVM comparison (2026-10-14)

The focused Problem 48 suites passed 134 assertions in the isolated Docker
bench. The SPVM test initially skipped because the bench's optional module
directories were not on `@INC`; explicitly adding the preinstalled benchmark
modules to `PERL5LIB` passed all five SPVM parity assertions and all 54
deterministic FFI adapter assertions. The production 210,000-round comparison
then completed five alternating runs with identical digests: Perl median
287.180 ms, OpenSSL through FFI::Platypus 30.868 ms (9.30×), and the complete
SPVM loop 512.355 ms (0.56× Perl speed); SPVM load/compile was 54.430 ms,
excluded from the routine medians. This confirms SPVM is slower even when the
loop stays inside SPVM, and the current FFI routine remains below 50×. No SPVM
implementation should be retained based on these results.

### Repeated MCE inventory scaling comparison (2026-10-14)

With MCE enabled through the isolated bench's optional-module path, a fresh
five-run comparison over 50, 250, 1,000, and 5,000 independent JSON configs
preserved exact ordered output. Four workers' warmed medians were 1.730,
5.746, 20.390, and 107.265 ms, compared with serial medians 1.417, 5.358,
20.733, and 112.403 ms respectively (0.82×, 0.93×, 1.02×, and 1.05× serial
speed). Cold MCE map startup was 5.171, 9.044, 22.245, and 182.417 ms. The
largest tested inventory improves only 5%; smaller inventories regress. This
does not justify bringing MCE into production or support the 50× target.

### NYTProf call-tree reinspection (2026-10-14)

Re-reading the saved matched 50-skill `paths` profile with `nytprofcalls`
confirmed that alias resolution reaches `Config::_skill_config_hash` once per
skill config. The line profile attributes about 2.032 ms to constructing 50
config paths and 0.285 ms to decoding those 50 JSON payloads; loading the
`Developer::Dashboard::JSON` wrapper accounts for about 2.937 ms inclusive
across two imports in that instrumented process. This does not expose a
50×-scale repeated Perl routine: JSON decoding is already in XS, and the
profiled config reads are individually small. The next production candidate
cannot be justified by this call tree; the resident-process architecture
still requires safe, complete invalidation and parity evidence before a code
change.

### Reproducible Inline::C/XS comparison (2026-10-14)

A new manual benchmark and red-first test compare the same 210,000-round
PBKDF2-HMAC-SHA256 input through the Perl reference, the existing FFI adapter,
and a one-call Inline::C-generated XS wrapper around OpenSSL. The Docker
regression passed nine assertions, including exact native digest parity. Five
timed runs measured Perl at 287.413 ms, FFI at 31.073 ms (9.25×), and
Inline::C/XS at 31.379 ms (9.16×); compiling the Inline binding took 610.263
ms outside the routine medians. Inline::C/XS is slightly slower than FFI here
and does not justify a second production backend. The reproducible benchmark
is `script/problem48-inline-xs-benchmark`; it is optional research tooling.

### Request-scoped Memoize comparison (2026-10-14)

A new benchmark and nine-assertion regression compared uncached path identity,
a request-local hash, and `Memoize` with its cache flushed before every
operation. All three produced exact results, and all observed a symlink
retarget between operation boundaries. Over 15 alternating Docker runs of
1,000 unique paths repeated twice, medians were 7.705 ms uncached, 4.246 ms
with the local hash (1.81×), and 5.006 ms with `Memoize` (1.54×). `Memoize`
adds overhead relative to the purpose-built operation-local cache, so it is
not adopted for this path. The benchmark is reproducible with
`script/problem48-memoize-benchmark --paths 1000 --runs 15`.

A fresh rerun on 2026-10-18 used 250 unique paths repeated twice across nine
alternating samples. Ordered identity outputs matched exactly and symlink
retargeting was detected at operation boundaries. Medians were 2.205 ms
uncached, 1.175 ms with a request-local hash (1.88x), and 1.446 ms with
Memoize flushed at the same boundary (1.52x). This confirms that a scoped hash
can help this repeated-identity workload, while standard Memoize is slower than
the hash and must not cache across mutable filesystem operations.

### Resident path-context mutation/parity probe (2026-10-14)

A new Docker benchmark retains one `PathRegistry` and `Config` object, resets
cwd/object memo/alias state at each request, rebuilds skill inventory, and
re-executes user `Folder.pm` code. The regression compares its response bytes
with a newly launched `share/private-cli/paths` helper and checks changed skill
config bytes, a `Folder.pm` method reading a changed environment value, and
skill creation/deletion between requests. The focused test passed ten
assertions. With 50 synthetic skills and nine alternating runs, output parity
and all mutation checks passed; the fresh helper median was 29.336 ms and the
resident handler median was 6.719 ms (4.37×). This is behavior-safe context
reuse but not a 50× route, even before adding IPC. The prototype is
`script/problem48-resident-path-benchmark`; no production daemon is adopted.

### Built-in class, field, method, and signature performance probe (2026-10-14)

The isolated Docker runtime is Perl 5.40.1. A direct seven-run alternating
probe compared two million blessed-hash method calls with two million calls to
a built-in `class`/`field`/`method` object, and two million ordinary subroutine
calls with two million signature subroutine calls. All four sums matched.
Median times were 179.731 ms for the conventional method and 230.533 ms for
the built-in class method/field (0.78× relative speed); ordinary subs took
142.308 ms and signature subs 196.421 ms (0.72×). Perl emitted its explicit
experimental warnings for `class`, `field`, and `method`. These features are
therefore not adopted: on the supported runtime they are slower and fail the
warning-free delivery requirement. No warning suppression was used. This is a
small synthetic dispatch probe, not proof about every project call site or the
50× target.

Perl's 5.42 documentation still identifies `class` as experimental; signatures
are stable since 5.36. The 5.40.1 benchmark above remains scoped to the Docker
runtime, but the experimental warning is not a 5.40-only issue. See the
official [Perl 5.42 `feature` documentation](https://perldoc.perl.org/5.42.0/feature)
and [class syntax reference](https://perldoc.perl.org/5.42.0/perlclass).

### Validated working-directory lookup recheck (2026-10-14)

A red-first Docker assertion verified that an absolute `$PWD` identical to
`Cwd::getcwd` uses the direct result and keeps logical symlink paths behind the
device/inode identity check. The focused `t/653-pathidentity-fast-cwd.t` suite
passes 17 assertions, including the empty-getcwd fallback. Seven alternating
100,000-call runs measured the earlier two-stat implementation at 262.482 ms,
the revised fast path at 52.454 ms, and the same-subroutine v5.88
`eval { getcwd() }` wrapper at 41.729 ms. Thus the revision repairs a 5×
regression in the prior current-branch helper but is still only 0.80× baseline
speed. It is recorded as a
regression reduction, not a v5.88 performance win; logical-path semantics
remain intact and further optimization is required.

### Full Docker coverage/security gate after working-directory recheck (2026-10-14)

The isolated suite passed 268 files and 23,388 tests. The canonical coverage
gate reported 100.0% statement, branch, condition, and subroutine coverage
across `lib/` (47,390 detail rows; no stale uncoverable annotations).
Optional/environment-dependent tests reported explicit skips. The required
post-gate `perldoc -t perlsec` check passed. `git diff --check` and POD syntax
checks passed. This verifies the changed worktree's quality gates; it does not
demonstrate 50× acceleration for every routine.

### Resident path-context inventory scaling (2026-10-14)

The freshness-preserving resident prototype was rerun with 250, 1,000, and
5,000 synthetic skills (three alternating samples each). Exact helper-output
parity and config replacement, dynamic `Folder.pm` environment refresh, skill
creation, and skill deletion checks passed at every size. Fresh-helper versus
resident-handler medians were 38.091/13.887 ms (2.74×), 75.883/50.994 ms
(1.49×), and 236.497/226.402 ms (1.04×), respectively. The context-reuse
benefit disappears as filesystem discovery dominates; this prototype cannot
provide the 50× target by itself. The next safe experiment is event-driven
invalidation of filesystem-derived inventory/config data while continuing to
execute arbitrary user `Folder.pm` providers on every request.

### MCE config-read scaling beyond 5,000 entries (2026-10-14)

The ordered-output MCE benchmark was extended to 10,000 and 20,000 JSON config
files. Each fixture contains 80 unrelated keys and one alias, and every result
matched the serial order and bytes. With four workers, warmed MCE versus serial
medians were 290.222/369.181 ms at 10,000 (1.27×) and 393.896/490.490 ms at
20,000 (1.25×); eight workers measured 341.180/435.242 ms at 20,000 (1.28×).
First-map timings varied from 0.98× to 1.63× serial, so startup behavior is not
stable enough to claim. MCE can help this synthetic, very large independent
read workload by about 25–28%, but does not approach 50× and has not been
integrated into production config loading.

### MCE against the actual Config::path_aliases API (2026-10-14)

The generic ordered-JSON benchmark did not include skill discovery, effective
layered config reads, alias qualification, or production alias expansion. A
new isolated Docker benchmark builds synthetic installed skills, measures
`Config::path_aliases`, and substitutes only the per-skill layered alias read
with ordered MCE workers; the remaining global merge and expansion still use
production methods. Every cold and warmed result is checked against canonical
serial output. The focused regression passed all nine assertions.

Three alternating measurements with four workers gave serial/MCE warmed
medians of 48.332/52.719 ms at 1,000 skills (0.92x), 300.048/350.766 ms at
5,000 (0.86x), and 619.155/587.044 ms at 10,000 (1.05x). With eight workers,
the corresponding measurements were 284.234/302.021 ms at 5,000 (0.94x) and
625.528/662.299 ms at 10,000 (0.94x). Exact alias output parity held in every
case. MCE's small 10k/four-worker advantage did not persist with eight workers
and is within run-to-run variation; parallel config reads are not a reliable
win for the actual API and will not be integrated based on these results. The
larger generic JSON gains do not represent the dashboard workload. Problem 48
remains open.

### Isolated 250-skill paths profile and MCE recheck (2026-10-14)

A fresh NYTProf run enabled profiling only around the actual
`CLI::Paths::run_paths_command(command => 'paths', args => ['-o', 'json'])`
operation, after fixture creation and module loading. With 250 installed skill
configs it emitted valid JSON (13,715 bytes, 264 aliases). Under NYTProf,
`Config::path_aliases` took 14.7 ms inclusive; its 250 `_skill_config_hash`
calls took 2.8 ms exclusive in total. The 250 skill-disable checks took 1.56
ms exclusive, while nested skill discovery took 11.5 ms inclusive. These are
instrumented timings and identify the current pipeline, not production wall
time.

The production-API MCE benchmark was also run at this profile's 250-skill
scale, with exact alias parity across 15 alternating pairs. Serial measured
14.400 ms; four-worker MCE measured 20.677 ms warmed and 19.209 ms cold
(0.70x warm, 0.75x cold relative speed). MCE therefore regresses the actual
250-skill alias workload and is not adopted. Problem 48 remains open.

A longer nine-run four-worker recheck at 10,000 skills preserved exact alias
parity and measured 671.440 ms serial versus 635.286 ms warmed MCE (1.06x).
The improvement remains small relative to the 50x target and is not enough to
justify MCE's process and lifecycle complexity in normal configuration reads.

### Share ancestor discovery inside one path operation (2026-10-14)

A red-first assertion tightened the existing all_paths contract from at most
two ancestor-layer walks to exactly one; it failed with two before the change.
PathRegistry now shares the ancestor list through its already operation-scoped
candidate structure between runtime_layers and runtime_layer_root_for. Calls
without an explicit scope still perform fresh discovery, preserving visibility
of runtime-layer creation/removal between operations. The focused PathRegistry
and I/O suites passed 325 assertions, and a 51-pair all_paths benchmark kept
exact JSON parity (1,171 bytes). This is a measured reduction in duplicate
filesystem discovery, not yet an isolated latency claim or a 50x result.

### Full Docker coverage/security gate after resident-context probe (2026-10-14)

The isolated full Docker suite passed 268 files and 23,385 tests. The canonical
coverage gate reported 100.0% statement, branch, condition, and subroutine
coverage across `lib/` (47,381 detail rows; no stale uncoverable annotations).
The suite explicitly skipped environment-dependent checks, including missing
`cpan-audit`, unavailable local browser loopback, an unreachable Docker daemon,
optional SPVM/kwalitee tooling, and operator-local `.claude` specs; the
benchmark-only SPVM case also skipped in the standard image. The required
`perldoc -t perlsec` check passed afterward, `git diff --check` was clean, and
the scoped Problem 48 Compose project had no remaining containers. This is a
passing code/test/security-doc gate, not evidence that the 50× all-subroutine
performance target or the remaining release gates are complete.

### Read indicator roots once per listing (2026-10-14)

An NYTProf profile of the real `/system/status` route showed
`IndicatorStore::list_indicators` taking 5.534 ms inclusive in the instrumented
request. Inspection found it resolving all indicator roots once to enumerate
names, then calling `get_indicator` for every name, which resolved those same
roots again. A red-first regression used four records and failed at five root
lookups before the change; it now asserts one lookup. The implementation passes
the discovered root list into a private reader, retaining root precedence,
fresh file reads, per-record error handling, and sorted results.

The reproducible isolated-Docker benchmark checks canonical JSON parity before
and during alternating runs. With 50 records over nine paired runs, one layer
measured 8.197 ms baseline versus 1.017 ms optimized (8.06x); two layers
measured 14.588 ms versus 1.201 ms (12.15x). This accelerates one listing
workload but is not a 50x result for each dashboard subroutine. Focused
IndicatorStore/collector tests passed 242 assertions, and the benchmark test
passed 12 assertions. The next required verification is the complete Docker
coverage gate after this change passed 270 files and 23,433 tests. All four
coverage dimensions measured 100.0% across `lib/` (47,422 detail rows), and
`perldoc -t perlsec` passed afterward. Optional environment/tool-dependent
tests reported explicit skips. The 50× performance objective and packaging /
release gates remain open.

### Reject direct-root indicator reads without an isolated gain (2026-10-14)

A second experiment tried avoiding deeper-root probes by reading each status
file directly from the directory currently being enumerated. A red-first test
measured three reads for two winning records and required two. The implementation
passed focused collector/IndicatorStore tests and preserved layered output, but
a three-way benchmark was needed to isolate it from the earlier root-discovery
optimization. Across 15 paired Docker runs at 50, 250, and 1,000 indicators in
two layers, the intermediate root-reuse path measured 1.015, 4.534, and 20.961
ms; direct-root measured 1.015, 4.357, and 20.492 ms (1.00×, 1.04×, and 1.02×).
The apparent gain is too small to establish a reliable speedup, so the direct-
root production edit and its temporary regression assertion were reverted.
The measured root-discovery optimization remains. All three implementations
produced byte-identical canonical JSON.

### Reuse the collector inventory in status responses (2026-10-14)

A fresh Docker NYTProf run of `t/03-web-app.t` showed that each configured
collector status-payload build first called `sync_collectors`, whose orphan
cleanup listed all indicators, then called `page_header_payload`, which listed
them again. The profile recorded 88 calls to `list_indicators` across 44
payload/summary builds; it attributed 136 ms inclusive to
`_page_status_payload` (3.09 ms average). A red-first route regression then
required one listing and byte-identical JSON. `sync_collectors` can now return
its final inventory to the payload renderer; if orphan cleanup deletes an
indicator it refreshes the inventory after deletion, while the default sync API
still returns its original written-record array.

The post-change profile recorded 46 listings over the same 44 payload/summary
builds (one explicit test list and one cleanup refresh account for the extra
two), with 114 ms inclusive in `_page_status_payload` (2.53 ms average, 1.22x
faster under NYTProf). The focused web, IndicatorStore, and collector suites
passed 580 assertions. This improves a measured route but remains far short of
the 50x-per-subroutine objective.

The canonical isolated Docker coverage gate then passed all 270 test files /
23,445 tests. Statement, branch, condition, and subroutine coverage were each
100.0% across `lib/` (47,452 detail rows), with no stale uncoverable
annotations. Optional environment/tool-dependent checks emitted explicit
skips. After the gate, `perldoc -t perlsec`, syntax checks for both changed
modules, their POD checks, and `git diff --check` all passed. This closes the
verification gate for this iteration only; the 50x-per-subroutine target and
release gates remain open.

### Remove repeated linear work from legacy section validation

A fresh NYTProf `subs=1` profile of `t/03-web-app.t` measured
`PageDocument::_parse_legacy_sections` at 482 ms exclusive over 148 calls
(3.26 ms/call under profiler). The parser validates each section by grepping
`@LEGACY_KEYS`, which contains the fixed `TITLE`/`ICON`/etc. keys plus every
`CODE0` through `CODE1000` key. That makes allowlist validation scale with the
full 1,008-entry list for each section. The test run is a mixed route workload
and NYTProf timings are not production wall-clock claims. A red-first Docker
regression tied the legacy key array and failed at 1,008 reads while parsing
`CODE1000`; it also established that `CODE1001` is accepted today, so that
behavior is retained. Fixed names now use a prebuilt membership hash and
numbered CODE sections use the equivalent digit-pattern check.

The Docker comparison verifies exact output before and during alternating
timings. Across 21 paired runs, 10 CODE sections measured 2.679 ms in the
reference implementation versus 0.022 ms currently (122.13x); 1,001 sections
measured 283.484 ms versus 2.224 ms (127.47x). Reprofiling the same web test
preserved 148 parser calls and reduced exclusive parser time to 3.59 ms from
482 ms. This is a strong optimization of one routine, not the requested 50x
gain for every Dashboard subroutine.

A current-container rerun of the same 1,001-section benchmark used nine
alternating runs and again verified exact parser-output parity. The linear
reference measured 284.100 ms median and the optimized parser 2.283 ms
(124.44x). This confirms that this particular large synthetic parser workload
continues to clear 50x; it is not evidence about the rest of the call graph.

### Skip duplicate home-root normalization in ancestry discovery

The same web-test NYTProf profile showed 3,373 calls to
`PathRegistry::_ancestor_runtime_layers`, including repeated normalization of
the selected home runtime path: `home_runtime_path` returned the same exact
path already present in `_existing_layer_dirs_for($home)`. A red-first Docker
test counted three calls for that spelling where two distinct uses are needed.
The implementation now deduplicates exact strings before path-identity checks;
it still normalizes distinct `.d2` and `.developer-dashboard` siblings
separately and excludes both home roots from ancestor results.

Reprofiling the same test preserved all 3,373 calls and reduced exclusive
routine time from 72.2 ms to 56.4 ms (1.28x). The focused PathRegistry and web
tests passed 631 assertions, including layer ordering and freshness checks.
These instrumented route-test timings are not production wall-clock figures,
nor do they satisfy the 50x-per-subroutine target.

The canonical Docker coverage gate then passed 270 test files / 23,450 tests.
Statement, branch, condition, and subroutine coverage were all 100.0% across
`lib/` (47,461 detail rows), with no stale uncoverable annotations. Optional
environment-dependent tests emitted explicit skips. Post-gate `perldoc -t
perlsec`, module syntax/POD checks, `t/15-release-metadata.t`, and
`git diff --check` passed. This closes this optimization's verification gate,
not Problem 48's 50x-every-subroutine objective.

The canonical full Docker coverage gate passed 270 test files / 23,448 tests.
Statement, branch, condition, and subroutine coverage were each 100.0% across
`lib/` (47,455 detail rows), with no stale uncoverable annotations. The gate
reported explicit skips for unavailable optional tooling and environment-bound
checks. The required post-gate `perldoc -t perlsec` and final metadata/diff
checks passed, along with Perl syntax and POD checks for the modified module
and benchmark. Problem 48's broader objective remains open.

### Verified-PWD lookup: matched baseline clarification (2026-10-14)

The current-directory optimization was remeasured against its actual replaced
call path. Across 21 alternating Docker pairs of 40 calls, the median was
1.7025 ms per call for `Cwd::cwd` and 0.0009 ms for
`PathIdentity::current_working_directory`, with equal physical-path results
(1,891.6x). The production common path calls native `Cwd::getcwd` once and
returns immediately when the absolute `PWD` matches; distinct absolute paths
pay the device/inode check to preserve valid logical symlinks. Native
`Cwd::getcwd` alone is faster than the helper, so this is not a universal cwd
speedup: its gain applies where the old call site used shell-backed
`Cwd::cwd`. Focused Docker suites for PathIdentity, PathRegistry, and the web
app passed 689 tests. The full gate then exposed one contradiction with the
existing one-getcwd contract; the implementation and red-first test were
aligned to that contract, then all focused tests passed. The corrected full
Docker gate passed 270 files / 23,458 tests, with 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,464 rows; no stale
uncoverables). Optional tool/environment checks emitted explicit skips.
Post-gate `perldoc -t perlsec` rendered successfully. The 50x target for every
subroutine is still unmet.
### Shared JSON::XS object reuse (2026-10-14)

The shared JSON wrapper used to instantiate `JSON::XS` on every encode/decode.
Red-first Docker probes count constructors and check canonical output, UTF-8
round-trips, and recovery after malformed transient-state JSON. Production now
keeps one lazy encoder with fixed UTF-8/canonical/pretty settings and one lazy
UTF-8 decoder per interpreter. The state decoder remains non-fatal for
incomplete state, and a subsequent valid decode succeeds on the same instance.

Alternating 21-pair Docker benchmarks of 10,000 calls measured 1.41x for
encoding and 1.17x for decoding versus per-call `JSON::XS` construction; the
canonical output and decoded values were exact. The gain is bounded to JSON
helper calls, and does not establish the Problem 48 50x goal for every
subroutine. The focused JSON test passed 20
assertions, and the module-scoped gate reported 100.0% statement, branch, and
subroutine coverage (conditions are not applicable). The corrected full Docker
gate passed 270 files / 23,465 tests with 100.0% statement, branch, condition,
and subroutine coverage across `lib/` (47,486 detail rows, no stale
uncoverables). Optional environment/tool checks emitted explicit skips. The
post-gate `perldoc -t perlsec` check succeeded; Problem 48 remains open.

### Rejected configurable-encoder cache experiment (2026-10-14)

`json_encode_with_options` varies only three boolean flags, so a candidate cache
of up to eight `JSON::XS` objects was tested. A red-first Docker probe observed
four constructors for repeated calls using two option combinations. The
candidate preserved exact output but an alternating 21-pair benchmark of
10,000 calls measured 0.93x for default options and 0.96x for ASCII mode
relative to per-call construction. Cache-key creation and hash lookup erased
the object-allocation saving, so the candidate and its test were removed. No
production behavior changed from this rejected experiment.

### Portable watcher API feasibility check (2026-10-14)

The container has `Filesys::Notify::Simple` 0.14, but its public interface
exposes a blocking `wait`; its optimized backend selection depends on optional
platform modules, and its fallback repeatedly scans the directory tree. Its
documented Windows backend also has a 64-directory limit. That API therefore
cannot be polled safely from a request handler over the hundreds of watched
directories in the synthetic workload. See the [module documentation](https://metacpan.org/pod/Filesys::Notify::Simple).

`File::ChangeNotify` 0.31 documents a nonblocking `new_events` API and an
inotify-backed watcher, while its default watcher uses a sleep loop; the module
is not installed in the current benchmark image. See its [top-level API](https://metacpan.org/pod/File::ChangeNotify)
and [watcher contract](https://metacpan.org/pod/File::ChangeNotify::Watcher).
Neither library has yet demonstrated the required backend availability,
overflow recovery, project-specific mutation coverage, and end-to-end parity
under the dashboard runtime. No dependency or watcher code was added from this
feasibility check.

### PathRegistry metadata type-check import (2026-10-14)

NYTProf attributed about 10.4k ticks to PathRegistry's compile-time Fcntl
import, which was used only for mode predicates immediately after the existing
metadata `lstat`. Perl's `-l _` and `-f _` inspect that cached lstat record, so
the import can be removed without changing the no-follow check or adding a
filesystem call. A Docker test asserting Fcntl stayed unloaded failed before
the edit; focused PathRegistry and lazy-loading suites passed afterward (355
assertions). In 21 alternating Docker process pairs, PathRegistry import took
13.888 ms without Fcntl versus 15.017 ms with the former import (1.08x). This
small startup improvement is retained but is not evidence for the overall
50x-per-routine requirement.

### Large-inventory resident-path call-tree probe (2026-10-14)

NYTProf was applied to the existing resident-path benchmark with 250
synthetic skills. The benchmark preserved exact output and passed config-edit,
Folder.pm environment refresh, skill-addition, and skill-removal checks. Its
call tree shows repeated `Config::_skill_config_hash` reads and
`PathRegistry::nested_skill_entries` discovery as the inventory work; the
profile also includes fixture creation, four post-benchmark freshness probes,
and fresh child processes. Because of that mixed workload and profiling
overhead, its displayed timing ratio is not a production performance result.
This probe narrows the next profiling target to repeated filesystem inventory
and per-skill config reads; it does not justify MCE or a persistent cache, and
does not establish any 50x gain.

### Reuse skill config entries for collector assembly (2026-10-14)

The production `Config::collectors` flow calls `merged()`, whose global load
reads each installed skill config to create underscored fragments, then calls
`_skill_collectors`, which independently reads the same skill configs again.
A red-first test wrapped `_skill_config_entries` and failed with two calls.
`load_global` can now return the exact entries it used through an optional
output array; `collectors` passes those entries to `_skill_collectors`, keeping
global-file reads, skill-read order, merge precedence, and error propagation
unchanged. The test now observes one enumeration and the existing config suite
passes all 235 tests in Docker. A separate alternating 21-pair Docker
benchmark with 250 synthetic skills and 80 unrelated config keys compared the
legacy double-read flow to `collectors()`: canonical output matched exactly,
and medians were 27.324 ms versus 15.446 ms (1.77x). The repeatable command is
`d2 docker compose -f /tmp/d2-problem48-bench.yml run --rm bench perl
script/problem48-collector-config-benchmark`. This is one collector path
improvement and does not establish 50x for every subroutine.

### CLI process-floor measurement (2026-10-14)

In the isolated Docker bench, 31 alternating child-process runs measured a
bare `perl -e 1` median of 2.286 ms and `perl bin/dashboard version` at
32.528 ms. Against the recorded v5.88 `version` median of 56.7 ms, a 50x
end-to-end target would require 1.134 ms total, below this measured child
process floor. The current command therefore cannot reach 50x through
subroutine optimization alone while remaining a newly spawned Perl CLI.
Meeting that command-level ratio would require changing invocation architecture
(for example, a resident process or non-Perl launcher), and any such change
would need separate security, lifecycle, and exact-output proof. This bound
applies to command elapsed time; it does not replace the objective to profile
and optimize individual routines wherever their work permits it.

### Request-scoped web settings snapshot (2026-10-14)

The current Docker NYTProf web-test call tree showed a saved page request
resolving web settings independently in request authorization and twice in page
chrome. A red-first route assertion counted three `web_settings` calls for one
request. `Web::App::handle` now provides a lazily populated request-local
snapshot shared by those callers; it is restored at the request boundary, so
later requests see configuration edits. `Config::web_settings` also now derives
SSL validity from the merged config it already loaded rather than calling
`ssl_validity_days` and loading it a second time. The same page/status request
therefore reduced merged-config reads from seven to one by passing the same
snapshot and skill entries into collector assembly. The route remains HTTP 200 and
the focused Docker web/config suites pass. This count-based result is scoped to
the tested request and is not a 50x claim for all subroutines.

The first full Docker coverage pass exposed a real 99.9% branch/condition gap
in the newly added request guard and SSL normalization. Red tests were added
for non-object and incomplete config providers, each SSL validity branch, and
skill-entry capture with/without an output target. After that correction, the
full gate passed 271 files / 23,901 tests with 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,644 detail rows; no stale
uncoverable annotations). Explicit skips were recorded for unavailable
`cpan-audit`, operator-local tools, Windows QEMU, loopback-inaccessible browser
checks, CPANTS kwalitee, and Docker-dependent post-build guard. The scoped
request optimization remains below the 50x-per-subroutine objective.

### Request-scoped Template Toolkit service reuse (2026-10-14)

The same NYTProf web-test call tree showed `Template::Base::new` repeatedly
under `PageRuntime::_render_templates`. A red-first Docker test required two
same-root renders in one request scope to construct one service; it failed
before the change. PageRuntime now caches services only in an explicit request
scope, keyed by ordered include roots and whether each root exists. Web::App
localizes that scope around one request. Direct PageRuntime calls without a
request scope remain fresh, and a later web request creates a new provider so
file edits are observed instead of waiting for Template Toolkit's stat TTL.
Tests verify changed stash values, new includes, changed include roots, and a
file edit becoming visible in a new request scope.

Twenty-one alternating Docker pairs, 500 scalar renders per sample, preserved
exact output and measured 0.1825 ms/render when constructing a fresh service
versus 0.1248 ms/render with reuse in one request scope (1.46x). This isolates service
construction from route latency and is not a 50x claim. The route regression
also confirms runtime-layer ancestry scans are bounded at two when nested
permission checks re-enter discovery; the broader runtime inventory stays
request-local so later calls see filesystem changes. The full Docker coverage
gate passed 272 files / 23,952 tests and reported 100.0% statement, branch,
condition, and subroutine coverage across `lib/` (47,723 detail rows; no stale
uncoverable annotations). Optional tooling and environment checks emitted
explicit skips. Required web security suites passed 459 tests; `perlsec`, module
syntax, POD syntax, release-metadata, and diff checks passed afterward. The
50x-every-subroutine objective remains unmet.

### Blank-environment verifier correction (2026-10-14)

The required clean-container install gate initially failed before `cpanm`
because its helper searched `lib/Developer/Dashboard.pm` for a literal version
assignment, but the module delegates its version to
`Developer::Dashboard::Version`. The archive provides the authoritative value
in `META.yml`. A red-first Docker regression reproduced this with a delegated
module fixture. The runner now parses the constrained distribution `version`
entry first and retains a literal-module fallback for older archives; tests
cover metadata precedence, legacy extraction, and loading the helper without
starting its integration flow. The focused test passes. This corrects a
verification blocker, not dashboard performance, and the 50x target remains
open.

The same full run also showed that the coverage gate stored its reader stamp
inside `cover_db`, where Devel::Cover interpreted it as malformed database
content. A red-first gate test now verifies the serializer marker is stored
beside the database and migrates the old marker only after checking its reader
identity. This removes the warning source without changing the coverage scope;
it is tooling hygiene, not a Problem 48 performance result.

### Skip Template Toolkit setup for static bookmark bodies (2026-10-14)

The profiled web test showed that PageRuntime prepares templates for pages with
static HTML as well as pages containing Template Toolkit directives. With the
default TT delimiters, a body without the `[%` opener cannot execute a TT
directive or include. A red-first Docker regression wrapped system-context,
include-root, and processor setup and observed three calls for a static UTF-8
body; it now requires zero and verifies the exact body survives unchanged.
PageRuntime checks the body before building that context and returns early
only for an undefined, empty, or opener-free body. TT-bearing bodies continue
through the existing renderer.

The reproducible command is `perl script/problem48-static-template-benchmark`
inside the isolated Docker Compose service. Twenty-one alternating runs of
5,000 renders preserved exact Unicode output and measured a 0.06436 ms median
for the Template Toolkit process call versus 0.00080 ms for the PageRuntime
static path (80.66x in this microbenchmark). The reference measures only TT
processing, so it is not an end-to-end route comparison; it also does not show
that every dashboard subroutine is 50x faster. A confirmatory run on the final
tree again preserved exact Unicode output and measured 0.06455 ms versus 0.00074
ms (86.73x); variation is expected for this small operation and neither value
is generalized beyond this render case.

After this change, the isolated Docker full suite passed 272 files / 23,751
tests. Coverage was 100.0% for statement, branch, condition, and subroutine
metrics across `lib/` (47,732 detail rows, no stale uncoverable annotations).
The required web security tests passed 459 assertions, and `perldoc -t
perlsec` rendered successfully. These gates validate the current change; they
do not close the broader 50x-per-subroutine objective.

### Matched v5.88 static-render comparison (2026-10-14)

The v5.88 baseline was extracted from commit
`a8d1fa2a4064640baba7a8ed7339462d9d3c3060`; the same static-render benchmark
script was run against that source and the current checkout inside the isolated
Docker service. Across 21 alternating samples of 5,000 renders, the median
`PageRuntime::_render_templates` call took 0.13501 ms at v5.88 and 0.00079 ms
on the current tree (about 171x), with exact UTF-8 output parity. The baseline
still routes static bodies through the full template setup, while the current
path returns the unchanged body before that setup. This is a direct comparison
for one routine and workload, not an end-to-end dashboard result or evidence
that every routine is 50x faster. Problem 48 remains open.

### Scope direct Dancer requests and avoid redundant state chmod (2026-10-14)

A steady-state NYTProf run on the actual PSGI `/system/status` route isolated
route work from application startup by enabling profiling only after loading
`app.psgi` and warming three requests. The direct Dancer handler path did not
enter `Web::App::handle()`, so its `authorize_request` and route method repeated
runtime-layer discovery without sharing the request-local inventory contract.
A red-first PSGI regression observed five ancestry scans across two reads; the
Dancer adapter now establishes the runtime-layer and installed-skill scopes
around both authorized and backend-only direct methods, and discards them at
request end. The same request was then benchmarked in 11 alternating pairs of
100 requests, with byte-identical response bodies: bypassing inventory scope
measured 0.5984 ms/request and using it measured 0.5696 ms/request (1.05x).

The route profile also showed PathRegistry issuing 1,300 chmod calls across
100 steady-state requests. Most came from state directories already at mode
0700. `_ensure_state_dir` now checks the cached mode from its directory test
and skips chmod only when the full permission/special-bit mask is exactly 0700;
other existing modes keep the chmod repair path and visible failure behavior.
A red-first I/O test forces chmod failure and proves the already-private case
does not attempt it. A separate 21-run Docker microbenchmark of 20,000 calls
per sample measured 0.002329 ms/call at v5.88 versus 0.001290 ms/call currently
(1.80x). In the steady-state route profile, PathRegistry chmod calls fell from
1,300 to 100 across 100 requests. This is a narrow helper gain and does not
establish a 50x route or all-subroutine result.

The focused Docker web and PathRegistry suites passed 506 assertions. The first
full coverage attempt is not valid evidence: source/test files changed while it
was running, so its gate correctly refused to emit a coverage report. It also
reported one unrelated operator-local `t/158` failure because its `t-tira-author`
spec could not resolve project selector `tira-ddd` in this container. The next
full run must start from a frozen tree and mask the untracked operator-local
`.claude/` tools from the isolated test container; no full-coverage percentage
is claimed from the interrupted run. Problem 48 remains open.

### Clean full coverage after request-scope guard tests (2026-10-14)

The isolated Docker `script/coverage-gate` rerun on the frozen updated tree
passed all 272 test files / 23,603 tests. The `lib/` report recorded 100.0%
statement, branch, condition, and subroutine coverage across 47,773 detail
rows, with no stale uncoverables. The run included explicit, deterministic
tests for `_ensure_state_dir`'s failed-stat guard and
`_with_request_scopes`'s non-hash app-reference guard. Documented environment
skips remained for operator-local tools and unavailable optional integrations.
After the gate, `perldoc -t perlsec` rendered 29,990 bytes; syntax and POD
checks for both changed test files and `git diff --check` passed. This closes
the coverage/security-documentation checks for the current tree, not Problem
48's 50x-per-subroutine performance requirement or its remaining release gates.

### Request-scoped path-identity reuse (2026-10-14)

A direct warmed PSGI profile and counter around 100 byte-identical
`/system/status` requests found 1,300 `PathIdentity::_path_identity` calls
across five exact path spellings repeated per request. A red-first test showed
two resolutions for identical spellings in each request. Dancer's request
scope now stores exact-spelling identity results only until callback return;
the regression invokes two consecutive scopes and proves the path is resolved
once in each, with the cache absent afterward. The focused Docker test passes
132 assertions. Across 100 identical 558-byte responses, the call count fell
from 1,300 to 600. Eleven alternating Docker pairs measured 0.478 ms/request
without this scope and 0.463 ms/request with it (1.03x). This small gain does
not satisfy the 50x-per-subroutine target.

### MCE against the complete indicator-list path (2026-10-14)

An exploratory isolated-Docker probe compared the current
`IndicatorStore::list_indicators` with an ordered MCE map over the same
indicator names, roots, `_get_indicator_from_roots` reader, and final priority
sort. Canonical JSON output matched exactly. Nine alternating warm pairs
measured serial versus MCE medians of 1.546/6.940 ms for 50 indicators
(0.22x), 20.020/22.656 ms for 1,000 (0.88x), and 97.739/78.368 ms for 5,000
(1.25x). A separate fresh-process 5,000-record run measured the first MCE
call at 63.449 ms against a 93.633 ms serial median, then 89.454 ms for warm
MCE (1.05x). The full-list result varies substantially and does not support
using MCE for ordinary inventories; even the 5,000-record advantage is too
small and inconsistent to justify worker lifecycle and optional dependency
costs. A lower-level file-read/decode-only probe showed larger MCE gains, but
that was not representative of the actual list routine. MCE is not adopted for
IndicatorStore, and Problem 48's 50x-per-subroutine target remains open.

### File::Spec path-assembly candidate (2026-10-14)

The saved matched 50-skill `paths` NYTProf profile attributed 2.032 ms across
50 `File::Spec->catfile($skill_path, 'config', 'config.json')` calls. A Docker
microbenchmark of that expression against string concatenation showed a large
micro-only difference, so both implementations were then compared through the
complete `_skill_config_hash` routine using 50 on-disk JSON files, all layered
reads, decoding, and merging. Across 21 alternating pairs of 20 full routine
calls, direct joining measured 11.676 ms versus 12.367 ms with `catfile` (1.06x).
The isolated difference therefore does not materially improve the real path,
and replacing `File::Spec` would weaken cross-platform path handling for a
negligible gain. No production code was changed. This candidate is rejected;
Problem 48 remains open.

### Skip PageRuntime for literal installed-skill nav (2026-10-16)

NYTProf on the 20-saved/50-skill route showed `PageRuntime::prepare_page` was
still invoked for each installed-skill nav page, including raw literal HTML
with no TT tokens or code blocks. The skill-nav rendering loop now uses the
same `_is_literal_raw_nav` predicate as saved nav and bypasses runtime state
preparation only for those literal fragments. Dynamic TT and structured
instruction pages continue through `_page_with_runtime_state` and
`PageRuntime::prepare_page`.

A red-first web regression failed because two skill fragments were prepared
instead of only the dynamic TT fragment. After the change, the focused web
test passes and verifies both the literal body and rendered TT output. The
Docker route fixture preserved its exact HTTP 200 response (14,942 bytes,
SHA-256 `aa4c502bfb3254233ee6b17050a09f7070b99ca24dfb908a7264bec2e0900a82`).
The 21-run/100-request median moved from 3.553019 to 3.153169 ms/request
(1.13x). This is a route-specific result; the universal 50x target remains
open.

### Bulk installed-skill entries for nav rendering (2026-10-16)

`all_skill_nav_pages` now consumes `PathRegistry::installed_skill_entries` for
top-level skills, passing each entry's already-resolved home-to-leaf layers
through a shared page-loader helper. Nested skill names are still discovered
from the deepest root and resolved through the existing nested-layer path.
Registries without the bulk API retain the former fallback. A red-first test
failed with four per-skill layer resolutions where the bulk path requires only
the one nested lookup, then passed with exact page ordering/content parity;
malformed entries fail explicitly.

The route benchmark gained a tested `--legacy-skill-nav-enumeration` control.
Two alternating Docker pairs used 20 saved nav fragments, 50 installed-skill
nav fragments, 100 requests per sample, and 31 samples. Bulk medians were
3.773839 and 3.644860 ms/request; the former loop measured 4.254751 and
4.386990 ms/request in matching positions. Every run returned HTTP 200, 14,942
bytes, and SHA-256
`aa4c502bfb3254233ee6b17050a09f7070b99ca24dfb908a7264bec2e0900a82`. Measured
skill-layer resolutions fell from 155,000 with the old loop to zero for the
bulk path. A matched NYTProf run measured 12.209 ms/request bulk versus 14.146
ms/request legacy, with profiler overhead. This is a route-fixture improvement,
not a 50x per-subroutine proof; broader delivery gates remain open. The full
Docker coverage gate then passed 285 test files / 24,642 tests, with statement,
branch, condition, and subroutine coverage at 100.0% across `lib/` (49,972
detail rows; no stale uncoverable annotations).

### Rejected literal skill-nav preparation bypass (2026-10-16)

A red-first regression confirmed that literal raw skill-nav fragments still pass
through `PageRuntime::prepare_page`; dynamic TT fragments need that preparation.
A candidate bypass for static fragments preserved exact HTML and reduced the
fixture's preparation-call counter to zero, but repeated route benchmarks did
not show a stable wall-clock gain. With 20 saved and 50 skill nav fragments,
100-request/21-sample runs first measured 4.034 ms/request with the bypass
control and 3.520 ms/request without preparation; reversing the order measured
4.064 and 4.065 ms/request. Larger 200-request/21-sample runs measured 4.235
ms/request with preparation and 4.256 ms/request without it. Since the apparent
gain did not reproduce and the larger sample was slightly slower, the candidate
and its temporary tests/control were reverted. No production behavior changed.

### Heavier saved-page profile with 50 installed-skill nav fragments (2026-10-16)

A fresh current-source NYTProf run exercised the production `/app/welcome` route
with 20 saved nav fragments and 50 installed-skill nav fragments over 20
measured requests. Every request returned HTTP 200 with byte-identical normalized
output (14,942 bytes; SHA-256
`aa4c502bfb3254233ee6b17050a09f7070b99ca24dfb908a7264bec2e0900a82`). The
request-local nav inventory scanned once; nav fragment reads were 20 total and
skill-layer resolutions were 1,000 total.

The instrumented route medians were 123.889 ms/request for v5.88 and 14.439
ms/request for current source (8.58x); profiler overhead makes these unsuitable
as wall-clock latency claims. The old source was recovered from repository
commit `a8d1fa2a` (the 5.88 release) into a disposable container directory after
the previously documented benchmark path proved absent. Both profiled runs
returned the same HTTP status, body size, and SHA-256. On the current profile,
`_nav_items_html` used 10.9 ms exclusive and `_skill_layers` 4.44 ms exclusive;
inclusive costs overlap through nested calls and must not be summed. The
current route performed 1,000 skill-layer resolutions over 20 measured
requests, compared with 3,000 for v5.88; saved-nav file reads were 20 after
current request-local caching versus 460 across the old profile's initial,
warmup, and measured requests. `_all_installed_skill_names` remains a measured
candidate for a focused enumeration experiment. These profile results do not
prove 50x for every subroutine.

The matched per-routine comparison for the common `Developer::Dashboard::*`
subroutines also does not support a broad 50x claim: `PageRuntime::_render_templates`
was 42.63x faster per call, `_nav_items_html` 2.90x, `SkillDispatcher::_load_skill_page`
1.51x, and `PathRegistry::skill_layers` 0.66x per call (though it ran far fewer
times). In this heavier fixture, `_skill_nav_route_ids` and
`_all_installed_skill_names` were slower per call in current source (0.60x and
0.56x respectively). Treat these as profiler measurements for this exact route
fixture, not production latency; the nav-ID and skill-name paths are the next
focused investigation targets, with output parity retained as a requirement.

### Full condition-coverage closure (2026-10-16)

The full Docker coverage gate first exposed one uncovered compound condition in
`IndicatorStore::sync_collectors`. The unchanged-inventory decision now uses a
small named predicate so inventory equality, status-file change state, and
active-indicator presence can be tested independently. The 53-assertion focused
Docker test covers all eight boolean combinations and also verifies stable
inventory reuse and repair of an active indicator whose status file is missing.
The final `d2 docker compose exec dev perl script/coverage-gate` run passed all
285 test files / 24,620 tests with statement, branch, condition, and subroutine
coverage at 100.0% across `lib/` (49,932 detail rows; no stale uncoverable
annotations). This closes the coverage requirement for the current tree only;
it does not establish the Problem 48 all-subroutine 50x performance goal.

### Reuse the validated status-snapshot collector signature (2026-10-16)

NYTProf's 50-indicator status-route profile showed collector synchronization
still serializing the same normalized collector-job array on every request,
even when the existing config watcher reused an unchanged snapshot. The
snapshot now keeps that canonical job signature with its collector projection;
each synchronization still reads and includes the current indicator roots.
Missing signatures are computed once; malformed explicitly supplied signatures
are rejected. Red-first Docker tests proved repeated serialization before the
change, one signature encode after it, exact response parity with caching
disabled, and explicit errors for undefined, reference, and empty signatures.

Two order-reversed Docker comparisons used 50 collectors, 100 requests per
sample and 21 samples. Cached medians were 0.105081 and 0.103180 ms/request;
the no-signature-cache control measured 0.123909 and 0.124791 ms/request. The
mean-of-pair medians indicate a 1.19x route improvement. Both modes returned
HTTP 200, 12,864 bytes, and the same SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`; signature
encodes fell from 2,103 to 1. This is an incremental route result, not a
v5.88 comparison or evidence for the all-subroutine 50x goal. Problem 48
remains open.

### Current-directory identity fast-path candidate (2026-10-14)

Because the current `current_working_directory` implementation measured 0.80x
the same helper at v5.88 in an earlier matched probe, an alternative was
benchmarked before considering an edit. It would stat the absolute `PWD` and
`.` first, returning `PWD` on matching device/inode and calling `getcwd` only
for invalid or mismatched values. In 25 alternating Docker pairs of 100,000
verified same-directory calls, this candidate took 248.306 ms versus 56.970 ms
for the current helper (0.23x). The extra filesystem stats make this path
substantially slower; no code was changed. The current-directory helper still
needs a better safe optimization, and Problem 48 remains open.

### Path-identity argument parsing candidate (2026-10-14)

NYTProf identified `_path_identity` as a repeated PathRegistry helper. A
positional-argument prototype kept the same `abs_path` and fallback behavior
and returned the same path for the direct helper probe; in 25 Docker pairs of
10,000 calls it measured 12.113 ms versus 14.584 ms for the existing named
argument interface (1.20x). To check whether that translated to useful work,
both forms were measured through `all_paths` on 50 configured skills with
byte-identical JSON required for every run. Across 31 alternating runs, the
full operation measured 0.210 ms baseline versus 0.209 ms with the prototype
(1.01x). Since there is no meaningful aggregate gain and the named option is
clearer, no code was changed. Problem 48 remains open.

### Current web-test profile and page-ID normalization candidate (2026-10-14)

A fresh NYTProf subroutine profile of `t/03-web-app.t` passed all 351 tests.
The highest project-owned exclusive entry was the Perl PBKDF2 fallback at
144 ms across the test's password-hash workload; this standard bench process
did not have the optional FFI modules on its default `@INC`, so this is not
the native production path. The profile also ranked PathRegistry layer
discovery, while the reported `IO::Select::can_read` stack count was misleading:
direct instrumentation of the same test observed 15 actual calls.

`PageStore::_normalized_page_id` showed 6.1 ms inclusive across 364 test calls.
A combined single-regex candidate preserved every result in a representative
input corpus but measured 0.93x the existing implementation over 25 alternating
Docker pairs of 100,000 calls. The candidate was rejected with no code change.
This profile/test workload helps prioritize future probes but does not claim
that the test call tree represents production route proportions. Problem 48
remains open.

### Cross-reader disabled-marker cache candidate (2026-10-14)

The profiled `paths -o json` flow obtains a nested-skill inventory and then
loads layered per-skill path configuration. A red-first test confirmed both
readers inspect `.disabled` for the same physical skills. A request-scoped
cache candidate preserved canonical output over 250 synthetic skills, but 31
alternating Docker pairs measured 7.811 ms uncached versus 7.814 ms cached
(1.00x). It was removed: fewer marker reads did not translate into a runtime
gain, and the cache would add state and operation-lifetime semantics. This
candidate is rejected; Problem 48 remains open.

### Builtin class, field, method, and signature dispatch candidate (2026-10-14)

Perl 5.40.1 Docker benchmark compared a blessed-hash getter using ordinary
`@_` access, the same shape with a lexical subroutine signature, and a builtin
`class`/`field`/`method` getter. All three returned the same value across two
million calls per sample. Twenty-one rotated pairs measured medians of 161.889
ms, 209.391 ms, and 211.423 ms respectively. The builtin class method and
signature variants were about 0.77x the existing method speed. No production
object conversion is justified by this result; Problem 48 remains open.

### XS-backed HTML escaping candidate check (2026-10-14)

`HTML::Entities::encode_entities($text, "<>&")` matched the project body
escaper for the tested Unicode strings, but `B` reported that entry point was
not an XSUB in the installed module. It was also slower in Docker: at 64, 4,096,
and 65,536 characters, medians were 0.34x, 0.14x, and 0.13x the current
`_escape_html` speed over 21 alternating pairs. No dependency or production
change is justified. A native Inline::C/XS body escaper would require its own
parity and whole-route measurement before consideration.

### Inline::C/XS body-escape and editor-highlight candidate (2026-10-14)

A reproducible Inline::C benchmark compares the exact body-escape helper and
`Web::App::_highlight_instruction_html`, with byte and UTF-8-flag parity checks
for raw bytes, Unicode, NUL, empty, and undefined inputs. It also requires
byte-identical full editor-highlight output for every timed sample. Across 21
alternating Docker pairs, the XS helper measured 4.25x, 16.31x, 14.97x, and
14.79x the Perl helper at 64, 4,096, 65,536, and 1,048,576 characters. The full
editor-highlight routine measured 2.33x, 10.63x, 8.60x, and 7.59x. Inline
compilation took 723.386 ms and is excluded from steady-call medians. This is
a promising result for one large-text path, not 50x and not a whole HTTP route.
It motivated the later compiled XS integration below.

### Compiled XS HTML body escaper integration (2026-10-14)

Expected outcome: use the measured one-pass C body escaper in installed builds
without changing HTML bytes, UTF-8 flags, overloaded-reference stringification,
or source-only developer tests. A red-first XS contract test failed because
HtmlEscape did not report or select a native backend. `HtmlEscape.xs` now
compiles into the Developer::Dashboard shared object; the MakeMaker mapping
loads its XSUB into `Developer::Dashboard::HtmlEscape`. The module uses XS only
for non-reference scalars when the extension exists and propagates all load
errors except the precise missing-object case, which explicitly selects the
documented Perl fallback. Overloaded references use Perl substitutions.

The first staged build exposed that `VERSION_FROM => lib/Developer/Dashboard.pm`
no longer works after the main module delegated its version scalar. MakeMaker
warned and emitted version 0, which would have made XSLoader reject the
extension. `VERSION_FROM` now points to the lightweight `Version.pm`, and a
red-first release-metadata assertion checks both source and generated
configuration without warnings. A staged Docker build compiled the `.xs`
source without warnings; all 19 focused XS test assertions passed, including
undef, empty, quotes, embedded NUL, Unicode, UTF-8 flags, overloaded values,
and exact public output. The existing HtmlEscape suite also passed 13 checks.

The native taint audit ran a taint-mode Perl process against the staged shared
object using an environment-derived input. It confirmed the escaped result
remains tainted and exactly equals the expected escaped text. A permanent
taint-mode subprocess assertion now covers both built and source fallback
paths.

The benchmark now compares the Perl reference, Inline::C, the shipped compiled
XS backend, and the rejected chunk-copy variant. Across 21 rotated Docker
samples with exact helper and complete highlighter output parity, production
XS measured 15.05x faster than Perl at 4,096 chars, 13.33x at 65,536, and
12.63x at 1 MiB. Full instruction highlighting measured 10.76x, 10.90x, and
9.53x at those sizes. Compile time is build-time, not included in call
latency. This is production progress for one text path, not a 50x or
all-subroutine result; Problem 48 remains open.

### XS dispatch coverage closure (2026-10-14)

The first full coverage run after the XS integration passed all 274 files and
24,061 tests but reported 99.9% branch and condition coverage. A focused
coverage run isolated the gap to `_escape_html`'s `XS_LOADED && !ref($text)`
dispatch: the normal source-only suite never sees a built XS object. The
red-first test change adds a scoped native-call stub to exercise both dispatch
outcomes without making source tests depend on a binary artifact. The focused
HTML escaper gate now passes 100.0% statement, branch, condition, and
subroutine coverage for `HtmlEscape.pm`, with 72 detail rows and no stale
uncoverable annotations. After updating the MakeMaker test fixtures to include
the XS source and lightweight version module required by `Makefile.PL`, the
complete Docker suite passed 274 files / 24,063 tests. Statement, branch,
condition, and subroutine coverage are all 100.0% across `lib/` (47,861 detail
rows, no stale uncoverable annotations). The required web security tests and
the broader Problem 48 50x-every-subroutine objective remain separate gates;
Problem 48 is still open.

### Single-pass Perl HTML-escape candidate (2026-10-14)

Tested replacing the shared helper's three substitutions with one substitution
and a three-entry replacement hash. The output matched for all four benchmark
sizes. In 11 alternating Docker pairs, however, the one-pass form was slower:
0.44x at 64 characters, 0.21x at 4,096, 0.20x at 65,536, and 0.21x at
1,048,576. The callback/hash lookup cost outweighs the saved scans, so no
production change is justified. Problem 48 remains open.

### FFI libc realpath path-identity candidate (2026-10-14)

Compared the current `Cwd::abs_path` path identity with FFI::Platypus calling
Linux `libc.so.6` `realpath(path, NULL)`, then measuring, copying, and freeing
the returned allocation. Exact output parity passed for an existing nested
directory and a symlinked spelling. Across 21 alternating Docker pairs of
1,000 iterations over both paths, `abs_path` measured 11.428 ms and the
allocation-safe FFI path 7.206 ms (1.59x). A reusable caller buffer measured
1.72x when allocated per call and 1.97x when allocated once per path, but the
fixed-size buffer is not acceptable for arbitrary path lengths. The safe
allocation form is a promising Linux-specific helper result, not a production
change or aggregate/all-routine result. A reusable Docker benchmark then
checked existing, symlinked, and missing paths and exact `Config::path_aliases`
JSON over 50 and 250 synthetic skills. Both workloads retained exact parity,
but the FFI aggregate measured 1.00x at both sizes (2.115/2.105 ms and
10.237/10.236 ms for baseline/candidate), so no production change is
justified. `FFI::CheckLib` discovery of libc produced warnings and a
container-process crash in the initial probe; the benchmark used explicit
`libc.so.6`. Portable library discovery, long paths, and other OS behavior
remain unproven. Problem 48 remains open.

### Runtime-layer directory snapshot candidate (2026-10-14)

Expected outcome: within one runtime-layer operation, avoid repeating the two
directory existence checks for each identical parent path without changing
layer freshness between operations. A red-first Docker assertion verified
that an operation-local snapshot would remain stable if `.d2` appeared midway
through a scope, while a later unscoped lookup noticed it. After implementing
that candidate, a focused helper probe ran 5,000 calls per sample over seven
Docker rounds: scoped/unscoped ratios were 1.03x, 1.00x, 1.01x, 1.01x, 0.97x,
1.02x, and 1.06x, with median about 1.01x. A second 31-pair `all_paths`
benchmark on the same four-layer fixture preserved exact JSON, but the
baseline and candidate medians were both approximately 1.00 ms (about 1.00x).
The cache lookup overhead erased the small filesystem-check reduction, so the
candidate and its temporary test were removed. No production change remains;
Problem 48 remains open.

### Fresh repeat of measured parser and static-render gains (2026-10-14)

To confirm the strongest existing >50x results still hold on the current
checkout, both parity-checked Docker benchmarks were rerun. The legacy parser
benchmark compared the v5.88 linear allowlist validation with the current
fixed-key membership/numeric-CODE check over 1,001 sections; 21 alternating
runs preserved canonical JSON and measured medians of 272.541 ms and 2.335
ms (116.72x). The static page benchmark compared the v5.88-equivalent
Template Toolkit processing path with the current unchanged-body fast path;
5,000 renders per sample over 21 alternating runs preserved Unicode output
and measured 0.07041 ms versus 0.00078 ms per render (90.04x). Focused Docker
PageDocument and PageRuntime tests passed 105 assertions. These results
confirm two individual routines, not the full inventory or every-subroutine
target; Problem 48 remains open.

### Inline::C chunk-copy HTML escape candidate (2026-10-14)

Expected outcome: use libc's `memchr`/`memcpy` to skip stretches without HTML
special characters and outperform the existing XS byte loop, while preserving
bytes, embedded NULs, UTF-8 flags, taint flags, undef, and empty values. A
red-first Docker test required a parity result from the benchmark and failed
before the candidate existed. The benchmark now checks exact parity for those
inputs and for the full instruction-highlighting output. In 21 rotated Docker
runs, the chunk-copy candidate was slower than the direct C byte loop at every
size: 0.001 ms versus below 0.001 ms at 64 chars (timer-limited), 0.018 versus
0.007 ms at 4,096 chars, 0.324 versus 0.115 ms at 65,536 chars, and 5.742
versus 2.262 ms at 1 MiB. For the complete highlighting operation it measured
1.87x, 4.36x, 4.42x, and 4.37x versus Perl at those sizes; the direct byte
loop reached 2.01x, 9.20x, 7.80x, and 6.58x. The approach is rejected for
production; the benchmark retains it as reproducible negative evidence.

### Inline::C lookup-table HTML escape candidate (2026-10-14)

A red-first Docker regression required a byte/UTF-8 parity marker before
accepting a lookup-table candidate. The candidate passed raw-byte, UTF-8,
embedded-NUL, undef, empty, and complete instruction-highlighting parity. In a
staged build with the production XS extension loaded, 21 rotated samples
compared Perl, production XS, direct-loop Inline C, chunk-copy, and lookup
table. At 1 MiB, the production loop measured 13.16x faster than Perl for
escaping and 9.26x for full instruction highlighting; lookup-table measured
11.04x and 8.18x. It was also slower than production at 4 KiB and 64 KiB for
the helper. The table implementation was rejected and removed from production;
the benchmark retains it as negative evidence. A compiled 1 MiB XS parity
case remains in the regression suite. Problem 48 remains open.

### Problem 48 distribution-aware XS HTML escaping (2026-10-14)

Expected outcome: preserve exact HTML output while avoiding the direct native
byte-loop regression on plain Unicode and rare-escape text. Reproduction runs
`script/problem48-inline-html-escape-benchmark --runs 21` after staging the XS
extension in Docker, over dense, sparse, and plain Unicode input at 64 B,
4 KiB, 64 KiB, and 1 MiB. The original direct byte loop reached 13.58x versus
Perl for 1 MiB dense input, but only 0.74x for sparse input and 0.07x for
plain text; the full highlighter measured 7.65x, 0.79x, and 0.35x.

The public wrapper now locates the first escapable character with Perl's
optimized `index` operation. Text with no such character is returned unchanged;
an escape in the first 64 characters uses the direct XS loop, while later
first matches use an XS `memchr`/`memcpy` chunk-copy helper. This keeps dense
inputs on the fast loop and avoids byte-by-byte scanning of long plain spans.
The red-first source-only test first failed because sparse input still called
the direct path. Tests now assert the plain, sparse, dense, undefined, and
reference routing outcomes; staged XS checks include exact 1 MiB dense,
sparse, and Unicode plain output, byte digests, UTF-8 flags, and taint.

After implementation, all 42 staged XS test assertions passed. Across 21
rotated Docker pairs at 1 MiB, exact-output parity held and the production
helper measured 12.40x, 3.08x, and 1.02x faster than Perl for dense, sparse,
and plain workloads. Complete instruction highlighting measured 9.02x, 1.74x,
and 1.00x. The benchmark now records all three distributions and retains the
slower lookup-table experiment only as negative evidence. This is a balanced
improvement to one HTML-escaping path; the all-subroutine 50x Problem 48 goal
remains open. The final init-enabled Docker coverage gate passed 274 files /
24,088 tests with 100.0% statement, branch, condition, and subroutine coverage
across lib/ (47,881 detail rows; no stale uncoverables). The first run without
container init exposed five unrelated process-reaping test failures; all five
passed standalone and on the full gate with init enabled.

### Scoped skill-layer inventory candidate (2026-10-15)

A red-first Docker regression confirmed that `skill_layers` rescans each
runtime skills root even after the same operation has built the shared
installed-skill directory inventory. A candidate used that inventory's name
lists while continuing to recheck directory existence and disabled markers;
focused PathRegistry and web-app tests passed, including home/project order,
disabled masking, and next-operation freshness. The first benchmark that omitted
the runtime-layer request scope misleadingly measured 13.67x and was discarded.
The corrected benchmark matched `Web::App::handle` by establishing both request
scopes, using one lookup per skill, and comparing 250 skills across two layers.
Across 21 alternating Docker runs it preserved exact ordered layers but measured
2.7361 ms for the current root scan and 2.5539 ms for the candidate (1.07x).
A 1,000-skill, 31-run confirmation measured 9.4831 ms and 8.8410 ms (also
1.07x). This gain is too small to justify production complexity against the
50x objective; the production change and candidate-specific regression were
removed. The benchmark remains as reproducible negative evidence. A fresh
NYTProf run of `t/03-web-app.t` showed 767 `PathRegistry::runtime_layers`
calls (0.081 s inclusive) and 26 `_nav_items_html` calls (0.082 s inclusive),
but those are instrumented test totals, not production latency. Problem 48
remains open.

### Early-but-rare escape dispatch follow-up (2026-10-15)

Expected outcome: preserve output while routing long text with an escape near
the beginning but very few early escapes away from the full direct byte loop.
The reproduction workload starts with `<` and contains only two additional
escapes across a 1 MiB input; before the fix, the first-match-only policy chose
the direct loop. A red-first test stubs that direct helper to fail and confirms
the chunked helper is selected, then checks dense inputs still use the direct
path.

The dispatcher now samples the first 16 characters: up to 64-character inputs
with an escape retain the direct loop; longer input uses it only when at least
four escapes occur in that prefix. Other escaped long inputs use chunk-copy.
This adds a bounded count but leaves plain text on the no-escape fast return.
The staged Docker MakeMaker build compiled the production XS and all 44
assertions in `t/665-problem48-xs-html-escape.t` passed, including 1 MiB exact
bytes, UTF-8 flags, NUL, taint, and reference behavior. Source-only focused
tests also passed; the optional Inline benchmark test explicitly skipped in
the standard dev image because Inline is not installed. The full Docker gate
then passed 275 files / 23,738 tests with 100.0% statement, branch, condition,
and subroutine coverage across lib/ (47,889 detail rows, no stale
uncoverables).

The 21-sample compiled-XS benchmark with exact output parity measured the 1 MiB
prefix-sparse helper at 2.65x versus Perl and full instruction highlighting at
1.69x; dense inputs measured 10.98x and 10.18x, ordinary sparse inputs 2.72x
and 1.85x, and plain inputs remained near parity. This addresses one measured
distribution-specific regression only. Problem 48's all-subroutine 50x
objective, release gates, and commit remain open.

### Fresh NYTProf workload-quality check (2026-10-15)

A fresh `subs=1` profile of `t/03-web-app.t` completed successfully. Its largest
sampled paths were not CPU work in Dashboard routines: 6,994,785 profiler ticks
were under `IO::Select::can_read` while draining saved-Ajax streams, and
3,811,703 were under `system` captured by the test harness. The profile also
showed FFI::CheckLib discovery during Auth PBKDF2 setup and Template Toolkit
parsing during nav-fragment rendering, but their test-mixed sample counts do
not establish production route cost. This confirms that reusing the whole test
profile as a ranking of production hotspots would misdirect optimization. The
next profile must isolate a representative saved-page or status request and
report wall-clock request latency alongside subroutine samples before another
production edit is selected. No code change is justified by this test-mixed
profile alone; the 50x-per-subroutine goal remains open.

### Request-scoped Template Toolkit scalar parse reuse (2026-10-15)

Expected outcome: repeated rendering of identical scalar TT source within one
request should avoid reparsing while preserving each render's dynamic stash,
TT metadata, INCLUDE lookup, and established parse-error reporting. The
red-first Docker regression counted two parser calls for two identical
renders; after the change it counts one, and a fresh request reparses. Different
sources parse independently. Direct calls without a request scope stay on the
original scalar processing path.

The request-local cache stores only successful parse trees and creates a fresh
`Template::Document` for every render, avoiding shared mutable document state.
It is bounded at 16 source strings, 256 KiB per source, and 1 MiB aggregate
source text per include-root set. Parse initialization, parse, document
construction, oversized-source, and cache-limit fallbacks were tested; invalid
TT remains visible through the normal runtime error path. The focused Docker
suites `t/390-page-modules-coverage.t` and
`t/663-problem48-template-service-benchmark.t` passed 91 assertions after the
follow-up fallback checks.

An alternating 21-run Docker benchmark used one Template Toolkit service per
request, five renders per request, and a real INCLUDE file in both arms. With
five identical sources it measured 0.2083 ms per render without parse reuse
and 0.1505 ms with reuse (1.38x); with five distinct sources, 0.2188 ms versus
0.2252 ms (0.97x). Output was exact in both workloads. The cache helps repeated
sources within one request; distinct-source behavior is near parity with a
slight regression. This is not end-to-end request latency and does not meet the
50x-per-subroutine target. The full Docker suite ran 275 files / 18,117 tests
but exited 2 on repository tracking and Git-safety/identity setup failures in
`t/13`, `t/15`, `t/158`, and `t/34`. A preliminary PageRuntime report from that
run was 100.0% statement/subroutine, 99.0% branch, and 99.3% condition before
the final boundary tests were added; the focused additions pass, but aggregate
coverage needs a clean rerun. The next step is to profile the updated isolated
saved-page request and use that call tree to select the next candidate.

### Resident paths benchmark recheck (2026-10-15)

The existing resident-handler benchmark was rerun in Docker with 50 synthetic
skills and 21 paired samples. It reported exact output parity and a 6.41x
median speedup over starting a fresh `paths -o json` helper process
(23.381 ms versus 3.650 ms). The freshness probes passed for replacement of
global config, changes to skill `Folder.pm`, and addition/removal of skills.
The resident handler still refreshes its discovered config and module state at
each request; this result is not evidence for a stale-cache shortcut or a 50x
result. It remains a prototype benchmark, not a production change.

A 2026-10-15 Docker recheck with the same 50-skill, nine-run workload again
preserved exact output and all freshness probes. The fresh helper median was
23.184 ms and the resident handler median was 3.525 ms (6.58x). This is
consistent with the previous result, does not meet 50x, and does not justify
shipping the prototype as a production runtime.

A request-isolated saved-page profile could not yet be started: Docker Compose
reported that all predefined address pools were subnetted while creating its
temporary `dev` service network. No existing container was stopped or modified
to work around this host-level allocation failure. The next step remains a
request-isolated profile and latency measure in Docker, followed by a
separately measured production candidate. Problem 48 remains open.

### Saved-page worker-cache and request-snapshot follow-up (2026-10-15)

The Compose network-pool limitation above was avoided safely for this isolated
profiling run by using `network_mode: none`; no running or unrelated container
was stopped. The current saved-page request was then profiled in Docker after
the Template Toolkit worker cache had been introduced. NYTProf exposed that a
cached TT parse tree still caused `Template::Document->new` to `eval` its
generated Perl block for every render. The cache now retains the compiled
block references and builds a new `Template::Document` for each render, keeping
request stashes, TT services, and INCLUDE file resolution fresh. A red-first
test observed four scalar-block compilations across two source bodies rendered
over multiple requests; it now requires one compile per distinct body. The
focused PageRuntime suite passed 88 tests.

The same route profile found repeated machine-interface command lookup and
canonical path/runtime-layer existence checks. Web workers now cache the
machine-address candidate list for five seconds. A request-scoped path identity
memo and runtime-layer directory-existence snapshot are discarded at request
end; an unscoped operation immediately observes layer creation/removal. Red-
first tests verified path-scope presence and cleanup, plus the filesystem
snapshot boundary. The focused Web App, Web update, PathRegistry, PageRuntime,
and benchmark tests passed 1,044 assertions in Docker.

The final isolated comparison used 15 alternating runs each of the checked-out
code and a read-only Git archive of v5.88, on the same image/Perl, temporary
HOME, saved page, warmup, and 9,573-byte response. Median request latency was
0.497 ms for the current code and 1.673 ms for v5.88 (3.37x). Disabling compiled
template reuse measured 0.656 ms (1.32x slower); disabling the five-second
address cache measured 0.522 ms (1.05x slower). A separate cache-on versus
cache-off test for runtime-layer existence snapshots measured 0.485 ms versus
0.506 ms (1.04x). Exact body size and the page marker matched in every run;
there were no benchmark container warnings. These are route-specific results,
not an all-subroutine speedup. A final NYTProf trace still shows indicator-file
directory enumeration and runtime response assembly as recurring request
costs. The 50x objective remains open.

The full Docker coverage attempt after these changes ran 275 files / 18,148
tests, but could not produce a valid aggregate coverage verdict because the
suite failed in environment-sensitive repository/operator tests (`t/13`,
`t/15`, `t/158`, and `t/34`) and one cache-aware fixture in `t/105`. The latter
was stale test state: its direct machine-IP discovery assertion reused an
instance-level cached value. Clearing only that fixture's cache made the full
`t/105` test pass. The remaining suite failures concern Git safe-directory /
identity, network access, or the current tracked-input view; they do not
exercise the Problem 48 changes. A follow-up focused Docker coverage run passed
all 1,482 selected assertions and measured statement/branch/condition/
subroutine coverage of 78.3/52.9/50.5/77.3% for `PageRuntime.pm`,
87.3/79.3/75.5/91.8% for `PathRegistry.pm`, and 96.4/91.6/93.1/96.8% for
`Web/App.pm`. These are focused-run measurements, not whole-library coverage;
the canonical full-coverage gate must be rerun in a clean Docker Git/network
environment before claiming the gate passes.

### Saved-page profile reinspection (2026-10-15)

The retained NYTProf line reports were re-read after the worker-cache changes.
Across the 110-request profile, `PathIdentity::_path_identity` was entered 1,030
times and accounted for 7.634 ms instrumented line time; indicator ordering
accounted for 3.762 ms across 110 calls, and legacy CODE-section ordering for
4.457 ms across 550 comparator calls. These profiler totals are useful for
ranking repeated work, not uninstrumented latency estimates. Path identity
already has request-local exact-spelling reuse, and the earlier FFI realpath
experiment produced only parity at the complete path-alias API level. The
remaining candidate gains are therefore small against the measured 0.497 ms
route median and do not justify weakening filesystem freshness or portability.
No additional production optimization was selected from this trace. The next
optimization must be driven by an isolated representative route profile and
paired wall-clock benchmark; the full 50x objective remains open.

### Cross-request Template service reuse rejected (2026-10-15)

A Docker experiment tested reusing one Template Toolkit service while forcing
`STAT_TTL => -1`, then rewriting an included template and restoring its exact
mtime before the next process call. The reused service returned the old
content (`first`); a newly constructed service returned the edited content
(`second`). Thus even aggressive provider stat refresh does not preserve the
existing immediate-freshness contract for same-mtime edits. No production
change was made; any future service-reuse candidate must explicitly refresh
the provider cache without weakening this behavior and show a paired latency
gain first.

### Numeric CODE-section sorting candidate rejected (2026-10-15)

The retained route profile showed numeric CODE-section sorting as repeated
work, so an isolated Docker comparison measured the existing regex comparator
against extracting each numeric suffix once before sorting. Both produced
identical order for 5 and 1,001 sections across 31 alternating samples. The
decorated version was 1.31x at 5 entries but 0.95x at 1,001; the common-case
absolute saving was about one microsecond per sort, while large documents
regressed. No production change was made because the result does not justify a
special-case branch for negligible route benefit.

### FFI path identity on the saved-page route rejected (2026-10-15)

The earlier 1.59x isolated FFI `realpath` result was rechecked through the
actual saved-page handler, with the existing request-local exact-path cache
left enabled. In 21 alternating Docker pairs, baseline median latency was
1.657 ms and the FFI variant was 2.072 ms (0.80x baseline/candidate, or about
25% slower). Both returned 9,573-byte bodies; their SHA-256 matched after
normalizing the live datetime field. FFI call and allocation overhead erased
the isolated helper gain on this request, so no production change was made.

### Collector-backed status route profile (2026-10-15)

Expected outcome: repeated `/system/status` requests with unchanged collector
configuration should compare each persisted indicator once per synchronization,
return byte-identical response data, and observe disk changes on the next
request. Reproduction: in an isolated HOME, seed 50 collector indicators, warm
the endpoint once, then profile 100 `Web::App->handle('/system/status')`
requests with NYTProf enabled only around the request loop. The Docker profile
returned HTTP 200 and a 12,687-byte body on every request. Before the fix it
recorded 5,000 calls to `_collector_sync_plan`, 15,000 calls to
`_read_indicator_file`, and 15,100 calls to `PathRegistry::indicators_roots`;
`sync_collectors` had 2.40 seconds inclusive profile time over the 100 calls.
The root cause was that each collector sync separately resolved the same roots
for effective state, local state, and final inventory, then decoded each file
again at each lookup.

The first Docker regression run was red: a 12-indicator steady-state sync
resolved roots 37 times instead of once. The implementation now gives one
`sync_collectors` call a roots snapshot and decoded-file cache; the final
inventory reuses both. Writes and deletions invalidate their entries, and the
cache ends at sync return. Tests verify one root resolution and one physical
read per file, next-sync visibility of changed state, and correct listing after
collector retirement. The focused Docker suites passed 229 assertions.

On the same 50-collector `/system/status` workload, 15 alternating unprofiled
Docker pairs measured 9.203 ms/request before and 2.689 ms/request after
(3.42x), with exact response-byte parity. Both variants returned HTTP 200 and
12,687 bytes. In the request-scoped NYTProf recheck, physical status-file reads
fell from 15,000 to 5,000, indicator-root resolutions from 15,100 to 100, and
`sync_collectors` inclusive time from 2.40 s to 513 ms across 100 calls. These
figures establish a collector-heavy route gain, not a 50x improvement for all
subroutines; Problem 48 remains open.

### Single-root collector lookup follow-up (2026-10-15)

The initial follow-up profile was first read from the installed `/root/perl5`
copy rather than this checkout, so it was not valid evidence for the source
changes. The profile was rerun in Docker with `/work/lib` explicitly first in
`@INC`; it confirmed the checked-out implementation performs 101 root
snapshots across 100 requests, not 15,100. Its repeated local-state and
inherited-state reads were therefore not the remaining source bottleneck.

In the collector plan, the effective indicator lookup already reads the only
possible root when the snapshot has one entry. The local lookup then repeated
that work, and a placeholder-missing record caused an inherited lookup even
though there was no inherited root. A red-first test counted both calls across
12 indicators and failed before the change (12 local plus 12 inherited calls).
The planner now reuses the existing record for the single-root case and skips
the impossible fallback. Multi-root behavior remains unchanged. The focused
Docker regression passes all 10 assertions and still verifies fresh disk state
on the next sync and correct collector retirement.

The matched 50-collector Docker status workload retained exact 12,687-byte
responses and measured 7.708 ms/request for the legacy strategy versus 2.195
ms/request for current source (3.51x). The correctly source-bound NYTProf
profile showed `_local_indicator` and `_nearest_inherited_indicator` were not
called in the one-root workload. `_collector_sync_plan` remains a leading
inclusive cost, and one physical read per persisted indicator is retained to
preserve cross-process freshness. This is a narrow incremental gain; the
all-subroutine 50x goal remains open.

### Direct v5.88 status-route comparison (2026-10-15)

To verify progress against the named baseline rather than only against a
current-source compatibility strategy, the same `/system/status` workload was
run against the preserved v5.88 tree and the checkout in the same Docker image.
Each run used an isolated HOME, 50 configured collectors, the same request
shape, and exact body comparison at every sample. Across 15 run samples, both
versions returned byte-identical 12,687-byte responses. The median was 35.090
ms/request on v5.88 and 1.624 ms/request on the current checkout, a 21.61x
route-specific speedup. This is direct evidence against v5.88, but it is not
evidence that every subroutine is 50x faster; the full objective remains open.

### Stable collector-sync freshness cache (2026-10-15)

Red-first Docker tests showed the stable sync repeated 12 collector plans and
12 physical reads for 12 indicators. The implementation now caches raw JSON
bytes across sync calls only while high-resolution status-file signatures,
active collector configuration, and directory inventories are unchanged. It
decodes fresh Perl values for each request and falls back to reconciliation on
any detected change. Focused coverage verifies atomic external replacement,
API mutation, collector retirement, deletion/recreation, config changes, and
caller mutation isolation. The same 50-collector status route returned exact
12,687-byte bodies and measured 0.670 ms/request versus 35.090 ms on v5.88
(52.37x). The source-bound profile shows status content is not reread on the
stable path, though per-file metadata checks remain. This is one-route evidence
only; the every-subroutine 50x objective remains open.

### Validated status-response reuse (2026-10-15)

The first serialized-body cache still rebuilt and sorted the in-memory status
payload on every stable request. A red-first Docker regression counted those
payload builds and failed when a second unchanged request rebuilt it. The route
now asks the collector sync for its validated unchanged result: only when a
previous response exists and sync confirms the active collector config,
high-resolution status-file signatures, and directory inventory are unchanged
does it reuse the body and bypass payload construction. Changed indicator or
collector state takes the full payload and serialization path. Tests verify
that stable bodies remain byte-identical, the payload builder is skipped only
for the stable response, and an API-persisted change appears in the next body.

In the same Docker image and isolated 50-collector workload, 31 samples measured
34.257 ms/request on v5.88 and 0.597 ms/request on the current source (57.38x).
Both returned exact 12,687-byte responses. This clears the target for this
single route/workload, not the broader requirement to accelerate every
subroutine by at least 50x; Problem 48 remains open.

The final clean Docker coverage gate for this iteration passed 277 test files /
23,871 tests. Statement, branch, condition, and subroutine coverage across
`lib/` were all 100.0% (48,324 detail rows, no stale uncoverable annotations).
The required OWASP gate and web-update, static-file, and TLS regression suites
also passed. The Docker image's `perldoc perlsec` frontend failed because no Pod
formatter is installed; the complete core `perlsec.pod` source was reviewed
directly instead. The cache change introduces no command execution, route,
authentication, path, or cryptographic behavior; its freshness contract is
covered by the atomic-replacement, configuration-change, retirement, and
persisted-update tests above. Problem 48 is still open because evidence for
this one route cannot prove 50x speedup for every routine.
### Blank-container install test isolation correction (2026-10-15)

The first `cpanm` test-install of the 5.94 tarball failed only at
`t/08-web-update-coverage.t`: its empty-IP assertion inherited a machine
address cached by earlier route assertions. This made the test depend on
test order and the Docker host's network interfaces, rather than the behavior
it intended to exercise.

The fixture now clears the worker-local address cache before checking empty
interface discovery. The prior full blank-container run reported 276 passing
test files and one failing file; the focused Docker rerun passes all 286
assertions. Version 5.95 carries the correction. Its full `cpanm` install
gate subsequently passed in a blank Docker environment; the broader 50x-per-
subroutine objective remains open.

### Event-driven stable indicator validation (2026-10-15)

Expected outcome: on Linux with optional FFI::Platypus installed, an unchanged
collector inventory can avoid repeated `readdir` and high-resolution `stat`
calls, while file writes, metadata changes, directory creation/deletion, and
renames force the existing full validator before cached data is reused. On
unsupported systems or without FFI, the portable validator remains active.

The red-first store contract in `t/670-problem48-indicator-sync-watch.t`
failed before integration because the sync path did not configure a watcher,
still enumerated roots on a stable request, and still statted every file. The
adapter in `Developer::Dashboard::IndicatorStore::Watch` binds libc's
`inotify_init1` and `inotify_add_watch` through FFI::Platypus. It watches each
indicator root and each existing indicator directory. Any queued record is
treated as invalidation, including queue-overflow and ignored-watch events;
the code does not interpret filenames. A portable full validation is performed
once after installing a new watch set to establish the scan-to-watch baseline.

An initial benchmark was 0.96x at 50 indicators because the watch mask also
included access/open events generated by the portable benchmark arm. The mask
was narrowed to mutations only (`MODIFY`, `ATTRIB`, `CLOSE_WRITE`, create,
delete, and move events); queue overflow remains delivered independently of the
mask. The paired Docker benchmark in
`script/problem48-indicator-watch-benchmark` then ran 21 alternating samples,
100 calls per sample, and exact inventory comparisons. The stable helper
measured 0.001600 ms per call with inotify versus 0.256500 ms with the portable
validator (160.33x). The same run verified an external status write invalidated
the watcher and appeared in the next full sync. The latest native-enabled
focused tests pass 116 assertions across the adapter and store integration,
including real Linux inotify writes and visible fallback warnings. All five
focused Problem 48 files pass 210 tests. This helper-level result is not a
direct v5.88 or whole-dashboard comparison.

This clears 50x for the stable `_collector_sync_files_unchanged` workload
versus its pre-watch portable validator at 50 indicators on the tested Linux
Docker runtime. It is not a direct v5.88 component comparison and does not
establish 50x for other routines, platforms without inotify, changed-state
reconciliations, or the whole dashboard. The Problem 48 all-subroutine target
remains open.

### Inotify FFI feasibility probe and profiler workload rejection (2026-10-15)

A fresh isolated Docker `dev` run installed and tested FFI::Platypus 2.12, then
bound libc `inotify_init1` and `inotify_add_watch`. With one directory watch,
10,000 nonblocking `IO::Select->can_read(0)` polls averaged 0.000941 ms each;
creating a file in the watched directory produced a readable 128-byte event
record. This confirmed that an optional Linux event source was technically
available, but that first probe did not test queue overflow, watcher
replacement, concurrent status-file writes, watch-limit exhaustion, or
end-to-end dashboard latency. Those gaps were addressed by the later integrated
adapter, event-invalidation tests, and paired stable-sync benchmark above.

A separate attempt to use NYTProf around all of `t/03-web-app.t` was rejected
as route evidence. That test includes subprocess setup, helper-account PBKDF2,
and many unrelated routes; the instrumented run exited with six assertion
failures while the ordinary Docker run passed all 355 assertions. The profile
was dominated by test setup and password hashing, and report generation on the
host emitted source-path warnings because the profile came from the container.
Those measurements are not used to select or claim an optimization. A next
profile must isolate one stable request path, validate its response parity,
and avoid timing-sensitive assertions under instrumentation. Problem 48's
50x-per-subroutine target remains open.

### Full Docker coverage rerun after config-merge closure (2026-10-15)

`d2 docker compose exec dev perl script/coverage-gate` completed successfully:
281 test files and 24,151 tests passed; statement, branch, condition, and
subroutine totals were all 100.0% (48,963 detail rows, no stale uncoverable
annotations). The malformed-ZIP tests emitted their expected parser diagnostics
while passing. The container's `perldoc perlsec` command exited 13 because no
POD text formatter is installed; the full core `perlsec.pod` source was read
directly in three consecutive ranges. This closes the current coverage gate,
not the all-subroutine 50x performance objective or remaining delivery gates.

### Matched status-route rerun and current NYTProf call tree (2026-10-15)

The production-boundary benchmark was rerun with 50 synthetic collectors,
100 requests per sample, and 21 samples against both the v5.88 tree and the
current source. Both returned HTTP 200 and byte-identical 12,864-byte bodies
(SHA-256 `da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`).
Median latency was 72.415810 ms/request on v5.88 and 0.249081 ms/request on the
current source (290.73x for this endpoint and fixture only). Run-to-run variance
means this is a refreshed measurement, not an incremental gain attributed to
the config-merge follow-up.

A current-source NYTProf run profiled only the warmed 500-request loop and kept
the same body hash. The instrumented request median was 1.313282 ms; it is not
a wall-clock performance figure. The largest application source-line totals in
the generated CSV were JSON decode (22.703 ms / 500 calls), JSON encode
(15.320 ms / 1,000 calls), indicator projection (10.122 ms / 25,000 entries),
and `dispatch_request` (9.960 ms / 500 calls). Path discovery and secure
runtime metadata checks also recur on the request path. These results identify
different costs rather than a single universal accelerator; no code change is
justified by the trace alone, and the all-subroutine 50x target remains open.

The same NYTProf invocation was run for 100 warmed requests against v5.88 and
current source. Both profiles returned the same body hash. Under instrumentation,
v5.88 measured 169.546802 ms/request and current source 1.108379 ms/request
(152.97x); this is profiler-bound evidence, not a production latency ratio. The
line reports show the principal call-count change: `abs_path` was called
808,400 times in v5.88 versus 400 times currently (2,021x fewer), and the old
trace made 100,800 `getpwuid` calls while the current trace had no such call.
On the same 100-request workload, JSON decode fell from 20,000 calls to 100,
and JSON encode from 25,300 calls to 200. This traces the route-level gain to
eliminated repeated discovery/serialization work, but it still says nothing
about uncalled routines or every routine's independent speedup.

### Parsed-config clone cache candidate rejected (2026-10-15)

The current profile shows one JSON decode per request for the merged global
config. To test whether a metadata-validated parsed-tree cache could avoid that
work without sharing mutable config objects, an isolated Docker probe compared
`JSON::XS` decode with cloning a cached decoded tree using core `Storable::dclone`.
The 8,504-byte, 50-collector fixture preserved canonical JSON exactly. Across
21 alternating rounds of 5,000 operations, median decode time was 240.356 ms
and median clone time was 348.680 ms; cloning was only 0.69x as fast. This
candidate is rejected: it would add cache invalidation and ownership complexity
while making config reconstruction slower. The current request-fresh config
read remains unchanged.

### Bounded state-metadata JSON scalar reuse (2026-10-15)

NYTProf showed one state-metadata JSON encode on each identical status request.
A red-first Docker regression in `t/97-pathregistry-coverage.t` failed because
two identical metadata calls invoked `json_encode` twice, and also required a
changed runtime root or application name to regenerate the correct payload.
`PathRegistry` now keeps one encoded scalar for the latest exact pair. It does
not cache parsed data or filesystem trust: every call still creates/hardens the
directory as needed, performs `lstat`, rejects symlinks/non-files/foreign owners,
requires mode 0600 for reuse, opens and reads the existing bytes, and rewrites
stale state visibly. The test passes all 318 assertions, including key changes,
exact JSON contents, and a defined-name request rejecting an undefined-name
cache entry. Malformed cache entries lacking required encoded fields are
treated as misses rather than producing an uninitialized-value warning.

The warmed 50-collector status route preserved the exact 12,864-byte response
hash. Its current median was 0.247939 ms/request versus 0.249081 ms in the
preceding run; this difference is within noise and no route gain is claimed.
The optimization removes one encode operation when the same state identity is
revisited, but does not establish the all-subroutine 50x objective.

The clean Docker coverage gate was rerun after this change. All 281 test files
and 24,160 tests passed; statement, branch, condition, and subroutine coverage
were each 100.0% (48,989 detail rows, no stale uncoverable annotations). This
closes the current coverage gap, not the broader performance objective or
remaining Problem 48 delivery gates.

### Post-change NYTProf hotspot map (2026-10-15)

The warmed 50-collector `/system/status` workload was profiled again after the
state-metadata cache change: 100 requests returned the same 12,864-byte body
and SHA-256 as the prior runs. NYTProf's instrumented median was 1.560960
ms/request; this is not a production timing or a direct v5.88 comparison. The
largest inclusive totals in the application call tree were
`_request_config_snapshot` (52.2 ms / 100 requests), `Config::load_global`
(46.8 ms / 100), `_page_status_payload` (32.2 ms / 100), and
`PathRegistry::runtime_layers` (24.1 ms / 300 calls). The top exclusive cost
was `Config::_merge_named_hash_array` at 6.05 ms / 100 calls. These totals
overlap by design and must not be summed. The next candidate is layered config
loading/merging; an optimization must retain next-request visibility of
external file edits and exact merged-config semantics. The all-subroutine 50x
objective remains open.

### Matched v5.88/current status-route profile and microcheck (2026-10-15)

The same warmed 50-collector `/system/status` harness was profiled against
`/work/nytprof/v588/lib` and current `/work/lib`, 100 requests each. Both
returned HTTP 200 and the exact 12,864-byte response hash. Instrumented medians
were 165.528901 ms/request for v5.88 and 0.959980 ms/request currently (172.43x
for this route/workload under NYTProf, not an unprofiled ratio).

The subroutine report appeared to show `_ip_is_loopback` slower currently,
although the routine body is unchanged between the two source trees. A separate
unprofiled 21-sample microbenchmark of 100,000 identical IPv4 loopback checks
per sample measured 538.9 ns/call on v5.88 and 433.1 ns/call currently; all
2.1 million checks in each tree returned true. This demonstrates profiler
distortion for tiny methods in this trace. Use NYTProf primarily for call-path
and call-count selection, then validate individual hot methods with direct
microbenchmarks. The route result does not prove 50x for every subroutine.

### `_merge_named_hash_array` v5.88/current direct benchmark (2026-10-15)

To check the NYTProf-ranked config merge routine outside profiler overhead, both
source trees merged the same pair of 50-item arrays with unique names, nested
settings, and no collisions. Canonical JSON output hashes matched exactly
(`a2a48266e4168e41d4add395fa11950a53a099926c83dd6067c64a0dec89fcc5`), and
each tree returned 4,200,000 total items across 21 batches of 2,000 calls.
Median time was 32.975 microseconds/call for v5.88 and 30.609 microseconds/call
currently (1.08x). The routine is already modestly faster per call, but not
close to 50x; no change was made because the prior nested-loop variant also
provided only a small gain without compelling route-level improvement.

### `sync_collectors` direct v5.88/current benchmark (2026-10-15)

To isolate the largest remaining collector-sync cost from the status route,
both trees seeded the same 50 named indicator records in private temporary
homes, then ran the production stable-sync call 100 times per sample across 21
samples. The current implementation returned the same canonical indicator
inventory before and after the timed loop. The v5.88 implementation took a
median 46.966250 ms per call; current source took 0.133100 ms per call (352.86x
faster for this stable 50-indicator workload). This is an unprofiled direct
measurement, not a general application-wide ratio. It independently confirms
the watcher-backed freshness path's benefit without NYTProf overhead.

### Standalone `Config::load_global` cost and profile (2026-10-15)

A direct 50-collector comparison used the same private-home configuration in
both trees, checked the canonical output hash
`6209a8a5f7c423f2a882d1897f5e6e5f2d7e70c59908fddbb567983f67f5fa6e`, and
confirmed that a saved external edit was visible on the next load. With fresh
per-call path scopes, v5.88 measured 0.076998 ms/load and current source
0.146348 ms/load (current is 1.90x slower in this standalone API workload).
This does not contradict the much faster production status route: the route
uses request-scoped config and path inventories and avoids repeated old-version
work. It does identify a remaining method-level gap rather than supporting a
universal 50x claim.

NYTProf over 250 current-source loads (250 collectors in the fixture) ranked
`_merge_named_hash_array` at 11.4 ms exclusive, `_ancestor_runtime_layers` at
6.66 ms, `_layer_dir_for` at 5.48 ms over 750 calls, and `config_roots` at
5.06 ms exclusive / 39.3 ms inclusive. Those instrumented figures select the
next path-discovery and merge checks; they are not wall-clock timings. No code
change is justified until the equivalent production-scoped call is isolated
and any proposed cache preserves next-request filesystem freshness.

### Scoped runtime-path snapshot fast paths (2026-10-15)

Two red-first cases exposed redundant work within an already scoped runtime
layer operation: `_layer_dir_for` selected `.developer-dashboard` and then
rechecked for `.d2` on repeated calls, and `_ancestor_runtime_layers` still
performed project-root and canonical ancestry checks when cwd exactly equaled
home. `_layer_dir_for` now caches the first directory-name choice only inside
`_runtime_layer_candidate_scope`; a later unscoped operation still sees a
newly created `.d2`. `_ancestor_runtime_layers` now returns immediately for an
exact home cwd while symlink-spelled paths still use canonical ancestry.
The helper also rejects undefined, empty, and reference-valued parent paths
with an explicit contract error rather than leaking incidental Perl warnings.

The scoped 50-collector standalone `Config::load_global` median fell from
0.146348 ms to 0.084262 ms/load (1.74x faster across both changes), with the
same canonical hash and external edits still visible on the next load. The
v5.88 median for that API fixture was 0.076998 ms/load, so the expanded current
layer semantics remain about 1.09x slower in isolation. The production status
route continued to return the same 12,864-byte response hash; three post-change
21-sample medians varied from 0.237870 to 0.288861 ms/request, so no route gain
is claimed from this change. `prove -Ilib` passed the four affected Docker test
files (418 tests). These focused path fast paths do not establish the global
per-subroutine 50x goal.

### State-root permission-check de-duplication (2026-10-16)

The next fresh profile used 100 warmed 50-collector `/system/status` requests.
The response remained HTTP 200 with the exact 12,864-byte SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`.
NYTProf showed `_ensure_state_dir` called 400 times and taking 2.82 ms exclusive.
Inspection found `state_root` and `_state_root_for_layer` hardening a directory
immediately before `_write_state_metadata` performed the same creation and
permission check. Red-first assertions failed at two checks per root; after
removing only the duplicate calls, they observed one while retaining metadata
creation and aggregate `all_paths` semantics. Focused Docker tests passed 361
assertions. The profiled helper fell to 300 calls / 0.523 ms; total instrumented
route time moved from 0.883100 to 0.851929 ms/request, not production timing.
An unprofiled 21-sample route check measured 0.250821 ms/request versus
0.249081 ms previously, within noise, so no route gain is claimed.

A separate `_configured_indicator_jobs` shortcut was tested against the
existing collector merge. Exact-output alternating measurements over 1,000
iterations were 60.192 ms for the current implementation and 70.158 ms for the
candidate (0.858x); it was rejected. The later clean Docker coverage gate
passed 281 files / 24,182 tests, with all four `lib/` metrics at 100.0% (49,039
detail rows; no stale annotations). Neither result changes the open
all-subroutine 50x target.

### Matched status-route wall-clock recheck (2026-10-16)

After the state-root follow-up, the same Docker benchmark compared the v5.88
source tree with the current checkout over 21 runs of 100 warmed requests and
50 indicators. Both returned HTTP 200, exactly 12,864 response bytes, and SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. Median
latency was 60.881879 ms/request on v5.88 and 0.342300 ms/request currently
(177.77x). The current timing varied from prior rechecks (0.249081–0.342300
ms/request); this is a matched, route-specific result, not proof that every
subroutine is at least 50x faster.

A short exact-source confirmation after the later nav and collector changes
used five runs of 20 warmed requests per tree. The v5.88 median was 57.779455
ms/request and current source was 0.104547 ms/request (552.67x for this
fixture). Both returned HTTP 200, exactly 12,864 bytes, and the same SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`.
The shorter sample corroborates route-level behavior but does not replace the
21-run/100-request comparison or prove the required speedup for every
subroutine.

### Matched NYTProf subroutine map for status route (2026-10-16)

Both trees were profiled with the same 50-indicator fixture and 20 requests.
Each trace returned the same 12,864-byte response hash. Instrumented route
medians were 149.958611 ms/request on v5.88 and 1.031256 ms/request currently
(145.45x under NYTProf; not comparable to the unprofiled ratio). The old trace
recorded 80,840 calls to `Cwd::abs_path` (350 ms exclusive) and 40,520 calls to
`PathIdentity::_path_identity` (57.2 ms); the current trace recorded 40 and 80
calls respectively (197 µs and 114 µs). `_ensure_state_dir` fell from 25,200
calls / 70.7 ms to 60 / 141 µs; `_write_state_metadata` fell from 5,040 calls
/ 66.5 ms to 20 / 236 µs. These are route-attributed totals showing request-
scope and call-count effects, not isolated per-call speed factors. Remaining
top current exclusive application work included `Config::_merge_named_hash_array`
(858 µs / 20 calls), `Config::indicator_collectors` (737 µs / 20), JSON decode
(708 µs / 20), and `Web::App::_request_config_snapshot` (2.34 ms / 40 calls).
Earlier exact-output merge and indicator-job alternatives did not improve this
workload; no 50x result is claimed for these routines.

### Saved-page raw-nav fast path and STASH memoization (2026-10-16)

Red-first Docker regressions now prove that ordinary raw `nav/*.tt` fragments
skip the full instruction parser while structured bookmark headers still use
the canonical parser. A separate `PageDocument` regression proves repeated
legacy Perl-literal STASH values are Safe-evaluated once, return isolated deep
copies, respect the bounded LRU and text-size limits, and can be disabled. The
cache stores only JSON snapshots of values that successfully passed Safe.

The warmed `/app/welcome` benchmark used five raw nav fragments, 100 requests
per run, and 21 runs against both v5.88 and current source. Both returned HTTP
200, exactly 10,042 bytes, and SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`. The
latest medians were 3.866441 ms/request (v5.88) and 0.927038 ms/request
(current), 4.17x for this route fixture. A matched current NYTProf run showed
runtime-layer/config discovery and route rendering remain prominent costs;
the STASH decoder was called once per measured request with no Safe parser
calls in that warmed loop. Four focused Docker test files passed 563 tests.
This incremental route result is not a 50x per-subroutine result; Problem 48
and its delivery gates remain open.

The decoder was also isolated with a deterministic nested legacy STASH literal
and 3,000 calls per sample across 21 samples. Both trees serialized the result
to SHA-256
`63729c336dce4d41aae5ccfb4a169905b9166fbef87f3bae78dc185cbb2e3d5b`.
Median cost was 254.948 µs/call on v5.88 and 2.401 µs/call currently (106.2x
for repeated identical literals). The reproducible command is
`d2 docker compose exec dev env P48_LIB=/work/nytprof/v588/lib perl script/problem48-stash-decode-benchmark --iterations 3000 --runs 21`, repeated with `P48_LIB=/work/lib`.
The benchmark interface test and STASH behavior tests pass. The subsequent
full Docker gate passed 283 files / 24,236 tests; statement, branch, condition,
and subroutine coverage are all 100.0% across `lib/` (49,095 detail rows, no
stale uncoverable annotations). `PageDocument.pm` and `PageStore.pm` each report
100.0% on all four metrics. The required web/update, static-file, and SSL
security regression trio passed 466 assertions. `perldoc perlsec` could not
format in the container because no Pod formatter is installed; the Perl 5.40
`perlsec.pod` source was read directly. These checks cover this change only;
Problem 48's broader 50x objective and delivery gates remain open.

### Literal static raw-nav preparation bypass (2026-10-16)

The fresh saved-page profile showed `_nav_items_html` preparing every raw nav
fragment per request even when its content had neither CODE blocks nor a
Template Toolkit opener. A red-first web-app assertion confirmed that a plain
raw HTML fragment entered `PageRuntime`, while the existing dynamic
`nav/here.tt` fragment still requires normal rendering. The route now bypasses
request-context mutation, CODE handling, and TT setup only for a scalar raw
fragment without `[%` and with no code blocks; dynamic fragments keep the
original path.

The focused Docker app and benchmark tests passed 368 assertions. The matched
current-source `/app/welcome` benchmark, five literal nav fragments, 100
requests per sample and 21 samples, retained HTTP 200 and the exact 10,042-byte
body hash, while median latency moved from 0.927038 to 0.804060 ms/request
(1.15x incremental). Against v5.88's latest 3.866441 ms/request, the route is
4.81x faster in this fixture. This code change was made after the prior full
coverage run, so the full gate must be repeated before calling coverage current.

### Avoid canonical serialization for literal raw navigation (2026-10-16)

A fresh NYTProf run showed that the literal-fragment bypass still called
`PageDocument::canonical_instruction` for every nav page before checking whether
the result was needed. A red-first regression recorded raw-nav serialization:
the old implementation included `nav/static-plain.tt`, and failed. The route now
builds canonical instruction text only for dynamic fragments that will enter
`PageRuntime`; the dynamic `nav/here.tt` path remains unchanged. A separate
truth-table regression covers all raw-nav bypass predicate inputs, including
non-raw sources, missing/reference bodies, TT openers, and populated/empty code
arrays.

The Docker web-app suite passes 367 assertions. The matched current-source route
benchmark retained HTTP 200, 10,042 bytes, and SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`; median
latency moved from 0.753798 to 0.733690 ms/request (1.03x incremental). Against
v5.88's latest 3.866441 ms/request, it is 5.27x faster for this fixture. The
fresh NYTProf profile records 20 rather than 100 `PageDocument::legacy_instruction`
calls across the 20-request loop. The focused coverage report confirms the
extracted predicate's source-format condition is 100%; complete library-wide
coverage is still required. Problem 48's global 50x target remains open.

### Request-scoped saved-page root resolution (2026-10-16)

NYTProf identified repeated `Cwd::abs_path` calls inside
`PageStore::_assert_page_path_contained`: the same dashboards root was resolved
for every saved page and each nav fragment, twice on the read path. A red-first
Docker test observed 12 root resolutions during one route request and 24 across
two requests. `Web::App::handle` now scopes a dashboards-root realpath map to
one request; `PageStore` still resolves every candidate file and performs the
existing containment and no-follow open checks. The following request gets a
fresh map. The focused web-app suite passes 370 assertions.

The exact-output route median improved from 0.733690 to 0.673630 ms/request
(1.09x incremental), retaining HTTP 200, 10,042 bytes, and the established
response hash. A fresh matched 21-sample run measured 3.758640 ms/request on
v5.88 and 0.673630 currently (5.58x for this fixture). Matched 20-request
NYTProf profiles reduced `Cwd::abs_path` from 540 to 320 calls and
`_assert_page_path_contained` exclusive time from 3.91 to 1.29 ms; profile
instrumentation affects absolute timings. The latest full Docker gate
passed 283 files / 24,251 tests with statement, branch, condition, and subroutine
coverage at 100.0% across `lib/` (49,149 detail rows; no stale uncoverable
annotations). The required web/update, static-file, and SSL security trio
passed 466 assertions. The global 50x objective remains open.

### Matched status-route follow-up and warmed call-count profile (2026-10-16)

A fresh Docker resample of the 50-indicator `/system/status` fixture returned
the same HTTP 200 response, 12,864-byte body, and SHA-256 on both trees. Nine
runs per source, executed as separate sequential invocations, measured 63.425219
ms/request on v5.88 and 0.262971 ms/request currently (241.2x in this resample).
Because these samples were not interleaved, the earlier 21-sample matched
177.77x result remains the primary timing comparison; this is a follow-up, not
a universal or per-subroutine ratio.

Warmed NYTProf profiles, enabled only around the request loop, also retained
the exact response hash across 20 requests. Current versus v5.88 call counts
fell from 60 to 20 for `PathRegistry::config_roots`, 160 to 20 for
`Config::_merge_named_hash_array`, 5,180 to 60 for `PathRegistry::runtime_layers`,
25,200 to 60 for `_ensure_state_dir`, and 5,040 to 20 for
`_write_state_metadata`. These call-count reductions select where the request
scope avoids repeated work; profiler timings are instrumented and are not
per-call speedup measurements. The profile still identifies current exclusive
work in config-root discovery, collector merging, and indicator projection.
The all-subroutine 50x requirement remains unmet and Problem 48 remains open.

### Rejected home-runtime path-only fast path (2026-10-16)

The warmed NYTProf line report attributed elevated `config_roots` exclusive
time to the `runtime_layers` path that calls `home_runtime_root`. A red-first
Docker test confirmed that replacing it with `home_runtime_path` preserves the
returned paths and avoids creating the home directory. The focused PathRegistry
test and the web-app, d2 alias, and EnvLoader suites passed (864 assertions in
total). NYTProf appeared to show `config_roots` dropping from 1.89 ms to 81 µs
over 20 requests, but a direct alternating 21-round benchmark of 2,000
`runtime_layers` calls measured only 36.572 ms with ensure versus 35.534 ms
path-only (1.03x). This means the profile attribution overstated the production
gain. Because the behavior change was outside the performance objective and
the controlled speedup was negligible, the candidate was reverted. The
unmodified current implementation remains in the repository; this experiment
does not close the all-subroutine 50x requirement.

### Status-route snapshot invalidation by redundant permission checks (2026-10-16)

Expected outcome: unchanged web configuration is merged once and reused across
requests, while file edits, new runtime layers, and permission failures remain
immediately visible.

A red-first Docker regression with the native inotify backend and an explicit
`DEVELOPER_DASHBOARD_CONFIGS` root failed: the second `/system/status` request
performed another config merge. A profile of the 50-indicator fixture showed
2,102 config merges across 2,102 requests; watcher validations succeeded only
after each merge. Temporary event decoding showed repeated `IN_ATTRIB` events
for the runtime root. `config_roots()` resolves configured directories via
`_ensure_dir()`, whose `secure_dir_permissions()` unconditionally chmodded the
already-private root during both pre- and post-load inventory checks. Those
self-generated events made the cache miss on the next request.

`secure_dir_permissions()` now stats each existing directory and chmods only
when its mode is not already `0700`; stat and chmod errors remain explicit.
The config watcher also stops its ancestor walk at the same home/project
boundary used by `PathRegistry`, avoiding unrelated watchers such as `/` and
`/tmp`. Red-first tests now cover root/nested stat and chmod failures,
idempotent hardening, native cache reuse with configured-root resolution,
configuration invalidation, and unrelated-ancestor exclusion. Focused Docker
tests passed 428 assertions across the web app, PathRegistry I/O, and benchmark
contracts.

The matched synthetic workload used 50 indicators, 21 runs of 100 requests,
and exact response parity (HTTP 200, 12,864 bytes,
SHA-256 `da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`).
The v5.88 median was 61.043739 ms/request; current source measured 0.160201
ms/request (381.04x for this route fixture). Current counters showed one config
merge across warmup and timed requests and 4,205 successful watcher checks out
of 4,205. This route-specific result does not prove 50x for every subroutine;
Problem 48 remains open.

### Post-cache status-route NYTProf map (2026-10-16)

After the invalidation fix, a 100-request warmed profile retained the exact
12,864-byte response and showed one config merge plus 205 successful watcher
checks. The top current exclusive costs were `_write_state_metadata` (3.96 ms
over 100 calls), `_ensure_dir` (2.01 ms/100), `secure_dir_permissions` (1.77
ms/100), `_page_status_payload` (0.904 ms/100), and `runtime_layers` (0.674
ms/100). These measurements are NYTProf-instrumented and overlap with parent
inclusive totals; they select next experiments but are not production
per-call speed ratios. The unprofiled 21-run route measurement remains
0.160201 ms/request versus v5.88's 61.043739 ms/request. The all-subroutine
50x objective remains open.

### Follow-up NYTProf hotspot map after aggregate caching (2026-10-17)

The warmed 100-skill/5-saved-nav `/app/welcome` route was profiled for 100
requests using `Devel::NYTProf` inside Docker. It remained HTTP 200, returned
17,742 bytes with SHA-256
`c481093b9c88db29e384a545305c4fc02056feaf652682691a13a962939e1270`, and kept
exact repeated-response parity. NYTProf's instrumented median was 3.465891
ms/request and is diagnostic only; it is not comparable with unprofiled
latencies. The exclusive-time ranking was `_nav_items_html` (9.14 ms),
`_top_chrome_html` (7.59 ms), `PageDocument::render_html` (7.19 ms),
`_top_context_html` (3.59 ms), and `PathRegistry::runtime_layers` (2.82 ms)
over the profiled loop. The output also attributes about 1.25 ms exclusive to
`PageStore::load_saved_page`; call-stack totals overlap and must not be added.

The profile identifies request-context/chrome generation and nav assembly as
the next candidates, but it does not yet justify a cache: these outputs include
current timestamps, request/host data, indicator state, and filesystem-backed
navigation. A candidate must preserve those freshness and security properties,
prove exact HTTP response parity, and improve an alternating unprofiled
benchmark before production implementation. This route is already measured at
286.22x against the exact v5.88 fixture in the immediately preceding matched
experiment, while the 50x requirement for every individual routine remains
unproven.

### PageStore legacy-icon repair precheck and matched compiled route (2026-10-17)

Expected behavior: preserve all three legacy malformed-icon repairs while
leaving unrelated U+FFFD content untouched; ordinary bookmark reads should not
run the replacement expressions when no replacement character is present.
The PageStore NYTProf map showed `_normalize_legacy_icon_markup` among repeated
per-request costs. A U+FFFD index guard now returns ordinary text before the
three repair regexes. `t/73-pagestore-coverage.t` explicitly covers the three
repair contexts, unrelated replacement text, and undef/plain inputs. The
focused Docker suites passed both with source-only Perl and with the compiled
XS extension.

The direct paired microbenchmark used seven alternating samples of 100,000
calls: the guard measured 1.32x for a 5-byte plain value, 1.66x for 60-byte
ordinary markup, and 1.98x for a 7,207-byte ordinary body. A 27-byte repairable
icon case measured 0.93x because it pays for the guard before repairing; such
malformed legacy content is the exceptional path. This is helper-level
evidence only.

The matched Docker route comparison used 100 requests per sample, 21 runs, 100
installed skill-nav roots, and 20 saved nav fragments. v5.88 and current
source-only and compiled-XS variants all returned HTTP 200, 18,792 bytes, and
the same SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. Median
latencies were 91.746640 ms/request (v5.88), 0.472751 ms/request (source-only,
194.07x), and 0.338168 ms/request (compiled XS, 271.30x). Current native XS
was 1.40x faster than the source-only path on this route. This new matched
result supersedes earlier samples for this exact fixture; it still does not
prove 50x for every subroutine or workload.

A fresh compiled-XS NYTProf map over 100 requests ranked
`PageDocument::from_instruction` and `_parse_legacy_sections`,
`PathRegistry::runtime_layer_root_for`, `_render_page_html`, and
`all_skill_nav_literal_items_html` as current candidates. The instrumented run
was 1.534312 ms/request and profile totals overlap, so they are not production
latencies. The next optimization should target canonical page parsing and be
retained only if exact output/security behavior and a paired route benchmark
show a real gain.

The initial plain `make` experiment failed because the container exposed an
incompatible flat-architecture `Storable` from `/root/perl5` to system Perl
5.40.1. Re-running MakeMaker with only the active versioned local-lib path in
`PERL5LIB` built the XS extension successfully; the compiled focused suites
and route benchmark then passed. No product fallback or error suppression was
added. This is a container-local environment constraint, not evidence that
other platform builds have passed.

### Same-fixture route rerun after warning/security fixes (2026-10-17)

After the skill-nav fallback and static-attribute fixes, the same Docker
fixture was rerun: 100 requests/sample, 21 runs, 100 skill-nav roots, and 20
saved nav fragments. All variants retained HTTP 200, 18,792 bytes, and the
exact SHA-256 `74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`.
Fresh v5.88 measured 69.971821 ms/request; current source-only measured
0.717950 ms/request (97.46x), while current compiled XS measured 0.773010
ms/request (90.52x). This supersedes earlier current-source numbers for this
fixture. The XS variant was 0.93x the source-only latency in this sample, so
no end-to-end benefit from XS is claimed for this route. Both implementations
remain above 50x for this workload only. This does not demonstrate the
objective of 50x for every subroutine; fresh per-routine and broader workload
evidence is still required.

### Warning-free skill-nav snapshot fallback found by full coverage gate (2026-10-17)

The full Docker gate exposed a latent warning in
`all_skill_nav_literal_items_html`: when the page provider returned `undef` but
an earlier request had left a valid array snapshot, the code compared
`refaddr(undef)` numerically. A red-first regression in
`t/105-web-app-coverage-2.t` captured the warning. The guard now rejects
non-array current results before reference-address comparison, returning to the
existing non-aggregate renderer path. The tests also clear the saved-nav HTML
snapshot between mocked fallback scenarios; their previous expectation of an
empty response was invalid while an unchanged, correctly cached real fragment
was present. The generated literal-nav attribute now uses concatenation after
the escaper, satisfying the repository's static attribute-context security
check without changing rendered output. Docker verification: t/105 passes 449
assertions with no warning and t/126 passes 21 attribute-security assertions.
The earlier full gate was still running against a mixed source state when the
fix landed; a clean full-gate rerun is required before claiming coverage.

### Native-aware PageDocument escaping (2026-10-17)

The expected output remains the previous four-substitution HTML result,
including quote escaping and the Perl UTF-8 flag. A red-first Docker test
failed because the helper did not call the shared escaper for dense content.
`PageDocument::_html` now returns plain scalar text after `index` checks, keeps
the original Perl replacements for short/sparse content, and uses the native
body escaper only when XS is loaded, text is at least 64 characters, and at
least four `&`, `<`, or `>` characters occur in the first 16 characters.
`t/72-pagedocument-coverage.t` passes in both source-only and compiled-XS
modes; the compiled run also passes `t/665-problem48-xs-html-escape.t`.

Seven alternating function-level Docker samples (20,000 calls per strategy per
sample) retained exact bytes. With compiled XS, the new path measured 1.09x for
a 10-character plain value, 0.94x for an 18-character quote-heavy value, 1.06x
for 1,408-character plain text, and 11.29x for a 384-character dense fixture.
Without XS, the fallback measured 1.08x, 0.85x, 1.11x, and 1.34x for those
same cases. Thus short quote-heavy cases remain near parity or slightly slower;
there is no route-level speed claim. The extension itself compiled and loaded
from `blib/arch`, but the subsequent `make` target failed while fixing the
`d2` script: `Storable.c: loadable library and perl binaries are mismatched`
because the container's `/root/perl5` `Storable.pm` was selected ahead of the
system Perl 5.40.1 core copy. This environment/build gate remains unresolved.
Problem 48's all-subroutine 50x objective remains open.

### Full coverage follow-up for the status snapshot watcher (2026-10-16)

The first clean full Docker coverage run passed all 283 files / 24,268 tests
but correctly failed its 100% gate: statement coverage was 99.9%, branch
coverage 99.6%, and condition coverage 99.1%, all shortfalls in
`Web/App.pm`'s snapshot watcher and bounded path discovery. Red-first tests now
exercise missing and rejecting native backends, empty and supplied watcher
diagnostics, each cache reuse/invalidation state, malformed installed/nested
skill records, absent optional PathRegistry methods, and home/project boundary
cases. The rerun passed all 283 files / 24,307 tests and reached 100.0%
statement, branch, condition, and subroutine coverage across `lib/` (49,396
detail rows; no stale uncoverable annotations). No production logic changed in
this coverage-only follow-up. The all-subroutine 50x requirement and remaining
Problem 48 delivery gates remain open.

### Fresh post-coverage NYTProf map (2026-10-16)

A new 3-run profile used the checked-in status-route benchmark in the `dev`
container (50 indicators, 100 requests per run). It returned HTTP 200 with the
same 12,864-byte response and SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`;
configuration merged once, with 605/605 watcher checks reporting unchanged.
The instrumented median was 0.551820 ms/request; this is profile overhead, not
the production timing result.

The line profile attributes roughly 2.5 ms over 300 samples to state-root
directory derivation, 2.5 ms to state-directory validation, and about 2.2 ms to
metadata file closes. Those costs are spread across many requests and each is
small; avoiding metadata reads by trusting only cached timestamps would weaken
tamper detection, so that optimization is rejected. The resulting next action
is to profile a materially heavier user-facing operation (saved-page execution
or template rendering) rather than spend complexity on this small filesystem
path. This profile does not establish per-subroutine 50x performance, and the
Problem 48 objective remains open.

### Saved-page route profile after coverage completion (2026-10-16)

The corresponding saved-page benchmark rendered the same 10,042-byte
`/app/welcome` response (five shared nav fragments) for all requests. A
3-run, 100-request-per-run NYTProf sample measured 2.688041 ms/request under
profiling; the run's purpose was attribution, not an unprofiled timing claim.
The largest measured source costs were repeated `PageStore` realpath and
no-follow open validation, then nav directory enumeration in `Web::App` and
instruction parsing in `PageDocument`. The profile reported 3,600 `abs_path`
calls over 300 profiled requests and 1,500 nav-entry filter iterations. These
security checks and filesystem freshness are part of the behavior, so the
next experiment should reduce redundant work only with explicit invalidation
tests for page replacement, symlinks, and nav additions/removals. NYTProf also
warned that dynamically compiled `PageRuntime` source could not be synchronized
to source lines; its line-level attribution is therefore not used. No code was
changed based on that warning. The universal per-subroutine 50x target remains
unproven.

### Saved-page nav inventory cache (2026-10-16)

Expected outcome: repeated requests with unchanged shared-nav directories avoid
enumerating the same filenames, while adding or removing a fragment updates the
next request immediately. Fragment contents must still be loaded and rendered
fresh on every request. An unavailable directory remains skipped as before,
but an incomplete inventory must not be cached; stat, read, and close failures
must remain visible.

Red-first tests in `t/03-web-app.t` first failed because the dedicated nav
inventory scanner did not exist. The implementation now keys the per-app
filename inventory by each ordered `nav/` directory's device, inode, mode,
owner, group, size, and high-resolution modification/change timestamps. A
changed signature triggers a rescan. Tests cover unchanged reuse, add/remove
invalidation, malformed cache entries, missing roots, incomplete opens, and
visible stat/read/close failures. A route-level integration regression proves
that fragment edits are still rendered without rescanning the IDs.

The focused Docker suites for the web app, saved-page benchmark, and I/O fault
coverage pass. A warmed, alternating 7-pair route comparison used 100
iterations per sample and 21 samples per pair. Both modes returned HTTP 200,
10,042 bytes, and the same SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`. Median
time was 0.651679 ms/request with the cache and 0.667362 without it (1.024x,
about 2.4%). The inventory scan count fell from 2,103 to 1. An isolated
10,000-call inventory microbenchmark measured 3.66x, but the whole-route gain
is modest and is the relevant user-facing result. The full Docker coverage
gate passed 283 files / 24,346 tests with all four library metrics at 100.0%
(49,493 detail rows, no stale uncoverable annotations). This does not establish
the required 50x speedup for every subroutine; Problem 48 remains open.

### Duplicate saved-page containment check (2026-10-16)

The fresh post-cache NYTProf trace recorded 240 calls to
`PageStore::_assert_page_path_contained` over 20 saved-page requests, while
`_existing_page_file` and `_open_saved_page_at` each checked the same existing
candidate immediately before its secure read. The second check at secure open
is the required boundary: it revalidates the path immediately before the
no-follow open. The lookup-time check added no protection after that and
duplicated realpath resolution.

A red-first Docker assertion in `t/73-pagestore-coverage.t` failed against the
old flow with two checks for one `read_saved_entry`; it now confirms one
containment validation at secure open. Existing symlink-escape tests still
verify that neither parsed nor raw saved-page reads return outside content.
The focused PageStore, web-app, and benchmark suites passed 599 assertions.

The saved-page benchmark now exposes a control that deliberately restores the
old extra check and counts containment calls. Seven alternating pairs of 100
iterations x 21 samples kept HTTP 200, 10,042 response bytes, and SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212` in both
modes. Median-of-run-medians was 0.578761 ms/request with one secure-open
check and 0.642362 ms with the duplicate (1.11x); check counts were 12,600 and
25,200. Timing varied across pairs, so the result is a targeted route
comparison, not a universal ratio. The full Docker gate passed 283 test files /
24,353 tests with all four `lib/` metrics at 100.0% (49,493 detail rows, no
stale uncoverable annotations). Problem 48's all-subroutine 50x objective
remains open.

### Request-local saved-page root inventory (2026-10-16)

A fresh current-checkout NYTProf trace showed 120 calls to
`PathRegistry::dashboards_roots` over 20 requests (six saved-page loads per
request for the main page and five nav fragments). `App::handle` already gives
the request a stable runtime-layer scope and a request-local PageStore root
realpath map, but each candidate lookup independently rebuilt the same ordered
dashboard-root list. The request now lazily snapshots that list in the PageStore
and discards it with the other per-request state. Direct PageStore calls remain
uncached; a subsequent web request resolves a fresh list.

Red-first tests first observed ten root lookups in one web request with nine
nav fragments and eleven on the next request including the test's own root
query. After scoping the assertion to candidate lookup, it verifies one lookup
per request and fresh resolution on the next. A PageStore unit regression
simulates the available roots changing between request scopes and confirms the
new root is observed. The saved-page benchmark now accepts
`--nav-fragments N` and has `--no-page-roots-cache` to compare prior behavior.

Seven alternating 21-sample pairs at the default five fragments retained exact
HTTP/body/hash parity and reduced root-list calls from 12,600 to 2,100 across
2,100 requests. The median-of-run-medians was 0.584528 ms/request cached and
0.582500 ms uncached: no route-speed gain is claimed for this small fixture.
At ten fragments, seven alternating pairs of 20 requests x 9 samples retained
the same output hash per pair and reduced calls from 1,980 to 180; the
median-of-run-medians was 0.792992 versus 0.824606 ms/request (1.04x). This is a
small workload-dependent benefit, not evidence for 50x across subroutines.
The full Docker coverage gate after this change passed 283 files / 24,372 tests
with 100.0% statement, branch, condition, and subroutine coverage across
`lib/` (49,511 detail rows, no stale uncoverable annotations). The
all-subroutine objective remains open.

### POSIX path separator preservation (2026-10-16)

While reviewing `_assert_page_path_contained` as the remaining saved-page
profile hotspot, a red-first Docker regression exposed a containment flaw:
normalizing backslashes unconditionally made a literal POSIX directory name
compare as a slash-separated sibling. The test failed before the change and
passes after limiting case/separator normalization to Windows. The POSIX path
comparison now skips two substitutions while retaining the same realpath
containment test; no timing claim is made for this small hot-path reduction.
The focused PageStore suite passes all 136 assertions. The broader 50x target
remains open. A fresh matched exact-output route rerun measured 3.777349
ms/request on v5.88 and 0.632660 currently (5.97x), retaining HTTP 200, 10,042
response bytes, and SHA-256
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`. This is
cumulative route evidence, not a measured benefit from this small change.

### One-pass XS attribute escaping (2026-10-16)

The saved-page route profile attributed 2.59 ms across 160 calls to the Perl
work in _escape_html_attr. Its established implementation first escaped body
metacharacters and then ran two quote substitutions. A red-first dispatch test
failed because scalar attributes had no native route. The new XS helper escapes
all five sensitive bytes in one pass; overloaded references and source-only
builds retain the Perl implementation. Tests cover exact output and UTF-8 flags
for undefined, empty, quote-heavy, Unicode, and embedded-NUL values, plus
taint-mode behavior.

The repeatable command is:

    d2 docker compose exec dev perl -I.p48-xs-build/blib/arch -I.p48-xs-build/blib/lib -Ilib script/problem48-html-attribute-escape-benchmark --iterations 100000 --runs 9

With XS loaded, medians were 0.000576 versus 0.000270 ms/call (2.13x) for
nav/static-1.tt and 0.001619 versus 0.000359 ms/call (4.51x) for the
quote-heavy input a&<>"'b, Perl reference versus production helper. Exact
output and UTF-8 parity passed. Without XS, results remain equivalent and
performance is about 1x. The full saved-page route showed no measurable
improvement (0.570421 versus 0.572760 ms/request in the paired current-source
comparison), so the gain is specific to this helper and does not establish the
all-subroutine 50x target.

### Status-route collector projection reuse (2026-10-16)

The fresh status-route NYTProf profile attributed about 10 ms over 303 calls
to `Config::indicator_collectors`' configured-job projection. The route already
reused merged configuration after an inotify-backed validation, but rebuilt
the filtered `{ name, indicator }` array on every request. A red-first web test
failed at two projections across two unchanged requests and failed to detect a
change to `DEVELOPER_DASHBOARD_CHECKERS` in the environment signature.

The application now stores that derived array in the watcher-validated config
snapshot. The checker filter is included in the signature, so an environment
change rebuilds the merged snapshot and projection. This retains config and
skill-entry freshness via the existing watcher; no unvalidated filesystem or
environment values are memoized.

The benchmark's `--no-collector-cache` mode forces the former per-request
projection while retaining byte-for-byte route validation. Two reverse-order
21-sample Docker pairs, 50 indicators, and 100 requests per sample returned
HTTP 200 with identical 12,864-byte bodies and SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. The
no-cache medians were 0.143151 and 0.148051 ms/request; cached medians were
0.113299 and 0.111630, giving a median pair ratio of 1.29x. Projection calls
dropped from 2,103 to 1. This is a status-route-specific improvement; it does
not prove 50x for every subroutine or the entire dashboard. The corrected full
Docker coverage gate passed 284 files / 24,419 tests, with all four library
metrics at 100.0% (49,525 detail rows; no stale uncoverables). The required
`perldoc perlsec` command was attempted after the gate but the minimal
container lacks a loadable POD formatter, so this command is not recorded as a
pass.

### Saved-page literal-nav root provenance and content reuse (2026-10-16)

Expected outcome: saved-page responses must preserve the exact rendered bytes,
layer precedence, dynamic TT behavior, immediate file-update visibility, and
path-containment/no-follow protections, while avoiding repeated page-root
search, HTML-fragment document construction, and file decoding for unchanged
literal nav content.

Reproduction: run the saved-page benchmark in Docker with `--nav-fragments 5`
or `20`, 100 requests per run, and 21 runs. Before this change the warmed
current route still called the saved-page loader and instruction parser for
each literal nav file on every request; the v5.88 20-fragment case took
9.278910 ms/request. The current baseline before this optimization was about
0.52–0.57 ms for 20 fragments and around 0.66 ms for five, with repeated
PageStore candidate search and file reads.

Root cause: the nav directory inventory already knew which dashboard layer
provided each id, but discarded that provenance. `_nav_items_html` then called
the general saved-page resolver, which searched roots and allocated a page
document even for literal HTML. The same bytes were read and decoded again on
every request.

Red-first Docker tests in `t/73-pagestore-coverage.t` failed because
`load_nav_fragment` did not exist; after adding the initial fast path, tests
proved unchanged files were still read twice. Tests now verify one load per
unchanged fragment, same-size edit invalidation, symlink replacement rejection,
configured-root validation, deepest-layer precedence, custom resolver
authority, dynamic/structured page metadata, item/byte cache limits, and
containment checks on cache hits. The route benchmark test verifies the
no-cache control's file-read count and exact response hash. Five focused Docker
test files pass: 971 assertions.

The nav scan now retains deepest-layer root provenance, matching the previous
`dashboards_roots` lookup order. Custom page resolvers remain authoritative;
the direct PageStore fast path is used with the built-in resolver. PageStore
checks containment, checks the file as a regular non-symlink, and performs the
secure no-follow open on a miss. Literal decoded HTML only is stored in a
128-entry, 4 MiB
per-store cache (individual entries are capped at 256 KiB); the cache key uses
the high-resolution lstat device, inode, mode, size, mtime, and ctime. A hit
therefore checks the current path and metadata every request and does not reuse
Template Toolkit output. TT and structured nav still use the full document and
request-context path.

The reproduction command is:

    d2 docker compose exec dev env P48_LIB=/work/nytprof/v588/lib perl script/problem48-saved-page-route-benchmark --iterations 100 --runs 21 --nav-fragments 20
    d2 docker compose exec dev env P48_LIB=/work/lib perl script/problem48-saved-page-route-benchmark --iterations 100 --runs 21 --nav-fragments 20

Both versions returned HTTP 200, exactly 11,092 response bytes, and SHA-256
`95282bc166a550ec0dfaba8737888fcdea84b39cd695aa323fbe785442d6f388`. Corrected
medians were 9.256661 ms/request on v5.88 and 0.699711 current (13.23x). The
current `--no-nav-fragment-cache` control took 1.406310 ms/request (2.01x slower
than cached) with identical body hash; measured fragment reads fell from
42,060 to 20. With five fragments the matched medians were 3.711650 and
0.531738 ms/request (6.98x), with the unchanged 10,042-byte response hash
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`.

This improves one request route and the literal-nav helper behavior; it does
not demonstrate 50x for every subroutine. The full coverage gate, remaining
security/integration checks, packaging, and complete Problem 48 performance
audit are still pending.

### HTML attribute escape fast path and benchmark baseline correction (2026-10-16)

The saved-page NYTProf profile placed `_escape_html_attr` among the top
exclusive-time helpers. The common plain navigation ID ran body escaping plus
two quote substitutions even though it contained no HTML metacharacters. A
red-first Docker test made a plain attribute fail if it called the multi-pass
body escaper; it failed before the change. The Perl path now returns unchanged
for plain scalar values of at least twelve characters after checking the five
escapable ASCII characters. Short values, references, undefined inputs, and
escaping values retain the existing behavior. Tests cover each metacharacter,
short escaped input, XS dispatch, overloads, taint, and byte/UTF-8 parity.

The existing helper benchmark's purported pre-XS baseline called the public
body escaper, which selected XS when the compiled extension was present. That
made the Perl/XS comparison invalid. Its reference now calls the pure-Perl body
helper explicitly and reports `perl_baseline=pure-perl`. Two 100,000-iteration,
nine-sample Docker runs preserved exact output. The normal 15-character nav ID
measured 1.63x (source-only) and 1.80x (XS-loaded) relative to that independent
reference; quote-heavy text measured 4.20x with XS. The short quote-heavy
source-only wrapped helper measured 0.89x relative to the lower-level reference,
so the fast path is a common-plain-text tradeoff, not a universal helper speedup.
The focused Docker tests pass 82 assertions, including source-only and compiled
XS runs; the latter also checks taint preservation for the plain return path.
This does not establish
the required 50x per-subroutine or dashboard-wide result; the full coverage gate
and remaining delivery checks are still pending.

The same attribute benchmark was rerun against the current checkout in Docker
with the built XS extension, 100,000 calls per sample, and nine alternating
runs. Output and UTF-8 parity held. The plain 15-character navigation ID
measured 1.76x and quote-heavy input measured 4.87x versus the independent
pure-Perl reference. This updates the earlier 1.80x/4.20x XS figures for the
current container; neither workload reaches 50x.

A fresh, profiled 20-request route run preserved HTTP 200, 11,092 response
bytes, and SHA-256
`95282bc166a550ec0dfaba8737888fcdea84b39cd695aa323fbe785442d6f388`. Its next
exclusive-time targets were `_assert_page_path_contained` (4.77 ms / 420 calls),
`Cwd::abs_path` (4.48 ms / 480 calls), `_validated_page_id` (3.79 ms / 460 calls),
and `_state_root_for_layer` (2.79 ms / 20 calls). These profile timings are
instrumented and are used only to prioritize the next safe optimization; path
containment must not be weakened to reduce the cost.

### Malformed literal-nav cache entry and full-gate follow-up (2026-10-16)

The next full Docker coverage run passed 284 files / 24,495 tests, but failed
the aggregate threshold at 99.9% branch and 99.8% condition coverage. The
PageStore detail report also exposed untested cache-state paths. Red-first
regressions then found a real failure: when a cached file entry was not a hash,
refresh reached the replacement accounting code and dereferenced it as one,
causing `Not a HASH reference`. Cache replacement and eviction now count an
invalid old entry as having no body, while retaining the configured cache
limits. A changed-to-nonregular path now produces an explicit path error before
fingerprinting. Tests cover malformed and stale entries, missing root snapshot
values, read-time file/symlink swaps, compatibility fallback behavior, and page
id fallback. The focused Docker PageStore/web test run passes 646 assertions.
The next complete Docker coverage gate passed 284 files / 24,513 tests with
statement, branch, condition, and subroutine coverage all at 100.0% across
`lib/` (49,769 detail rows and no stale uncoverable annotations). The focused
PageStore condition result and aggregate gate now agree. This closes current
coverage work only; it does not close the all-subroutine 50x objective or the
remaining Problem 48 delivery gates.

The report's only remaining condition miss was the logically unreachable case
where both an existing parsed page id and its validated replacement id were
false. `_validated_page_id` guarantees the latter is non-empty. The `||=` was
rewritten as an explicit false-value assignment guard, preserving the original
truthiness behavior while removing that impossible condition outcome. A focused
instrumented Docker run reports 100.0% PageStore condition coverage and 646
focused assertions pass. The subsequent full aggregate gate passed all four
library metrics at 100.0% across 49,769 detail rows.

### Cache-miss containment check and confirmatory route benchmark (2026-10-16)

The cache-miss path previously called `_assert_page_path_contained` before
reading and then called it again at `_open_saved_page_at`, the secure-open
boundary. A red-first PageStore test confirmed that duplicate work. The pre-check
was removed: misses still pass the containment check at secure open, and
unchanged cache hits still validate containment on every request. The focused
regression verifies one assertion for a miss and one for a cache hit; no
containment check was removed from the hit path.

The confirmatory Docker A/B commands were:

    d2 docker compose exec dev env P48_LIB=/work/nytprof/v588/lib perl script/problem48-saved-page-route-benchmark --iterations 100 --runs 21 --nav-fragments 20
    d2 docker compose exec dev env P48_LIB=/work/lib perl script/problem48-saved-page-route-benchmark --iterations 100 --runs 21 --nav-fragments 20

The v5.88 and current medians were 9.080269 ms/request and 0.712309
ms/request (12.75x). Both returned HTTP 200, 11,092 bytes, and the exact same
SHA-256 `95282bc166a550ec0dfaba8737888fcdea84b39cd695aa323fbe785442d6f388`.
The route fixture counted 88,200 containment checks on v5.88 and 44,100 on the
current path, with 42,060 baseline nav candidate searches/file reads versus
zero candidate searches and 20 file reads currently. This is a route-specific
optimization, not 50x for every subroutine. A complete Docker coverage gate on
the resulting tree passed 284 files / 24,515 tests; statement, branch,
condition, and subroutine coverage were each 100.0% across `lib/` (49,770 detail
rows, no stale uncoverable annotations). Optional security-tool, platform, and
browser tests that reported skips remain separate verification items.

### Canonical nav-id validation fast path (2026-10-16)

The same saved-route profile showed `_validated_page_id` being called for each
literal nav fragment. A safe, single-level ASCII `nav/<name>.tt` grammar was
added as a narrow early-return path, bypassing whitespace normalization and
path-component splitting for only that canonical case. Inputs that are
prefixed, nested, unusual, overloaded references, or traversal-shaped still
go through the existing normalization and validation. The red-first Docker
test proved the common id reached normalization before the change; after the
change the fast path, compatibility prefix, nested and unusual ids, and
traversal rejection all pass.

The repeatable helper benchmark is:

    d2 docker compose exec dev perl script/problem48-page-id-benchmark --iterations 500000 --runs 9

It preflights successful-value and invalid-id parity against a local reference
to the previous implementation, then alternates nine timing samples. Common
nav-id validation measured 0.001109 ms/call previously and 0.000453 ms/call
with the fast path (2.45x). A reversed-order 21-sample Docker route comparison
returned the same HTTP 200, 11,092-byte body, and SHA-256
`95282bc166a550ec0dfaba8737888fcdea84b39cd695aa323fbe785442d6f388`; medians
were 9.553111 ms/request for v5.88 and 0.682609 ms/request currently (13.99x).
These are one helper and one route fixture, not evidence for 50x on every
subroutine. The next full Docker gate passed 285 files / 24,543 tests with
statement, branch, condition, and subroutine coverage each at 100.0% across
`lib/` (49,777 detail rows and no stale uncoverable annotations). Optional
browser, platform, kwalitee, and security-tool tests that reported skips remain
separate verification items.

### Containment hotspot recheck and rejected cache candidate (2026-10-16)

A fresh NYTProf run of the warmed saved-page route reported 120 containment
checks for 20 measured requests; `_assert_page_path_contained` accounted for
1.61 ms inclusive under profiling, including 120 `Cwd::abs_path` calls. Because
containment must be re-evaluated for cached content to prevent a symlinked
parent from redirecting a saved fragment outside its configured root, removing
that check was not considered safe.

A Docker A/B run compared the current route with a control that restores the
former duplicate containment check. At 100 requests across nine runs, both
returned HTTP 200 and the identical 10,042-byte body hash
`5b217655b90ff66db1d2fdb5a9d3e4aa6a4d4f05f073f1d7f9fc6ec40746d212`.
The current median was 0.4510 ms/request; the duplicate-check control measured
0.4387 ms/request, within measurement noise despite adding 900 containment
calls. This does not justify further containment caching or weakening the
check. No production change was made from this experiment. The next target must
be selected from a repeatable profile with a material end-to-end effect.

The route NYTProf report ranked `_config_snapshot_environment_signature` at
184 microseconds inclusive per request, but an isolated profile of 10,000 calls
measured 9.3 microseconds inclusive per call; the unprofiled 100,000-call run
measured 5.4 microseconds per call. The route's NYTProf file also warns about a
generated `#line` directive in `PageRuntime.pm`. Therefore that apparent route
ranking is profiler-sensitive and is not accepted as a production hotspot.
An isolated comparison of the current per-call `qw` name list against a
predeclared list preserved JSON output but measured the candidate at 0.94x, so
that candidate was rejected.

An unprofiled route-scaling check with one versus five literal navigation
fragments returned exact repeat parity. Median latency was 0.3489 ms/request
with one fragment and 0.4510 ms/request with five. This gives a workload scaling
signal but does not separate file-validation, rendering, or dispatcher costs;
those must be measured individually before a code change.

### Installed-skill navigation layer-resolution reuse (2026-10-16)

The saved-route benchmark now creates temporary installed skills, each with one
raw navigation fragment under its dashboards tree. Fifty such fragments were
rendered by the production `/app/welcome` route. The baseline Developer
Dashboard v5.88 median was 32.1768 ms/request; current source measured 4.2943
ms/request (7.49x) with HTTP 200 and exact 13,892-byte response parity at SHA-256
`380611cca9e0a6a71e30c51ca82973444798dfa8ed79364ae32a36e2f26191f3`.

NYTProf showed that `_load_skill_page` resolved the same skill layers once to
find the file and again to store those layers in page metadata. It also showed
repeated validation and top-level skill-root scans during a request. A
red-first regression failed with two resolutions per page; the implementation
now passes the resolved home-to-leaf layers to `_page_location` and reuses
request-scoped segment validation and the existing installed-skill directory
inventory. Directory presence and `.disabled` markers are still rechecked on
each `skill_layers` call, while calls outside an explicit request inventory
remain fresh. The duplicate-lookup control and optimized path both produce the
exact response hash above. The 50-skill paired current-source medians were
4.7143 ms with 33,750 layer resolutions and 4.2943 ms with 22,500 resolutions
(1.10x). This is a modest, workload-specific route gain, not 50x per routine.

### Reuse skill layers across nav enumeration and loading (2026-10-16)

Profiling the same 50-installed-skill fixture showed two layer lookups per
skill per page request: one in `_skill_nav_route_ids` to find nav fragments,
then another in `_load_skill_page` for each fragment. `skill_nav_pages` now
resolves the participating layers once and passes that trusted internal list
to both enumeration and loading. Standalone page loading still resolves its
own layers, and route lookup order, precedence, and disabled-marker checks are
unchanged.

The red-first dispatcher test failed before the change with three lookups for
one skill contributing two nav files; it now passes with exactly one. A paired
Docker benchmark used 20 saved fragments and 50 installed-skill fragments,
100 requests per sample and 21 samples. The duplicate-resolution control
measured 4.576519 ms/request and 210,000 layer resolutions; the optimized
route measured 4.087360 ms/request and 105,000 resolutions (1.12x). Both
returned HTTP 200, 14,942 bytes, and the exact same SHA-256
`aa4c502bfb3254233ee6b17050a09f7070b99ca24dfb908a7264bec2e0900a82`.
This is a modest fixture-specific improvement; Problem 48's all-subroutine
50x objective remains open.

For a matched baseline comparison, the same benchmark command was run with
`P48_LIB=/work/nytprof/v588/lib`. v5.88 measured 32.750230 ms/request and the
current route measured 4.087360 ms/request (8.01x). Both produced the same
HTTP 200 response bytes and SHA-256 above. The older implementation performed
42,060 nav candidate searches and reads, while current source performs zero
candidate searches and 20 fragment reads. This remains a route-specific result.
The subsequent full Docker gate passed 285 files / 24,576 tests with statement,
branch, condition, and subroutine coverage at 100.0% across `lib/` (49,841
detail rows; no stale uncoverable annotations).

### Skip structured parsing for raw skill nav fragments (2026-10-16)

NYTProf showed that raw skill `nav/*.tt` fragments were sent through
`PageDocument::from_instruction`, which throws while trying to parse ordinary
HTML/TT text, before `_load_skill_page` catches the exception and wraps the
text as a raw fragment. A narrow detector now sends only files with recognized
modern markers, legacy section headers, or section separators through the
structured parser. Raw URL bookmarks keep their redirect behavior. Tests verify
the parser is skipped for raw TT while legacy and modern structured nav files
keep their parsed title, HTML, and source format.

The paired Docker benchmark used 20 saved fragments and 50 installed-skill nav
fragments, with 100 requests per sample over 21 samples. Forcing raw nav text
through the prior parser path measured 4.648869 ms/request; the new detector
measured 4.076271 ms/request (1.14x). Both returned HTTP 200, 14,942 bytes and
SHA-256 `aa4c502bfb3254233ee6b17050a09f7070b99ca24dfb908a7264bec2e0900a82`.
Raw-nav file reads fell from 40 to 20 across the benchmark's initialization
and measured fixture, and nav inventory scans fell from two to one. This is a
targeted route-fixture result; the all-subroutine 50x target remains open.
The complete Docker suite passed 285 files / 24,593 tests; statement, branch,
condition, and subroutine coverage were all 100.0% across `lib/` (49,880 detail
rows and no stale uncoverable annotations).

A follow-up 50-skill-nav benchmark isolated the raw-fragment parsing toggle
with 100 requests per sample and 31 samples, preserving the same 13,892-byte
response and SHA-256 `380611cca9e0a6a71e30c51ca82973444798dfa8ed79364ae32e2f26191f3`.
The normal fast path measured 4.081211 ms/request; forcing structured parsing
measured 4.100540 ms/request (1.005x). A reverse-order pair varied more, so the
earlier 1.14x result is not a stable incremental gain estimate. The existing
parser avoidance remains correct, but this follow-up does not justify a new
optimization or a larger speedup claim.

An isolated detector rewrite then combined the four existing format checks
into one alternation. Seven representative plain, TT, legacy, modern, and URL
strings returned identical booleans, but 500,000 checks of the common raw-HTML
case took 1.415 seconds for the combined expression versus 0.422 seconds for
the current staged checks. This microprobe is not a full test or route
benchmark; the rewrite was rejected and no production code changed.

Pure route-segment memoization was also tested with a red-first dispatcher
regression test. The repeated-value microprobe itself favored a bounded cache,
but the matched 100-request / 31-sample saved-page route control did not: the
cached route measured 3.981490 ms/request and direct validation measured
3.777671 ms/request, with the same HTTP 200 body hash in both runs. The NYTProf
call count fell from 3,450 to 2,020 validation calls, but cache lookup overhead
outweighed that reduction in the unprofiled route control. The production cache
and its temporary tests were removed; no route speedup is claimed.

A fast marker-token precheck for plain skill-nav fragments also failed its
matched profile comparison. For the same 20-saved/50-skill-nav route and exact
14,942-byte response hash, the precheck profile attributed 2.04 ms to the
existing detector and 1.23 ms to the new precheck; a control that retained the
existing detector attributed 1.27 ms to it and 1.54 ms to the trivial precheck
call. The combined cost therefore increased (3.27 ms versus 2.81 ms across
1,000 calls). Unprofiled route samples were noisy and did not establish a gain.
The precheck and tests were removed; the staged detector remains unchanged.

### Warmed saved-page route profile after skill-nav improvements (2026-10-16)

A fresh warmed NYTProf run of the small `/app/welcome` route fixture (20
requests) showed security preflight and response encoding among the largest
inclusive subroutine costs: `_fetch_site_is_foreign` 3.28 ms across 40 calls,
`JSON::json_encode` 3.25 ms across 20 calls, and `Auth::_canonical_ip` 2.86 ms
across 40 calls. These figures are profiler-instrumented and overlap through
call stacks; they are not additive wall-clock costs or evidence of a 50x
candidate. The request/origin checks and canonical IP handling are security
boundaries, so this profile does not justify caching or removing their
validation. The route remains functionally stable (HTTP 200, 10,042 bytes,
same-output parity); an unprofiled three-run check measured 0.455141 ms/request.
The next experiment should use a representative higher-cost route and compare
its exact output and security checks before proposing another optimization.
Problem 48 remains open.

### Cross-platform configuration snapshot reuse (2026-10-16)

The Linux-only inotify backend had left a real performance gap: on macOS and
Windows, the web app rebuilt the merged config for every request because no
native watcher was available. The no-native path now fingerprints the exact
global, project, and installed-skill config inputs with SHA-256 and records
metadata for the layered directories that define their discovery. This
preserves snapshot reuse while detecting same-size in-place edits, file
creation/removal, and directory-layer changes. The focused Docker regression
forces the backend to be unavailable, observes a stable cache hit, edits a
config file without changing its size, and verifies an immediate reload; it
also verifies skill config creation and deletion.

If native watcher setup is rejected at runtime, the app now records the setup
diagnostic and seeds the same portable freshness baseline after its fresh
merge. A red-first regression verifies subsequent unchanged requests reuse
that portable snapshot instead of permanently disabling caching for the app.

This removes the Linux-only cache availability gap for configuration snapshots.
The portable validator's per-request cost has not yet been benchmarked on
macOS or Windows, and this change does not establish equal platform latency or
the all-subroutine 50x requirement. The GitHub-hosted compatibility workflow
must run before cross-OS test compatibility can be claimed.

An in-container paired Linux simulation then ran the same 50-indicator,
100-request, seven-sample status-route fixture with identical HTTP status,
12,864-byte response, and SHA-256 body. The forced no-native-watcher path
measured a 0.551040 ms/request median; the inotify-enabled path measured
0.106809 ms/request, making the portable path 5.16x slower in this Linux
simulation. This confirms functional parity and exposes a real latency cost,
but does not measure macOS or Windows, nor prove the 50x target. Further work
should benchmark and, if material, optimize portable invalidation without
weakening detection of same-size edits or newly added/deleted config layers.

### Reproducible cross-platform config-cache comparison (2026-10-16)

The status-route benchmark now has `--portable-config-cache`, which bypasses
only the web app's config watcher while leaving collector synchronization and
the rest of the production route unchanged. Its regression checks exact HTTP
response parity. The five-leg full-suite GitHub matrix exports the isolated
Perl dependency tree, then runs the automatic and forced-portable 50-indicator
route measurements before the complete test suite on Linux x64/arm64, macOS
Intel/arm64, and Windows x64. A sixth, separate Windows ARM64 job is a native
watcher smoke test only; it does not run either benchmark or the full suite.

The paired dev-container rerun used 100 requests per sample across seven runs.
Both modes returned HTTP 200 and the same 12,864-byte body with SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. Automatic
mode measured 0.117619 ms/request with the native watcher; forced-portable mode
measured 0.336020 ms/request (2.86x slower). This is a repeatable Linux control,
not evidence for macOS/Windows latency; those results require the workflow run.
Problem 48's all-subroutine 50x target remains open.

### Share portable config-validation skill inventory (2026-10-17)

The forced-portable NYTProf map showed `_config_snapshot_watch_paths` and
`_config_snapshot_portable_signature` independently enumerating installed skill
layers. In the cache-miss path, the second pair of calls after the config merge
is still required as a freshness check; however, each pair can share the same
skill-entry inventory. A red-first Docker regression measured four inventory
lookups on an initial request and two on a cache hit. The implementation now
passes the discovered skill entries from watch-path construction into the
portable signature, while retaining a new discovery for the post-merge
freshness check. The test now verifies two lookups on first fill and one on
each cache hit, and verifies malformed optional inventories fail explicitly.

The focused web suite passes 507 assertions. Before/after NYTProf runs each
profiled 100 warmed requests with 50 indicators, forced-portable config
validation, HTTP 200, and the same 12,864-byte response hash
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. The
pre-change profile recorded 22.2 ms inclusive for watch-path discovery and
18.2 ms for portable signature validation; the updated profile recorded 21.7
and 15.6 ms respectively. NYTProf timings include instrumentation and the
inventory was empty in this fixture, so this is not a claimed end-to-end
speedup or a v5.88 comparison. The updated unprofiled 21-sample portable route
median is 0.251069 ms/request, but no matched pre-change route control was
retained. The change reduces duplicate inventory work and preserves a fresh
scan per request; Problem 48's all-subroutine 50x target remains open.

The final Docker coverage run passed all 285 test files and 24,840 tests.
Statement, branch, condition, and subroutine coverage each measured 100.0%
across `lib/` (50,496 detail rows, no stale uncoverable annotations). This
verifies test coverage for the current tree; it does not establish the 50x
per-subroutine performance target or complete the remaining delivery checks.

### Portable validation root reuse (2026-10-16)

The portable route profile showed repeated `runtime_roots()` discovery inside
`config_roots()` and `skills_roots()` after the request had already obtained the
same runtime-root inventory. These accessors now accept that operation-local
snapshot, while calls without it retain live discovery and the explicit
`DEVELOPER_DASHBOARD_CONFIGS` replacement setting remains unchanged. Mock and
PathRegistry tests verify the supplied snapshot avoids rediscovery; non-
PathRegistry providers keep their previous no-argument calls.

After this change, the same seven-run Docker comparison returned HTTP 200 and
the identical response hash in both modes. Automatic mode measured 0.122919
ms/request; forced-portable mode measured 0.272412 ms/request (2.22x slower).
Compared with the immediately preceding portable measurement this is about a
19% reduction, though it remains a Linux simulation and is not evidence of
macOS/Windows latency. Both modes remain substantially faster than the v5.88
baseline for this one route; neither this single route nor these platform
simulations establish the all-routine 50x target or cross-platform parity.

A fresh warmed portable NYTProf run (900 requests, 50 indicators) then ranked
`_config_snapshot_portable_signature` at 39.2 ms exclusive / 151 ms inclusive,
`_config_snapshot_watch_paths` at 30.9 ms exclusive / 191 ms inclusive, and
`Digest::SHA::add` at 38.2 ms exclusive. These instrumented values are
overlapping stack costs and must not be added or compared with unprofiled
latency. They point to portable filesystem inventory and exact-content hashing
as the next work area; changing to metadata-only checks would weaken detection
of same-size edits and is not an acceptable optimization. The platform matrix
still needs to run before any macOS or Windows performance claim.

### Fresh warmed status-route NYTProf map (2026-10-16)

A current-source profile of 900 warmed `/system/status` requests (50 configured
indicators; profiling enabled only for the measured loop) retained HTTP 200 and
the exact 12,864-byte response hash
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. The
profile-ranked inclusive totals were `_page_status_payload` 168 ms,
`_handle_request_with_template_scope` 276 ms, `sync_collectors` 161 ms, and
`_collector_sync_files_unchanged` 10.9 ms. These overlap through callers and
must not be added as independent costs. At exclusive time, `_write_state_metadata`
used 9.26 ms across 900 calls, `JSON::XS::encode` used 9.60 ms across 1,800
calls, and `Auth::_canonical_ip` used 7.38 ms across 1,800 calls. The route's
unprofiled paired benchmark remains the authoritative latency comparison; this
profile is only a candidate map. State-metadata checks and canonical IP/origin
validation are security-sensitive. The repeated metadata cost was isolated in
a paired route experiment below and did not justify a cache or shortcut. The
50x-per-subroutine goal remains open.

A red-first attempt to memoize successful metadata validation inside the
existing request/aggregate scope did not improve the measured status route.
The matched Docker control and candidate both made exactly 2,100 metadata
`lstat`/content-read pairs over 2,100 timed requests; medians were 0.107791 and
0.107780 ms/request, with the same response hash. The route performs only one
metadata validation per request, so the repeated-call cache had no work to
eliminate. The candidate implementation and its temporary regression were
removed; no production behavior changed. This rules out that optimization for
this workload, not for routes with different state-root access patterns.

### Portable-validator profile and v5.88 baseline (2026-10-16)

The 50-indicator route was profiled again with forced-portable config
validation. Across 900 measured requests, `_config_snapshot_portable_signature`
used 46.4 ms exclusive (170 ms inclusive), `_config_snapshot_watch_paths` used
42.4 ms exclusive (224 ms inclusive), and `Digest::SHA::add` used 43.5 ms
exclusive across 2,700 calls. These totals overlap through callers; they
identify the portable freshness work but are not additive. The profile retained
the same HTTP status, response byte count, and SHA-256 as automatic mode. An
unprofiled seven-run current-source route measured 0.105231 ms/request with the
automatic watcher and 0.251710 ms/request forced-portable.

The exact v5.88 source was recovered from commit `a8d1fa2a` in a detached local
worktree. The same unprofiled 50-indicator status route returned the identical
12,864-byte response and hash at 59.064181 ms/request. This is 561x for the
current automatic path and 235x for the forced-portable path on this specific
Linux fixture; neither ratio proves every routine is at least 50x faster or
predicts macOS/Windows latency. A v5.88 NYTProf run of 20 requests ranked
`Cwd::abs_path` (370 ms exclusive / 80,840 calls),
`PathIdentity::_path_identity` (152 ms exclusive / 80,840 calls), and
`PathRegistry::_ancestor_runtime_layers` (114 ms exclusive / 5,040 calls)
among the largest costs. These point to canonical-path and ancestry work as
candidate areas, but many such reductions are already represented in current
scoped caches; a fresh paired source comparison is required before another
change. The all-subroutine 50x objective remains open.

### Native filesystem watchers on macOS and Windows (2026-10-16)

The portable validation path made config snapshot reuse available on all
platforms, but Linux alone had a native watcher. The watcher adapter now also
uses Mac::FSEvents on macOS when installed and Unicode-aware
FindFirstChangeNotificationW APIs through FFI::Platypus on Windows. The
portable SHA-256 validator remains the fallback when optional modules are
unavailable or watcher setup fails.

Red-first mocked tests cover FSEvents stream setup/read/cleanup failures and
Win32 handle setup, timeout, event re-arm, and close behavior. A follow-up
closed error-reporting gaps: false FSEvents stop results now fail explicitly,
partial native cleanup failures remain visible, and malformed handles and
optional-loader errors are tested. The focused Docker Linux test passes 209
assertions, including a real inotify write; isolated `Watch.pm` coverage is
100.0% for statement, branch, condition, and subroutine metrics.

The native integration test is platform-neutral: each CI runner must configure
its native backend, observe a real file write, and close its resources. The
full-suite GitHub Actions matrix covers Linux x64/arm64, macOS Intel/arm64, and
Windows x64; a separate Windows ARM64 smoke job checks the watcher with the
runner's native Perl. Each job checks the actual OS and CPU architecture and
installs platform watcher dependencies. Windows ARM64 is not a full-suite leg:
the hosted image currently provides Perl 5.32.1, below this project's Perl
5.38 minimum, and the Perl setup action does not support that runner target.
Hosted macOS and Windows workflow results remain pending, so their API behavior
and latency are not yet confirmed.
Problem 48's all-subroutine 50x target remains open.

### Rejected repeated environment-signature serialization cache (2026-10-17)

Expected outcome: repeated calls to
`Web::App::_config_snapshot_environment_signature` with an unchanged process
environment should return byte-identical output while reducing its measured
cost; changing a relevant environment variable must still produce a different
signature. The reproduction counted JSON encoding calls around two unchanged
calls, then changed `DEVELOPER_DASHBOARD_CHECKERS`. The new red-first assertions
failed before implementation (two encodes for unchanged calls and three after
the environment change). The candidate cached the signature only after
comparing every exact scalar input, and the focused Docker test then passed.

The candidate was rejected after an alternating Docker microbenchmark of 50,000
calls per sample across nine runs. The median was 418.531 ms with the cache and
331.603 ms when forcing the existing JSON::XS serialization (0.79x relative
speed, so the candidate was slower). This shows the scalar-array comparison
costs more than JSON::XS encoding for this input. A second alternating
comparison of a length-framed scalar fingerprint against JSON::XS was slower
again: 536.025 ms versus 332.344 ms (0.62x). Both candidates and the temporary
assertions were removed; production behavior is unchanged. Next work should
follow the current NYTProf map and require an unprofiled paired gain before
retaining a change. No whole-dashboard or per-subroutine 50x claim follows
from these experiments.

### Refreshed v5.88 status-route comparison (2026-10-17)

The exact v5.88 library at commit `a8d1fa2a` was re-extracted inside the Docker
`dev` container, then the existing status-route benchmark ran against that
library and the current `/work/lib` tree. Both 21-run comparisons used 50
indicators, 100 requests per sample, HTTP 200, and the exact 12,864-byte
response SHA-256
`da887f795a1b16c65b1c3b8d54a7e390425b1dd0b19731cac0b437dd95d9ac68`. The
baseline measured 63.530080 ms/request; current source measured 0.164301
ms/request, or 386.68x for this status-route fixture. Current source performed
one config merge and 4,205 watcher checks/hits across 21 timed runs; v5.88
performed 6,309 config merges and had no watcher. This refresh supports a large
route-specific gain, not 50x for every subroutine or every application
workload. Problem 48 remains open.

### Refreshed nested skill-nav route baseline and hotspot map (2026-10-17)

The exact v5.88 library from `a8d1fa2a` and current source were compared in the
Docker `dev` container with 100 skill nav roots, 20 saved nav fragments, 100
requests per sample, and 21 runs. Both returned HTTP 200 and the same 18,792-byte
response SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. The
baseline median was 70.445819 ms/request and current source was 9.496582
ms/request (7.42x). The sizable reduction is real for this workload, but it is
well below 50x and does not satisfy the requested universal target.

A warmed current-source NYTProf profile of the same 100-skill/20-nav workload
identified repeated route assembly as the next hotspot. Across 100 profiled
requests, `_page_location` ran 10,000 times (165 ms exclusive under profiling),
`_skill_nav_inventory` and `_load_skill_page` each ran 10,000 times (140 ms
exclusive), and `File::Spec::Unix::catdir` used 167 ms exclusive. These
instrumented totals overlap through callers and are not unprofiled timings.
The route still resolves and validates every nav page each request despite
cached literal page documents and route inventories. The next candidate is a
watcher-validated aggregate literal-nav snapshot that can bypass repeat path
resolution without hiding file edits, new/removed skill layers, or nested nav
directory changes; it must retain the current portable metadata path if a
reliable native watch set is unavailable or reports an event.

### Watcher-validated aggregate literal skill-nav snapshot (2026-10-17)

The red-first Docker regression showed that `all_skill_nav_pages` still called
`_load_skill_page` for every route on each request even after its per-file
literal cache was warm. A bounded aggregate array is now reused only when all
pages are literal raw nav fragments and the existing cross-platform watcher
confirms that the runtime-root identity and watched filesystem inventory are
unchanged. The watch set includes skill/runtime roots, parent directories that
observe newly created layers, dashboards/nav parents, and recursively visited
nav directories. An event forces normal route inventory and per-file checks;
unavailable/setup-failed/read-failed watchers visibly disable aggregate reuse.
The dispatcher closes the watcher at destruction. Dynamic/structured pages
and arrays over the explicit count/byte limits are not cached.

Red-first coverage established zero repeat `_load_skill_page` calls on a
watcher-confirmed second request, then verified file edits, route additions and
removals, runtime-root identity changes, watcher setup/read failures, portable
fallback, and cleanup. The focused Docker test passes 239 assertions. The
matched 100-skill/20-saved-fragment route benchmark retains exact HTTP 200 and
response SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`; current
median fell from 9.496582 to 2.258520 ms/request (4.21x incremental). Compared
with the same v5.88 fixture at 70.445819 ms/request, current is 31.19x, still
below 50x. NYTProf now ranks `_nav_items_html` and saved-page
`PageStore::load_nav_fragment` as the next hot path; the all-subroutine 50x
objective remains open.
### Rejected watcher-backed parsed-page clone cache and refreshed route comparison (2026-10-17)

Expected behavior was a byte-identical `/app/welcome` response while avoiding
repeated parsing of the primary saved-page instruction. A red-first Docker test
proved the page was parsed on each uncached request, then a bounded watcher
cache with recursive `PageDocument` cloning was implemented and its focused
tests passed. A matched 100-skill/20-saved-nav Docker experiment showed the
candidate was counterproductive: current-source median was 0.699959 ms/request
with parsed-page reuse versus 0.474980 ms/request when disabled (0.68x, or
about 32% slower). Recursive cloning cost more than reparsing this page. The
cache, clone method, and candidate-only tests were removed; the post-removal
focused route, page-document, and benchmark suites pass 676 assertions.

The same current benchmark was compared with the exact v5.88 library from
`a8d1fa2a`, using 100 requests per sample across 21 samples, 100 installed
skill nav roots, and 20 saved nav fragments. Both returned HTTP 200, 18,792
bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. The
Docker median was 108.165948 ms/request for v5.88 and 0.377908 ms/request for
current source (286.22x for this route fixture). This is a route-level result;
it does not establish 50x for every subroutine or workload. A fresh NYTProf
map now ranks Perl HTML escaping, `_top_context_html`, `PathRegistry::runtime_layers`,
`PageDocument::render_html`, and saved-page loading as candidate hot paths.
Instrumented costs overlap and are not production timings. The all-subroutine
50x objective remains open.

### Matched 100-skill saved-page route recheck (2026-10-17)

The current and exact v5.88 source trees were rerun with identical benchmark
arguments: `/app/welcome`, 100 installed skill nav fragments, five saved nav
fragments, 100 requests per sample, and nine samples. Both returned HTTP 200,
17,742 response bytes, and SHA-256
`c481093b9c88db29e384a545305c4fc02056feaf652682691a13a962939e1270`. The
v5.88 median was 102.897069 ms/request; current source measured 0.560360
ms/request (183.65x for this exact fixture). The current run recorded 100
skill-nav content reads across the fixture warmup and one saved-nav inventory
scan; v5.88 recorded 270,000 skill-layer resolutions, 90,300 skill-nav
inventory scans, and 4,515 saved-nav reads. A current-source control with only
the aggregate literal skill-nav cache disabled measured 21.126659 ms/request,
with the same output hash, showing that the validated aggregate cache accounts
for a substantial workload-specific portion of the improvement. This is
strong matched route evidence, not proof of 50x for every subroutine, route, or
platform; the universal target remains open.

### Matched 20-saved-nav route recheck (2026-10-17)

Using the same benchmark harness and Docker container, reran exact v5.88 and
current sources with 100 installed skill-nav roots, 20 saved nav fragments,
100 requests per sample, and nine samples. Both outputs were HTTP 200 with
18,792 bytes and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. The
v5.88 median was 135.065870 ms/request and current source measured 1.136279
ms/request, a matched 118.87x route improvement. The current run performed one
saved-nav inventory scan and 100 skill-nav content reads across warmup; v5.88
performed 90,300 skill-nav inventory scans and 18,060 saved-nav reads. This
confirms the current route exceeds 50x on this fixture, but does not prove the
per-subroutine or cross-platform 50x requirement.

A warmed NYTProf profile of the same 20-fragment fixture kept HTTP/body parity;
instrumentation measured 1.528752 ms/request and generated a known PageRuntime
`#line` source-attribution warning. The highest exclusive totals over 900
profiled requests were `_parse_legacy_sections` (41.0 ms), `_nav_items_html`
(35.6 ms), `PathRegistry::secure_dir_permissions` (27.6 ms), and
`PageStore::_normalized_page_id` (24.4 ms). These overlapping instrumented
totals help rank candidates; they are not production timings and must not be
added together. No production change is justified by this profile alone.

### Repeated XS attribute-escape benchmark (2026-10-18)

With the built extension loaded from `blib/arch`, nine alternating 100,000-call
Docker samples preserved exact output parity. Plain nav text measured 0.000495
versus 0.000279 ms/call (1.77x); quote-heavy input measured 0.001315 versus
0.000286 ms/call (4.59x), Perl reference versus production XS path. The
source-only run without that include path correctly reported no XS backend.
These helper-specific gains do not establish a route-wide or all-subroutine
50x result.

To test whether the helper gain moved its parent workload, the same
`/app/welcome` route ran in nine alternating process pairs, each with 100
requests, 20 saved-nav fragments, and 100 skill-nav fragments. Every response
matched HTTP 200, 18,792 bytes, and SHA-256
`74036c2e3f7001f8d7344b486400e71a9cd62154059f7af2e235ccdb59beb724`. The
median of the nine per-process route medians was 0.343490 ms/request without
XS and 0.343912 ms/request with XS (0.999x), effectively no route-level
change. The isolated attribute helper is too small a share of this warmed
route to move its total latency.

### Prompt-summary list allocation reduction (2026-10-18)

The existing routine copied the payload array and then built a second parts
array before joining status/alias text. A Docker regression first pinned output
ordering, Unicode aliases, and input-array immutability for 50 rows. The
implementation now maps directly over the payload and joins once. Nine
alternating 100,000-call samples measured 865.926 ms before and 797.271 ms
after (1.09x), exact output parity. This is a measured helper improvement, not
a 50x subroutine or route result.

### Rejected colon-index legacy section parser candidate (2026-10-18)

The profiled header regexp scans each section body while capturing it. An
experimental parser instead found the first colon with `index`, validated only
the header slice, then copied and split the body. On a four-section fixture
with 800-byte body lines, canonical parsed output matched exactly. Nine
alternating 10,000-parse samples measured 652.764 ms for the production parser
and 658.969 ms for the candidate (0.99x); candidate-side serialization was
also checked each iteration. The candidate was rejected, and production
parsing remains unchanged.

### Blank-tarball test portability and watcher capability reporting (2026-10-18)

The v5.98 blank-environment `cpanm` run exposed that
`t/41-skill-dispatcher-direct-coverage.t` called the optional native watcher
for a path-filtering assertion, and `t/673-problem48-saved-page-route-benchmark.t`
used a response SHA-256 tied to the source checkout's location. The first
correction injected the existing deterministic watcher and compared benchmark
modes to their default run's response hash. The 5.99 tarball run then showed
two remaining benchmark assumptions: one nav inventory scan and six path
containment checks require the optional FFI watcher. With FFI absent, the
portable route preserved the same response bytes while observing nine scans
and 36 containment checks.

The benchmark now reports native watcher availability and actual saved-nav
snapshot hits, and `--no-native-watch` forces the portable behavior on systems
where FFI is installed. The test always requires response-hash parity and only
asserts native cache counters when a backend exists. The combined focused
Docker suites pass 432 assertions, including the forced portable path. This is
packaging/test portability work, not a performance gain. The rebuilt 6.00
blank-tarball install was later verified successfully in the release-gate run
below. Problem 48's universal 50x goal remains open.

The same security-gate rerun caught lazy watcher loading after a route changes
the current directory: a relative `@INC` entry then failed and the Dancer skill
page returned HTTP 500. Both Web::App and SkillDispatcher now derive the
optional module path from their captured absolute module locations, while
preserving the module's existing `%INC` entry and test-injected implementation.
The red Docker reproduction was `t/08-web-update-coverage.t`; the combined
`t/08`, `t/41`, and `t/673` rerun passes 722 assertions. This correctness fix
does not claim a performance gain. The rebuilt 6.00 tarball now passes the
blank-container `cpanm` installation and the full integration harness; the
release metadata suite also confirms no default or named `cover_db` member is
shipped after the hyphenated-name exclusion was added.

### 6.00 full Docker coverage and blank-container release verification (2026-10-18)

After the lazy watcher-load fix, `script/coverage-gate --database
/tmp/p48-cover-db-20261018-v6` passed all 285 test files and 25,247 tests.
Statement, branch, condition, and subroutine coverage each report 100.0%
across `lib/` (51,618 detail rows; no stale uncoverable annotations). The
required web-security tests passed 470 assertions; `t/15-release-metadata.t`
passed 5,756 assertions against the rebuilt archive. The first 6.00 archive
incorrectly included the generated `cover_db-p48-focus` directory; the
red-first metadata checks reproduced the leak, and the corrected hyphen and
underscore rules were verified both by the archive scan and the release test.
Finally, the exact 6.00 tarball installed with plain `cpanm` in the blank Docker
environment and the integration harness completed successfully. These gates
validate packaging and source correctness, not the universal 50x target or
hosted cross-platform workflow results.

### Full Docker coverage after summary invalidation (2026-10-18)

After the red-first status-route prompt-summary invalidation regression was
fixed, `script/coverage-gate --database
/tmp/p48-cover-db-20261018-r3` passed all 285 test files and 25,293 tests.
Statement, branch, condition, and subroutine coverage are each 100.0% across
`lib/` (51,645 detail rows; no stale uncoverable annotations). Optional browser,
Windows QEMU, CPANTS, POD, and audit-tool checks were explicitly skipped when
their external dependencies were unavailable. This gate verifies code coverage;
it does not establish the universal 50x objective or hosted platform results.
