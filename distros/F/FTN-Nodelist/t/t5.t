#!/usr/bin/env perl -w

use strict;
use Test;
BEGIN { plan tests => 4 }

use FTN::Nodelist;

my $ndl = new FTN::Nodelist(-file=>'t/pntlist2.*');

my %nodes = (
             '2:550/357.1'      => 'Dniepropetrowsk Ukraine',
             '2:550/357.601'    => 'Krasnoyarsk-26 Russia',
             '2:550/4077.740'   => 'Ust-Kamenogorsk Kazakhstan',
             '2:550/4077.32767' => 'Oikumena Universe',
            );

foreach my $addr (keys %nodes) {
  my $node = $ndl->getNode($addr);
  die $@ unless $node;
  ok($node->location(), $nodes{$addr});
}

exit;
