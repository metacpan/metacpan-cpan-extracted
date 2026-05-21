use strict;
use warnings;
use Test::More;
use GDPR::IAB::TCFv2;
use File::Spec;

eval { require JSON; 1 } or eval { require JSON::PP; 1 } or plan skip_all => 'JSON or JSON::PP required for this test';

my $json_pkg = JSON->can('new') ? 'JSON' : 'JSON::PP';

sub decode_json_str {
  my $s = shift;
  return eval { $json_pkg->new->utf8->decode($s) };
}

# Test TC strings
my $tc_with_res  = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';    # Core + Restrictions
my $tc_with_disc = $tc_with_res . '.IAAA';                                      # Core + Res + Discl (empty)
my $tc_full
  = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.ILrtR_G__bXlv-bb36ftkeYxf9_hr7sQxBgbJs24FzLvW7JwX32E7NEzatqYKmRIAu3TBIQNtHJjURVChKIgVrzDsaEyUoTtKJ-BkiHMRY2NYCFxvm4tjWQCZ5vr_91d9mT-N7dr-2dzyy7hnv3a9_-S1WJidKYetHfv8bBKT-_IU9_x-_4v4_N7pE2-eS1v_tGvt639-4vP_dpvxt-7yffz____73_e7X__d_______Xf_7____________4AAA';

subtest 'Predicates' => sub {

  # TCF v2.3 string without DV segment (CP188...)
  my $tc_basic
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA.f_wACHwAAAAA';
  my $c1 = GDPR::IAB::TCFv2->Parse($tc_basic);
  ok(!$c1->has_vendor_disclosure,      'No disclosure segment');
  ok(!$c1->has_publisher_restrictions, 'No restrictions on CP188 string');

  my $c2 = GDPR::IAB::TCFv2->Parse($tc_with_res);
  ok($c2->has_publisher_restrictions, 'Has restrictions');

  my $c3 = GDPR::IAB::TCFv2->Parse($tc_with_disc);
  ok($c3->has_vendor_disclosure, 'Has disclosure segment');
};

subtest 'Robustness: Truncated segments' => sub {
  use Test::Exception;

  # Using the valid disclosure segment from $tc_full
  my $segment_disc
    = 'ILrtR_G__bXlv-bb36ftkeYxf9_hr7sQxBgbJs24FzLvW7JwX32E7NEzatqYKmRIAu3TBIQNtHJjURVChKIgVrzDsaEyUoTtKJ-BkiHMRY2NYCFxvm4tjWQCZ5vr_91d9mT-N7dr-2dzyy7hnv3a9_-S1WJidKYetHfv8bBKT-_IU9_x-_4v4_N7pE2-eS1v_tGvt639-4vP_dpvxt-7yffz____73_e7X__d_______Xf_7____________4AAA';

  # Valid disclosure
  my $tc_valid = $tc_with_res . '.' . $segment_disc;
  lives_ok { GDPR::IAB::TCFv2->Parse($tc_valid) }
  'Valid disclosure segment lives';

  # Truncated disclosure: remove most of the bitfield
  # This segment uses MaxId=1502.
  my $tc_truncated = $tc_with_res . '.' . substr($segment_disc, 0, 48);
  throws_ok { GDPR::IAB::TCFv2->Parse($tc_truncated) }
  qr/a BitField for \d+ bits requires a consent string of at least \d+ bits/, 'Croaks on truncated bitfield disclosure';
};

subtest 'vendor_id filter in TO_JSON' => sub {
  my $c = GDPR::IAB::TCFv2->Parse($tc_full);

  # Vendor 1 is present in core consents and disclosed
  my $json_1 = $c->TO_JSON(vendor_id => 1);

  # Check that ONLY vendor 1 is in the vendor sections
  is_deeply([sort { $a <=> $b } keys %{$json_1->{vendor}{consents}}], [1], 'Vendor section isolated: only vendor 1');
  ok(!exists $json_1->{vendor}{legitimate_interests}{2}, 'Other vendor (2) removed from LI');

  # Purpose section should still have entries for vendor 1
  ok(exists $json_1->{purpose}{consents}{23}, 'Vendor 1 still has Purpose 23');

  # Publisher restrictions should only show 32
  my $json_res = $c->TO_JSON(vendor_id => 32);
  is_deeply([keys %{$json_res->{publisher}{restrictions}{7}}], [32],
    'Filtered publisher restrictions only contains 32');
};

subtest 'CLI --vendor-id option' => sub {
  my $bin  = File::Spec->catfile('bin', 'iabtcfv2');
  my $perl = $^X;

  # Filter for vendor 1.  Decoded structurally so the assertions don't
  # depend on JSON key order, which varies by encoder, Perl version,
  # and hash randomization (CPAN Testers report 4f448578-4978-... saw
  # JSON::XS on Perl 5.32.1 emit a different key order than the
  # previous regex assumed).
  my $data = decode_json_str(`$perl -Ilib $bin dump --vendor-id 1 $tc_full`);
  ok($data, 'CLI emits valid JSON') or BAIL_OUT('--vendor-id output was not parseable JSON');

  is_deeply([sort { $a <=> $b } keys %{$data->{vendor}{consents} || {}}],
    [1], 'CLI isolated vendor consents to vendor 1 only');
  ok($data->{vendor}{consents}{1},           'vendor 1 consent is true');
  ok(!exists $data->{vendor}{disclosed}{23}, 'CLI removed other disclosed vendors (vendor 23 not in disclosed)');

  # Regression: lowercase short -v must be parsed as --vendor-id by the
  # `dump` subcommand, NOT slurped by the global Getopt::Long as a
  # case-insensitive match for --version|-V.  Before require_order was
  # added to the Getopt::Long config, this would print
  # "iabtcfv2 version 0.351" instead of the JSON dump.
  my $out_short = `$perl -Ilib $bin dump -v 1 $tc_full`;
  unlike($out_short, qr/^iabtcfv2 version/, 'short -v is not shadowed by the global -V/--version');
  my $data_short = decode_json_str($out_short);
  ok($data_short, 'short -v emits valid JSON') or BAIL_OUT('-v output was not parseable JSON');
  is_deeply(
    $data_short->{vendor}{consents},
    $data->{vendor}{consents},
    'short -v isolates the same vendor as --vendor-id'
  );
};

subtest 'CLI --strict option' => sub {
  my $bin  = File::Spec->catfile('bin', 'iabtcfv2');
  my $perl = $^X;

  # TCF v2.3 string without DV segment (CP188...)
  my $tc_v23_no_dv
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA';

  my $out_lenient = `$perl -Ilib $bin dump $tc_v23_no_dv`;
  like($out_lenient, qr/"tc_string":/i, 'Lenient mode (default) succeeds');

  # Warnings are off by default (Path D), so no need to silence them.  The
  # error JSON is still emitted to stdout, which is what we assert on.
  my $out_strict = `$perl -Ilib $bin dump --strict $tc_v23_no_dv`;
  like($out_strict, qr/Disclosed Vendors segment is mandatory/, 'Strict mode fails for v2.3 without DV');
};

done_testing();
