#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestCPANfile;
use Clone qw(clone);

sub test_cpanfile {
    my $desc    = shift;
    my $prereqs = shift;
    my $config  = shift;
    my $test    = build_dist( clone( $prereqs ), $config);

    is $test->{cpanfile}->basename, $config->{filename}, 'Check filename';
    my $content = $test->{cpanfile}->slurp_raw;
    ok check_cpanfile( $content, $prereqs ), $desc;
}

test_cpanfile
  'change cpanfile name',
  [],
  { filename => 'test.cpanfile' }
;


test_cpanfile
  'change cpanfile name - simple prereq',
  [
      Prereqs => [
          'Mojo::File' => 8,
      ]
  ],
  { filename => 'test.cpanfile' }
;

test_cpanfile
  'change cpanfile name - complex list prereq',
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
  ],
  { filename => 'test.cpanfile' }
;

done_testing;
