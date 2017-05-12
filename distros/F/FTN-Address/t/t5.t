#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 5 }

use FTN::Address;

my @addr = ('2:550/357',
            '2:550/0',
            '2:463/4077',
            '2:550/4077@othernet',
            '2:550/357.1',
           );

my @dom =  ('net',
            'org',
            'kiev.ua',
            'com',
            'biz',
           );

my @res =  ('f357.n550.z2.fidonet.net',
            'f0.org',
            'f4077.n463.kiev.ua',
            'f4077.n550.z2.com',
            'p1.f357.n550.z2.biz'
           );

foreach my $i (0 .. $#addr) {
  if (my $node = empty FTN::Address()) {
    $node->assign($addr[$i]);

    print $node->fqdn($dom[$i], $i), "\n\n";

    ok($node->fqdn($dom[$i], $i), $res[$i]);
  } else {
    ok('object', 'failed') unless $node;
  }
}

exit;
