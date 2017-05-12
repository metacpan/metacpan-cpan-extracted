#!/bin/env perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 3;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(hashsort);

# hashsort
{
  # it's called 'hashsort' but we sort an array - because otherwise it's hard to convince ourselves
  # that (a) hashsort doesn't do anything, and (b) the %data just happens to be ordered in a way that
  # allows the test to pass
  my @data = (
    revenue     => 10,
    SEARCH      => 20,
    contributor => 30,
  );

  my @descending_by_value = hashsort { $b->{value} <=> $a->{value} } @data;
  is_deeply( \@descending_by_value, [contributor => 30, SEARCH => 20, revenue => 10], 'hashsort by ->{value} works' );

  my @asciibetical_by_key = hashsort { $a->{key} cmp $b->{key} } @data;
  is_deeply( \@asciibetical_by_key, [SEARCH => 20, contributor => 30, revenue => 10], 'hashsort by ->{key} works' );
}

# we don't nuke your existing variables
{
  my ($a, $b, $c, $d) = (1..4);
  hashsort { 1 } ('a'..'z');
  is_deeply( [$a, $b, $c, $d], [1..4], 'hashsort localized variables properly' );
}

