#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestInfo;

my $info = qr/\#\s+Development.*?--release\n```\n+\#\s+AUTHOR/s;

subtest 'no git repository at all' => sub {
  my $test = build_dist({ before => '# AUTHOR', add_contribution_file => 1 }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker",
    MetaResources => {
      'repository.url' => undef,
    },
  });

  my $contrib = $test->{contribution_file}->slurp_raw;
  is $contrib, "\n";
};

subtest 'no git repository name' => sub {
  my $test = build_dist({ before => '# AUTHOR', add_contribution_file => 1 }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker",
    MetaResources => {
      'repository.url' => 'https://github.com/reneeb/',
    },
  });

  my $contrib = $test->{contribution_file}->slurp_raw;
  is $contrib, "\n";
};

subtest 'git repositry has different name than dist' => sub {
  my $test = build_dist({ before => '# AUTHOR', add_contribution_file => 1 }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker",
    MetaResources => {
      'repository.url' => 'https://github.com/reneeb/anything.git',
    },
  });

  like $test->{readme}->slurp_raw,
    qr/$info/,
    'info added after build';

  unlike $test->{readme}->slurp_raw, qr/^release/m, 'not yet released';

  $test->{zilla}->release;

  my $readme = $test->{readme}->slurp_raw;

  like $readme,
    qr/$info\n+.*release\z/sm,
    'info added between build and release';

  my $contrib = $test->{contribution_file}->slurp_raw;

  like $contrib,
    qr/cd anything/,
    'used git repository name to `cd` in';
};

subtest 'no .git suffix' => sub {
  my $test = build_dist({ before => '# AUTHOR', add_contribution_file => 1  }, {
    plugins => ['PhaseReadme'],
    content => "readme\n# AUTHOR\n\nRenee Baecker",
    MetaResources => {
      'repository.url' => 'https://github.com/reneeb/anything',
    },
  });

  like $test->{readme}->slurp_raw,
    qr/$info/,
    'info added after build';

  unlike $test->{readme}->slurp_raw, qr/^release/m, 'not yet released';

  $test->{zilla}->release;

  my $readme = $test->{readme}->slurp_raw;

  like $readme,
    qr/$info\n+.*release\z/sm,
    'info added between build and release';

  my $contrib = $test->{contribution_file}->slurp_raw;

  like $contrib,
    qr/cd anything/,
    'used git repository name to `cd` in';
};

done_testing;
