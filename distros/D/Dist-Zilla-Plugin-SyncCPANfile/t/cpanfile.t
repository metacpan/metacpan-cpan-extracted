#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestCPANfile;
use Clone qw(clone);

sub test_cpanfile {
    my $desc    = shift;
    my $prereqs = shift;
    my $test    = build_dist( clone( $prereqs ), @_);

    my $content = $test->{cpanfile}->slurp_raw;
    ok check_cpanfile( $content, $prereqs ), $desc;
}

test_cpanfile
  'default cpanfile';

test_cpanfile
  'simple prereq',
  [
      Prereqs => [
          Mojolicious => 8,
      ]
  ]
;

test_cpanfile
  'complex list prereq',
  [
      Prereqs => [
          Mojolicious => 8,
      ],
      'Prereqs / TestRecommends' => [
          Moo => 2,
      ],
      'Prereqs/Hallo' => [
          -phase => 'test',
          -relationship => 'requires',

          'Test::More' => 1
      ]
  ]
;

done_testing;
