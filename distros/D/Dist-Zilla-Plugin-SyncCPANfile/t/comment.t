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

    my $content = $test->{cpanfile}->slurp_raw;
    ok check_cpanfile( $content, $prereqs ), $desc;

    my $comment = $config->{comment} || '';
    like $content, qr/\Q$comment\E/, "Check Comment";
}

test_cpanfile
  'original comment',
  []
;

test_cpanfile
  'changed comment',
  [],
  { comment => 'This is a changed comment!' }
;


test_cpanfile
  'original comment - simple prereq',
  [
      Prereqs => [
          'Mojo::File' => 8,
      ]
  ]
;

test_cpanfile
  'changed comment - simple prereq',
  [
      Prereqs => [
          'Mojo::File' => 8,
      ]
  ],
  { comment => 'This is a changed comment!' }
;

done_testing;
