use strict;
use warnings;

use Test::More;
use Test::Exception;

use GDPR::IAB::TCFv2;

my $tc_v23
  = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.ILrtR_G__bXlv-bb36ftkeYxf9_hr7sQxBgbJs24FzLvW7JwX32E7NEzatqYKmRIAu3TBIQNtHJjURVChKIgVrzDsaEyUoTtKJ-BkiHMRY2NYCFxvm4tjWQCZ5vr_91d9mT-N7dr-2dzyy7hnv3a9_-S1WJidKYetHfv8bBKT-_IU9_x-_4v4_N7pE2-eS1v_tGvt639-4vP_dpvxt-7yffz____73_e7X__d_______Xf_7____________4AAA';

subtest "TCF v2.3 segments" => sub {
  my $consent;
  lives_ok {
    $consent = GDPR::IAB::TCFv2->Parse($tc_v23);
  }
  'should parse v2.3 string with disclosed vendors';

  is $consent->version, 2, 'version should be 2';

  # Disclosed vendors check
  ok $consent->disclosed_vendor(284),   'Weborama (284) should be disclosed';
  ok !$consent->disclosed_vendor(9999), 'vendor 9999 should NOT be disclosed';

  # Allowed vendors check (not present in this string)
  ok !$consent->allowed_vendor(284), 'vendor 284 should NOT be in allowed vendors segment (segment missing)';
};

subtest "duplicate segment check" => sub {
  my $duplicate_string = $tc_v23
    . '.ILrtR_G__bXlv-bb36ftkeYxf9_hr7sQxBgbJs24FzLvW7JwX32E7NEzatqYKmRIAu3TBIQNtHJjURVChKIgVrzDsaEyUoTtKJ-BkiHMRY2NYCFxvm4tjWQCZ5vr_91d9mT-N7dr-2dzyy7hnv3a9_-S1WJidKYetHfv8bBKT-_IU9_x-_4v4_N7pE2-eS1v_tGvt639-4vP_dpvxt-7yffz____73_e7X__d_______Xf_7____________4AAA';
  throws_ok {
    GDPR::IAB::TCFv2->Parse($duplicate_string);
  }
  qr/duplicate segment type 1/, 'should throw exception for duplicate segment type 1';
};

subtest "TCF v2.3 Mandatory segment" => sub {
  my $tc_v23_no_dv
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA.f_wACHwAAAAA';

  lives_ok { GDPR::IAB::TCFv2->Parse($tc_v23_no_dv) }
  'should parse by default (lenient)';

  throws_ok { GDPR::IAB::TCFv2->Parse($tc_v23_no_dv, strict => 1) }
  qr/Disclosed Vendors segment is mandatory/, 'should die in strict mode if DV segment is missing for v2.3';
};

subtest "TCF v2.2/v2.3 Legitimate Interest Restrictions" => sub {

  # TCF v2.0 string with P1 LI bit set (COwAdDh...)
  my $tc_v20 = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';
  my $c20    = GDPR::IAB::TCFv2->Parse($tc_v20);
  is($c20->policy_version,                                  2, 'v2.0 policy');
  is($c20->_safe_is_purpose_legitimate_interest_allowed(1), 1, 'P1 LI bit is 1');
  is($c20->is_purpose_legitimate_interest_allowed(1),       0, 'P1 LI logic returns 0 (forbidden)');
  is($c20->is_purpose_legitimate_interest_allowed(3),       1, 'P3 LI allowed in v2.0');

  # TCF v2.3 string (CP188...)
  my $tc_v23
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA.f_wACHwAAAAA';
  my $c23 = GDPR::IAB::TCFv2->Parse($tc_v23);
  is($c23->policy_version, 5, 'v2.3 policy');

# Even if bits were set (need a string with bits set to be 100% sure, but logic is verified)
  is($c23->is_purpose_legitimate_interest_allowed(3),  0, 'P3 LI forbidden in v2.3');
  is($c23->is_purpose_legitimate_interest_allowed(10), 1, 'P10 LI allowed in v2.3');

  # Flexible purpose check
  # Purpose 10 allows LI. Vendor 46 has LI but no Consent.
  # Default LI=1 should return 1.
  ok($c23->is_vendor_allowed_for_flexible_purpose(46, 10, 1), 'P10 flexible with default LI returns 1 for vendor 46');

  # Purpose 3 prohibits LI in v2.3. Vendor 46 has LI but no Consent.
  # Default LI=1 should return 0 (forced fallback to Consent).
  ok(!$c23->is_vendor_allowed_for_flexible_purpose(46, 3, 1),
    'P3 flexible with default LI returns 0 for vendor 46 (forced consent)');
};

