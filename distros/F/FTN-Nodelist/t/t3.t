#!/usr/bin/env perl -w

use strict;
use Test;
BEGIN { plan tests => 4}

use FTN::Nodelist;

my $ndl = new FTN::Nodelist(-file=>'t/nodelist.*');

my @nodes = (
             '2:55/1',
             '2:55/2',
             '2:55/3',
             '2:55/4',
            );

foreach my $addr (@nodes) {
  my $node = $ndl->getNode($addr);
  ok($node, undef);
}

exit;
