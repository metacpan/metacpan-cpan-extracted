#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestInfo;

my $info = qr/\#\s+Development.*?--release\n```\n/s;

subtest 'after build' => sub {
  my $test = build_dist({}, {
    plugins => ['PhaseReadme'],
    content => 'readme'
  });

  like $test->{readme}->slurp_raw,
    qr/$info\z/,
    'badges added after build';

  unlike $test->{readme}->slurp_raw, qr/^release/m, 'not yet released';

  $test->{zilla}->release;

  like $test->{readme}->slurp_raw,
    qr/$info\n+release\z/m,
    'info added between build and release';
};

subtest 'after release' => sub {
  my $test = build_dist({phase => 'release'}, {
    plugins => ['PhaseReadme'],
    content => 'readme'
  });

  unlike $test->{readme}->slurp_raw, $info,
    'dist built, info not yet added';

  $test->{zilla}->release;

  like $test->{readme}->slurp_raw,
    qr/$info\z/,
    'info added after release';
};

done_testing;
