#!/usr/bin/env perl -w

use strict;
use Test;
BEGIN { plan tests => 11 }

use FTN::Nodelist;

my $ndl = new FTN::Nodelist(-file=>'t/nodelist.*');

my %nodes = (
             '2:2/0'      => 'Belgium',
             '2:2/5501'   => 'IP Gate Z1',
             '2:2/5503'   => 'IP Gate Z3',
             '2:2/5504'   => 'IP Gate Z4',
             '2:2/5505'   => 'IP Gate Z5',
             '2:2/5506'   => 'IP Gate Z6',
             '2:55/0'     => 'IP-ONLY Region',
             '2:550/0'    => 'IP-ONLY Net',
             '2:550/357'  => 'Kijow Ukraina',
             '2:550/4077' => 'Dniepropetrowsk Ukraine',
             '2:550/9999' => 'Net550 Freezer',
            );

foreach my $addr (keys %nodes) {
  my $node = $ndl->getNode($addr);
  die $@ unless $node;
  ok($node->location(), $nodes{$addr});
}

exit;
