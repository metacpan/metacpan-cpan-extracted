#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Validator;
use JSON::PP;
use FindBin;
use File::Spec;
use IO::Compress::Gzip qw($GzipError);

my $corpus_dir     = File::Spec->catdir($FindBin::Bin, 'corpus');
my $input_file     = File::Spec->catfile($corpus_dir, 'gdpr_subset.txt');
my $output_file    = File::Spec->catfile($corpus_dir, 'golden.jsonl.gz');
my $scenarios_file = File::Spec->catfile($corpus_dir, 'validator_scenarios.pl');

# Canonical scenario list shared with t/08-golden-validator.t.  Pre-build
# the Validator instances once -- their constructors are pure functions
# of the args, so there is no need to re-instantiate per TC string.
my $scenarios = do $scenarios_file or die "Could not load $scenarios_file: " . ($@ || $!);
my @validators
  = map { {name => $_->{name}, validator => GDPR::IAB::TCFv2::Validator->new(%{$_->{args}}),} } @{$scenarios};

open my $ifh, '<', $input_file or die "Could not open $input_file: $!";
my $ofh  = IO::Compress::Gzip->new($output_file, Level => 9) or die "Could not open $output_file: $GzipError";
my $json = JSON::PP->new->canonical->utf8;

while (my $line = <$ifh>) {
  chomp $line;
  next unless $line;

  eval {
    my $consent = GDPR::IAB::TCFv2->Parse($line, json => {boolean_values => [JSON::PP::false, JSON::PP::true]});

    my $data = {
      tc_string      => $line,
      expect_failure => JSON::PP::false,
      tests          => {
        to_json  => $consent->TO_JSON,
        metadata =>
          {version => $consent->version, cmp_id => $consent->cmp_id, created_epoch => scalar($consent->created),},
        sampling => {
          purpose_1_consent  => $consent->is_purpose_consent_allowed(1) ? JSON::PP::true : JSON::PP::false,
          vendor_284_consent => $consent->vendor_consent(284)           ? JSON::PP::true : JSON::PP::false,
        }
      }
    };

    # Add new methods if they exist (Phase 0+)
    if ($consent->can('is_vendor_consent_allowed')) {
      $data->{tests}{sampling}{vendor_284_purpose_1_allowed} = $consent->is_vendor_consent_allowed(284, 1) ? \1 : \0;
    }

    # Validator scenarios (Phase 2+).  Use validate_all so the
    # golden captures every reason, not just the fail-fast first one.
    my %validator_results;
    for my $entry (@validators) {
      my $result = $entry->{validator}->validate_all($consent);
      $validator_results{$entry->{name}}
        = {valid => $result->is_valid ? JSON::PP::true : JSON::PP::false, reasons => [$result->reasons],};
    }
    $data->{tests}{validator} = \%validator_results;

    print $ofh $json->encode($data) . "\n";
  };
  if ($@) {
    my $err = $@;
    $err =~ s/ at .* line \d+.*//s;    # Strip file/line for better matching
    print $ofh $json->encode({tc_string => $line, expect_failure => JSON::PP::true, error_match => $err,}) . "\n";
  }
}

close $ifh;
close $ofh;

print "Golden file generated at $output_file\n";
