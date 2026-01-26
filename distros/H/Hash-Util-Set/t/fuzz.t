#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok('Hash::Util::Set::PP', qw[ keys_union
                                    keys_intersection
                                    keys_difference
                                    keys_symmetric_difference
                                    keys_disjoint
                                    keys_equal
                                    keys_subset
                                    keys_proper_subset
                                    keys_superset
                                    keys_proper_superset
                                    keys_any
                                    keys_all
                                    keys_none ]);
}

sub TRUE    () { !!1 }
sub FALSE   () { !!0 }

sub MAX_KEY () {   64 }
sub ROUNDS  () { 1000 }

sub rand_hash {
  my %h;
  for my $k (0..MAX_KEY - 1) {
    $h{$k} = 1 if rand() < 0.5;
  }
  return %h;
}

sub hash_to_vec {
  my ($h) = @_;
  my $v = "\x00" x 8;
  vec($v, $_, 1) = 1 for keys %$h;
  return $v;
}

sub vec_keys {
  my ($v) = @_;
  return grep { vec($v, $_, 1) } 0..MAX_KEY - 1;
}

sub vec_any {
  my ($v, @k) = @_;
  return FALSE unless @k;
  for (@k) {
    return TRUE if vec($v, $_, 1);
  }
  return FALSE;
}

sub vec_all {
  my ($v, @k) = @_;
  for (@k) {
    return FALSE unless vec($v, $_, 1);
  }
  return TRUE;
}

sub vec_none {
  my ($v, @k) = @_;
  for (@k) {
    return FALSE if vec($v, $_, 1);
  }
  return TRUE;
}

for (1..ROUNDS) {
  my %x = rand_hash();
  my %y = rand_hash();

  my $vx = hash_to_vec(\%x);
  my $vy = hash_to_vec(\%y);

  vec($vx, MAX_KEY - 1, 1) |= 0;
  vec($vy, MAX_KEY - 1, 1) |= 0;

  {
    my $got = [ sort { $a <=> $b } keys_union %x, %y ];
    my $exp = [ vec_keys($vx | $vy) ];
    is_deeply($got, $exp, 'union');
  }

  {
    my $got = [ sort { $a <=> $b } keys_intersection %x, %y ];
    my $exp = [ vec_keys($vx & $vy) ];
    is_deeply($got, $exp, 'intersection');
  }

  {
    my $got = [ sort { $a <=> $b } keys_difference %x, %y ];
    my $exp = [ vec_keys($vx & ~$vy) ];
    is_deeply($got, $exp, 'difference');
  }

  {
    my $got = [ sort { $a <=> $b } keys_symmetric_difference %x, %y ];
    my $exp = [ vec_keys($vx ^ $vy) ];
    is_deeply($got, $exp, 'symmetric difference');
  }

  is(keys_disjoint(%x, %y), !($vx & $vy), 'disjoint');
  is(keys_equal(%x, %y), ($vx eq $vy), 'equal' );
  is(keys_subset(%x, %y), !($vx & ~$vy), 'subset');
  is(keys_proper_subset(%x, %y), (!($vx & ~$vy) && $vx ne $vy), 'proper subset');
  is(keys_superset(%x, %y), !($vy & ~$vx), 'superset');
  is(keys_proper_superset(%x, %y), (!($vy & ~$vx) && $vx ne $vy), 'proper superset');

  {
    my @k = map { int rand MAX_KEY } 0..int rand 10;

    is(keys_any(%x, @k), vec_any($vx, @k), 'keys_any');
    is(keys_all(%x, @k), vec_all($vx, @k), 'keys_all');
    is(keys_none(%x, @k), vec_none($vx, @k), 'keys_none');
  }
}

done_testing;
