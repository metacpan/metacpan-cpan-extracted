use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON::PP;
use FindBin;
use File::Spec;
use IO::Uncompress::Gunzip qw($GunzipError);
use lib 'lib';
use GDPR::IAB::TCFv2;

# The golden corpus is shipped gzipped (~16x smaller).  To inspect a regen
# diff locally:
#   gunzip -c t/corpus/golden.jsonl.gz | diff - <(git show HEAD:t/corpus/golden.jsonl.gz | gunzip -c)
my $corpus_dir  = File::Spec->catdir($FindBin::Bin, 'corpus');
my $golden_file = File::Spec->catfile($corpus_dir, 'golden.jsonl.gz');

# Support regeneration via environment variable
if ($ENV{REGEN_CORPUS}) {
  diag("Regenerating corpus...");
  my $generator = File::Spec->catfile($FindBin::Bin, 'generate_golden.pl');
  system($^X, '-Ilib', $generator) == 0 or die "Failed to regenerate corpus: $!";
}

if (!-f $golden_file) {
  plan skip_all => "Golden file $golden_file not found";
}

my $fh   = IO::Uncompress::Gunzip->new($golden_file) or die "Could not open $golden_file: $GunzipError";
my $json = JSON::PP->new->utf8;

my $count = 0;
while (my $line_json = <$fh>) {
  chomp $line_json;
  next unless $line_json;

  my $entry     = $json->decode($line_json);
  my $tc_string = $entry->{tc_string};

  $count++;

  # Grouping each entry under a subtest collapses ~7 ok-records into 1 at the
  # outer level and lets Test2 release per-ok history between iterations.
  # Important for memory-tight smokers (e.g. OmniOS/Solaris on threaded perl).
  subtest "String $count" => sub {
    if ($entry->{expect_failure}) {
      throws_ok { GDPR::IAB::TCFv2->Parse($tc_string); }
      qr/\Q$entry->{error_match}\E/, "should fail as expected";
      return;
    }

    my $consent;
    lives_ok {
      $consent = GDPR::IAB::TCFv2->Parse($tc_string, json => {boolean_values => [JSON::PP::false, JSON::PP::true]});
    }
    "parsed successfully";

    return unless $consent;

    my $tests = $entry->{tests};

    is_deeply_with_diag($consent->TO_JSON, $tests->{to_json}, "TO_JSON match");

    is($consent->version,         $tests->{metadata}->{version},       "version match");
    is($consent->cmp_id,          $tests->{metadata}->{cmp_id},        "cmp_id match");
    is(scalar($consent->created), $tests->{metadata}->{created_epoch}, "created match");

    my $sampling = $tests->{sampling};
    foreach my $key (keys %{$sampling}) {
      if ($key eq 'purpose_1_consent') {
        is(!!$consent->is_purpose_consent_allowed(1), !!$sampling->{$key}, "$key match");
      }
      elsif ($key eq 'vendor_284_consent') {
        is(!!$consent->vendor_consent(284), !!$sampling->{$key}, "$key match");
      }
      elsif ($key eq 'vendor_284_purpose_1_allowed' && $consent->can('is_vendor_consent_allowed')) {
        is(!!$consent->is_vendor_consent_allowed(284, 1), !!$sampling->{$key}, "$key match");
      }
    }
  };
}

sub is_deeply_with_diag {
  my ($got, $expected, $name) = @_;
  if (!is_deeply($got, $expected, $name)) {
    diag("\n" . ("!" x 60));
    diag("GOLDEN FILE MISMATCH DETECTED");
    diag("If this is expected (e.g. intentional logic change), regenerate the corpus with:");
    diag("  REGEN_CORPUS=1 prove -l $0");
    diag(("!" x 60) . "\n");
    return 0;
  }
  return 1;
}

done_testing;
