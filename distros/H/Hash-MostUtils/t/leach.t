#!/usr/bin/env perl

use strict;
use warnings; no warnings 'once';

use Test::More tests => 10;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(leach hashmap n_each n_map);

{
  my @list = (1..10);
  my @got;
  while (my ($k, $v) = leach @list) {
    push @got, [$k, $v];
  }
  is_deeply( \@got, [hashmap { [$a, $b] } @list], 'list-each works for arrays' );
}

# you can leach a list twice and get the same results
{
  my @list = (1..10);

  my @got1;
  while (my ($k, $v) = leach @list) {
    push @got1, [$k, $v];
  }

  my @got2;
  while (my ($k, $v) = leach @list) {
    push @got2, [$k, $v];
  }

  is_deeply( \@got2, \@got1, 'list-each works twice in a row' );
}

{
  my @list = (1..9);
  my @got = ();
  while (my ($k, $v1, $v2) = n_each 3, @list) {
    push @got, [$k, $v1, $v2];
  }
  is_deeply( \@got, [n_map 3, sub { [$::a, $::b, $::c] }, @list], 'n_each works' );
}

{
  my @list = (1..10);
  my @got = ();
  while (my ($k, $v) = leach @list) {
    @list = () if $k == 1;
    push @got, [$k, $v];
  }
  is_deeply( \@got, [[1, 2]], 'mutating @list updated $leach object' );
  is_deeply( \@list, [], 'we set @list to ()' );
}

# Aaron Cohen (morninded) pointed out that the implementation of n_each would allow
# this to work. Here's a test to lock it down against refactorings.
{
  my @list = (
    a => 1..1,
    b => 1..2,
    c => 1..3,
    d => 1..4,
    e => 1..5,
    f => 1..6,
    g => 1..7,
  );

  my %hash;
  my $n = 2;
  while (my ($k, @v) = n_each $n++, @list) {
    $hash{$k} = \@v;
  }

  is_deeply( \%hash, +{
    a => [1..1],
    b => [1..2],
    c => [1..3],
    d => [1..4],
    e => [1..5],
    f => [1..6],
    g => [1..7],
  }, 'we can triangle-slice our list' );
}

# leach for hashes: for when you really want each-like behavior for hashes
# *without* keeping an internal iterator on the hash
{
  my %hash = (1..10);
  my %nested;
  while (my ($k, $v) = leach %hash) {
    while (my ($k2, $v2) = each %hash) {
      $nested{$k}{$v2} = 1;
    }
  }

  is_deeply( \%nested, +{
    1 => +{2 => 1, 4 => 1, 6 => 1, 8 => 1, 10 => 1},
    3 => +{2 => 1, 4 => 1, 6 => 1, 8 => 1, 10 => 1},
    5 => +{2 => 1, 4 => 1, 6 => 1, 8 => 1, 10 => 1},
    7 => +{2 => 1, 4 => 1, 6 => 1, 8 => 1, 10 => 1},
    9 => +{2 => 1, 4 => 1, 6 => 1, 8 => 1, 10 => 1},
  }, 'intermixing leach and each on a hash works just fine' );
}

# what happens if we mutate the subject data structure?
{
  my @got;
  foreach (1..100) {
    my %hash = (1..4);
    while (my ($k, $v) = leach %hash) {
      $hash{$v} = $k;
    }
    push @got, \%hash;
  }
  is_deeply( \@got, [(+{1 => 2, 2 => 1, 3 => 4, 4 => 3}) x 100], 'mutating is okay' );
}

# we use refaddr, not "", to get an $ident for our subject data structure
{
  {
    package superheavy; # because it's overloaded, yo
    use strict;
    use warnings;
    use overload '""' => sub { 'hi' };
    sub new { shift; return bless +{@_} }
  }

  my $delta_heavy_one = superheavy->new(1..10);
  my $bravo_heavy_two = superheavy->new(11..20);

  my (%delta, %bravo);
  my $infinite_loop;
local $MY::var = 1; # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  while (my ($k, $v) = leach $delta_heavy_one) {
    $delta{$k} = $v;
    last if $infinite_loop++ > 50;
    while (my ($k2, $v2) = leach $bravo_heavy_two) {
      $bravo{$k2} = $v2;
    }
  }

  ok( $infinite_loop == scalar keys %$delta_heavy_one, 'no infinite loop' );
  is_deeply( \%bravo, {11..20}, 'implementation correctly finds a unique $ident' );
}
