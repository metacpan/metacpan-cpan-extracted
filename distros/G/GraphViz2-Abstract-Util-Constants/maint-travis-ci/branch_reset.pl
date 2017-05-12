#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

if ( not env_true('TRAVIS') ) {
  diag('Is not running under travis!');
  exit 1;
}
diag("Resetting branch to \e[32m$ENV{TRAVIS_BRANCH}\e[0m @ \e[33m$ENV{TRAVIS_COMMIT}\e[0m");
git( 'checkout', $ENV{TRAVIS_BRANCH} );
git( 'reset', '--hard', $ENV{TRAVIS_COMMIT} );
my $goodtag;
do {
  my ( $output, $return ) = capture_stdout {
    safe_exec_nonfatal( 'git', 'describe', '--tags', '--abbrev=0', $ENV{TRAVIS_BRANCH} );
  };
  ($goodtag) = split /\n/, $output;
  if ( not $return ) {
    diag("TIP Version tag is \e[32m$goodtag\e[0m");
  }
};
my %good_tags;
do {
  my $output = capture_stdout {
    git( 'log', '--simplify-by-decoration', '--pretty=format:%d' );
  };
  for my $line ( split /\n/, $output ) {
    if ( $line =~ /\(tag:\s+(.*)\)/ ) {
      my $tag = $1;
      diag("Good tag: \e[32m$tag\e[0m");
      $good_tags{$tag} = 1;
    }
    else {
      diag("Line not matched regexp: <\e[31m$line\e[0m>");
    }
  }
};
do {
  my $output = capture_stdout {
    git('tag');
  };
  for my $line ( split /\n/, $output ) {
    next if $good_tags{$line};
    diag("Bad tag: \e[31m$line\e[0m");
    git( 'tag', '-d', $line );
  }
};
