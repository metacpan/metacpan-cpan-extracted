use strict;
use warnings;

use Test::More;
use JSON::PP;
use FindBin;
use File::Spec;
use IO::Uncompress::Gunzip qw($GunzipError);
use lib 'lib';
use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Validator;

# Replays the validator scenarios listed in t/corpus/validator_scenarios.pl
# against every TC string in the golden corpus and diffs the live results
# against the pre-recorded outcomes under tests.validator.<scenario_name>.
#
# To regenerate after intentionally changing validator behavior:
#     REGEN_CORPUS=1 prove -lr t/07-golden.t
# then inspect the diff and commit t/corpus/golden.jsonl.gz alongside the
# code change.

my $corpus_dir     = File::Spec->catdir($FindBin::Bin, 'corpus');
my $golden_file    = File::Spec->catfile($corpus_dir, 'golden.jsonl.gz');
my $scenarios_file = File::Spec->catfile($corpus_dir, 'validator_scenarios.pl');

if (!-f $golden_file) {
  plan skip_all => "Golden file $golden_file not found";
}
if (!-f $scenarios_file) {
  plan skip_all => "Scenario list $scenarios_file not found";
}

my $scenarios = do $scenarios_file or die "Could not load $scenarios_file: " . ($@ || $!);

# Pre-build the Validators once; they are pure functions of their args.
my @validators
  = map { {name => $_->{name}, validator => GDPR::IAB::TCFv2::Validator->new(%{$_->{args}}),} } @{$scenarios};

my $fh   = IO::Uncompress::Gunzip->new($golden_file) or die "Could not open $golden_file: $GunzipError";
my $json = JSON::PP->new->utf8;

my $count         = 0;
my $checked_count = 0;

while (my $line_json = <$fh>) {
  chomp $line_json;
  next unless $line_json;

  my $entry = $json->decode($line_json);
  $count++;

  # Parse-failure entries don't carry a validator section.
  next if $entry->{expect_failure};

  my $expected = $entry->{tests}{validator};
  next unless $expected;    # forward compat with pre-Phase-2 corpora

  $checked_count++;

  my $consent = eval {
    GDPR::IAB::TCFv2->Parse($entry->{tc_string}, json => {boolean_values => [JSON::PP::false, JSON::PP::true]});
  };
  if (my $err = $@) {
    fail("String $count: parse failed unexpectedly: $err");
    next;
  }

  for my $entry_v (@validators) {
    my $name        = $entry_v->{name};
    my $expected_sc = $expected->{$name};

    # If the scenario list has grown since the corpus was last
    # regenerated, skip rather than fail -- the user will hit this
    # legitimately on the regen iteration before they re-run prove.
    next unless $expected_sc;

    my $result = $entry_v->{validator}->validate_all($consent);
    my $got    = {valid => $result->is_valid ? JSON::PP::true : JSON::PP::false, reasons => [$result->reasons],};

    is_deeply $got, $expected_sc, "String $count: validator scenario '$name' matches golden";
  }
}

close $fh;

# Always emit at least one assertion so the file doesn't degrade to a
# bare `1..0` (which prove reports as exit 255 even when Perl returns 0).
# A corpus that pre-dates the validator section is legitimate -- it just
# means the section gets added on the next regen.
ok(1,
  $checked_count
  ? "replayed $checked_count corpus entries through validator scenarios"
  : "no tests.validator section in corpus -- " . "regenerate with REGEN_CORPUS=1 prove -lr t/07-golden.t");

done_testing;
