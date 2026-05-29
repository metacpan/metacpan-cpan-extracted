use strict;
use warnings;
use Test::More;

eval { require JSON; 1 } or eval { require JSON::PP; 1 } or plan skip_all => 'JSON or JSON::PP required for this test';

my $json_pkg = JSON->can('new') ? 'JSON' : 'JSON::PP';
use File::Spec;

my $bin       = File::Spec->catfile('bin', 'iabtcfv2');
my $tc_string = 'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA';

# Use $^X to ensure we use the same perl interpreter
my $perl    = $^X;
my $devnull = ($^O eq 'MSWin32') ? 'NUL' : '/dev/null';

sub decode_helper {
  my $json_str = shift;
  return eval { $json_pkg->new->utf8->decode($json_str) };
}

# Test basic dump (JSON Line)
my $output = `$perl -Ilib $bin dump $tc_string`;
ok($output, "Got output from CLI dump");

my $json_obj = decode_helper($output);
ok($json_obj, "Output is valid JSON");
is($json_obj->{version}, 2, "Parsed version is correct");

# Test pretty print
my $pretty_output = `$perl -Ilib $bin dump --pretty $tc_string`;
my $pretty_json   = decode_helper($pretty_output);
ok($pretty_json, "Pretty output is valid JSON");
is($pretty_json->{version}, 2, "Pretty output reports version 2");

