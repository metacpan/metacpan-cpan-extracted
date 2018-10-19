#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestInfo;

my $info = qr/\#\s+Development.*?--release\n```/s;

subtest 'after build' => sub {
  my $test = build_dist({ add_contribution_file => 1 }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker"
  });

  like $test->{contribution_file}->slurp_raw,
    qr/$info/,
    'info added after build';

};

subtest 'after release' => sub {
  my $test = build_dist({phase => 'release', add_contribution_file => 1 }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker"
  });

  unlike $test->{contribution_file}->slurp_raw, $info,
    'dist built, info not yet added';

  $test->{zilla}->release;

  like $test->{contribution_file}->slurp_raw,
    qr/$info/,
    'info added after build';
};

done_testing;
