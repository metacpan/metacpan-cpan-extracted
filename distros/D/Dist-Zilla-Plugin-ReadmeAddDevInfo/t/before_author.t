#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestInfo;

my $info = qr/\#\s+Development.*?--release\n```\n+\#\s+AUTHOR/s;

subtest 'after build' => sub {
  my $test = build_dist({ before => '# AUTHOR' }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker"
  });

  like $test->{readme}->slurp_raw,
    qr/$info/,
    'info added after build';

  unlike $test->{readme}->slurp_raw, qr/^release/m, 'not yet released';

  $test->{zilla}->release;

  like $test->{readme}->slurp_raw,
    qr/$info\n+.*release\z/sm,
    'info added between build and release';
};

subtest 'after release' => sub {
  my $test = build_dist({phase => 'release', before => '# AUTHOR' }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker"
  });

  unlike $test->{readme}->slurp_raw, $info,
    'dist built, info not yet added';

  $test->{zilla}->release;

  my $readme = $test->{readme}->slurp_raw;

  like $readme,
    qr/$info/,
    'info added after release';

  like $readme,
    qr/cd Test-DevInfo/,
    'used git repository name to `cd` in';
};

done_testing;
