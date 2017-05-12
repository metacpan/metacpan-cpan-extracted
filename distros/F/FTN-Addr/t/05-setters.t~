#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 97;

BEGIN {
	use_ok( 'FTN::Addr' );
}

my %test_addrs = ('2:451/31' => ['fidonet', 2, 451, 31, 0, '2:451/31', '2:451/31.0', '2:451/31@fidonet', '2:451/31.0@fidonet', 'fidonet.2.451.31.0'],
		  '2:5020/400' => ['fidonet', 2, 5020, 400, 0, '2:5020/400', '2:5020/400.0', '2:5020/400@fidonet', '2:5020/400.0@fidonet', 'fidonet.2.5020.400.0'],
		  '2:5020/52@deadnet' => ['deadnet', 2, 5020, 52, 0, '2:5020/52', '2:5020/52.0', '2:5020/52@deadnet', '2:5020/52.0@deadnet', 'deadnet.2.5020.52.0'],
		  '2:451/23.0' => ['fidonet', 2, 451, 23, 0, '2:451/23', '2:451/23.0', '2:451/23@fidonet', '2:451/23.0@fidonet', 'fidonet.2.451.23.0'],
		  '2:451/23.11' => ['fidonet', 2, 451, 23, 11, '2:451/23.11', '2:451/23.11', '2:451/23.11@fidonet', '2:451/23.11@fidonet', 'fidonet.2.451.23.11'],
                  '2:451/31.4' => ['fidonet', 2, 451, 31, 4, '2:451/31.4', '2:451/31.4', '2:451/31.4@fidonet', '2:451/31.4@fidonet', 'fidonet.2.451.31.4'],
		  '2:5020/400.44' => ['fidonet', 2, 5020, 400, 44, '2:5020/400.44', '2:5020/400.44', '2:5020/400.44@fidonet', '2:5020/400.44@fidonet', 'fidonet.2.5020.400.44'],
		  '2:5020/52.6@deadnet' => ['deadnet', 2, 5020, 52, 6, '2:5020/52.6', '2:5020/52.6', '2:5020/52.6@deadnet', '2:5020/52.6@deadnet', 'deadnet.2.5020.52.6'],
		  );

my $node;

while (my ($t_addr, $t_exp) = each %test_addrs) {
  if (defined $node) {
    $node = $node -> new($t_addr);
  } else {
    $node = FTN::Addr -> new($t_addr);
  }
  ok(defined $node, "new('$t_addr') returned something");
  ok($node -> isa('FTN::Addr'), "  and it's the right class\t($t_addr)");
  is($node -> domain, $t_exp -> [0], "  domain\t($t_addr)");
  is($node -> zone, $t_exp -> [1], "  zone\t($t_addr)");
  is($node -> net, $t_exp -> [2], "  net\t($t_addr)");
  is($node -> node, $t_exp -> [3], "  node\t($t_addr)");
  is($node -> point, $t_exp -> [4], "  point\t($t_addr)");
  is($node -> s4, $t_exp -> [5], "  short 4d\t($t_addr)");
  is($node -> f4, $t_exp -> [6], "  full 4d\t($t_addr)");
  is($node -> s5, $t_exp -> [7], "  short 5d\t($t_addr)");
  is($node -> f5, $t_exp -> [8], "  full 5d\t($t_addr)");
  is($node -> bs, $t_exp -> [9], "  brake style\t($t_addr)");
}