subtest "MaxVendorId == 0 yields an empty vendor section" => sub {
  my $consent = GDPR::IAB::TCFv2->Parse('COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA');

  # Hand-built Disclosed Vendors segment:
  #   segment_type      = 001 (=1)
  #   max_vendor_id     = 16 zero bits
  #   is_range_encoding = 1
  #   num_entries       = 12 zero bits
  # With IsRange=1 and max_id=0, RangeSection->Parse would parse the
  # 12-bit num_entries from the trailing zeros (NumEntries=0, harmless
  # here, but a malicious payload could declare NumEntries>0).  The
  # short-circuit must skip RangeSection entirely and return an empty
  # BitField regardless of the IsRange flag.
  my $segment = '001' . ('0' x 16) . '1' . ('0' x 12);

  my $section;
  lives_ok {
    $section = $consent->_parse_vendor_bitfield_or_range($segment,
      GDPR::IAB::TCFv2::Parser::SEGMENT_TYPES->{DISCLOSED_VENDORS},);
  }
  'max_id=0 segment parses without error';

  ok defined $section, 'returns a defined section';
  is $section->max_id, 0, 'max_id is 0';
  ok !$section->contains(1), 'contains(1) returns falsey (early-exit on id > max_id)';
};

subtest "Disclosed Vendors helper rejects mis-typed payload" => sub {

  # Hand-craft a "Disclosed Vendors" segment whose first 3 bits claim
  # segment_type=2 (Allowed Vendors) instead of 1.  The router would
  # never feed this through _parse_disclosed_vendors today, but the
  # helper itself should still reject it as defense-in-depth.
  my $consent = GDPR::IAB::TCFv2->Parse('COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA');

  # 3 bits = 010 (=2), then a benign MaxVendorId=0, IsRangeEncoding=0 tail.
  my $bad = '010' . ('0' x 16) . '0';

  throws_ok {
    $consent->_parse_vendor_bitfield_or_range($bad, GDPR::IAB::TCFv2::Parser::SEGMENT_TYPES->{DISCLOSED_VENDORS},);
  }
  qr/invalid segment type/, 'helper croaks when payload header does not match expected type';
};

subtest "Core BitField data_size reflects slice length, not full core" => sub {

  # Single-segment v2.0 string with a sizeable core bitfield
  # (max_vendor_id_consent = 115).  Truncating 4 base64 chars chops
  # ~24 bits off the bitfield tail.
  #
  # OLD behavior: data_size = length(core_data) > max_id, so the
  # BitField guard never fires; the parser stumbles forward and
  # eventually croaks deep in _parse_publisher_section with a
  # misleading "missing 'core_data'" error.
  # NEW behavior: data_size = length(slice) < max_id, the guard
  # fires immediately with a clear "requires N bits" message that
  # points at the actual problem.
  my $good = 'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA';

  lives_ok { GDPR::IAB::TCFv2->Parse($good) } 'baseline parses cleanly';

  my $truncated = substr($good, 0, length($good) - 4);

  throws_ok { GDPR::IAB::TCFv2->Parse($truncated) }
  qr/a BitField for \d+ bits requires a consent string of at least \d+ bits/,
    'truncated core bitfield is rejected with slice-aware size guard';
};

done_testing;
