#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark qw(:all);
use lib 'lib';
use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Validator;

# Phase 4 benchmark harness.  Loads the 1024-string TC-string corpus
# from t/corpus/gdpr_subset.txt and exercises the hot paths:
#
#   * raw Parse
#   * Parse + TO_JSON   (covers the BitField / RangeSection serialization
#                        path that is the TC-string -> JSON bridge)
#   * Validator->validate     (fail-fast)
#   * Validator->validate_all (accumulate every reason)
#
# `cmpthese -5` runs each benchmark for at least 5 wall-clock seconds.
# An additional `timeit` block prints absolute throughput numbers for
# easy comparison across runs / branches.
#
# Run:   perl -Ilib bench/performance.pl
#
# To compare two branches, run on each, capture the output, and diff.
# Numbers will fluctuate by a few percent run to run; only treat
# differences greater than ~5% as signal.

my $corpus_file = 't/corpus/gdpr_subset.txt';

open my $fh, '<', $corpus_file or die "Could not open $corpus_file: $!\n" . "(run from the distribution root)";
chomp(my @strings = <$fh>);
close $fh;
@strings = grep {length} @strings;

my $simple_validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 284, consent_purpose_ids => [1, 3],);

print "Benchmarking against ", scalar(@strings), " TC strings...\n\n";

my $idx = 0;
cmpthese(
  -5,
  {
    '01_Parse' => sub {
      GDPR::IAB::TCFv2->Parse($strings[$idx++ % @strings]);
    },
    '02_Parse+TO_JSON' => sub {
      my $tcf = GDPR::IAB::TCFv2->Parse($strings[$idx++ % @strings]);
      $tcf->TO_JSON;
    },
    '03_Validate' => sub {
      $simple_validator->validate($strings[$idx++ % @strings]);
    },
    '04_Validate_all' => sub {
      $simple_validator->validate_all($strings[$idx++ % @strings]);
    },
  }
);

print "\nAbsolute throughput (50_000 iterations, single-thread):\n";

for my $bench (
  ['Parse', sub { GDPR::IAB::TCFv2->Parse($strings[$idx++ % @strings]) }],
  [
    'Parse+TO_JSON',
    sub {
      my $tcf = GDPR::IAB::TCFv2->Parse($strings[$idx++ % @strings]);
      $tcf->TO_JSON;
    }
  ],
  ['Validate', sub { $simple_validator->validate($strings[$idx++ % @strings]) }],
  )
{
  my $count = 50_000;
  my $t     = timeit($count, $bench->[1]);
  my $sec   = $t->[0] + $t->[1] || 1;
  printf "  %-15s %10.0f ops/sec   (%.3fs cpu)\n", $bench->[0], $count / $sec, $sec;
}
