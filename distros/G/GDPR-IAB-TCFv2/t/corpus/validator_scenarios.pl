use strict;
use warnings;
use FindBin;

# Canonical list of Validator scenarios driven against every TC string in
# the golden corpus.  This file is `do`-loaded by both
# t/generate_golden.pl (which writes the expected outcomes into
# t/corpus/golden.jsonl.gz under tests.validator.<name>) and
# t/08-golden-validator.t (which replays the scenarios at test time and
# diffs against the stored outcomes).
#
# Adding a scenario:
#   1. Append it here.
#   2. Re-run `REGEN_CORPUS=1 prove -lr t/07-golden.t`.
#   3. Inspect the corpus diff and commit both files together.
#
# Scenario design notes:
#   - Each `args` hash is what gets splatted into Validator->new.
#   - vendor 284 is "Weborama" in the IAB GVL and appears in many of
#     the corpus's bitfields, giving a healthy mix of valid/invalid
#     outcomes across the corpus.
#   - vendor 99999 is intentionally out-of-range so it always fails
#     vendor-level checks: it pins down the "vendor not allowed"
#     branch of the validator.
#   - Two flexible-purpose scenarios exist (consent default vs LI
#     default) so the corpus exercises is_vendor_allowed_for_flexible_purpose
#     for both default bases.
#   - The cmp_validator scenario uses the small fixture in
#     t/corpus/cmp-list.json with `now` pinned so the deletedDate /
#     stale-warning checks are deterministic.

# Both consumers (t/generate_golden.pl and t/08-golden-validator.t) live
# in t/, so $FindBin::Bin resolves to that directory.
my $cmp_file = "$FindBin::Bin/corpus/cmp-list.json";

return [
  {name => 'v284_baseline',     args => {vendor_id => 284},},
  {name => 'v284_consent_p1',   args => {vendor_id => 284,   consent_purpose_ids             => [1],},},
  {name => 'v99999_consent_p1', args => {vendor_id => 99999, consent_purpose_ids             => [1],},},
  {name => 'v284_li_p7',        args => {vendor_id => 284,   legitimate_interest_purpose_ids => [7],},},
  {
    name => 'v284_flex_p2_consent',
    args => {vendor_id => 284, consent_purpose_ids => [2], flexible_purpose_ids => [2],},
  },
  {
    name => 'v284_flex_p7_li',
    args => {vendor_id => 284, legitimate_interest_purpose_ids => [7], flexible_purpose_ids => [7],},
  },
  {name => 'v284_min_policy_v5',    args => {vendor_id => 284, min_tcf_policy_version   => 5,},},
  {name => 'v284_verify_disclosed', args => {vendor_id => 284, verify_disclosed_vendors => 1,},},

  {
    name => 'v284_cmp_registry',
    args => {
      vendor_id     => 284,
      cmp_validator => {
        file => $cmp_file,
        now  => 1776254400,    # 2026-04-15, fixture is fresh
      },
    },
  },
];
