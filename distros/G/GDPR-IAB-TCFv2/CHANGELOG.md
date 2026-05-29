## [0.530] - 2026-05-28

### Features

- *(validator)* Cross-language validator parity with the Go lib-gdpr redesign branch (`validator_strict.go`)
  - Auto-enable `verify_disclosed_vendors` when `min_tcf_policy_version >= 5`, and run the mandatory disclosed-vendors check independently of it (mirrors Go `New` + `yieldMandatoryDisclosedVendors`).
  - Strictly-after v2.3 deadline boundary (`created > TCF_V23_DEADLINE`) matching Go `created.After(v23Deadline)`; the parser's `is_v23` keeps `>=` for its own strict-parse gate.
  - Single `PolicyVersionTooLow` when both the policy floor and the v2.3 date rule apply (`_check_policy_version`, mirrors Go `yieldPolicyVersionFailure`).
  - Global vendor gate emitting `ReasonVendorNotAllowed` when a vendor has neither vendor-consent nor vendor-LI — short-circuits before per-purpose checks in both fail-fast and exhaustive modes.
  - Flexible-purpose `_flexible_failure` follows Go `runFlexibleCheck`'s effective legal basis: spec carve-out (P1, or P3–6 at policy ≥ 4) forces consent; `RequireConsent`/`RequireLI` override; `NotAllowed` surfaces `ReasonPublisherRestrictionNotAllowed`; carve-out outranks the generic LI reason.
- *(cmp)* Add `CMPDeleted` / `CMPUnknown` reason codes and `CMPValidator->state` (active/deleted/unknown); validator maps CMP lifecycle state to these reasons.
- *(tests)* `t/18-go-parity.t` pinning each rule to its Go counterpart; updates to `t/06` and `t/17` for the aligned behavior; validator golden corpus regenerated.

### Documentation

- Claim SLSA Build Level 2

## [0.520] - 2026-05-18

### Bug Fixes

- Stop EUMM installing CONTRIBUTING and TODO as modules 

### Other

- Merge branch 'release/0.520'
- Update changelog
- Bump version
- Remove extra test, not needed
- Update changelog
- SLSA Build L1 — provenance for CPAN tarball and Docker image 
- Merge tag 'v0.512' into devel

Tagged for release. v0.512

## [0.512] - 2026-05-15

### Documentation

- Update disclaimer about maintenance mode
- Update changelog

### Other

- Release v0.512
- Phase 12.1b: Migrate to Perl 5.12 Baseline 

* feat: migrate to Perl 5.12 baseline

Establish Perl 5.12 as the minimum version.
- Update MIN_PERL_VERSION to 5.012000.
- Adopt 'use v5.12;' (implicitly enabling strict).
- Modernize inheritance with 'use parent'.
- Modern package version syntax (package Name VERSION;).
- Updated tools/bump-version to support new syntax.

Fixes #132

* fix(docs): resolve Test::Synopsis failure in iabtcfv2.pm

* chore: finalize perl 5.12 baseline and restore fallback testing
- Merge tag 'v0.511' into devel

Tagged for release. v0.511

## [0.511] - 2026-05-15

### Bug Fixes

- Fix min perl version

### Other

- Merge branch 'release/0.511'
- Update changelog
- Merge tag 'v0.510' into devel

Tagged for release. v0.510

## [0.510] - 2026-05-15

### Other

- Merge branch 'release/0.510'
- Update changelog
- Phase 12.1a: Migrate to Perl 5.10 Baseline 

* docs(todo): update Perl migration plan to split 5.10 and 5.12 phases

* feat: migrate to Perl 5.10 baseline

