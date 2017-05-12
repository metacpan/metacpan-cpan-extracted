#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 4 }

use FTN::Address;

my @addr = ('2:550/357',
            '2:550/357.1',
            '2:550/0',
            '2:550/4077',
           );

my @res =  ('2:550/357.0',
            '2:550/357.1',
            '2:550/0.0',
            '2:550/4077.0',
           );

foreach my $i (0 .. $#addr) {
  my $node = new FTN::Address($addr[$i]);
  die $@ unless $node;
  ok($node->get(), $res[$i]);
}

exit;
