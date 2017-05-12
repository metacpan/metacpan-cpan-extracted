#!/bin/env perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 4;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(hashgrep n_grep);

# hashgrep
{
  my @match = hashgrep { $a =~ /[aeiou]/i && $b > 100 } (
    apple     => 1,
    cherimoya => 500,
    cwm       => 1000,
    zebra     => 50000,
  );

  use Data::Dumper;
  is_deeply( \@match, [cherimoya => 500, zebra => 50000], 'hashgrep works and maintains order' )
    or warn Data::Dumper::Dumper \@match;
}

# n_grep
{
  my (@thorax) = Hash::MostUtils::n_grep(3, sub { $::a == 4 && $::b == 5 && $::c == 6 }, (1..9));
  is_deeply( \@thorax, [4, 5, 6], 'can grep out the middle three numbers' );
}

# we don't nuke your existing variables
{
  my ($a, $b, $c, $d) = (1..4);
  hashgrep { 1 } ('a'..'z');
  is_deeply( [$a, $b, $c, $d], [1..4], 'hashgrep localized variables properly' );

  n_grep(7, sub { 1 }, 'a'..'n');
  is_deeply( [$a, $b, $c, $d], [1..4], 'n_grep localized variables properly' );
}
