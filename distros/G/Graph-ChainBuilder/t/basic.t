#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use Graph::ChainBuilder;

# splits from a list of "$p0$p1$rev$data" strings
sub build (@) {
  my @input = @_;

  my $graph = Graph::ChainBuilder->new;

  foreach my $v (@input) {
    my ($p0, $p1, @and) = split(//, $v);
    $graph->add($p0, $p1, [@and]);
  }
  return($graph);
}

{
  my $g = build qw(
    AB0
    CB1
    AC1
  );
  my @l = $g->loops;
  is(scalar(@l), 1);
  my @l0 = @{$l[0]};
  push(@l0, shift(@l0)) until($l0[0]->p0 eq 'A');
  my $ans = join(",", map({$_->p0 . $_->p1 . $_->reversed} @l0));
  is($ans, 'AB0,BC1,CA1');
}
{
  my $g = build qw(
    BA1
    CB1
    AC1
  );
  my @l = $g->loops;
  is(scalar(@l), 1);
  my @l0 = @{$l[0]};
  push(@l0, shift(@l0)) until($l0[0]->p0 eq 'A');
  my $ans = join(",", map({$_->p0 . $_->p1 . $_->reversed} @l0));
  is($ans, 'AC0,CB0,BA0');
}

{
  my $g = build qw(
    AB01
    CD03
    HG17
    EF05
    FG06
    HA08
    CB12
    DE04
  );
  # use YAML; warn YAML::Dump($g);
  my @l = $g->loops;
  is(scalar(@l), 1);
  my @l0 = @{$l[0]};
  push(@l0, shift(@l0)) until($l0[0]->p0 eq 'A');
  my $ans = join(",", map({$_->data->[1]} @l0));
  is($ans, '1,2,3,4,5,6,7,8');
}

# vim:ts=2:sw=2:et:sta