# Multi-line indentation is the *visible* effect of --pretty; this regex
# is over plain output structure (newline + whitespace + open quote), not
# JSON content, so it stays.
like($pretty_output, qr/\n\s+"/, "Pretty output contains indentation");

# Test short -p alias
my $short_p_output = `$perl -Ilib $bin dump -p $tc_string`;
my $short_p_json   = decode_helper($short_p_output);
is_deeply($short_p_json, $pretty_json, "Short -p alias produces logically same output as --pretty");

# Test JSON Lines output: dumping multiple strings emits one JSON object
# per line (the `--json-array` flag was removed; `jq -s .` does the wrap).
my $multi_output = `$perl -Ilib $bin dump $tc_string $tc_string`;
my @multi_lines  = grep {/\S/} split /\n/, $multi_output;
is(scalar @multi_lines, 2, "Two TC strings yield two output lines");
for my $i (0 .. $#multi_lines) {
  my $obj = decode_helper($multi_lines[$i]);
  ok($obj && ref($obj) eq 'HASH', "Line " . ($i + 1) . " is a JSON object");
  is($obj->{version}, 2, "Line " . ($i + 1) . " parsed as version 2");
}

# Test STDIN (using Perl to avoid shell-specific echo/heredoc issues)
my $stdin_output = `$perl -e "print '$tc_string'" | $perl -Ilib $bin dump`;

my $stdin_json = decode_helper($stdin_output);
ok($stdin_json, "Parsed from STDIN correctly") or diag("Output was: $stdin_output");
is($stdin_json->{version}, 2, "Parsed version from STDIN is correct");

# Test compact output
my $compact_output = `$perl -Ilib $bin dump --compact $tc_string`;
my $compact_json   = decode_helper($compact_output);
ok($compact_json, "Got compact output");
is(ref($compact_json->{purpose}{consents}), 'ARRAY', "Compact output uses array for purpose consents");

# Test Error Handling
my $invalid_str = "INVALID_STRING_XYZ";
my $json_false  = $json_pkg->can('false') ? $json_pkg->false() : JSON::PP::false();

# 1. Default Error JSON
my $err_output = `$perl -Ilib $bin dump $invalid_str 2>$devnull`;
my $err_json   = decode_helper($err_output);
ok($err_json, "Invalid string produces JSON error object");
is($err_json->{success},   $json_false,  "Error object success is false");
is($err_json->{tc_string}, $invalid_str, "Error object includes raw string");

# 2. --ignore-errors
my $ignore_output = `$perl -Ilib $bin dump --ignore-errors $invalid_str 2>$devnull`;
is($ignore_output, "", "--ignore-errors produces no output for bad string");

# 3. --fail-fast
my $ff_output = `$perl -Ilib $bin dump --fail-fast $invalid_str 2>$devnull`;
ok($? != 0, "--fail-fast exits with non-zero code");

# 4. --errors-to-stderr
# Use a temporary file to capture stderr safely
my $stderr_file = File::Spec->catfile(File::Spec->tmpdir(), "tcf_stderr_$$");
my $e2s_stdout  = `$perl -Ilib $bin dump --errors-to-stderr $invalid_str 2>$stderr_file`;

is($e2s_stdout, "", "--errors-to-stderr stdout is empty for bad string");

my $e2s_stderr = "";
if (-f $stderr_file) {
  open my $fh, '<', $stderr_file;
  $e2s_stderr = join '', <$fh>;
  close $fh;
  unlink $stderr_file;
}

my $e2s_stderr_json = decode_helper($e2s_stderr);
ok($e2s_stderr_json, "--errors-to-stderr routes JSON to stderr") or diag("Stderr was: $e2s_stderr");

# Test Help System
subtest 'Help System' => sub {

  # 1. Global Help
  my $global_help = `$perl -Ilib $bin --help`;
  like($global_help, qr/SUBCOMMANDS/i, "Global help lists subcommands");
  like($global_help, qr/dump/i,        "Global help mentions 'dump'");
  like($global_help, qr/validate/i,    "Global help mentions 'validate'");

  # 2. Subcommand Help (dump)
  my $dump_help = `$perl -Ilib $bin dump --help`;
  like($dump_help, qr/DUMP/i,      "Subcommand help header found");
  like($dump_help, qr/--compact/i, "Subcommand help lists --compact");
  like($dump_help, qr/--pretty/i,  "Subcommand help lists --pretty");
  like($dump_help, qr/Examples/i,  "Subcommand help shows examples");

  # 3. Help Subcommand
  my $help_cmd = `$perl -Ilib $bin help dump`;
  is($help_cmd, $dump_help, "'help dump' is same as 'dump --help'");

  # 4. Top-level short help (`-h` is now distinct from `--help`).
  my $short_top = `$perl -Ilib $bin -h 2>&1`;
  like($short_top, qr/Subcommands:/,                    "Top-level -h lists subcommands header");
  like($short_top, qr/dump\s+Parse TC strings/,         "Top-level -h describes 'dump'");
  like($short_top, qr/validate\s+Validate TC strings/i, "Top-level -h describes 'validate'");
  like($short_top, qr/--help.*for the full manual/,     "Top-level -h points to --help");

  # 5. Bare invocation gets the same short help (mirrors no-args case).
  my $bare = `$perl -Ilib $bin 2>&1`;
  is($bare, $short_top, "Bare 'iabtcfv2' is the same short help as '-h'");

  # 6. Subcommand short help (`dump -h`).
  my $short_dump = `$perl -Ilib $bin dump -h 2>&1`;
  like($short_dump, qr/iabtcfv2 dump - Parse TC strings/, "dump -h has subcommand summary header");
  like($short_dump, qr/-p, --pretty\s+Indent JSON/,       "dump -h lists -p, --pretty with description");
  like(
    $short_dump,
    qr/Run 'iabtcfv2 dump --help' for the full documentation/,
    "dump -h points to dump --help for full docs"
  );
  unlike($short_dump, qr/^=head/m, "dump -h does not leak raw POD markers");

  # 7. Validate short help shows the required vendor flag and cmp-validator.
  my $short_val = `$perl -Ilib $bin validate -h 2>&1`;
  like($short_val, qr/-v, --vendor-id <ID>\s+REQUIRED/, "validate -h marks --vendor-id as required");
  like($short_val, qr/--cmp-validator <PATH-OR-URL>/,   "validate -h shows --cmp-validator with placeholder");

  # 8. Unknown-subcommand error is informative and exits 2.
  my $unknown_out  = `$perl -Ilib $bin frobnicate 2>&1`;
  my $unknown_code = $? >> 8;
  is($unknown_code, 2, "unknown subcommand exits 2");
  like($unknown_out, qr/unknown subcommand 'frobnicate'/,      "unknown subcommand error names the bad token");
  like($unknown_out, qr/Available subcommands:/,               "unknown subcommand error lists subcommands");
  like($unknown_out, qr/dump\s+Parse TC strings/,              "unknown subcommand list includes dump");
  like($unknown_out, qr/validate\s+Validate TC strings/i,      "unknown subcommand list includes validate");
  like($unknown_out, qr/Run 'iabtcfv2 -h'.*'iabtcfv2 --help'/, "unknown subcommand error points at -h and --help");
};

# Test Version Option
subtest 'Version Option' => sub {
  my $version_output = `$perl -Ilib $bin --version`;
  like($version_output, qr/iabtcfv2 version \d+\.\d+/, "--version prints version string");

  my $short_version_output = `$perl -Ilib $bin -V`;
  is($short_version_output, $version_output, "-V is alias for --version");
};

# Test Short Option Bundling and = syntax
subtest 'Short option bundling and = value syntax' => sub {

  # Bundled boolean flags: -pi is parsed as --pretty --ignore-errors.
  # `--pretty` produces multi-line indented JSON, which is the easiest
  # observable side effect to assert on; -i is a no-op for a valid TC
  # string (no parse error to ignore).
  my $bundled_flags_out  = `$perl -Ilib $bin dump -pi $tc_string`;
  my $bundled_flags_data = decode_helper($bundled_flags_out);
  ok($bundled_flags_data, '-pi produces valid JSON');
  like($bundled_flags_out, qr/\n\s+"/, '-pi enables --pretty (multi-line output)');

  # Bundled flag + value-taking short: -pv 1 is --pretty --vendor-id 1.
  # Compare logically against the canonical long-form invocation so the
  # assertion doesn't depend on which fields are populated for the chosen
  # vendor in the fixture.
  my $bundled_value_data = decode_helper(`$perl -Ilib $bin dump -pv 1 $tc_string`);
  my $longform_data      = decode_helper(`$perl -Ilib $bin dump --pretty --vendor-id 1 $tc_string`);
  is_deeply($bundled_value_data, $longform_data, '-pv 1 produces the same data as --pretty --vendor-id 1');

  # GNU-style --opt=value: --vendor-id=1 must behave identically to
  # --vendor-id 1.
  my $eq_data    = decode_helper(`$perl -Ilib $bin dump --vendor-id=1 $tc_string`);
  my $space_data = decode_helper(`$perl -Ilib $bin dump --vendor-id 1 $tc_string`);
  is_deeply($eq_data, $space_data, '--vendor-id=1 is parsed identically to --vendor-id 1');
};

# Test short aliases -c (compact) and -s (strict-legal-basis)
subtest 'Short aliases -c (compact) and -s (strict-legal-basis)' => sub {

  # -c == --compact: assert by comparing decoded data against the long form.
  my $c_data    = decode_helper(`$perl -Ilib $bin dump -c $tc_string`);
  my $long_data = decode_helper(`$perl -Ilib $bin dump --compact $tc_string`);
  is_deeply($c_data, $long_data, '-c produces the same data as --compact');
  is(ref($c_data->{purpose}{consents}), 'ARRAY', '-c enables compact form (purpose consents as array)');

  # -s == --strict: a TCF v2.3 string without Disclosed Vendors segment
  # must be rejected with the standard "Disclosed Vendors segment is
  # mandatory" message.  Warnings are off by default (Path D), so no
  # extra flag needed to keep CI clean.
  my $tc_v23_no_dv
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA';

  my $s_out = `$perl -Ilib $bin dump -s $tc_v23_no_dv`;
  like(
    $s_out,
    qr/Disclosed Vendors segment is mandatory/,
    '-s enables --strict-legal-basis (rejects v2.3 without Disclosed Vendors)'
  );

  # Bundled new shorts: -cp must produce the same data as --compact --pretty.
  my $bundled_cp_data  = decode_helper(`$perl -Ilib $bin dump -cp $tc_string`);
  my $longform_cp_data = decode_helper(`$perl -Ilib $bin dump --compact --pretty $tc_string`);
  is_deeply($bundled_cp_data, $longform_cp_data, '-cp produces the same data as --compact --pretty');
};

subtest 'validate subcommand' => sub {

  # Vendor 21 holds a vendor-level consent bit in the fixture, so it clears
  # the global vendor gate; with no required purposes it always succeeds.
  # The same bit-bearing vendor with required purposes it cannot satisfy
  # (purpose 2 has no consent; purposes 7,8 have no vendor legitimate
  # interest) always fails, giving stable assertions independent of the GVL.

  my $valid_out  = `$perl -Ilib $bin validate -v 21 $tc_string`;
  my $valid_data = decode_helper($valid_out);
  ok($valid_data, 'validate emits JSON');
  is($valid_data->{valid},     JSON->can('true') ? JSON->true() : JSON::PP::true(), 'valid case has valid:true');
  is($valid_data->{vendor_id}, 21,                                                  'valid case echoes vendor_id');

  # Failure (singular reason, fail-fast default).
  my $fail_out  = `$perl -Ilib $bin validate -v 21 -C 1,2 $tc_string`;
  my $fail_code = $? >> 8;
  my $fail_data = decode_helper($fail_out);
  ok($fail_data, 'failing validate emits JSON');
  is($fail_data->{valid}, $json_false, 'failing case has valid:false');
  ok(exists $fail_data->{reason},   'fail-fast uses singular reason');
  ok(!exists $fail_data->{reasons}, 'fail-fast does not emit reasons array');
  is($fail_code, 1, 'failing validate exits 1');

  # --all aggregates reasons.
  my $all_out  = `$perl -Ilib $bin validate -av 21 -C 1,2 -L 7,8 $tc_string`;
  my $all_data = decode_helper($all_out);
  ok(exists $all_data->{reasons}, '--all uses plural reasons array');
  ok(!exists $all_data->{reason}, '--all does not emit singular reason');
  is(ref $all_data->{reasons}, 'ARRAY', 'reasons is an array');
  cmp_ok(scalar @{$all_data->{reasons}}, '>=', 2, '--all aggregates multiple failures');

  # --text output paths (success and failure).
  my $text_ok = `$perl -Ilib $bin validate -tv 21 $tc_string`;
  like($text_ok, qr/^OK\s+\S+\s+vendor 21/, '--text valid line shape');

  my $text_fail = `$perl -Ilib $bin validate -tv 21 -C 2 $tc_string`;
  like($text_fail, qr/^FAIL\s+\S+\s+vendor 21:/, '--text fail line shape');

  my $text_all   = `$perl -Ilib $bin validate -atv 21 -C 2 -L 7 $tc_string`;
  my @text_lines = split /\n/, $text_all;
  cmp_ok(scalar @text_lines, '>=', 2, '--text --all spans multiple lines');
  like($text_lines[0], qr/^FAIL\s+\S+\s+vendor 21:$/, '--text --all first line ends with colon');
  like($text_lines[1], qr/^\s+-\s/,                   '--text --all subsequent lines are indented bullets');

  # --quiet preserves exit code, suppresses stdout.
  my $quiet_ok = `$perl -Ilib $bin validate -qv 21 $tc_string`;
  is($quiet_ok, '', '--quiet on success emits nothing');
  is($? >> 8,   0,  '--quiet on success exits 0');

  my $quiet_fail = `$perl -Ilib $bin validate -qv 21 -C 2 $tc_string`;
  is($quiet_fail, '', '--quiet on failure emits nothing');
  is($? >> 8,     1,  '--quiet on failure still exits 1');

  # Missing --vendor-id: exit 2 with diagnostic on STDERR.
  my $missing_v_stderr = File::Spec->catfile(File::Spec->tmpdir(), "tcf_missing_v_$$");
  my $missing_v_stdout = `$perl -Ilib $bin validate $tc_string 2>$missing_v_stderr`;
  is($? >> 8, 2, 'missing --vendor-id exits 2');
  my $missing_v_msg = "";
  if (-f $missing_v_stderr) {
    open my $fh, '<', $missing_v_stderr;
    $missing_v_msg = join '', <$fh>;
    close $fh;
    unlink $missing_v_stderr;
  }
  like($missing_v_msg, qr/--vendor-id\|-v is required/, 'missing --vendor-id explains itself on STDERR');

  # Parse error path.
  my $parse_err_out  = `$perl -Ilib $bin validate -v 32 INVALID_STRING 2>$devnull`;
  my $parse_err_code = $? >> 8;
  my $parse_err_data = decode_helper($parse_err_out);
  ok($parse_err_data, 'parse error emits JSON');
  is($parse_err_data->{success}, $json_false, 'parse error has success:false');
  is($parse_err_code,            1,           'parse error exits 1');

  # --ignore-errors silences the parse error JSON but keeps exit code.
  my $ignore_out = `$perl -Ilib $bin validate -iv 32 INVALID_STRING 2>$devnull`;
  is($ignore_out, '', '--ignore-errors silences parse error JSON');
  is($? >> 8,     1,  '--ignore-errors still exits 1');

  subtest 'Clean error messages' => sub {
    my $malformed_str = "Foo";

    # Dump error
    my $dump_err      = `$perl -Ilib $bin dump $malformed_str 2>$devnull`;
    my $dump_err_data = decode_helper($dump_err);
    ok($dump_err_data && $dump_err_data->{error}, "Dump got error for malformed string");
    unlike($dump_err_data->{error}, qr/ at \S+ line \d+/, "Dump error message is clean (no location info)");

    # Validate error
    my $val_err      = `$perl -Ilib $bin validate -v 32 $malformed_str 2>$devnull`;
    my $val_err_data = decode_helper($val_err);
    ok($val_err_data && $val_err_data->{error}, "Validate got error for malformed string");
    unlike($val_err_data->{error}, qr/ at \S+ line \d+/, "Validate error message is clean (no location info)");

    # Initialization error (invalid CLI arg value)
    my $init_stderr = File::Spec->catfile(File::Spec->tmpdir(), "tcf_init_stderr_$$");
    `$perl -Ilib $bin validate -v 32 --cmp-validator /non/existent/file $tc_string 2>$init_stderr`;
    open my $fh, '<', $init_stderr or die "open $init_stderr: $!";
    my $init_msg = do { local $/ = undef; <$fh> };
    close $fh;
    unlink $init_stderr;
    ok($init_msg, "Got initialization error");
    unlike($init_msg, qr/ at \S+ line \d+/, "Initialization error message is clean");
  };
};

subtest '--cmp-validator integration' => sub {
  my $cmp_file   = File::Spec->catfile('t', 'corpus', 'cmp-list.json');
  my $tc_known   = $tc_string;                                                 # CMP 21, present in fixture
  my $tc_unknown = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  # Known CMP: should still validate.
  my $ok_out  = `$perl -Ilib $bin validate -v 1 --cmp-validator $cmp_file $tc_known 2>$devnull`;
  my $ok_data = decode_helper($ok_out);
  ok($ok_data, "known-CMP validate emits JSON");
  is($ok_data->{valid}, JSON->can('true') ? JSON->true() : JSON::PP::true(), "known CMP passes the cmp_validator rule");

  # Unknown CMP: should fail with an unknown-CMP reason.
  my $bad_out  = `$perl -Ilib $bin validate -v 1 --cmp-validator $cmp_file $tc_unknown 2>$devnull`;
  my $bad_code = $? >> 8;
  my $bad_data = decode_helper($bad_out);
  ok($bad_data, "unknown-CMP validate emits JSON");
  is($bad_data->{valid}, $json_false, "unknown CMP fails validation");
  like($bad_data->{reason}, qr/CMP\s+\d+\s+is not valid/, "reason names the bad CMP");
  is($bad_code, 1, "unknown CMP exits 1");

  # URL without --cmp-validator-network-ok: refused (exit 2, message on stderr).
  my $stderr_capture = File::Spec->catfile(File::Spec->tmpdir(), "tcf_cmp_url_stderr_$$");
  my $url_out
    = `$perl -Ilib $bin validate -v 1 --cmp-validator https://example.invalid/x.json $tc_known 2>$stderr_capture`;
  my $url_code = $? >> 8;
  is($url_code, 2,  "URL without --cmp-validator-network-ok exits 2 (bad usage)");
  is($url_out,  '', "URL refusal emits no stdout");
  open my $fh, '<', $stderr_capture or die "Could not read $stderr_capture: $!";
  my $stderr = do { local $/ = undef; <$fh> };
  close $fh;
  unlink $stderr_capture;
  like($stderr, qr/network_ok was not set/, "URL refusal mentions network_ok in the diagnostic");

  # --no-cmp-validator-verify-ssl is accepted as a flag (file path makes
  # the SSL setting moot at runtime, but Getopt::Long must accept it).
  my $no_verify_out
    = `$perl -Ilib $bin validate -v 1 --cmp-validator $cmp_file --no-cmp-validator-verify-ssl $tc_known 2>$devnull`;
  my $no_verify_data = decode_helper($no_verify_out);
  ok($no_verify_data, "--no-cmp-validator-verify-ssl is accepted");
  is(
    $no_verify_data->{valid},
    JSON->can('true') ? JSON->true() : JSON::PP::true(),
    "--no-cmp-validator-verify-ssl does not affect file-path use"
  );

  # --cmp-validator-timeout takes an integer.
  my $timeout_out
    = `$perl -Ilib $bin validate -v 1 --cmp-validator $cmp_file --cmp-validator-timeout 5 $tc_known 2>$devnull`;
  ok(decode_helper($timeout_out), "--cmp-validator-timeout is accepted");
};

subtest '--cmp-validator staleness warning gate' => sub {
  my $cmp_file = File::Spec->catfile('t', 'corpus', 'cmp-list.json');

  # Fixture lastUpdated is 2026-04-01. The repo policy is that this
  # gets older over time — we rely on that fact for this test. Skip
  # if for any reason we are running before the fixture turned 28
  # days old (would never happen on the maintained line, but keeps
  # the test honest if someone backports it onto an older snapshot).
  plan skip_all => "fixture not yet 28 days stale (future-dated run?)"
    if time() < (1743465600 + 28 * 86400);    # 2026-04-01 + 28d

  my $stderr_quiet = File::Spec->catfile(File::Spec->tmpdir(), "tcf_cmp_stale_quiet_$$");
  my $stderr_loud  = File::Spec->catfile(File::Spec->tmpdir(), "tcf_cmp_stale_loud_$$");

  # Without --enable-warnings: staleness carp is suppressed.
  `$perl -Ilib $bin validate -v 1 --cmp-validator $cmp_file $tc_string 2>$stderr_quiet`;
  open my $qfh, '<', $stderr_quiet or die "open $stderr_quiet: $!";
  my $quiet = do { local $/ = undef; <$qfh> };
  close $qfh;
  unlink $stderr_quiet;
  unlike($quiet, qr/CMP list is older than 28 days/, "no staleness warning without --enable-warnings");

  # With --enable-warnings: staleness carp surfaces on stderr.
  `$perl -Ilib $bin validate -wv 1 --cmp-validator $cmp_file $tc_string 2>$stderr_loud`;
  open my $lfh, '<', $stderr_loud or die "open $stderr_loud: $!";
  my $loud = do { local $/ = undef; <$lfh> };
  close $lfh;
  unlink $stderr_loud;
  like($loud, qr/CMP list is older than 28 days/, "staleness warning surfaces with --enable-warnings");
};

done_testing();
