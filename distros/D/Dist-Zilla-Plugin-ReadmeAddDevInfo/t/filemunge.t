#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestInfo;

my $info = qr/\#\s+Development.*?--release\n```\n+\#\s+AUTHOR/s;

subtest 'filemunge' => sub {
  my $test = build_dist({phase => 'filemunge', before => '# AUTHOR', add_contribution_file => 1 }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker"
  });

  unlike $test->{readme}->slurp_raw, $info,
    'dist built, info not yet added';

  $test->{zilla}->release;

  my $readme = $test->{readme}->slurp_raw;

  unlike $readme,
    qr/$info/,
    "info isn't added in filemunge at all";

  my $contrib = $test->{contribution_file}->slurp_raw;

  is $contrib, "\n", "Contribution file not generated";
};

done_testing;
