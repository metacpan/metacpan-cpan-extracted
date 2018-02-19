#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestBadges;

sub test_badges {
  my $desc = pop;
  my $test = build_dist(@_);

  subtest $desc, sub {
    my $patterns = badge_patterns(@$test{qw( user repo )});

    my $content = $test->{readme}->slurp_raw;

    foreach my $badge ( sort keys %$patterns ){
      if( grep { $_ eq $badge } @{ $test->{plugin}->badges } ){
        like $content, $patterns->{ $badge },
          "readme contains $badge";
      }
      else {
        unlike $content, $patterns->{ $badge },
          "not present: $badge";
      }
    }
  };
}

test_badges
  'default badges';

test_badges
  {
    badges => [qw(
      gitter
      issues
      github_tag
      license
      version
    )],
  },
  'non default badges';

test_badges
  {
    badges => [qw(
	gitlab_ci
	gitlab_cover
    )],
  },
  'gitlab badges';


done_testing;