Establish Perl 5.10 as the minimum version.
- Update MIN_PERL_VERSION to 5.010000.
- Adopt 'use v5.10;' everywhere.
- Remove 5.8.9 legacy checks (like eval { pack 'Q>' }).
- Adopt the defined-or operator (//) and state variables for caching.

Fixes #131

* fix: allow version strings in .perlcriticrc for Phase A

Fixes critic failure on 'use v5.10;' syntax.

* ci: add Test::Version to linux workflow for author tests
- Merge tag 'v0.500' into devel

Tagged for release. v0.500

## [0.500] - 2026-05-14

### Documentation

- *(roadmap)* Add Phase 12 Modernization roadmap 
- *(todo)* Expand Phase 2 follow-up scope -- narrow validate() overrides 
- *(roadmap)* Add Phase 11 -- registry freshness policy and CMP-list hot-reload 
- *(todo)* Add Phase 2 follow-up for Validator strict_legal_basis coupling 

### Features

- *(parser)* Make is_v23 time-aware and support reference_time 

### Other

- Merge branch 'release/0.500'
- Update changelog
- Merge tag 'v0.401' into devel

Tagged for release. v0.401

### Refactor

- Split parser into GDPR::IAB::TCFv2::Parser + add iabtcfv2 short-alias 

## [0.401] - 2026-05-11

### Bug Fixes

- Restore PAUSE indexation regressed by #72 (CMPValidator $VERSION) 

### Other

- Merge branch 'release/0.401'
-   v0.400 -- Phase 5 + Phase 6 (CMP validator + structured failure reporting)
  Highlights:
    * Phase 5: CMPValidator + iabtcfv2 CLI integration
    * Phase 6 (6.1-6.5): structured Validator::Failure objects with
      machine-readable Reason codes, per-call list overrides
    * MIN_PERL_VERSION raised to 5.8.9; runtime now Perl 5.8 clean
    * Performance: vec() + regex optimizations for bitfields
    * CLI: short-help (-h) and informative unknown-subcommand errors
    * CMPValidator JSON::PP and Time::Piece are now optional
      (lazy-required, listed under META `recommends`)
    * Bug fixes: trailing padding bits in PublisherRestrictions,
      cleaner CLI error formatting
  See CHANGELOG.md for the full list.

## [0.400] - 2026-05-09

### Bug Fixes

- Post-release audit (hash-form check + POD alignment) 
- *(cli)* Provide concise usage errors 
- Final review refinements (POD, CMPValidator, and Parse safety) 
- Omit file path and line number from CLI error messages 
- Correctly handle trailing padding bits in PublisherRestrictions 
- *(cmp-validator)* Make JSON::PP and Time::Piece optional 
- Replace // defined-or with defined() ternary for Perl 5.8 

### Documentation

- Retire TODO.md, sync remaining items into TODO.pod
- Final v0.400 prep (POD fix + roadmap sync)
- Add Phase 10 (Advanced Error Handling) to roadmap
- Align POD and error messages with implementation 

### Features

- *(cli)* Short-help via -h and informative unknown-subcommand error 
- *(validator)* Align disclosure logic and naming 
- *(validator)* Per-call overrides for purpose ID lists 
- *(validator)* Emit distinct ReasonPublisherRestriction* codes (Phase 6.4) 
- *(validator)* Emit ReasonLegitimateInterestNotPermittedForPurpose for TCF carve-out (Phase 6.3) 
- *(validator)* Structured Failure objects + Result accessors (Phase 6.2) 

### Other

- Merge branch 'release/0.400'
- Try normalize email
- Update changelog
- Regenerate readme
- Update changelog
- Merge tag 'v0.391' into devel

Tagged for release. v0.391

### Performance

- Implement vec() and regex optimizations for bitfields 

### Refactor

- Rename cmp_state_provider to cmp_validator 

## [0.391] - 2026-05-07

### Features

- *(cli)* Integrate CMPValidator into iabtcfv2 validate 
- *(cmp-validator)* Http_client injection + verify_ssl/timeout/env_proxy 
- *(validator)* Add Validator::Reason constants module (Phase 6.1) 

### Other

- Release v0.391 include cmp validator in cli
- Merge tag 'v0.390' into devel

Tagged for release. v0.390

## [0.390] - 2026-05-07

### Features

- CMPValidator + cmp_validator rule (Phase 5) 

### Other

- Release v0.390 - add cmp validator
- Update manifest
- Include docs/ in gitignore
- Update changelog
- Merge tag 'v0.380' into devel

Tagged for release. v0.380

## [0.380] - 2026-05-07

### Features

- *(constants)* TCF v2.3 spec-aligned long-form aliases 

### Other

- Release v0.380 - improvements in performance and changes in cli.
- Update manifest
- Merge tag 'v0.370' into devel

Tagged for release. v0.370

### Performance

- *(range-section)* Avoid O(n^2) hash rebuild in TO_JSON 

## [0.370] - 2026-05-06

### Bug Fixes

- Avoid 32-bit IV overflow when decoding 36-bit timestamps 

### Other

- Release v0.370 add gdpr consent string validator package and subcommand.
- Phase 2: The Validator Interface (rebased + reviewed) 

* Phase 2: The Validator Interface

* Refactor Validator to reduce complexity (fix perlcritic)

* Phase 2: review fixups for the Validator interface

Three must-fix changes plus expanded test coverage that came out of
the deep review on PR #35:

  * Encapsulation: _check_disclosed used to reach into the parser's
    private hash (\$tc->{disclosed_vendors_data}).  Replace with the
    public predicate \$tc->has_vendor_disclosure (added in Phase 1).

  * Test regex bug (t/06-validator.t):
        qr/purpose 1.* | .*purpose 7/
    has an unescaped pipe inside qr//, so it parsed as alternation
    rather than a literal " | " separator.  The test passed even
    when the \$\\-aware joining didn't work, leaving the headline
    feature unverified.  Fix:
        qr/purpose 1.*\\Q | \\E.*purpose 7/

  * POD: previously zero documentation.  Phase 1 set the bar; add
    full POD for both modules with SYNOPSIS, DESCRIPTION, every
    constructor key, both methods, the boolean/stringification
    overloads, and the \$\\-aware separator behaviour.

Test coverage added for previously-uncovered paths:

  * Pre-parsed GDPR::IAB::TCFv2 object as input
  * Missing vendor_id (croak) plus override fill-in
  * legitimate_interest_purpose_ids (pass + spec-forbidden P1)
  * flexible_purpose_ids scalar form
  * flexible_purpose_ids hashref form (both default_is_li values)
  * strict-mode override (warn path via Test::Warn + croak path)
  * validate_all accumulating reasons across all three rule families

MANIFEST: add lib/GDPR/IAB/TCFv2/Validator.pm,
lib/GDPR/IAB/TCFv2/Validator/Result.pm, and t/06-validator.t
(missing from the original Phase 2 commits).

t/06-validator.t now has 11 subtests (was 4); 8287 tests pass
overall (was 8280).  perlcritic + perltidy clean.

* refactor(validator): derive flexible-purpose default basis from membership

flexible_purpose_ids is now a flat ArrayRef[Int].  The default
legal basis for each flexible purpose is derived structurally:

  * Purpose in consent_purpose_ids   AND flexible_purpose_ids
        -> flexible with default consent
  * Purpose in legitimate_interest_purpose_ids AND flexible_purpose_ids
        -> flexible with default legitimate interest

This mirrors the IAB GVL vendor-entry schema 1:1 (purposes /
legIntPurposes / flexiblePurposes) and removes the mixed-shape
parameter that accepted both scalars and {purpose_id, default_is_li}
hashrefs.  Constructor builds a private _flexible_set hash for O(1)
lookup; _check_consent_purposes and _check_li_purposes dispatch to
is_vendor_allowed_for_flexible_purpose when the purpose is flexible.

The standalone _check_flexible_purposes helper is removed and its
call site in _run_validation deleted.  Failure reasons now read
"(consent)" or "(legitimate interest)" -- the basis used for the
check -- regardless of whether the purpose was flexible.

Tests in t/06-validator.t updated for the new shape:
  * The two old "flexible_purpose_ids - {scalar,hashref} form"
    subtests collapsed into one "derives default basis from
    membership" subtest covering both consent-default and LI-default
    flexible purposes plus a negative case.
  * The validate_all subtest reworked to demonstrate accumulation
    across consent + LI rules with one flexible purpose, using
    vendor 99 (out of range for both bitfields) so all rules fail.

* feat(validator): croak on incoherent purpose-list configurations

Two configurations are now caught at construction time rather than
silently producing strange validation outcomes:

  1. A purpose listed in both consent_purpose_ids and
     legitimate_interest_purpose_ids (GVL semantics treat those
     as mutually exclusive vendor declarations).
  2. A purpose listed in flexible_purpose_ids but neither of the
     other two lists (no default basis can be derived).

Both croak with explicit messages naming the offending purpose ID.

* feat(validator): add from_gvl_vendor_entry helper

Maps a parsed IAB GVL vendor entry hashref to the constructor
arguments Validator->new expects.  Field aliases:

  id               -> vendor_id
  purposes         -> consent_purpose_ids
  legIntPurposes   -> legitimate_interest_purpose_ids
  flexiblePurposes -> flexible_purpose_ids

Returns a list (key-value pairs) so callers can splat into the
constructor and add extras:

  my \$v = GDPR::IAB::TCFv2::Validator->new(
      GDPR::IAB::TCFv2::Validator::from_gvl_vendor_entry(\$entry),
      strict => 1,
  );

Croaks only on missing 'id'.  Missing list fields default to
empty arrayrefs per the GVL schema (a vendor may legitimately
have no LI or flexible purposes).

* docs(validator): rewrite flexible_purpose_ids POD for the new shape

Document the structural derivation of default basis (membership in
consent_purpose_ids vs legitimate_interest_purpose_ids), the
construction-time coherence checks that croak on incoherent inputs,
and the new from_gvl_vendor_entry public function in a new
=head1 FUNCTIONS section.  SYNOPSIS updated to use the flat-int
flexible_purpose_ids shape and shows the from_gvl_vendor_entry
splat idiom.

* feat(validator): add min_policy_version rule

Optional min_policy_version constructor arg (positive int; undef = no
check) gates validation by the parser's policy_version().  The check
runs FIRST in the rule order -- before disclosed-vendor and the
purpose checks -- because it's the most fundamental reason to reject
a TC string.  In fail-fast mode it short-circuits the rest; in
validate_all mode the other rules still run and accumulate.

Failure reason: 'TC string policy version X is below required
minimum Y'.  Per-call override via validate($tc, min_policy_version => N)
is supported, mirroring the other override-able knobs.

* feat(cli): flip dump warnings to opt-in; repurpose --quiet to silence stdout

Path D for the dump subcommand:

  - Add --enable-warnings|-w (default off). The previous --quiet flag
    silenced human-readable warnings on STDERR, which left CI/pipeline
    invocations noisy by default. Warnings are now off by default and
    must be opted into with -w.

  - Repurpose --quiet|-q to suppress all STDOUT for the run, which makes
    `if iabtcfv2 dump -q "$tc"; then ...` a clean shell idiom — exit
    code reflects parse success, no output to discard.

Tests in t/09-predicates.t and t/10-cli-iabtcfv2.t are updated for the
new defaults; POD for the dump subcommand documents the new flag and
the new --quiet semantics.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>

* feat(cli): add validate subcommand with JSON and text output modes

Implement the previously-stubbed `iabtcfv2 validate` subcommand.  It wraps
GDPR::IAB::TCFv2::Validator with a CLI surface that mirrors the validator's
constructor:

  -v|--vendor-id ID                   (required)
  -C|--consent-purposes 1,2,3
  -L|--legitimate-interest-purposes 1,2,3
  -F|--flexible-purposes 1,2,3
  -d|--check-disclosed-vendors
  -s|--strict
  -m|--min-policy-version N
  -a|--all                            (validate_all instead of fail-fast)

Output is one JSON object per TC string by default, or human-readable
lines with -t|--text.  Failure shape uses a singular `reason` in
fail-fast mode and a plural `reasons` array in --all mode.

Pipeline ergonomics match the dump subcommand: --json-array,
--ignore-errors (parse only), --fail-fast (parse OR validation),
--errors-to-stderr, --enable-warnings (off by default), --quiet
(suppresses stdout, preserves exit code).

Exit codes: 0 = all valid; 1 = at least one parse or validation
failure; 2 = bad CLI usage (missing --vendor-id, incoherent purpose
lists, --text with --json-array).

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>

* docs(roadmap): plan Phases 6, 7, 8 in TODO.md

Three new phases tracked after the CMP validator (Phase 5):

  - Phase 6: GVL-aware Validator. Reintroduces the
    from_gvl_vendor_entry helper deferred from Phase 2 and adds a
    higher-level from_gvl loader plus a CLI --gvl flag.

  - Phase 7: features, special features, and special purposes.
    Extends Validator + CLI past the standard purpose taxonomy.

  - Phase 8: CLI configuration loading. Maps flags to environment
    variables and an optional .iabtcfv2rc / .env file with documented
    precedence.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>

* revert(validator): defer from_gvl_vendor_entry to Phase 6

The from_gvl_vendor_entry helper was added speculatively in this
branch but its only useful caller — feeding parsed GVL JSON into the
validator — depends on the GVL infrastructure that lands in Phase 6
(see TODO.md).  Removing it now keeps Phase 2's API surface focused on
what is actually exercised by the validate subcommand.

The helper, its POD, and its dedicated subtest will be reintroduced
together with the rest of the GVL surface in Phase 6.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>

* style: perltidy t/10-cli-iabtcfv2.t

xt/tidy.t (Test::PerlTidy under .perltidyrc) was failing on the
'Perl latest on ubuntu' CI job for PR #54.  Cosmetic-only reflow:
column alignment between consecutive my() lines, splitting long
arg-lists across multiple lines, breaking some closing parens onto
their own line.  No assertions changed.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>

* fix(cli): declare =encoding utf8 in iabtcfv2 POD

The validate subcommand's "Exit codes" section uses em-dashes in
its prose (B<0> — every input TC string was parsed...).  Without an
explicit =encoding directive, Test::Pod warns "Non-ASCII character
seen before =encoding in '—'. Assuming UTF-8" and t/99-pod.t fails
on smokers running Test::Pod with strict POD validation.

Add =encoding utf8 right after __END__ so the entire POD block is
declared as UTF-8.  No prose changes.

---------

Co-authored-by: Claude Opus 4.7 <noreply@anthropic.com>
- Merge tag 'v0.360' into devel

Tagged for release. v0.360

## [0.360] - 2026-05-06

### Features

- *(cli)* Bundling + short aliases (-c for --compact, -s for --strict) 

### Other

- Release v0.360 -- modernize iabtcfv2 cli
- Merge tag 'v0.352' into devel

Tagged for release. v0.352

## [0.352] - 2026-05-06

### Bug Fixes

- *(cli)* Stop short -v from being shadowed by global --version|-V 

### Other

- Release v0.352 - fix iabtcvf2 cli tool that mix -v with -V
- Update changelog
- Merge tag 'v0.351' into devel

Tagged for release. v0.351

## [0.351] - 2026-05-06

### Bug Fixes

- Restore --version / -V + bump to v0.351 
- *(ci)* Drop unused pod2markdown install and use latest Perl in release.yml 

### Documentation

- Track Phase 5 (CMP Validation) in TODO.md 
- Test::Warn refactor, bug-tracker footer, Docker image name fix 

### Other

- Merge branch 'release/0.351'
- Merge tag 'v0.350' into devel

Tagged for release. v0.350

## [0.350] - 2026-05-06

### Bug Fixes

- Coerce Math::BigInt fallback values to plain scalars in BitUtils 

### Features

- Add --version and -V options to CLI

### Other

- Merge branch 'release/0.350'
- Remove docs
- Update changelog, bump version
- Remove broken badges
- Phase 1: TCF v2.3 Support & Logic Alignment (Re-issue) 

* docs: update TCF version mentions to v2.3 in constants

* feat: Phase 1 implementation (predicates, vendor_id filter, CLI options)

* feat: enforce TCF v2.2/v2.3 legal restrictions on Legitimate Interest

* feat: add --strict option to CLI dump and enforce TCF v2.3 rules

* chore: prepare for v0.350 release (Phase 1)

* chore: consolidate documentation to README.md and remove README.pod

* chore: simplify docker tagging (version and latest only)

* chore: final Phase 1 refinements (POD, logic fixes, golden file)

* chore: establish strict operational boundaries for agents in AGENTS.md

* feat: add automated release workflow for CPAN and GitHub Releases

* docs: update AGENTS.md with automated release flow and Phase 1 features

* fix: improve TO_JSON isolation and fix predicates tests

* fix: robust regex for CLI isolation test

* fix: satisfy perl critic and tidy in CI

* Vendor segment parser cleanup (stacked on #44) 

* fix: align core bitfield/range data_size to slice length

Both _parse_bitfield and _parse_range_section previously passed the
full core_data bit-length as data_size while passing a sliced \$data.
This made the BitField/RangeSection size validation lenient for
truncated cores: malformed inputs would stumble forward and croak deep
in _parse_publisher_section with a misleading "missing 'core_data'"
error instead of failing fast at the bitfield boundary.

Align with the pattern already used in _parse_vendor_bitfield_or_range
so data_size faithfully describes what the callee receives.

* feat: defensive segment-type check in vendor-segment helper

_parse_vendor_bitfield_or_range now accepts an expected_segment_type
argument and croaks if the payload header disagrees. Brings parity
with PublisherTC->Parse and protects against future refactors that
might bypass _decode_tc_string_segments routing.

* docs: explain single-return shape of vendor-segment helper

* fix: short-circuit MaxVendorId=0 in vendor-segment helper

Per IAB TCF v2 spec, MaxVendorId=0 means the field is unused.
Previously, a segment with max_id=0 and IsRangeEncoding=1 would
fall into RangeSection->Parse and either parse spurious range
entries or croak from the 31-byte minimum-size guard.

Now we return an empty BitField immediately, preserving
has_vendor_disclosure() semantics while making contains() return
falsey for any vendor id.

* docs: refresh plan with current line numbers and rebase notes

* docs: regenerate README from POD and remove changelog merge noise

Phase 1 added several public methods (is_v22_plus, is_v23,
disclosed_vendor, has_vendor_disclosure, allowed_vendor,
has_publisher_restrictions) and two Parse options (TCF v2.3
strict-mode behaviour, vendor_id JSON filter), all documented in
the .pm POD but missing from README.md.  Regenerated README.md via
the documented workflow (`pod2markdown lib/GDPR/IAB/TCFv2.pm > README.md`).

Also removed two leaked lines from a prior merge commit message
(`# Conflicts:` / `#\tCHANGELOG.md`) that git-cliff had swept into
the v0.350 "Other" section.

* docs: expand CONTRIBUTING with full Git Flow release procedure

The previous "FOR RELEASE MANAGER" section was a 12-line stub.
Replaced with a comprehensive guide covering:

  - Prerequisites: Pod::Markdown, git-cliff, git-flow CLI,
    PAUSE secrets configuration
  - Versioning convention (0.XYZ, v-prefix only on tags)
  - Step-by-step release (10 steps), each with side-by-side
    git-flow and vanilla-git commands
  - What .github/workflows/release.yml does on tag push
  - Hotfix release procedure (skips devel)

Added `=encoding utf8` so podchecker accepts the em-dashes used
throughout the new section.

* docs: explain why we don't document the draft-release pattern

Adds a "Pre-release review" subsection that calls out two reasons
the draft GitHub Release pattern doesn't actually buy us anything
on this project:

  1. PAUSE upload is irreversible, so reviewing the GitHub Release
     before it ships only protects the rendered notes page, not the
     CPAN-distributed artifact.
  2. release.yml hard-codes draft: false in the softprops step and
     listens only on push.tags, so naively adding a draft step would
     either close the review window in 3 minutes or skip release.yml
     entirely (API-created tags don't trigger push events).

Points readers at the existing PR-based vanilla-git path in step 8 as
the actual review gate, and notes the workflow tweak required if
someone later wants to support drafts properly.
- Merge devel into Phase 2 and resolve CHANGELOG conflict
- Merge feat/phase-1-tcf-v23-segments into devel

## [0.340] - 2026-05-05

### Other

- Merge feat/phase-0-core-logic into devel

## [0.330] - 2026-05-05

### Bug Fixes

- Allow non-standard semver in Docker tags

### Other

- Unified Docker Distribution (iabtcfv2) 

## [0.320] - 2026-05-05

### Bug Fixes

- Resolve subroutine name mismatch and incorrect parameter passing in CLI

### Documentation

- Improve CLI help system with subcommand-specific documentation

### Other

- Centralized Quality Checks (xt/ & Makefile) 

## [0.310] - 2026-05-05

### Features

- Implement unified subcommand-based CLI and bump version to 0.310

## [0.300] - 2026-05-05

### Bug Fixes

- Fix yaml lint issues

### Documentation

- Update changelog for Phase 2
- Update changelog for Phase 1

### Other

- Independent iabtcf-dump CLI utility 
- Merge Phase 1 updates
- Merge Phase 0 updates
- Update documentation
- Update doc
- Merge test fix
- Fix test expectation for aligned TO_JSON
- Merge updated Golden File
- Update Golden File for TCF v2.3
- Merge TO_JSON alignment
- Align TO_JSON output
- Refactor Validator to reduce complexity (fix perlcritic)
- Phase 2: The Validator Interface
- Phase 1: TCF v2.3 & Segment Robustness
- Add Golden File Test System baseline
- Phase 0: Core Logic Expansion (Fixed linting & tidy)
- Phase 0: Core Logic Expansion (Fixed linting & tidy)
- Phase 0: Core Logic Expansion
- Normalize macos
- Update changelog

## [0.203] - 2025-04-21

### Bug Fixes

- Fix tests with tap
- Fix perl tidy issue

### Other

- Update changelog
- Bump version to v0.203
- Try fix workflow linux last try
- Try fix workflow linux
- Try refactor linux tests
- Run perltidy on code
- Merge remote-tracking branch 'refs/remotes/origin/devel' into devel
- Update windows.yml

try fix windows
- Update linux.yml

install git and curl
- Update linux.yml

force install linux in older versions
- Update linux.yml

try fix images

## [0.202] - 2025-04-21

### Other

- Bump version
- Bump version
- Improve error message
- Update CONTRIBUTING.pod

fix branch again
- Update CONTRIBUTING.pod

fix branch again
- Merge tag 'v0.201' into devel

Tagged for release. v0.201

## [0.201] - 2023-12-20

### Other

- Merge branch 'release/0.201'
- Promote new version
- Bump version
- Change how we redefine subroutines
- Small fixes
- Merge tag 'v0.200' into devel

Tagged for release. v0.200

## [0.200] - 2023-12-17

### Bug Fixes

- Fix manifest
- Fix issue #25

### Other

- Merge branch 'release/0.200'
- Update manifest
- Promote new version
- Add missing changes
- Refactor publisher restrictions 

* add named parameters on check_publisher_restriction method

* add new method

* improve test

* Revert "improve test"

This reverts commit ae7274e49ad0b767b158beadd9ce73e07a5eb836.

* fix format

* fix pod

* Update Publisher.pm

Remove char

* Update PublisherRestrictions.pm

Remove char

* tidy test

* remove bad chars

* try remove all bad chars
- Increase tests
- Add range section cache 

* add initial code

* reorg code

* rename test

* add unit tests

* add pod

* update readme
- Merge tag 'v0.100' into devel

Tagged for release. v0.100

## [0.100] - 2023-12-15

### Bug Fixes

- Fix workflows

### Other

- Merge branch 'release/0.100'
- Tidy file
- Update manifest
- Promote new version
- Remove unused code
- Add support to publisher tc 

* add code to handle publisher tc, start to implement #13

* add missing changes

* some refactor

* add example

* update pod

* add unit tests

* add unit tests

* force read the first segment as core string

* verify unit tests

* narrow unit test

* narrow unit test 2

* continue search

* fix unit test
- Prepare code to decode other sections
- Fetch other sections of the tcstring
- Group publisher section
- Group constants
- Add strict mode
- Merge tag 'v0.084' into devel

Tagged for release. v0.084

### Refactor

- Refactor code, regroup logic
- Refactor code: group vendor section

## [0.084] - 2023-12-14

### Other

- Merge branch 'release/0.084'
- Update manifest
- Promote new version
- Bump version
- Fix but index out of bonds while parsing range based consent strings 

* add unit test to trigger bug #20 

* add fix

* add changes file
- Merge tag 'vv0.083' into devel

Tagged for release. vv0.083

## [0.083] - 2023-12-13

### Bug Fixes

- Fix pod 2
- Fix pod
- Fix changes

### Other

- Merge branch 'release/v0.083'
- Update manifest
- Bump version
- Revert "try fix links"

This reverts commit e5fb435f3d78beb07ef44b434282724c4f0270ec.
- Revert "try 2"

This reverts commit dca6f2f25344bbd226f8ef79780414f57b378f1a.
- Try 2
- Try fix links
- Merge branch 'devel' of github.com:peczenyj/GDPR-IAB-TCFv2 into devel
- Refactor bitfield & others 

* increase performance in 17% on TO_JSON method when it is bitfield by limit data size

* small refactor on range section

* continue refactor on bitfield, range section and publisher restriction

* refactor offsets

* add changes

* refactor offset / data_size

* verify if offset exists on range section Parse method

* fix tidy

* restrict bitfield data

* tidy code
- Restrict bitfield data
- Reset readme
- Merge branch 'devel' of github.com:peczenyj/GDPR-IAB-TCFv2 into devel
- Update README.pod

Try fix link to method
- Format changes
- Increase performance on range section 

performance improvement on range objects

## [0.082] - 2023-12-12

### Bug Fixes

- Fix perltidy
- Fix example in pod
- Fix pod
- Fix issue #17
- Fix pod
- Fix typo in exception, add more bit check
- Fix pod json fields
- Fix format

### Other

- Bump version to 0.082
- Update changes
- Add small refactor on safe functions
- Revert "refactor purposes and special feature opt in internals"

This reverts commit af62cf3873f673bcc0f790a2523a036042ec34d6.
- Rename options
- Start refactor
- Remove useless method
- Update changes
- Update changes
- Increase TO_JSON performance by 17% on bitfields and 70% on range based
- Add new tests
- Update changelog
- Rename property
- Change bitutils to return the offset of the next piece of information
- Improve bitutils to also return next offset in array context via wantarray

### Refactor

- Refactor purposes and special feature opt in internals

## [0.081] - 2023-12-11

### Bug Fixes

- Fix pod

### Other

- Bump version
- Start to fix issue #17

## [0.08] - 2023-12-10

### Bug Fixes

- Fix makefile
- Fix typo
- Fix pod and readme

### Other

- Update manifest
- Bump version
- Finish TO_JSON method
- Add tests and small refactors in code
- Add missing changes
- Add TO_JSON and tc_string method
- Add TO_JSON method
- Remove = character from base64 validation, since the url version does not have it
- Substitute hardcoded numeric offsets by constants
- Update issue templates
- Create CODE_OF_CONDUCT.md

add coc
- Add missing function on perldoc
- Update TCFv2.pm

add badges
- Update README.pod

add new bagdes
- Update perlcritic.yml

retry perlcritic
- Update perlcritic.yml

try different approach
- Update perlcritic.yml

try again
- Create perlcritic.yml
- Update TCFv2.pm

update badges
- Delete .appveyor.yml

remove appveyor
- Update README.pod

update badges
- Rename macos.yaml to macos.yml

rename file
- Update linux.yml

fix 2
- Update linux.yml

fix linux
- Update linux.yml

improve linux tests
- Create macos.yaml

add tests on macos
- Create windows.yml

add tests on windows
- Create perltidy.yml

add perldity
- Update TCFv2.pm

fix typo in badges
- Update README.pod

fix pod
- Update README.pod

fix typo
- Update linux.yml

try fix git config
- Update linux.yml

add coveralls repo token on secret
- Update linux.yml
- Update linux.yml

update action
- Add test pod and fix small typos
- Explain changes
- Add version on changes file

## [0.07] - 2023-12-07

### Bug Fixes

- Fix unit tests again
- Fix unit test
- Fix type validation
- Fix pod

### Other

- Simplify code
- Remove usage of // operation
- Revert "fix unit test"

This reverts commit c56400f41b1f71f516d999786ec88f1144945f48.
- Update manifest
- Bump version
- Merge branch 'main' of github.com:peczenyj/GDPR-IAB-TCFv2
- Update TCFv2.pm

Fix pod
- Update README.pod

Fix pod
- Update changelog
- Update readme
- Add publisher restriction check and fix issue #11
- Check if string is a base64 url encoded string before parse it and fix issue #3

## [0.06] - 2023-12-06

### Other

- Update docs
- Bump version to 0.06
- Update changes
- Add wantarray on created and last_updated methods
- Add coveralls badge
- Update linux.yml

add coveralls
- Add badge
- Add appveyor
- Push new constants and docs
- Merge branch 'main' of github.com:peczenyj/GDPR-IAB-TCFv2
- Update linux.yml

rename
- Add new readme
- Update readme
- Add special features as constants
- Add purposes constants, fix issue #2
- Simplify ctor
- Add comments
- Add small changes in code

## [0.051] - 2023-12-05

### Bug Fixes

- Fix readme
- Fix readme
- Fix branch name
- Fix pod
- Fix contributing file

### Other

- Release version 0.051

## [0.05] - 2023-12-05

### Other

- Add missing changes

## [0.0.5] - 2023-12-05

### Bug Fixes

- Fix module format
- Fix test matrix
- Fix manifest
- Fix issue #9 by trying to use MIME::Base64->can("decode_base64url")  or use a fallback

### Other

- Bump version
- Try to force mininum perl 5.8
- Try make it work on perl 5.8
- Try even older version
- Try again
- Small refactors
- Try fix markdown format

## [0.0.4] - 2023-12-04

### Bug Fixes

- Fix issue #8
- Fix dependency

### Other

- Add manifest
- Add contributing file
- Add changelog
- Update version

## [0.0.3] - 2023-12-04

### Other

- Add manifest
- Improve doc
- Complete pod documentation
- Add full support to vendor consent and vendor legitimate interest, ias bitfield or range sections. fix issue #1
- Complete code, add support to bitfields
- Add more methods

## [0.0.2] - 2023-12-03

### Other

- Update code, add skip
- Rename readme
- Improve documentation
- Skip .github dir
- Update license
- Add github meta

## [0.0.1] - 2023-12-02

### Other

- Add github workflow
- Add makefile.pl
- Add *.bak on .gitignore
- Remove .bak
- Add some properties and tests
- Initial commit

<!-- generated by git-cliff -->
